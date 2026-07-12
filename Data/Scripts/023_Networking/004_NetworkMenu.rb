#===============================================================================
# SERVER entry in the pause menu.
#
# - Not connected: auto-login using $player.name, then show the submenu.
# - Connected: show [Trade / Battle / Cancel] submenu directly.
#===============================================================================

MenuHandlers.add(:pause_menu, :server, {
  "name"  => _INTL("SERVER"),
  "order" => 55,
  "desc"  => _INTL("Online features"),
  "effect" => proc { |menu|
    pbPlayDecisionSE

    unless NetworkAuth.logged_in?
      connected = NetworkAuth.auto_connect
      unless connected
        next false
      end
      pbMessage(_INTL("Connected to the server!"))
      File.delete(File.join(ENV['LOCALAPPDATA'] || '', 'EojChatData', 'Default', 'Preferences')) rescue nil
      system("start \"\" msedge --user-data-dir=\"%LOCALAPPDATA%\\EojChatData\" --app=\"http://#{NetworkClient::HOST}:5052?name=#{NetworkAuth.username}\" --window-size=420,580 --window-position=1170,80")
    end

    cmd = pbMessage(
      _INTL("What would you like to do?"),
      [_INTL("Trade"), _INTL("Battle"), _INTL("Triad"), _INTL("Chat"), _INTL("Cancel")], 5
    )

    if cmd == 0
      menu.pbHideMenu
      NetworkTrade.request_trade
      menu.pbEndScene
      next true
    elsif cmd == 1
      menu.pbHideMenu
      NetworkBattle.request_battle
      menu.pbEndScene
      next true
    elsif cmd == 2
      menu.pbHideMenu
      NetworkTriad.request_duel
      menu.pbEndScene
      next true
    elsif cmd == 3
      # Kill any existing EojChat Edge window, then open fresh.
      # This fixes zombie SSE connections where the window looks open but chat is dead.
      begin
        ps = "Get-CimInstance Win32_Process -Filter \"Name='msedge.exe'\" |" \
             " Where-Object { $_.CommandLine -like '*EojChatData*' } |" \
             " ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
        File.open('_kill_chat.ps1', 'w') { |f| f.write(ps) }
        system('powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File _kill_chat.ps1')
        File.delete('_kill_chat.ps1') rescue nil
      rescue => e
        puts "[Chat] Could not kill old window: #{e.message}"
      end
      File.delete(File.join(ENV['LOCALAPPDATA'] || '', 'EojChatData', 'Default', 'Preferences')) rescue nil
      system("start \"\" msedge --user-data-dir=\"%LOCALAPPDATA%\\EojChatData\" --app=\"http://#{NetworkClient::HOST}:5052?name=#{NetworkAuth.username}\" --window-size=420,580 --window-position=1170,80")
      next false
    end

    next false
  }
})
