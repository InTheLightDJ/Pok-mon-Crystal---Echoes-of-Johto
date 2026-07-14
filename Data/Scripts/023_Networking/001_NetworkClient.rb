#===============================================================================
# NetworkClient — core TCP connection to the Echoes of Johto server.
#
# Uses Ruby's TCPSocket (available via MKXP-Z) and a background thread for
# non-blocking reads. The main thread calls NetworkClient.update each frame
# to process queued events and fire registered callbacks.
#
# Protocol: newline-delimited JSON over TCP.
#   Send:    NetworkClient.send_msg({ action: "move", x: 5, y: 3 })
#   Receive: callbacks registered with NetworkClient.on("player_moved") { |data| ... }
#===============================================================================

require 'socket'
require 'thread'

# Minimal JSON encoder/decoder — MKXP-Z does not bundle the stdlib json gem.
unless defined?(JSON)
  module JSON
    ParserError = Class.new(StandardError)

    def self.parse(str)
      val, _ = _val(str.strip, 0)
      val
    end

    def self.generate(obj)
      _enc(obj)
    end

    def self._enc(o)
      case o
      when Hash  then "{#{o.map { |k, v| _enc(k.to_s) + ':' + _enc(v) }.join(',')}}"
      when Array then "[#{o.map { |v| _enc(v) }.join(',')}]"
      when String
        '"' + o.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
              .gsub("\n", '\\n').gsub("\r", '\\r').gsub("\t", '\\t') + '"'
      when Integer, Float then o.to_s
      when true  then 'true'
      when false then 'false'
      when nil   then 'null'
      else _enc(o.to_s)
      end
    end

    def self._skip(s, i)
      i += 1 while i < s.length && " \t\n\r".include?(s[i])
      i
    end

    def self._val(s, i)
      i = _skip(s, i)
      c = s[i]
      if    c == '{'  then _obj(s, i)
      elsif c == '['  then _arr(s, i)
      elsif c == '"'  then _str(s, i)
      elsif c == 't'  then [true,  i + 4]
      elsif c == 'f'  then [false, i + 5]
      elsif c == 'n'  then [nil,   i + 4]
      else                 _num(s, i)
      end
    end

    def self._obj(s, i)
      i += 1; obj = {}
      i = _skip(s, i)
      return [obj, i + 1] if s[i] == '}'
      loop do
        i = _skip(s, i)
        k, i = _str(s, i)
        i = _skip(s, i); i += 1
        v, i = _val(s, i)
        obj[k] = v
        i = _skip(s, i)
        break if s[i] == '}'
        i += 1
      end
      [obj, i + 1]
    end

    def self._arr(s, i)
      i += 1; arr = []
      i = _skip(s, i)
      return [arr, i + 1] if s[i] == ']'
      loop do
        v, i = _val(s, i)
        arr << v
        i = _skip(s, i)
        break if s[i] == ']'
        i += 1
      end
      [arr, i + 1]
    end

    def self._str(s, i)
      i += 1; buf = ''
      while i < s.length
        c = s[i]
        if c == '\\'
          i += 1
          case s[i]
          when '"'  then buf << '"'
          when '\\' then buf << '\\'
          when '/'  then buf << '/'
          when 'n'  then buf << "\n"
          when 'r'  then buf << "\r"
          when 't'  then buf << "\t"
          when 'b'  then buf << "\b"
          when 'f'  then buf << "\f"
          when 'u'
            buf << [s[i + 1, 4].to_i(16)].pack('U')
            i += 4
          end
        elsif c == '"'
          # The socket buffer this was sliced from is raw ASCII-8BIT; any
          # non-ASCII byte appended into buf above (e.g. from "Pokémon" or any
          # other accented text the server sends) silently downgrades buf's
          # tag from UTF-8 to ASCII-8BIT via Ruby's ascii_only compatibility
          # rule — no error at parse time, but this string later blows up
          # with Encoding::CompatibilityError the moment it's gsub!'d into a
          # UTF-8 _INTL template that itself has any non-ASCII character.
          # The server always sends UTF-8 (Node's default), so it's always
          # correct to relabel it here.
          return [buf.force_encoding(Encoding::UTF_8), i + 1]
        else
          buf << c
        end
        i += 1
      end
      [buf.force_encoding(Encoding::UTF_8), i]
    end

    def self._num(s, i)
      j = i
      j += 1 if s[j] == '-'
      j += 1 while j < s.length && s[j] >= '0' && s[j] <= '9'
      if j < s.length && s[j] == '.'
        j += 1
        j += 1 while j < s.length && s[j] >= '0' && s[j] <= '9'
        [s[i...j].to_f, j]
      else
        [s[i...j].to_i, j]
      end
    end
  end
end

module NetworkClient
  # Flip to true to connect to localhost instead of the live server (local testing only).
  LOCAL_TEST = false

  # Change for upload

  HOST    = LOCAL_TEST ? '127.0.0.1' : 'pokemonechosofjhoto.duckdns.org'
  PORT    = 5051
  TIMEOUT = 10  # seconds for initial connect

  @socket     = nil
  @recv_queue = Queue.new
  @callbacks  = Hash.new { |h, k| h[k] = [] }
  @recv_thread = nil
  @connected  = false
  @mutex      = Mutex.new

  def self.connected?
    @connected
  end

  # Connect to the server. Returns true on success, false on failure.
  def self.connect(host = HOST, port = PORT)
    return true if @connected
    begin
      @socket = TCPSocket.new(host, port)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @connected = true
      _start_recv_thread
      puts "[Network] Connected to #{host}:#{port}"
      true
    rescue => e
      puts "[Network] Connection failed: #{e.message}"
      @socket = nil
      false
    end
  end

  def self.disconnect
    return unless @connected
    @connected = false
    @recv_thread&.kill rescue nil
    @socket&.close    rescue nil
    @socket = nil
    @recv_thread = nil
    puts "[Network] Disconnected"
  end

  # Send a hash as a JSON message to the server.
  def self.send_msg(hash)
    return unless @connected && @socket
    @mutex.synchronize do
      begin
        @socket.write(JSON.generate(hash) + "\n")
      rescue => e
        puts "[Network] Send error: #{e.message}"
        _handle_disconnect
      end
    end
  end

  # Register a callback for a server event type. Returns the block so it can be
  # passed to remove() for selective cleanup without touching other listeners.
  def self.on(event, &block)
    @callbacks[event] << block
    block
  end

  # Remove one specific callback returned by on(). Leaves other listeners intact.
  def self.remove(event, block)
    @callbacks[event]&.delete(block)
  end

  # Clear all callbacks for an event (useful when changing scenes).
  def self.off(event)
    @callbacks.delete(event)
  end

  # Process all queued messages from the server. Call this each frame.
  # Hook this into your scene's pbUpdate loop or use the EventHandler below.
  def self.update
    return if @recv_queue.empty?
    until @recv_queue.empty?
      msg = @recv_queue.pop(true) rescue nil
      break unless msg
      unless msg.is_a?(Hash)
        puts "[Network] Unexpected non-object message: #{msg.class} #{msg.inspect[0, 120]}"
        next
      end
      event = msg['event']
      next unless event
      # Respond to server heartbeat without firing user callbacks.
      if event == 'ping'
        send_msg({ action: 'pong' }) if @connected
        next
      end
      @callbacks[event].each { |cb| cb.call(msg) }
    end
  end

  private

  def self._start_recv_thread
    @recv_thread = Thread.new do
      # Manual line buffering — MKXP-Z's gets() can return partial data for large
      # messages (e.g. the ~10KB market_listings response for many listings).
      # recv() + manual split is the safe approach for TCP message framing.
      buf = ''
      begin
        while @connected && @socket
          chunk = @socket.recv(4096)
          break if chunk.nil? || chunk.empty?
          buf << chunk
          while (idx = buf.index("\n"))
            line = buf.slice!(0, idx + 1).strip
            next if line.empty?
            msg = nil
            begin
              msg = JSON.parse(line)
            rescue JSON::ParserError
              puts "[Network] Bad JSON: #{line[0, 200]}"
              next
            end
            # Answered right here in the recv thread, not via @recv_queue/update,
            # so a battle log report still goes out even if the main thread is
            # completely hung (stuck in a frozen/desynced battle) — precisely
            # the situation a battle log report exists to diagnose. See
            # _reply_battle_log_request and NetworkBattleLog.
            if msg.is_a?(Hash) && msg['event'] == 'battle_log_request'
              _reply_battle_log_request(msg)
              next
            end
            @recv_queue.push(msg)
          end
        end
      rescue => e
        puts "[Network] Recv error: #{e.message}"
      ensure
        _handle_disconnect
      end
    end
    @recv_thread.abort_on_exception = false
  end

  def self._handle_disconnect
    return unless @connected
    @connected = false
    @recv_queue.push({ 'event' => 'disconnected', 'message' => 'Lost connection to server' })
  end

  # Reads the current on-disk battle log and replies immediately, from this
  # background thread. File I/O and send_msg (mutex-protected socket write)
  # are both safe to call off the main thread; NetworkBattleLog itself does
  # nothing RGSS/Graphics-related, just plain File access.
  def self._reply_battle_log_request(msg)
    text = defined?(NetworkBattleLog) ? (NetworkBattleLog.read_current rescue "") : ""
    send_msg({ action: 'battle_log_upload', battle_id: msg['battle_id'], text: text })
  rescue => e
    puts "[Network] battle_log_request reply failed: #{e.message}"
  end
end

#-------------------------------------------------------------------------------
# Hook NetworkClient.update into the Essentials frame update system so events
# are processed every frame without needing to call it manually everywhere.
#-------------------------------------------------------------------------------
EventHandlers.add(:on_frame_update, :network_client_update,
  proc { NetworkClient.update }
)

# Play a sound when another player sends a chat message.
NetworkClient.on('chat_notify') do |d|
  next if $PokemonSystem.chat_sounds == 1
  next if d['sender'] == NetworkAuth.username
  pbSEPlay("Repel") if FileTest.audio_exist?("Audio/SE/Repel")
end

# Play a sound when the server sends a broadcast announcement.
NetworkClient.on('broadcast_notify') do |_d|
  next if $PokemonSystem.chat_sounds == 1
  pbSEPlay("Battle ability") if FileTest.audio_exist?("Audio/SE/Battle ability")
end
