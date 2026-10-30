#===============================================================================
# Poke Poker - Texas Hold'em against 3 trainers. Ported from the Shadow
# version's "Poker mini game" script (Essentials v18.1, 512x384 screen) to
# v21.1 and the 320x288 screen: the table is laid out again, the game itself
# (betting, the trainers' AI, hand ranking) is the original's.
#
# From an event: Script command `pbPokePoker(500, 10)`
#   Takes 500 Coins for 500 chips (each trainer starts with 500 too), the
#   blind is 10 chips. When the player quits (at the end of a round) or wins,
#   the chips left are paid back as Coins; out of chips = nothing back.
#   Returns the chips paid back (0 if none), or nil if the player couldn't pay.
#
# Or without Coins: `Pokepoker.new(500, 10).final_chips` plays a game and
# gives the chips left (0 if out of chips).
#
#   Call / Raise / Fold / Quit Game from the menu. Raise opens the bet menu:
#   arrows move, C adds the amount (or All in / Confirm), B goes back.
#===============================================================================
def pbPokePoker(buyin = 500, blind = 10)
  if !$bag.has?(:COINCASE)
    pbMessage(_INTL("You need a Coin Case to play."))
    return nil
  end
  if $player.coins < buyin
    pbMessage(_INTL("You don't have enough Coins. You need {1} Coins to play.", buyin.to_s_formatted))
    return nil
  end
  $player.coins -= buyin
  pbSEPlay("Slots coin")
  pbMessage(_INTL("Your {1} Coins were exchanged for {1} chips!", buyin.to_s_formatted))
  chips = 0
  pbFadeOutIn { chips = Pokepoker.new(buyin, blind).final_chips }
  if chips > 0
    $player.coins = [$player.coins + chips, Settings::MAX_COINS].min
    pbSEPlay("Slots coin")
    pbMessage(_INTL("Your {1} chips were exchanged for {1} Coins.", chips.to_s_formatted))
  end
  chips
end

class Pokepoker

  def initialize(fee,blindvalue)
    @randomnpcnames = true
    @deck = [
    [1,"Two of Spades",2,"Spades"],
    [2,"Three of Spades",3,"Spades"],
    [3,"Four of Spades",4,"Spades"],
    [4,"Five of Spades",5,"Spades"],
    [5,"Six of Spades",6,"Spades"],
    [6,"Seven of Spades",7,"Spades"],
    [7,"Eight of Spades",8,"Spades"],
    [8,"Nine of Spades",9,"Spades"],
    [9,"Ten of Spades",10,"Spades"],
    [10,"Jack of Spades",11,"Spades"],
    [11,"Queen of Spades",12,"Spades"],
    [12,"King of Spades",13,"Spades"],
    [13,"Ace of Spades",14,"Spades"],
    [14,"Two of Clubs",2,"Clubs"],
    [15,"Three of Clubs",3,"Clubs"],
    [16,"Four of Clubs",4,"Clubs"],
    [17,"Five of Clubs",5,"Clubs"],
    [18,"Six of Clubs",6,"Clubs"],
    [19,"Seven of Clubs",7,"Clubs"],
    [20,"Eight of Clubs",8,"Clubs"],
    [21,"Nine of Clubs",9,"Clubs"],
    [22,"Ten of Clubs",10,"Clubs"],
    [23,"Jack of Clubs",11,"Clubs"],
    [24,"Queen of Clubs",12,"Clubs"],
    [25,"King of Clubs",13,"Clubs"],
    [26,"Ace of Clubs",14,"Clubs"],
    [27,"Two of Diamonds",2,"Diamonds"],
    [28,"Three of Diamonds",3,"Diamonds"],
    [29,"Four of Diamonds",4,"Diamonds"],
    [30,"Five of Diamonds",5,"Diamonds"],
    [31,"Six of Diamonds",6,"Diamonds"],
    [32,"Seven of Diamonds",7,"Diamonds"],
    [33,"Eight of Diamonds",8,"Diamonds"],
    [34,"Nine of Diamonds",9,"Diamonds"],
    [35,"Ten of Diamonds",10,"Diamonds"],
    [36,"Jack of Diamonds",11,"Diamonds"],
    [37,"Queen of Diamonds",12,"Diamonds"],
    [38,"King of Diamonds",13,"Diamonds"],
    [39,"Ace of Diamonds",14,"Diamonds"] ,
    [40,"Two of Hearts",2,"Hearts"],
    [41,"Three of Hearts",3,"Hearts"],
    [42,"Four of Hearts",4,"Hearts"],
    [43,"Five of Hearts",5,"Hearts"],
    [44,"Six of Hearts",6,"Hearts"],
    [45,"Seven of Hearts",7,"Hearts"],
    [46,"Eight of Hearts",8,"Hearts"],
    [47,"Nine of Hearts",9,"Hearts"],
    [48,"Ten of Hearts",10,"Hearts"],
    [49,"Jack of Hearts",11,"Hearts"],
    [50,"Queen of Hearts",12,"Hearts"],
    [51,"King of Hearts",13,"Hearts"],
    [52,"Ace of Hearts",14,"Hearts"]
    ]
    @pot = 0
    @playersup = 0
    @comcard1 = 0
    @comcard2 = 0
    @comcard3 = 0
    @comcard4 = 0
    @comcard5 = 0
    @roundover = 0
    @noraise = 5
    @playing = 0 ###highlight whos playing
    @call = 0 #value to call
    @skips = 1 #value to check if round is over
    @deckp = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,
    27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52]
    @blind = 0
    @blindvalue = blindvalue
    @round = 1
    @gameover = 0
    @previousbet = 0
    @fee = fee
    @players = [[0,1,1,$player.name],
                [0,1,1,"Lance"],
                [0,1,1,"Misty"],
                [0,1,1,"Bruno"]]  ### #1- chips  #2- is up for round? #3- out of chips? #4- name

    ### if randomnpcnames is true it will randomize the player names
    if @randomnpcnames == true
      @randomnames = ["Brock","Lance","Misty","Surge","Sabrina","Blaine","Bruno","Koga","Agatha","Lorelei","Erika","Oak","Rocket","DoorGuy"]
      @randomnames.shuffle!
      @players[1][3] = @randomnames[0]
      @players[2][3] = @randomnames[1]
      @players[3][3] = @randomnames[2]
    end
    @players[0][0] += @fee
    @players[1][0] += @fee
    @players[2][0] += @fee
    @players[3][0] += @fee
    @player1card1 = 0
    @player1card2 = 0
    @player2card1 = 0
    @player2card2 = 0
    @player3card1 = 0
    @player3card2 = 0
    @player4card1 = 0
    @player4card2 = 0
    @decision = 0
    @raisevalue = 0
    @player1srr = 0
    @player2srr = 0
    @player3srr = 0
    @player4srr = 0
    @final_chips = 0   # chips the player leaves with (0: out of chips)
    ### z 99999 like the fade pbPokePoker starts with (made after it, so above
    ### it); messages are made later still, so they go on top
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)  ## viewport for background table
    @viewport.z=99999
    @viewport2=Viewport.new(0,0,Graphics.width,Graphics.height) ##viewport for stuff that goes on table
    @viewport2.z=99999
    @viewport3=Viewport.new(0,0,Graphics.width,Graphics.height) ##viewport for written stuff
    @viewport3.z=99999
    @viewport4=Viewport.new(0,0,Graphics.width,Graphics.height) ##viewport for the bet / raise
    @viewport4.z=99999
    @viewport5=Viewport.new(0,0,Graphics.width,Graphics.height) ##viewport for select arrow
    @viewport5.z=99999
    @sprites={}
    @sprites["background"] = Sprite.new(@viewport)
    setbitmap("background", GFX + "pokerbg")
    ### the 4 seats: you bottom left, then clockwise. Left seats: cards, then
    ### the name / chips boxes; right seats: the boxes, then the cards
    SEATS.each_with_index do |(sx, sy, right), i|
      boxx = right ? sx : sx + 68
      cardx = right ? sx + 84 : sx
      [["player#{i+1}border", "names", sy], ["player#{i+1}chips", "chipscounter", sy + 24]].each do |key, gfx, y|
        @sprites[key] = Sprite.new(@viewport2)
        setbitmap(key, GFX + gfx)
        @sprites[key].x = boxx
        @sprites[key].y = y
      end
      @sprites["p#{i+1}name"] = Sprite.new(@viewport3)
      @sprites["p#{i+1}name"].bitmap = Bitmap.new(82,24)
      @sprites["p#{i+1}name"].x = boxx
      @sprites["p#{i+1}name"].y = sy
      pokertext(@sprites["p#{i+1}name"].bitmap, @players[i][3], Color.new(0,0,0), Color.new(255,255,255))
      @sprites["p#{i+1}chips"] = Sprite.new(@viewport3)
      @sprites["p#{i+1}chips"].bitmap = Bitmap.new(82,24)
      @sprites["p#{i+1}chips"].x = boxx
      @sprites["p#{i+1}chips"].y = sy + 24
      pokertext(@sprites["p#{i+1}chips"].bitmap, @players[i][0].to_s, Color.new(0,0,0), Color.new(240,240,200))
      2.times do |c|
        key = "p#{i+1}_#{c+1}"
        @sprites[key] = Sprite.new(@viewport2)
        setbitmap(key, GFX + "backcard")
        @sprites[key].x = cardx + 34 * c
        @sprites[key].y = sy
        @sprites[key].opacity = 0
      end
    end
    ### community cards
    5.times do |c|
      key = "c#{c+1}"
      @sprites[key] = Sprite.new(@viewport2)
      setbitmap(key, GFX + "backcard")
      @sprites[key].x = 14 + 34 * c
      @sprites[key].y = 72
      @sprites[key].opacity = 0
    end
    @sprites["roundcounter"] = Sprite.new(@viewport2)
    setbitmap("roundcounter", GFX + "roundcounter")
    @sprites["roundcounter"].x = 192
    @sprites["roundcounter"].y = 62
    ### red / green lights: pre flop, flop, turn, river
    4.times do |s|
      key = "sq#{s+1}"
      @sprites[key] = Sprite.new(@viewport2)
      setbitmap(key, GFX + "redsq")
      @sprites[key].x = 219 + 18 * s
      @sprites[key].y = 90
    end
    @sprites["potcounter"] = Sprite.new(@viewport2)
    setbitmap("potcounter", GFX + "potcounter")
    @sprites["potcounter"].x = 192
    @sprites["potcounter"].y = 102
    @sprites["potvalue"] = Sprite.new(@viewport3)
    @sprites["potvalue"].bitmap = Bitmap.new(120,32)
    @sprites["potvalue"].x = 192
    @sprites["potvalue"].y = 102
    pokertext(@sprites["potvalue"].bitmap, @pot.to_s, Color.new(96,64,0), Color.new(248,240,160))
    ### bet menu (under the table, where the message box goes)
    @sprites["betui"] = Sprite.new(@viewport4)
    setbitmap("betui", GFX + "betui")
    @sprites["betui"].x = BETUI_X
    @sprites["betui"].y = BETUI_Y
    @sprites["betui"].opacity = 0
    BET_OPTIONS.each_with_index do |label, n|
      x, y = BET_OPTION_POS[n]
      pokertext(@sprites["betui"].bitmap, _INTL(label), Color.new(80,80,88), Color.new(168,184,184), x, y, 84, 24, 0)
    end
    pokertext(@sprites["betui"].bitmap, _INTL("Bet"), Color.new(80,80,88), Color.new(168,184,184), 232, 14, 64, 24)
    @sprites["bet"] = Sprite.new(@viewport4)
    setbitmap("bet", GFX + "betborder")
    @sprites["bet"].x = BETUI_X + 232
    @sprites["bet"].y = BETUI_Y + 40
    @sprites["bet"].opacity = 0
    @sprites["betvalue"] = Sprite.new(@viewport5)
    @sprites["betvalue"].bitmap = Bitmap.new(64,24)
    @sprites["betvalue"].x = BETUI_X + 232
    @sprites["betvalue"].y = BETUI_Y + 40
    pokertext(@sprites["betvalue"].bitmap, @raisevalue.to_s, Color.new(0,0,0), Color.new(240,240,200))
    @sprites["betvalue"].opacity = 0
    @select = 1
    @sprites["selectarrow"] = Sprite.new(@viewport5)
    setbitmap("selectarrow", GFX + "selectarrow")
    @sprites["selectarrow"].opacity = 0
    updateselect
    pbpokepokerstart
  end

  attr_reader :final_chips

  GFX = "Graphics/Plugins/Poke Poker/"
  ### seats: [x, y, boxes on the left?] - you, then the 3 trainers clockwise
  SEATS = [[8, 136, false], [8, 8, false], [162, 8, true], [162, 136, true]]
  BETUI_X = 8
  BETUI_Y = 196
  BET_OPTIONS = ["5", "10", "50", "100", "All in", "Confirm"]
  ### option text in the bet menu (x, y in it); 3 rows of 2
  BET_OPTION_POS = [[28, 6], [120, 6], [28, 30], [120, 30], [28, 54], [120, 54]]

  ### the original counted pbWait in frames (40 a second); v21's is seconds
  def pbWait(frames)
    super(frames / 40.0)
  end

  ### players still up this round
  def pokerplayersup
    @players.count { |pl| pl[1] == 1 }
  end

  ### loads a picture into a sprite, disposing the one it had
  def setbitmap(key, path)
    old = @sprites[key].bitmap
    @sprites[key].bitmap = Bitmap.new(pbResolveBitmap(path) || path)
    old.dispose if old && !old.disposed?
  end

  ### text in the game's small font, centred in the box (align 1) or from its
  ### left (align 0); squeezed if it doesn't fit
  def pokertext(bitmap, text, base, shadow, x = 0, y = 0, w = nil, h = nil, align = 1)
    w ||= bitmap.width
    h ||= bitmap.height
    text = text.to_s
    pbSetSmallFont(bitmap)
    tw = bitmap.text_size(text).width + 2
    if tw <= w - 4
      pbDrawShadowText(bitmap, x, y, w, h, text, base, shadow, align)
      return
    end
    tmp = Bitmap.new(tw, h)
    pbSetSmallFont(tmp)
    pbDrawShadowText(tmp, 0, 0, tw, h, text, base, shadow, 0)
    bitmap.stretch_blt(Rect.new(x + 2, y, w - 4, h), tmp, tmp.rect)
    tmp.dispose
  end
  def roundannouncement
    if @round == 1
      @sprites["round"] = Sprite.new(@viewport3)
      @sprites["round"].bitmap = Bitmap.new(120,24)
      @sprites["round"].x = 192
      @sprites["round"].y = 62
      @sprites["round"].opacity = 0
      pokertext(@sprites["round"].bitmap, _INTL("Round {1}", @round), Color.new(0,0,0), Color.new(255,255,255))
      10.times do
        @sprites["round"].opacity += 25.5
        pbWait(1)
      end
    else
      10.times do
        @sprites["round"].opacity -= 25.5
        pbWait(1)
      end
      @sprites["round"].bitmap.clear
      @sprites["round"].opacity = 0
      pokertext(@sprites["round"].bitmap, _INTL("Round {1}", @round), Color.new(0,0,0), Color.new(255,255,255))
      10.times do
        @sprites["round"].opacity += 25.5
        pbWait(1)
      end
    end
    pbMessage(_INTL("Round {1} has started.", @round))
  end
 def drawcards
        setbitmap("sq1", GFX + "greensq")
   if @players[0][2] > 0
    @sprites["p1_1"].opacity = 255
    pbWait(8)
    @sprites["p1_2"].opacity = 255
    pbWait(16)
  end
  if @players[1][2] > 0
    @sprites["p2_1"].opacity = 255
    pbWait(8)
    @sprites["p2_2"].opacity = 255
    pbWait(16)
  end
  if @players[2][2] > 0
    @sprites["p3_1"].opacity = 255
    pbWait(8)
    @sprites["p3_2"].opacity = 255
    pbWait(16)
  end
  if @players[3][2] > 0
    @sprites["p4_1"].opacity = 255
    pbWait(8)
    @sprites["p4_2"].opacity = 255
    pbWait(16)
  end
    pbWait(20)
    #player 1cards
    if @players[0][2] > 0
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player1card1 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player1card2 = @deck[randomcardvalue-1]
    end
    ##player2 cards
    if @players[1][2] > 0
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player2card1 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player2card2 = @deck[randomcardvalue-1]
    end
    ##player3cards
    if @players[2][2] > 0
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player3card1 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player3card2 = @deck[randomcardvalue-1]
    end
    #player 4 cards
    if @players[3][2] > 0
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player4card1 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @player4card2 = @deck[randomcardvalue-1]
    end
    #### com cards
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @comcard1 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @comcard2 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @comcard3 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @comcard4 = @deck[randomcardvalue-1]
    randomcard = rand(@deckp.length)
    randomcardvalue = @deckp[randomcard]
    @deckp.delete_at(randomcard)
    @comcard5 = @deck[randomcardvalue-1]
    ###chooses a random number from @deckp and assigns the respective card value
    ###the chosen number is the nremoved from @deckp in order to avoid repeated cards
    @sprites["p1_1"].opacity = 0
        setbitmap("p1_1", sprintf(GFX + "card%d",@player1card1[0]))
    pbWait(8)
    @sprites["p1_1"].opacity = 255
    pbWait(8)
    @sprites["p1_2"].opacity = 0
        setbitmap("p1_2", sprintf(GFX + "card%d",@player1card2[0]))
    pbWait(8)
    @sprites["p1_2"].opacity = 255
    pbWait(8)
  end ## drawcards

  ## auxiliary function that handles the whole call raise fold shenanigans
  ## it also sets the @playing that will control who plays next, it will
  ## select the 1st available player to left - pre flop only
  def fsubround
    @previousbet = @blindvalue if @previousbet == 0   ##in pre flop (fsubround) previous bet is blind value
    while @players[@playing%4][1] == 0                ## selects who plays next (skips if player folded)
      @playing += 1
    end

    if @playing >= 4      ##if its higher then 3, 4=0, 5=1, 6=2, 7=3
      @playing -= 4
    end

    case @playing
    when 0 #player turn
      action = 0                 ##action loop is to make betscene compatible with cancel
      while action == 0
      cmds = [_INTL("Call"),_INTL("Raise"),_INTL("Fold"),_INTL("Quit Game")]
      cmd = pbMessage(_INTL("What will you do?"),cmds)
        if cmd == 0
          pbMessage(_INTL("{1} calls.", @players[0][3]))
          if @player1bet != @previousbet    ##if there was changes to player coins with this call
            @players[0][0]-= (@previousbet - @player1bet)  ##update player coins
            updatechips(0)  ##update chips bitmap
            @pot += (@previousbet - @player1bet) ##update pot value
            updatepot  ##update pot bitmap
          end
          @noraise -= 1  ##@noraise keeps track of when there's 4 (assigned by playersup) calls to move to next phase
          @player1bet += (@previousbet - @player1bet) ##adds the changed amount to the player1bet
          action = 1   ##breaks action loop -> next player turn
        elsif cmd == 1
          pbPlayDecisionSE()
          betscene
          if @raisevalue > 0  ##there's a raise
            raise = @raisevalue
            @pot += (@previousbet - @player1bet + raise)
            updatepot
            @players[0][0]-= (@previousbet - @player1bet + raise) ##reduces player chips
            updatechips(0)
            @noraise = @playersup  ##since there was a raise the @noraise counter is reseted with @playersup
            @player1bet += (@previousbet - @player1bet + raise) ##increases bet, accounts for the diference player would pay to call
            @previousbet += raise ##increases player bet
            @player1srr += 1      ##signals that there was a raise this sub round -> used for npc ai
            action = 1
          end
        elsif cmd == 2
          pbMessage(_INTL("{1} folds.", @players[0][3]))
          @players[0][1]=0     ## signals the fold, won't take action this round
          @noraise -=1
          @playersup-=1        ## reduces 1 from playersup, requiring 1 less call to skip to next sub round
          updatefold(0)
          action = 1
        elsif cmd == 3
          pbMessage(_INTL("Oh, it seems {1} wishes to quit the game.", @players[0][3]))
          pbMessage(_INTL("You may leave the table after this round, come back anytime."))
          @gameover = 1      ##will break scene loop and exit game on next chance
          @players[0][1] = 0
          @noraise -=1
          @playersup -=1
          action = 1
          @final_chips = @players[0][0]          ##reward
        end
          @playing=3 if @players[3][1]==1   ##if 1st and 2nd players to the left aren't up it's the 3rd player turn next
          @playing=2 if @players[2][1]==1   ##if 1st player to the left isn't up it's 2nd player turn next
          @playing=1 if @players[1][1]==1   ##if player to the left is up, its his turn next, overwrites previous decisions
      end

      when 1 #player2turn
        @decision = npcmove(1)      ##npcmove(X) decides the npc action
        case @decision
        when 1
          pbMessage(_INTL("{1} calls.", @players[1][3]))  ##in pre flop u can't check, only call.
          if @player2bet != @previousbet
            @players[1][0]-= (@previousbet - @player2bet)
            updatechips(1)
            @pot += (@previousbet - @player2bet)
            updatepot
          end
        @noraise -=1
        @player2bet += (@previousbet - @player2bet)
        when 2
          rscore = goodcard(1)          ##goodcard(X) judges how good npc hand is, stores 1 2 or 3 in rscore
          b = rand(100)+1
          r1 = 0
          r2 = 0
          lowestchip = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
            lowestchip[i] -= (@previousbet - respectivebet)
          end
          lowestchip.sort!
          ## this determines the lowest effective money any player has to not overbet lowestchip[0]
          ## it reduces the money players would need to call from their effective money to ensure
          ## no one will get negative chips from calling
          r1 = 1 if (@previousbet*3) <= lowestchip[0]
          r2 = 1 if (@previousbet*4) <= lowestchip[0]
          ## there's 3 types of raise, minimum, medium and high, if r1 = 1 it's okay to make medium bet
          ## if r2 = 1 its okay to make high bet
          case rscore
          ### these chunks decide how high the npc will bet
          when 0
            if b<=100 && b>95 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>80 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=95 && b>80 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=80
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          when 1
            if b<=100 && b>95 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>75 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=95 && b>75 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=75
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          when 2
            if b<=100 && b>90 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=90 && b>65 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>90 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=90 && b>65 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=65
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          end
          sbet = @previousbet*3
          if (@previousbet - @player2bet + sbet) > @players[1][0]
            @raisevalue = (2*@previousbet)
          end
          if @raisevalue > lowestchip[0]
            @raisevalue = (2*@previousbet)
          end
          ### the last 7 lines are a double check, if npc was gonna bet more then
          ### other plays can call it would default to the min raise which is defined elsewhere
          ### to be a safe thing to do - other players can call without geting negative chips
          ### the final 3 is an extra layer of security vs raising too much
          raise = @raisevalue
          pbMessage(_INTL("{1} raises {2} chips.", @players[1][3], @raisevalue))
          @pot += (@previousbet - @player2bet + raise)
          updatepot
          @players[1][0]-= (@previousbet - @player2bet + raise)
          updatechips(1)
          @noraise = @playersup
          @player2bet += (@previousbet - @player2bet + raise)
          @previousbet += raise
          @player2srr += 1
        when 3
          pbMessage(_INTL("{1} folds.", @players[1][3]))
          @players[1][1]=0
          @noraise -=1
          @playersup-=1
          updatefold(1)
        end
          @playing=0 if @players[0][1]==1
          @playing=3 if @players[3][1]==1
          @playing=2 if @players[2][1]==1
      when 2 #player3turn
        @decision = npcmove(2)
        case @decision
        when 1
          pbMessage(_INTL("{1} calls.", @players[2][3]))
          if @player3bet != @previousbet
            @players[2][0]-= (@previousbet - @player3bet)
            updatechips(2)
            @pot += (@previousbet - @player3bet)
            updatepot
          end
        @noraise -=1
        @player3bet += (@previousbet - @player3bet)
        when 2
          rscore = goodcard(2)
          b = rand(100)+1
          r1 = 0
          r2 = 0
          lowestchip = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
            lowestchip[i] -= (@previousbet - respectivebet)
          end
          lowestchip.sort!
          r1 = 1 if (@previousbet*3) <= lowestchip[0]
          r2 = 1 if (@previousbet*4) <= lowestchip[0]
          case rscore
          when 0
            if b<=100 && b>95 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>80 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=95 && b>80 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=80
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          when 1
            if b<=100 && b>95 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>75 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=95 && b>75 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=75
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          when 2
            if b<=100 && b>90 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=90 && b>65 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>90 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=90 && b>65 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=65
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          end
          sbet = @previousbet*3
          if (@previousbet - @player3bet + sbet) > @players[2][0]
            @raisevalue = (2*@previousbet)
          end
          if @raisevalue > lowestchip[0]
            @raisevalue = (2*@previousbet)
          end
          raise = @raisevalue
          pbMessage(_INTL("{1} raises {2} chips.", @players[2][3], @raisevalue))
          @pot += (@previousbet - @player3bet + raise)
          updatepot
          @players[2][0]-= (@previousbet - @player3bet + raise)
          updatechips(2)
          @noraise = @playersup
          @player3bet += (@previousbet - @player3bet + raise)
          @previousbet += raise
          @player3srr += 1
        when 3
          pbMessage(_INTL("{1} folds.", @players[2][3]))
          @players[2][1]=0
          @noraise -=1
          @playersup-=1
          updatefold(2)
        end
        @playing=1 if @players[1][1]==1
        @playing=0 if @players[0][1]==1
        @playing=3 if @players[3][1]==1

      when 3 #player4turn
        @decision = npcmove(3)
        case @decision
        when 1
          pbMessage(_INTL("{1} calls.", @players[3][3]))
          if @player4bet != @previousbet
            @players[3][0]-= (@previousbet - @player4bet)
            updatechips(3)
            @pot += (@previousbet - @player4bet)
            updatepot
          end
        @noraise -=1
        @player4bet += (@previousbet - @player4bet)
        when 2
          rscore = goodcard(3)
          b = rand(100)+1
          r1 = 0
          r2 = 0
          lowestchip = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
            lowestchip[i] -= (@previousbet - respectivebet)
          end
          lowestchip.sort!
          r1 = 1 if (@previousbet*3) <= lowestchip[0]
          r2 = 1 if (@previousbet*4) <= lowestchip[0]
          case rscore
          when 0
            if b<=100 && b>95 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>80 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=95 && b>80 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=80
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          when 1
            if b<=100 && b>95 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>75 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=95 && b>75 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=75
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          when 2
            if b<=100 && b>90 && r2 == 1
              @raisevalue = (4*@previousbet)
            elsif  b<=90 && b>65 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=100 && b>90 && r2 == 0 && r1 == 1
              @raisevalue = (3*@previousbet)
            elsif b<=90 && b>65 && r1 == 0
              @raisevalue = (2*@previousbet)
            elsif b<=65
              @raisevalue = (2*@previousbet)
            else
              @raisevalue = (2*@previousbet)
            end
          end
          sbet = @previousbet*3
          if (@previousbet - @player4bet + sbet) > @players[3][0]
            @raisevalue = (2*@previousbet)
          end
          if @raisevalue > lowestchip[0]
            @raisevalue = (2*@previousbet)
          end
          raise = @raisevalue
          pbMessage(_INTL("{1} raises {2} chips.", @players[3][3], @raisevalue))
          @pot += (@previousbet - @player4bet + raise)
          updatepot
          @players[3][0]-= (@previousbet - @player4bet + raise)
          updatechips(3)
          @noraise = @playersup
          @player4bet += (@previousbet - @player4bet + raise)
          @previousbet += raise
          @player4srr += 1
        when 3
          pbMessage(_INTL("{1} folds.", @players[3][3]))
          @players[3][1]=0
          @noraise -=1
          @playersup-=1
          updatefold(3)
        end
        @playing=2 if @players[2][1]==1
        @playing=1 if @players[1][1]==1
        @playing=0 if @players[0][1]==1
      end
  end

  def osubround     ##fsubround -> pre flop / osubround -> others
    while @players[@playing%4][1] == 0
      @playing += 1
    end
    if @playing >= 4
      @playing -= 4
    end
    case @playing
    when 0
      action = 0
      while action == 0
      if @previousbet == 0 ##turns call into check and raise into bet
        cmds = [_INTL("Check"),_INTL("Bet"),_INTL("Fold"),_INTL("Quit Game")]
      else
        cmds = [_INTL("Call"),_INTL("Raise"),_INTL("Fold"),_INTL("Quit Game")]
      end
      cmd = pbMessage(_INTL("What will you do?"),cmds)
        if cmd == 0
          @previousbet == 0 ? pbMessage(_INTL("{1} checks.", @players[0][3])) : pbMessage(_INTL("{1} calls.", @players[0][3]))
          if @player1bet != @previousbet
            @players[0][0]-= (@previousbet - @player1bet)
            updatechips(0)
            @pot += (@previousbet - @player1bet)
            updatepot
            @player1bet += (@previousbet - @player1bet)
          end
          @noraise -= 1
          action = 1
        elsif cmd == 1
          pbPlayDecisionSE()
          betscene
          if @raisevalue > 0
            raise = @raisevalue
            @pot += (@previousbet - @player1bet + raise)
            updatepot
            @players[0][0]-= (@previousbet - @player1bet + raise)
            updatechips(0)
            @noraise = @playersup
            @player1bet += (@previousbet - @player1bet + raise)
            @previousbet += raise
            @player1srr += 1
            action = 1
          end
        elsif cmd == 2
          pbMessage(_INTL("{1} folds.", @players[0][3]))
          @players[0][1]=0
          @noraise -=1
          @playersup-=1
          updatefold(0)
          action = 1
        elsif cmd == 3
          pbMessage(_INTL("Oh, it seems {1} wishes to quit the game.", @players[0][3]))
          pbMessage(_INTL("You may leave the table after this round, come back anytime."))
          @gameover = 1
          @players[0][1] = 0
          @noraise -=1
          @playersup -=1
          @final_chips = @players[0][0]    ##reward
          action = 1
        end
          @playing=3 if @players[3][1]==1
          @playing=2 if @players[2][1]==1
          @playing=1 if @players[1][1]==1
      end
    when 1
      @decision = npcmove(1)
      case @decision
      when 1
        @previousbet == 0 ? pbMessage(_INTL("{1} checks.", @players[1][3])) : pbMessage(_INTL("{1} calls.", @players[1][3]))
        if @player2bet != @previousbet
          @players[1][0]-= (@previousbet - @player2bet)
          updatechips(1)
          @pot += (@previousbet - @player2bet)
          updatepot
          @player2bet += (@previousbet - @player2bet)
        end
        @noraise -=1
      when 2
          rscore = goodcard(1)
          b = rand(100)+1
          r1 = 0
          r2 = 0
          lowestchip = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
            lowestchip[i] -= (@previousbet - respectivebet)
          end
          lowestchip.sort!
          if @previousbet == 0
            r1 = 1 if (@blindvalue*3) <= lowestchip[0]
            r2 = 1 if (@blindvalue*5) <= lowestchip[0]
          else
            r1 = 1 if (@previousbet*3) <= lowestchip[0]
            r2 = 1 if (@previousbet*4) <= lowestchip[0]
          end
          case rscore
          when 0
            if b<=100 && b>95 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>80 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=95 && b>80 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=80
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          when 1
            if b<=100 && b>95 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>75 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=95 && b>75 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=75
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          when 2
            if b<=100 && b>90 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=90 && b>65 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>90 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=90 && b>65 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=65
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          end
          @previousbet == 0 ? sbet = @blindvalue*2 : sbet = @previousbet*3
          if (@previousbet - @player2bet + sbet) > @players[1][0]
            @previousbet == 0 ? @raisevalue = (@blindvalue) : @raisevalue = (2*@previousbet)
          end
          if @raisevalue > lowestchip[0]
            @previousbet == 0 ? @raisevalue = (@blindvalue) : @raisevalue = (2*@previousbet)
          end
          raise = @raisevalue
          if @previousbet == 0
            pbMessage(_INTL("{1} bets {2} chips.", @players[1][3], @raisevalue))
          else
            pbMessage(_INTL("{1} raises {2} chips.", @players[1][3], @raisevalue))
          end
          @pot += (@previousbet - @player2bet + raise)
          updatepot
          @players[1][0]-= (@previousbet - @player2bet + raise)
          updatechips(1)
          @noraise = @playersup
          @player2bet += (@previousbet - @player2bet + raise)
          @previousbet += raise
          @player2srr += 1
      when 3
        pbMessage(_INTL("{1} folds.", @players[1][3]))
        @players[1][1]=0
        @noraise -=1
        @playersup-=1
        updatefold(1)
      end
        @playing=0 if @players[0][1]==1
        @playing=3 if @players[3][1]==1
        @playing=2 if @players[2][1]==1
    when 2
      @decision = npcmove(2)
      case @decision
      when 1
        @previousbet == 0 ? pbMessage(_INTL("{1} checks.", @players[2][3])) : pbMessage(_INTL("{1} calls.", @players[2][3]))
        if @player3bet != @previousbet
          @players[2][0]-= (@previousbet - @player3bet)
          updatechips(2)
          @pot += (@previousbet - @player3bet)
          updatepot
          @player3bet += (@previousbet - @player3bet)
        end
        @noraise -=1
      when 2
          rscore = goodcard(2)
          b = rand(100)+1
          r1 = 0
          r2 = 0
          lowestchip = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
            lowestchip[i] -= (@previousbet - respectivebet)
          end
          lowestchip.sort!
          if @previousbet == 0
            r1 = 1 if (@blindvalue*3) <= lowestchip[0]
            r2 = 1 if (@blindvalue*5) <= lowestchip[0]
          else
            r1 = 1 if (@previousbet*3) <= lowestchip[0]
            r2 = 1 if (@previousbet*4) <= lowestchip[0]
          end
          case rscore
          when 0
            if b<=100 && b>95 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>80 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=95 && b>80 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=80
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          when 1
            if b<=100 && b>95 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>75 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=95 && b>75 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=75
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          when 2
            if b<=100 && b>90 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=90 && b>65 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>90 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=90 && b>65 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=65
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          end
          @previousbet == 0 ? sbet = @blindvalue*2 : sbet = @previousbet*3
          if (@previousbet - @player3bet + sbet) > @players[2][0]
            @previousbet == 0 ? @raisevalue = (@blindvalue) : @raisevalue = (2*@previousbet)
          end
          if @raisevalue > lowestchip[0]
            @previousbet == 0 ? @raisevalue = (@blindvalue) : @raisevalue = (2*@previousbet)
          end
          raise = @raisevalue
          if @previousbet == 0
            pbMessage(_INTL("{1} bets {2} chips.", @players[2][3], @raisevalue))
          else
            pbMessage(_INTL("{1} raises {2} chips.", @players[2][3], @raisevalue))
          end
          @pot += (@previousbet - @player3bet + raise)
          updatepot
          @players[2][0]-= (@previousbet - @player3bet + raise)
          updatechips(2)
          @noraise = @playersup
          @player3bet += (@previousbet - @player3bet + raise)
          @previousbet += raise
          @player3srr += 1
      when 3
        pbMessage(_INTL("{1} folds.", @players[2][3]))
        @players[2][1] = 0
        @noraise -=1
        @playersup-=1
        updatefold(2)
      end
        @playing=1 if @players[1][1]==1
        @playing=0 if @players[0][1]==1
        @playing=3 if @players[3][1]==1
    when 3
      @decision = npcmove(3)
      case @decision
      when 1
        @previousbet == 0 ? pbMessage(_INTL("{1} checks.", @players[3][3])) : pbMessage(_INTL("{1} calls.", @players[3][3]))
        if @player4bet != @previousbet
          @players[3][0]-= (@previousbet - @player4bet)
          updatechips(3)
          @pot += (@previousbet - @player4bet)
          updatepot
          @player4bet += (@previousbet - @player4bet)
        end
        @noraise -=1
      when 2
          rscore = goodcard(3)
          b = rand(100)+1
          r1 = 0
          r2 = 0
          lowestchip = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
            lowestchip[i] -= (@previousbet - respectivebet)
          end
          lowestchip.sort!
          if @previousbet == 0
            r1 = 1 if (@blindvalue*3) <= lowestchip[0]
            r2 = 1 if (@blindvalue*5) <= lowestchip[0]
          else
            r1 = 1 if (@previousbet*3) <= lowestchip[0]
            r2 = 1 if (@previousbet*4) <= lowestchip[0]
          end
          case rscore
          when 0
            if b<=100 && b>95 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>80 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=95 && b>80 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=80
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          when 1
            if b<=100 && b>95 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=95 && b>75 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>95 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=95 && b>75 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=75
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          when 2
            if b<=100 && b>90 && r2 == 1
              @previousbet == 0 ? @raisevalue = (5*@blindvalue) : @raisevalue = (4*@previousbet)
            elsif  b<=90 && b>65 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=100 && b>90 && r2 == 0 && r1 == 1
              @previousbet == 0 ? @raisevalue = (3*@blindvalue) : @raisevalue = (3*@previousbet)
            elsif b<=90 && b>65 && r1 == 0
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            elsif b<=65
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            else
              @previousbet == 0 ? @raisevalue = (2*@blindvalue) : @raisevalue = (2*@previousbet)
            end
          end
          @previousbet == 0 ? sbet = @blindvalue*2 : sbet = @previousbet*3
          if (@previousbet - @player4bet + sbet) > @players[3][0]
            @previousbet == 0 ? @raisevalue = (@blindvalue) : @raisevalue = (2*@previousbet)
          end
          if @raisevalue > lowestchip[0]
            @previousbet == 0 ? @raisevalue = (@blindvalue) : @raisevalue = (2*@previousbet)
          end
          raise = @raisevalue
          if @previousbet == 0
            pbMessage(_INTL("{1} bets {2} chips.", @players[3][3], @raisevalue))
          else
            pbMessage(_INTL("{1} raises {2} chips.", @players[3][3], @raisevalue))
          end
          @pot += (@previousbet - @player4bet + raise)
          updatepot
          @players[3][0]-= (@previousbet - @player4bet + raise)
          updatechips(3)
          @noraise = @playersup
          @player4bet += (@previousbet - @player4bet + raise)
          @previousbet += raise
          @player4srr += 1
      when 3
        pbMessage(_INTL("{1} folds.", @players[3][3]))
        @players[3][1] = 0
        @noraise -= 1
        @playersup -= 1
        updatefold(3)
      end
        @playing=2 if @players[2][1]==1
        @playing=1 if @players[1][1]==1
        @playing=0 if @players[0][1]==1
    end

  end


 ## small blind players starts by posting it and increases blind so next player
 ## posts it in the next round
 ## noraise is defined in subround auxiliary function, when there'sX (players up)
 ## calls or folds in a row it will break the loop and show the 1st 3 community cards
 ## then it will go in the subround and show the 4th comunity card once its over, then
 ## the last community card, after that @roundover == 1 and breaks the loop
 ## then roundwinner function is called in the main function and player hands are rated

  def playround
    @totalraises = 0          ##used for npc AI
    @player1bet = 0
    @player2bet = 0
    @player3bet = 0
    @player4bet = 0
    @comcards = 0
    @playersup = 0
    @playersup += 1 if @players[0][0]>0
    @playersup += 1 if @players[1][0]>0
    @playersup += 1 if @players[2][0]>0
    @playersup += 1 if @players[3][0]>0

    while @players[@blind%4][1] == 0   ##selects next player to post the blind, must be in game [i][1] == 1
      @blind += 1
    end

    case @blind%4
     when 0
      pbMessage(_INTL("{1} posts the blind.", @players[0][3]))
      @players[0][0] -= @blindvalue        ##deducts blind value from players chips
      updatechips(0)
      @pot += @blindvalue
      updatepot
      @skips = 1                           ##fossil variable no longer used, remove it all one of these days
      @call = @blindvalue                  ## ^
      @player1bet = @blindvalue
     when 1
      pbMessage(_INTL("{1} posts the blind.", @players[1][3]))
      @players[1][0] -= @blindvalue
      updatechips(1)
      @pot += @blindvalue
      updatepot
      @skips = 1
      @call = @blindvalue
      @player2bet = @blindvalue
     when 2
      pbMessage(_INTL("{1} posts the blind.", @players[2][3]))
      @players[2][0] -= @blindvalue
      updatechips(2)
      @pot += @blindvalue
      updatepot
      @skips = 1
      @call = @blindvalue
      @player3bet = @blindvalue
     when 3
      pbMessage(_INTL("{1} posts the blind.", @players[3][3]))
      @players[3][0] -= @blindvalue
      updatechips(3)
      @pot += @blindvalue
      updatepot
      @skips = 1
      @call = @blindvalue
      @player4bet = @blindvalue
    end  ##case
    @blind +=1            ##control who pays next blind
    @playing = @blind%4   ##controls who plays exactly next
    @noraise = @playersup+1
    while @roundover != 1    ##round loop  - breaks when 4th subround is over
      while @noraise != 1 && pokerplayersup > 1    ##subround loop - breaks when there's #playersup calls in a row (or 1 player left)
        @comcards == 0 ? fsubround : osubround  ##comcards=0 is the pre flop
      end
      ### resets subround stuff, calculates totalraises before reseting them for npc AI use
      @previousbet = 0
      @totalraises += (@player1srr + @player2srr + @player3srr + @player4srr)
      @player1bet = 0
      @player2bet = 0
      @player3bet = 0
      @player4bet = 0
      @player1srr = 0
      @player2srr = 0
      @player3srr = 0
      @player4srr = 0

      break if pokerplayersup <= 1   ##everyone else folded, the round is over
      if @comcards == 3   ##breaks the round loop, round is over
        @roundover == 1
        break
      end


      if @comcards == 2  ##shows last card

                setbitmap("c5", sprintf(GFX + "card%d",@comcard5[0]))
        @sprites["c5"].opacity = 255
        pbWait(16)
                setbitmap("sq4", GFX + "greensq")
        @comcards += 1
        @noraise = @playersup+1
      end


      if @comcards == 1   ##shows 4th card

                setbitmap("c4", sprintf(GFX + "card%d",@comcard4[0]))
        @sprites["c4"].opacity = 255
        pbWait(16)
                setbitmap("sq3", GFX + "greensq")
        @comcards += 1
        @noraise = @playersup+1
      end


      if @comcards == 0  ##shows 3 1st cards


                setbitmap("c1", sprintf(GFX + "card%d",@comcard1[0]))
        @sprites["c1"].opacity = 255
        pbWait(16)
                setbitmap("c2", sprintf(GFX + "card%d",@comcard2[0]))
        @sprites["c2"].opacity = 255
        pbWait(16)
                setbitmap("c3", sprintf(GFX + "card%d",@comcard3[0]))
        @sprites["c3"].opacity = 255
        pbWait(16)
                setbitmap("sq2", GFX + "greensq")
        @comcards += 1
        @noraise = @playersup+1
      end #comcards == 0
      end #2nd while
    end ###playround

  def roundwinner
    @p1score = 0
    @p2score = 0
    @p3score = 0
    @p4score = 0
    #### reveals the cards of every player who's still in round @players[i][1]==1
    if @players[1][1]==1 ##p2 still in round
      @sprites["p2_1"].opacity = 0
            setbitmap("p2_1", sprintf(GFX + "card%d",@player2card1[0]))
      pbWait(8)
      @sprites["p2_1"].opacity = 255
      pbWait(8)
      @sprites["p2_2"].opacity = 0
            setbitmap("p2_2", sprintf(GFX + "card%d",@player2card2[0]))
      pbWait(8)
      @sprites["p2_2"].opacity = 255
      pbWait(8)
    end
    if @players[2][1]==1 ##p3 still in round
      @sprites["p3_1"].opacity = 0
            setbitmap("p3_1", sprintf(GFX + "card%d",@player3card1[0]))
      pbWait(8)
      @sprites["p3_1"].opacity = 255
      pbWait(8)
      @sprites["p3_2"].opacity = 0
            setbitmap("p3_2", sprintf(GFX + "card%d",@player3card2[0]))
      pbWait(8)
      @sprites["p3_2"].opacity = 255
    end
    if @players[3][1]==1 ##p4 still in round
      @sprites["p4_1"].opacity = 0
            setbitmap("p4_1", sprintf(GFX + "card%d",@player4card1[0]))
      pbWait(8)
      @sprites["p4_1"].opacity = 255
      pbWait(8)
      @sprites["p4_2"].opacity = 0
            setbitmap("p4_2", sprintf(GFX + "card%d",@player4card2[0]))
      pbWait(8)
      @sprites["p4_2"].opacity = 255
    end

    ### this next chunks runs the handrate function for all players who didnt fold this round,
    ### then stores in playerscores array the playernumber and its respective score and sorts
    ### the array from the highest score to the lowest


      @playerscores = [
      [0,0],
      [0,0],
      [0,0],
      [0,0]
      ]

      if @players[0][1] == 1
        @p1score = handrate(@player1card1,@player1card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
        @playerscores[0][0] = 1
        @playerscores[0][1] = @p1score
      end
      if @players[1][1] == 1
        @p2score = handrate(@player2card1,@player2card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
        @playerscores[1][0] = 2
        @playerscores[1][1] = @p2score
      end
      if @players[2][1] == 1
        @p3score = handrate(@player3card1,@player3card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
        @playerscores[2][0] = 3
        @playerscores[2][1] = @p3score
      end
      if @players[3][1] == 1
        @p4score = handrate(@player4card1,@player4card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
        @playerscores[3][0] = 4
        @playerscores[3][1] = @p4score
      end

      @playerscores.sort! {|a,b| b[1] <=> a[1]}   ##sorts the array by score, 1st one won, if 1st=2nd then both won, etc

      wsequence = sequenceannounce(@playerscores[0][1])

      ### the very very unlikely case all 4 scores are equal - 4 players tied
      if (@playerscores[0][1] == @playerscores[1][1]) && (@playerscores[0][1] == @playerscores[2][1]) && (@playerscores[0][1] == @playerscores[3][1])
        pbMessage(_INTL("Did this just happen?"))
        pbMessage(_INTL("Every player tied with {1}!", wsequence))
        pbMessage(_INTL("The pot is split by everyone."))
        @players[0][0] += (@pot/4) + @pot % 4   ##+ the chips left over
        @players[1][0] += (@pot/4)
        @players[2][0] += (@pot/4)
        @players[3][0] += (@pot/4)
        updatechips(@playerscores[0][0]-1)
        updatechips(@playerscores[1][0]-1)
        updatechips(@playerscores[2][0]-1)
        updatechips(@playerscores[3][0]-1)
      ### the very unlikely case 3 players tie
      elsif (@playerscores[0][1] == @playerscores[1][1]) && (@playerscores[0][1] == @playerscores[2][1])
        pbMessage(_INTL("Now that's something you don't see every day, a three-way tie!"))
        pbMessage(_INTL("They all got {1}!", wsequence))
        pbMessage(_INTL("{1}, {2} and {3} split the pot.", @players[(@playerscores[0][0])-1][3], @players[(@playerscores[1][0])-1][3], @players[(@playerscores[2][0])-1][3]))
        @players[(@playerscores[0][0])-1][0] += (@pot/3) + @pot % 3   ##+ the chips left over
        @players[(@playerscores[1][0])-1][0] += (@pot/3)
        @players[(@playerscores[2][0])-1][0] += (@pot/3)
        updatechips(@playerscores[0][0]-1)
        updatechips(@playerscores[1][0]-1)
        updatechips(@playerscores[2][0]-1)
      ### the unlikely case 2 players tie
      elsif (@playerscores[0][1] == @playerscores[1][1])
        pbMessage(_INTL("What a surprise, we have a tie between {1} and {2}!", @players[(@playerscores[0][0])-1][3], @players[(@playerscores[1][0])-1][3]))
        pbMessage(_INTL("Both of them got {1}!", wsequence))
        pbMessage(_INTL("Each player gets half of the pot."))
        @players[(@playerscores[0][0])-1][0] += (@pot/2) + @pot % 2   ##+ the chips left over
        @players[(@playerscores[1][0])-1][0] += (@pot/2)
        updatechips(@playerscores[0][0]-1)
        updatechips(@playerscores[1][0]-1)
      else ### pot goes to the winner
        pbMessage(_INTL("{1} wins the pot with {2}!", @players[(@playerscores[0][0])-1][3], wsequence))
        @players[(@playerscores[0][0])-1][0] += @pot
        updatechips(@playerscores[0][0]-1)
      end

      @round +=1          ##increases round, resets deck and round related stuff, updates pot
      @deckp = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,
      27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52]
      @roundover = 0
      @pot = 0
      updatepot

      @players[0][2] = 0 if @players[0][0] < @blindvalue   ##any player who can't pay the bind is removed from game [i][2]=0
      @players[1][2] = 0 if @players[1][0] < @blindvalue
      @players[2][2] = 0 if @players[2][0] < @blindvalue
      @players[3][2] = 0 if @players[3][0] < @blindvalue

      @players[0][2] == 0 ? @players[0][1] = 0 : @players[0][1] = 1    ##if [i][2] == 0 then [i][1] == 0 too just in case of bugs, else (case of fold)
      @players[1][2] == 0 ? @players[1][1] = 0 : @players[1][1] = 1    ## but still ingame, it resets teh [i][1] to 1 so the player can play next round
      @players[2][2] == 0 ? @players[2][1] = 0 : @players[2][1] = 1
      @players[3][2] == 0 ? @players[3][1] = 0 : @players[3][1] = 1

      @sprites["p1_1"].opacity = 0
            setbitmap("p1_1", GFX + "backcard")
      @sprites["p1_2"].opacity = 0
            setbitmap("p1_2", GFX + "backcard")
      @sprites["p2_1"].opacity = 0
            setbitmap("p2_1", GFX + "backcard")
      @sprites["p2_2"].opacity = 0
            setbitmap("p2_2", GFX + "backcard")
      @sprites["p3_1"].opacity = 0
            setbitmap("p3_1", GFX + "backcard")
      @sprites["p3_2"].opacity = 0
            setbitmap("p3_2", GFX + "backcard")
      @sprites["p4_1"].opacity = 0
            setbitmap("p4_1", GFX + "backcard")
      @sprites["p4_2"].opacity = 0
            setbitmap("p4_2", GFX + "backcard")
      @sprites["c1"].opacity = 0
            setbitmap("c1", GFX + "backcard")
      @sprites["c2"].opacity = 0
            setbitmap("c2", GFX + "backcard")
      @sprites["c3"].opacity = 0
            setbitmap("c3", GFX + "backcard")
      @sprites["c4"].opacity = 0
            setbitmap("c4", GFX + "backcard")
      @sprites["c5"].opacity = 0
            setbitmap("c5", GFX + "backcard")
      if @players[0][2] == 0   ##player can't pay the blind, is out of the game - game over
        pbMessage(_INTL("You're out of chips, better luck next time."))
        @gameover = 1
      end

      updatequitters if @players[0][2] == 1

      if (@players[1][2] == 0) && (@players[2][2] == 0) && (@players[3][2] == 0) ##only player is remaining - victory
        pbMessage(_INTL("You are the only player remaining, congratulations on your victory!"))
        @gameover = 1
        @final_chips = @players[0][0]  ##reward
        ### add the playercoins to a game variable to add the coins after game in the event
      end
                setbitmap("sq1", GFX + "redsq")
                setbitmap("sq2", GFX + "redsq")
                setbitmap("sq3", GFX + "redsq")
                setbitmap("sq4", GFX + "redsq")
  end

  def handrate(hand1,hand2,hand3,hand4,hand5,hand6,hand7)
    ##################################
    ## check for royal straight flush
    ##################################

    ### these var will store the amount of elements needed for a royal straight flush
    ### if they reach 5 means the 5 cards required are present
    hroyalf = 0
    droyalf = 0
    sroyalf = 0
    croyalf = 0
    @hand = [
    hand1,
    hand2,
    hand3,
    hand4,
    hand5,
    hand6,
    hand7
    ]
#    @hand = [
#    [45,"Seven of Hearts",4,"Spades"],
#    [5,"Six of Spades",10,"Clubs"],
#    [47,"Nine of Hearts",10,"Diamonds"],
#    [49,"Jack of Hearts",8,"Hearts"],
#    [41,"Three of Hearts",9,"Hearts"],
#    [6,"Seven of Spades",3,"Spades"],
#    [44,"Six of Hearts",14,"Hearts"]
#    ]
    @tiebreakerhand = []
    for i in 0...7
      @tiebreakerhand.push(@hand[i][2])
    end
    @tiebreakerhand.sort! { |a, b| b <=> a }

    ####### checks every card in @hand, adds +1 to the roayl flush counters - hroalf, droyalf
    for i in 0...7
      hroyalf += 1 if @hand[i][2] == 10  && @hand[i][3] == "Hearts"
      hroyalf += 1 if @hand[i][2] == 11  && @hand[i][3] == "Hearts"
      hroyalf += 1 if @hand[i][2] == 12  && @hand[i][3] == "Hearts"
      hroyalf += 1 if @hand[i][2] == 13  && @hand[i][3] == "Hearts"
      hroyalf += 1 if @hand[i][2] == 14  && @hand[i][3] == "Hearts"
      droyalf += 1 if @hand[i][2] == 10  && @hand[i][3] == "Diamonds"
      droyalf += 1 if @hand[i][2] == 11  && @hand[i][3] == "Diamonds"
      droyalf += 1 if @hand[i][2] == 12  && @hand[i][3] == "Diamonds"
      droyalf += 1 if @hand[i][2] == 13  && @hand[i][3] == "Diamonds"
      droyalf += 1 if @hand[i][2] == 14  && @hand[i][3] == "Diamonds"
      sroyalf += 1 if @hand[i][2] == 10  && @hand[i][3] == "Spades"
      sroyalf += 1 if @hand[i][2] == 11  && @hand[i][3] == "Spades"
      sroyalf += 1 if @hand[i][2] == 12  && @hand[i][3] == "Spades"
      sroyalf += 1 if @hand[i][2] == 13  && @hand[i][3] == "Spades"
      sroyalf += 1 if @hand[i][2] == 14  && @hand[i][3] == "Spades"
      croyalf += 1 if @hand[i][2] == 10  && @hand[i][3] == "Clubs"
      croyalf += 1 if @hand[i][2] == 11  && @hand[i][3] == "Clubs"
      croyalf += 1 if @hand[i][2] == 12  && @hand[i][3] == "Clubs"
      croyalf += 1 if @hand[i][2] == 13  && @hand[i][3] == "Clubs"
      croyalf += 1 if @hand[i][2] == 14  && @hand[i][3] == "Clubs"
    end

    ####### if any of the counters reaches 5 it will return 1000 - the highest
    ####### value possible

    if hroyalf == 5 || droyalf == 5 || sroyalf == 5 || croyalf == 5
      return 40000
    end
    ###########################
    ## check for straight flush
    ###########################

    #### each array represents a suit

    @hstflush = []
    @dstflush = []
    @sstflush = []
    @cstflush = []

    ### this will sort the hand and fill each array suit with the cards values

    for i in 0...7
      @hstflush.push(@hand[i][2]) if @hand[i][3] == "Hearts"
      @dstflush.push(@hand[i][2]) if @hand[i][3] == "Diamonds"
      @sstflush.push(@hand[i][2]) if @hand[i][3] == "Spades"
      @cstflush.push(@hand[i][2]) if @hand[i][3] == "Clubs"
    end

    ### if the suit array is 5 or bigger then there's 5 cards of the same suit
    ### it will then sort the array from highest to lowest and check for each value
    ### if the value -1, -2, -3 and -4 is present, it will return 2400 + array[i] which is
    ### the highest value of the sequence for tie breaker purposes
    ### the 1st if checks for ace through 5 straight flush, if an ace (14) is present
    ### will check for presence of the values 2 3 4 and 5

    if @hstflush.length >= 5
      @hstflush.sort! { |a, b| b <=> a }
      for i in 0...@hstflush.length
        if @hstflush[i]== 14
          if @hstflush.include?(2) &&  @hstflush.include?(3) &&  @hstflush.include?(4) &&  @hstflush.include?(5)
            return 39000 + 5
          end
        end
        if @hstflush.include?((@hstflush[i])-1) && @hstflush.include?((@hstflush[i])-2) && @hstflush.include?((@hstflush[i])-3) && @hstflush.include?((@hstflush[i])-4)
          return 39000 + @hstflush[i]
        end
      end
    end
    if @dstflush.length >= 5
      @dstflush.sort! { |a, b| b <=> a }
      for i in 0...@dstflush.length
        if @dstflush[i]== 14
          if @dstflush.include?(2) &&  @dstflush.include?(3) &&  @dstflush.include?(4) &&  @dstflush.include?(5)
            return 39000 + 5
          end
        end
        if @dstflush.include?((@dstflush[i])-1) && @dstflush.include?((@dstflush[i])-2) && @dstflush.include?((@dstflush[i])-3) && @dstflush.include?((@dstflush[i])-4)
          return 39000 + @dstflush[i]
        end
      end
    end
    if @sstflush.length >= 5
      @sstflush.sort! { |a, b| b <=> a }
      for i in 0...@sstflush.length
        if @sstflush[i]== 14
          if @sstflush.include?(2) &&  @sstflush.include?(3) &&  @sstflush.include?(4) &&  @sstflush.include?(5)
            return 39000 + 5
          end
        end
        if @sstflush.include?((@sstflush[i])-1) && @sstflush.include?((@sstflush[i])-2) && @sstflush.include?((@sstflush[i])-3) && @sstflush.include?((@sstflush[i])-4)
          return 39000 + @sstflush[i]
        end
      end
    end
    if @cstflush.length >= 5
      @cstflush.sort! { |a, b| b <=> a }
      for i in 0...@cstflush.length
        if @cstflush[i]== 14
          if @cstflush.include?(2) &&  @cstflush.include?(3) &&  @cstflush.include?(4) &&  @cstflush.include?(5)
            return 39000 + 5
          end
        end
        if @cstflush.include?((@cstflush[i])-1) && @cstflush.include?((@cstflush[i])-2) && @cstflush.include?((@cstflush[i])-3) && @cstflush.include?((@cstflush[i])-4)
          return 39000 + @cstflush[i]
        end
      end
    end

    ###########################
    ## check for 4 of a kind
    ###########################
    ### stores the value of every card in the four of a kind array
    ### then sorts the array by descending value
    ### if there's 4 equal cards then they will be adjacent so it checks
    ### i+1 i+2 and i+3, if all they're all of equal
    ### value returns 2100 (4 of a kind value) + array[i] (the card value)
    @fourofakind = []
    for i in 0...7
      @fourofakind.push(@hand[i][2])
    end

    @fourofakind.sort! { |a, b| b <=> a }

    for i in 0...@fourofakind.length
      if (@fourofakind[i] == @fourofakind[i+1]) && (@fourofakind[i] == @fourofakind[i+2]) && (@fourofakind[i] == @fourofakind[i+3])
        @tiebreakerhand.delete(@fourofakind[i])
        return 38000 + (@fourofakind[i]*14) + @tiebreakerhand[0]
      end
    end

    ###########################
    ## check for full house
    ###########################
    #### stores hands values by descending order in fullhouse array
    #### if theres 3 values in a row (at this point it already checked for 4 of a kind)
    #### returns the highest trio, it then checks for the highest pair
    #### it returns 1800 + 14x trio value + pair, it could go up to a max of 210
    #### so the value of four a kind is 2100 and this one's base is 1800 to make up for that
    @fullhouse = []
    trio = 0
    pair = 0
    for i in 0...7
      @fullhouse.push(@hand[i][2])
    end
    @fullhouse.sort! { |a, b| b <=> a }
    for i in 0...@fullhouse.length
      if (@fullhouse[i] == @fullhouse[i+1]) && (@fullhouse[i] == @fullhouse[i+2]) && trio == 0
        trio = @fullhouse[i]
      end
      if (@fullhouse[i] == @fullhouse[i+1]) && pair == 0 && (@fullhouse[i] != trio)
        pair = @fullhouse[i]
      end
    end
    if pair > 0 && trio > 0
      return 37000+(14*trio)+pair
    end


    ###########################
    ## check for flush
    ###########################
    ### distributes hand cards to its respective suit array and sorts descending
    ### if any suit array length is 5 or greater returns the 5 highest cards

    @hflush = []
    @dflush = []
    @sflush = []
    @cflush = []

    for i in 0...7
      @hflush.push(@hand[i][2]) if @hand[i][3] == "Hearts"
      @dflush.push(@hand[i][2]) if @hand[i][3] == "Diamonds"
      @sflush.push(@hand[i][2]) if @hand[i][3] == "Spades"
      @cflush.push(@hand[i][2]) if @hand[i][3] == "Clubs"
    end

    if @hflush.length >= 5
      @hflush.sort! { |a, b| b <=> a }
      return 36000 + @hflush[0] + @hflush[1] + @hflush[2] + @hflush[3] + @hflush[4]
    end
    if @dflush.length >= 5
      @dflush.sort! { |a, b| b <=> a }
      return 36000 + @dflush[0] + @dflush[1] + @dflush[2] + @dflush[3] + @dflush[4]
    end
    if @sflush.length >= 5
      @sflush.sort! { |a, b| b <=> a }
      return 36000 + @sflush[0] + @sflush[1] + @sflush[2] + @sflush[3] + @sflush[4]
    end
    if @cflush.length >= 5
      @cflush.sort! { |a, b| b <=> a }
      return 36000 + @cflush[0] + @cflush[1] + @cflush[2] + @cflush[3] + @cflush[4]
    end


    ###########################
    ## check for straight
    ###########################
    ### stores value of cards in straight array, sorts descending
    ### for each value, checks if @straight includes i+1,..i+4
    @straight = []

    for i in 0...7
      @straight.push(@hand[i][2])
    end
    @straight.sort! { |a, b| b <=> a }
    for i in 0...@straight.length
      if @straight[i] == 14
        if @straight.include?(2) && @straight.include?(3) && @straight.include?(4) && @straight.include?(5)
          return 35000 + 1
        end
      end
      if @straight.include?(@straight[i]+1) && @straight.include?(@straight[i]+2) && @straight.include?(@straight[i]+3) && @straight.include?(@straight[i]+4)
        return 35000 + @straight[i]
      end
    end

    ###########################
    ## check for 3 of a kind
    ###########################
    ### stores value of cards in threekind array and sorts descending
    ### for each value, checks if the 2 next values are equal to it
    ### note that by the time this chunk is run if there was a 4 of a kind /
    ### fullhouse, etc it will have already returned so this part only needs
    ### to check presence of a trio

    @threekind = []

    for i in 0...7
      @threekind.push(@hand[i][2])
    end

    @threekind.sort! { |a, b| b <=> a }

    for i in 0...@threekind.length
      if (@threekind[i] == @threekind[i+1]) && (@threekind[i] == @threekind[i+2])
        @tiebreakerhand.delete(@threekind[i])
        return 30000 + (@threekind[i]*140) + (14*@tiebreakerhand[0]) + @tiebreakerhand[1]
      end
    end


    ###########################
    ## check for 2 pairs
    ###########################
    ### stores value of cards in doublepair array and sorts descending
    ### for each value, checks if the next values is equal to it
    ### it will store the first pair in pair1 and the second pair in pair2
    ### when paircount == 2 it will stop looking for pairs
    ### returns 600 + 14x 1st pair value + 2nd pair for tiebreaker purposes
    ### range for double pairs in score is 600 - 810
    ### if paircount == 1 it will return 300 + pair1
    ### if paircount == 0 then it means the player got no "special hand"
    ### and it will return the highest card

    pair1 = 0
    pair2 = 0
    paircount = 0
    @doublepair = []

    for i in 0...7
      @doublepair.push(@hand[i][2])
    end

    @doublepair.sort! { |a, b| b <=> a }

    for i in 0...@doublepair.length
      if (@doublepair[i] == @doublepair[i+1]) && paircount <2
        if pair1 == 0
          pair1 = @doublepair[i]
          paircount += 1
        end
        if pair2 == 0 && (@doublepair[i] != pair1)
          pair2 = @doublepair[i]
          paircount += 1
        end
      end
    end
    if paircount == 2
      @tiebreakerhand.delete(pair1)
      @tiebreakerhand.delete(pair2)
      return 25000 + (140*pair1) + (14*pair2) + @tiebreakerhand[0]
    end

    if paircount == 1
      @tiebreakerhand.delete(pair1)
      return 300 + (pair1*1400) + (@tiebreakerhand[0]*140) + (@tiebreakerhand[1]*14) + @tiebreakerhand[2]
    end

    if paircount == 0
      if (@hand[0][2]) > (@hand[1][2])
        return 14*@hand[0][2] + @hand[1][2]
      else
        return 14*@hand[1][2] + @hand[0][2]
      end
    end

  end #function

  def updatepot
    10.times do
      @sprites["potvalue"].opacity -= 25.5
      pbWait(1)
    end
    pbWait(8)
    @sprites["potvalue"].bitmap.clear
    pokertext(@sprites["potvalue"].bitmap, @pot.to_s, Color.new(96,64,0), Color.new(248,240,160))
    10.times do
      @sprites["potvalue"].opacity += 25.5
      pbWait(1)
    end
  end

  def updatechips(player)
    case player
    when 0
      #update p1
      10.times do
        @sprites["p1chips"].opacity -= 25.5
        pbWait(1)
      end
      pbWait(8)
      @sprites["p1chips"].bitmap.clear
      pokertext(@sprites["p1chips"].bitmap, @players[0][0].to_s, Color.new(0,0,0), Color.new(240,240,240))
      10.times do
        @sprites["p1chips"].opacity += 25.5
        pbWait(1)
      end
    when 1
      #update p2
      10.times do
        @sprites["p2chips"].opacity -= 25.5
        pbWait(1)
      end
      pbWait(8)
      @sprites["p2chips"].bitmap.clear
      pokertext(@sprites["p2chips"].bitmap, @players[1][0].to_s, Color.new(0,0,0), Color.new(240,240,240))
      10.times do
        @sprites["p2chips"].opacity += 25.5
        pbWait(1)
      end
    when 2
      #update p3
      10.times do
        @sprites["p3chips"].opacity -= 25.5
        pbWait(1)
      end
      pbWait(8)
      @sprites["p3chips"].bitmap.clear
      pokertext(@sprites["p3chips"].bitmap, @players[2][0].to_s, Color.new(0,0,0), Color.new(240,240,240))
      10.times do
        @sprites["p3chips"].opacity += 25.5
        pbWait(1)
      end
    when 3
      #update p4
      10.times do
        @sprites["p4chips"].opacity -= 25.5
        pbWait(1)
      end
      pbWait(8)
      @sprites["p4chips"].bitmap.clear
      pokertext(@sprites["p4chips"].bitmap, @players[3][0].to_s, Color.new(0,0,0), Color.new(240,240,240))
      10.times do
        @sprites["p4chips"].opacity += 25.5
        pbWait(1)
      end
    end
  end

  def npcmove(npc)
    lowestchip = []
    for i in 0...4
      respectivebet = @player1bet if i == 0
      respectivebet = @player2bet if i == 1
      respectivebet = @player3bet if i == 2
      respectivebet = @player4bet if i == 3
      @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)  ##pushes high number that doesnt matter / else it bugs
      lowestchip[i] -= (@previousbet - respectivebet)  ##this is to avoid players calling and geting negative chips
    end
    lowestchip.sort!
    case npc
    when 1
      pcoins = @players[1][0] - (@previousbet - @player2bet)
      pbet = @player2bet
      subroundraise = @player2srr  ##subround raises, to avoid raisefest npcs only raise once per sub round
    when 2
      pcoins = @players[2][0] - (@previousbet - @player3bet)
      pbet = @player3bet
      subroundraise = @player3srr
    when 3
      pcoins = @players[3][0] - (@previousbet - @player4bet)
      pbet = @player4bet
      subroundraise = @player4srr
    end

    return 1 if (@players[0][1] + @players[1][1] + @players[2][1] + @players[3][1]) == 1  ##doesnt raise or fold if 1 player up only

    fold = 95
    raisem = 15
    a=rand(100)+1

    c = @player1srr + @player2srr + @player3srr + @player4srr

    c < 2 ? raisem -= 5*c : raisem -= 10*c    ##drops chance of raise if there was 1raise this subround, drops dramatically if there was 2 or more
    raisem -= @totalraises if @totalraises > 4 ##if there was more then 4 raises this ROUND, drops slightly and proportionately the chance for more raises

    if @previousbet == 0  ##check doesnt cost money, never fold
      fold = 101
    end
    if goodcard(npc) > 0   ##good hand, dont fold
      fold = 101
      raisem += 15 if goodcard(npc) == 1 ##good hand, more chances to raise
      raisem += 30 if goodcard(npc) == 2 ##rly good hand, more chances to raise
    end

    raisem -= @totalraises  ##adjust raise threshold for rng

    if subroundraise == 1   ##won't raise because already raised this subround
      raisem -= 45
    end

    if @previousbet == 0 && (pcoins < @blindvalue)  ##doesnt have money to bet
      raisem -= 45
    end

    if @previousbet > 0 && (pcoins < (@previousbet*2)) ##doesnt have money to raise
      raisem -= 45
    end

    if @comcards == 0 && ((@previousbet*2) > lowestchip[0]) ##lowest chips player cant call min raise
      raisem -= 45
    end

    if @comcards > 0 && (@blindvalue > lowestchip[0]) ##loest chips player cant call min bet
      raisem -= 45
    end
    return 3 if a > fold
    minraise = (@previousbet == 0) ? @blindvalue : 2*@previousbet
    return 1 if a<raisem && minraise > lowestchip[0]   ##can't raise without someone going below 0 chips
    return 2 if a<raisem
    return 1  ##calls / check if doesnt fold or raise
  end #function

  def goodcard(npc)
    score = 0
    case npc
    when 1
      score = handrate(@player2card1,@player2card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
    when 2
      score = handrate(@player3card1,@player3card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
    when 3
      score = handrate(@player4card1,@player4card2,@comcard1,@comcard2,@comcard3,@comcard4,@comcard5)
    end
    return 0 if score < 300    ##high card
    return 1 if score < 25000  ##1 pair
    return 2 if score > 25000  ##2 pair -> won't go any further, we don't want cheater npcs
  end

  def betscene
    @raisevalue = 0        #### fixes bug with the display of bet value
    @sprites["betvalue"].bitmap.clear
    pokertext(@sprites["betvalue"].bitmap, @raisevalue.to_s, Color.new(0,0,0), Color.new(240,240,200))
    updateselect
    @raisevalue = 0
    @betplaced = 0
    @select = 1
    @sprites["betui"].opacity = 255
    @sprites["selectarrow"].opacity = 255
    @sprites["betvalue"].opacity = 255
    @sprites["bet"].opacity = 255
    lowestchip = []

    for i in 0...4
      respectivebet = @player1bet if i == 0
      respectivebet = @player2bet if i == 1
      respectivebet = @player3bet if i == 2
      respectivebet = @player4bet if i == 3
      @players[i][1] == 1 ? lowestchip.push(@players[i][0]) : lowestchip.push(99999)
      lowestchip[i]-= (@previousbet - respectivebet)
    end
    lowestchip.sort!

    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::B)  ##cancels raise / bet scene
        #pbPlayCancelSE()
        @raisevalue = 0
        break
      end
      if Input.trigger?(Input::LEFT)
        pbPlayCursorSE()
        @select == 1 ? @select = 6 : @select -= 1
        updateselect
      end
      if Input.trigger?(Input::RIGHT)
        pbPlayCursorSE()
        @select == 6 ? @select = 1 : @select += 1
        updateselect
      end
      if Input.trigger?(Input::UP)   ##the row above (3 rows of 2)
        pbPlayCursorSE()
        @select = (@select + 3) % 6 + 1
        updateselect
      end
      if Input.trigger?(Input::DOWN)   ##the row below
        pbPlayCursorSE()
        @select = (@select + 1) % 6 + 1
        updateselect
      end
      if Input.trigger?(Input::C)
        case @select
        when 1
          if lowestchip[0] < 5 + @raisevalue
            pbPlayBuzzerSE()
            pbMessage(_INTL("Some players can't call that amount."))
          else
          pbPlayDecisionSE()
          @raisevalue += 5
          updatebet
          end
        when 2
          if lowestchip[0] < 10 + @raisevalue
            pbPlayBuzzerSE()
            pbMessage(_INTL("Some players can't call that amount."))
          else
          pbPlayDecisionSE()
          @raisevalue += 10
          updatebet
          end
        when 3
          if lowestchip[0] < 50 + @raisevalue
            pbPlayBuzzerSE()
            pbMessage(_INTL("Some players can't call that amount."))
          else
          pbPlayDecisionSE()
          @raisevalue += 50
          updatebet
          end
        when 4
          if lowestchip[0] < 100 + @raisevalue
            pbPlayBuzzerSE()
            pbMessage(_INTL("Some players can't call that amount."))
          else
          pbPlayDecisionSE()
          @raisevalue += 100
          updatebet
          end
        when 5
          allin = []
          for i in 0...4
            respectivebet = @player1bet if i == 0
            respectivebet = @player2bet if i == 1
            respectivebet = @player3bet if i == 2
            respectivebet = @player4bet if i == 3
            @players[i][1] == 1 ? allin.push(@players[i][0]) : allin.push(99999)
            allin[i]-= (@previousbet - respectivebet)
          end
          allin.sort!
          pbPlayDecisionSE()
          @raisevalue = allin[0]
          updatebet
        when 6
          if (@raisevalue<@blindvalue) && @previousbet == 0
            pbPlayBuzzerSE()
            pbMessage(_INTL("You must bet at least the value of the blind."))
          elsif (@raisevalue < (@previousbet*2))
            pbPlayBuzzerSE()
            pbMessage(_INTL("You must raise at least twice the previous bet."))
          elsif (@previousbet - @player1bet + @raisevalue > @players[0][0])
            pbPlayBuzzerSE()
            pbMessage(_INTL("You don't have that amount."))
          elsif (@raisevalue > lowestchip[0])
            pbPlayBuzzerSE()
            pbMessage(_INTL("Some players can't call that amount."))
          else
            if @previousbet == 0
              pbPlayDecisionSE()
              pbMessage(_INTL("{1} bets {2} chips.", @players[0][3], @raisevalue))
              @betplaced = 1      ##breaks the bet / raise scene loop
            else
              pbPlayDecisionSE()
              pbMessage(_INTL("{1} raises {2} chips.", @players[0][3], @raisevalue))
              @betplaced = 1
            end   ##@previousbet == 0
          end ## if @raisevalue < @blindvalue

        end ## case 1 - 6
      end ## if input C
      break if @betplaced == 1
    end  ## loop do
    @sprites["betui"].opacity = 0
    @sprites["selectarrow"].opacity = 0
    @select = 1 ##fixes bug with display of arrow next time betscene is accessed
    @sprites["betvalue"].opacity = 0
    @sprites["bet"].opacity = 0
  end ## function

  def updateselect
    x, y = BET_OPTION_POS[@select - 1]
    @sprites["selectarrow"].x = BETUI_X + x - 14
    @sprites["selectarrow"].y = BETUI_Y + y + 2
  end

  def updatebet
    10.times do
      @sprites["betvalue"].opacity -= 25.5
      pbWait(1)
    end
    @sprites["betvalue"].bitmap.clear
    pokertext(@sprites["betvalue"].bitmap, @raisevalue.to_s, Color.new(0,0,0), Color.new(240,240,200))
    10.times do
      @sprites["betvalue"].opacity += 25.5
      pbWait(1)
    end
  end

  def updatefold(arg)
    case arg
    when 0
      @sprites["p1_1"].opacity = 0
      @sprites["p1_2"].opacity = 0
    when 1
      @sprites["p2_1"].opacity = 0
      @sprites["p2_2"].opacity = 0
    when 2
      @sprites["p3_1"].opacity = 0
      @sprites["p3_2"].opacity = 0
    when 3
      @sprites["p4_1"].opacity = 0
      @sprites["p4_2"].opacity = 0
    end
  end

  def updatequitters
    if @players[1][2] == 0 && @sprites["p2name"].opacity == 255
      pbMessage(_INTL("{1} quits the game.", @players[1][3]))
      10.times do
        @sprites["p2name"].opacity -= 25.5
        pbWait(1)
      end
      @sprites["p2name"].bitmap.clear
      pokertext(@sprites["p2name"].bitmap, @players[1][3], Color.new(255,0,0), Color.new(255,255,255))
      10.times do
        @sprites["p2name"].opacity += 25.5
        pbWait(1)
      end
    end
    if @players[2][2] == 0 && @sprites["p3name"].opacity == 255
      pbMessage(_INTL("{1} quits the game.", @players[2][3]))
      10.times do
        @sprites["p3name"].opacity -= 25.5
        pbWait(1)
      end
      @sprites["p3name"].bitmap.clear
      pokertext(@sprites["p3name"].bitmap, @players[2][3], Color.new(255,0,0), Color.new(255,255,255))
      10.times do
        @sprites["p3name"].opacity += 25.5
        pbWait(1)
      end
    end
    if @players[3][2] == 0 && @sprites["p4name"].opacity == 255
      pbMessage(_INTL("{1} quits the game.", @players[3][3]))
      10.times do
        @sprites["p4name"].opacity -= 25.5
        pbWait(1)
      end
      @sprites["p4name"].bitmap.clear
      pokertext(@sprites["p4name"].bitmap, @players[3][3], Color.new(255,0,0), Color.new(255,255,255))
      10.times do
        @sprites["p4name"].opacity += 25.5
        pbWait(1)
      end
    end
  end

  def sequenceannounce(score)
    return _INTL("a Royal Straight Flush") if score == 40000
    return _INTL("a Straight Flush") if score >= 39000
    return _INTL("a 4 of a Kind") if score >= 38000
    return _INTL("a Full House") if score >= 37000
    return _INTL("a Flush") if score >= 36000
    return _INTL("a Straight") if score >= 35000
    return _INTL("a 3 of a Kind") if score >= 30000
    return _INTL("2 Pairs") if score >= 25000
    return _INTL("a Pair") if score >= 300
    return _INTL("a High Card")
  end

  def pokerdispose ###dispose all graphics
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    @viewport2.dispose
    @viewport3.dispose
    @viewport4.dispose
    @viewport5.dispose
  end


  def pbpokepokerstart
    loop do
      Graphics.update
      Input.update
      pbMessage(_INTL("Welcome to Poke Poker!"))
      pbMessage(_INTL("We have at the table {1}, {2}, {3} and {4}.", @players[0][3], @players[1][3], @players[2][3], @players[3][3]))
      pbMessage(_INTL("Each player starts with {1} chips, the value of the blind is {2} chips.", @fee, @blindvalue))
      pbMessage(_INTL("Happy gaming and may the odds be ever in your favor!"))
      while @gameover == 0
        roundannouncement
        drawcards
        playround
        roundwinner
      end
      break
    end
    pokerdispose
  end
end #classpokepoker
