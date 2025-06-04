--- STEAMODDED HEADER
--- MOD_NAME: GamblingBets
--- MOD_ID: GamblingBets
--- MOD_AUTHOR: [d_abco]
--- MOD_DESCRIPTION: Bet any amount of your money on your next hand in the shop.
--- STEAMODDED HEADER

----------------------------------------------
------------MOD CODE -------------------------

-- GLOBAL STATE VARIABLES

G.START_BET_ROLL = false
G.PAYOUT_CASH = false
G.BET_ALREADY_PLACED = false
G.BET_SIZE = 0
G.SAVED_BLIND = 0
G.LAST_USED_HAND = ''
G.HAND_BET_SELECTED = ''
G.HAND_BET_SELECTED_UI = ''
G.WIN_AMT_EARNINGS = 0
G.WIN_AMT_EARNINGS_UI = 0
G.BET_SIZE_UI = 5
G.LAST_BET_HAND = ''  -- Track last bet hand to prevent consecutive appearances

-- UTILITY FUNCTIONS

function safePlaySound(sound_name, volume)
  play_sound(sound_name, 1, volume or 0.7)
end

function G.FUNCS.checkTalismanFolder()
  local folderPath = "Mods/Talisman/"
  local folderInfo = love.filesystem.getInfo(folderPath, "directory")
  return folderInfo ~= nil
end

-- BET DISPLAY MANAGEMENT

function initializeBetFlameDisplay()
  if G.PAYOUT_CASH and G.BET_SIZE > 0 and G.HAND_BET_SELECTED ~= '' then
    G.BET_FLAME_TEXT = DynaText({
      string = {"BET: " .. G.HAND_BET_SELECTED .. " $" .. G.BET_SIZE},
      colours = {G.C.GOLD},
      scale = 0.6,
      shadow = true,
      float = true,
      bump = true
    })
    
    G.BET_FLAME_TEXT.T.x = 5
    G.BET_FLAME_TEXT.T.y = 2.7
    
    if not G.I then G.I = {} end
    if not G.I.TEXT then G.I.TEXT = {} end
    
    table.insert(G.I.TEXT, G.BET_FLAME_TEXT)
    return true
  end
  return false
end

function updateBetFlameDisplay()
  if G.PAYOUT_CASH and G.BET_SIZE > 0 and G.HAND_BET_SELECTED ~= '' then
    removeBetFlameDisplay()
    initializeBetFlameDisplay()
  end
end

function removeBetFlameDisplay()
  if G.BET_FLAME_TEXT then
    if G.I and G.I.TEXT then
      for i, text in ipairs(G.I.TEXT) do
        if text == G.BET_FLAME_TEXT then
          table.remove(G.I.TEXT, i)
          break
        end
      end
    end
    
    if G.BET_FLAME_TEXT.remove then
      G.BET_FLAME_TEXT:remove()
    end
    
    G.BET_FLAME_TEXT = nil
  end
end

function updateBetDisplay()
  if G.shop then
    local place_bet_element = G.shop:get_UIE_by_ID("place_bet_text")
    
    if place_bet_element then
      place_bet_element.config.text = "BET: $" .. G.BET_SIZE_UI
    end
    
    if G.shop.recalculate then 
      G.shop:recalculate()
    end
  end
end

-- STATE RESET FUNCTIONS

function resetBettingState()
  G.START_BET_ROLL = false
  G.PAYOUT_CASH = false
  G.BET_ALREADY_PLACED = false
  G.BET_SIZE = 0
  G.SAVED_BLIND = 0
  G.LAST_USED_HAND = ''
  G.HAND_BET_SELECTED = ''
  G.HAND_BET_SELECTED_UI = ''
  G.WIN_AMT_EARNINGS = 0
  G.WIN_AMT_EARNINGS_UI = 0
  G.BET_SIZE_UI = 5
  G.LAST_BET_HAND = ''
  removeBetFlameDisplay()
end

function Game:update_menu(dt)
  resetBettingState()
end

-- GAME LIFECYCLE HOOKS

Game.startRunRef = Game.start_run
function Game:start_run(...)
  self:startRunRef(...)
  
  resetBettingState()
  
  if G.GAME and G.GAME.p then
    G.GAME.p.bets = {active = false}
  end
end

Game.updateRoundRef = Game.update_round
function Game:update_round(dt)
  local oldRound = G.GAME.round
  self:updateRoundRef(dt)
  
  if G.GAME.round > oldRound then
    G.BET_ALREADY_PLACED = false
    
    if G.PAYOUT_CASH and G.BET_SIZE > 0 then
      G.PAYOUT_CASH = false
      G.BET_SIZE = 0
      G.HAND_BET_SELECTED = ''
      G.SAVED_BLIND = 0
      G.WIN_AMT_EARNINGS = 0
      removeBetFlameDisplay()
      
      if G.NOTIFICATION_QUEUE then
        G.NOTIFICATION_QUEUE:new_notification("Previous bet expired - new round started")
      end
    end
  end
end

Game.updateRef = Game.update
function Game:update(dt)
  self:updateRef(dt)
  
  if G.PAYOUT_CASH and G.BET_SIZE > 0 and G.HAND_BET_SELECTED ~= '' then
    if not self.last_bet_update or 
       not G.BET_FLAME_TEXT or
       self.last_bet_size ~= G.BET_SIZE or 
       self.last_bet_hand ~= G.HAND_BET_SELECTED then
      
      self.last_bet_size = G.BET_SIZE
      self.last_bet_hand = G.HAND_BET_SELECTED
      self.last_bet_update = true
      
      updateBetFlameDisplay()
    end
  else
    if self.last_bet_update then
      removeBetFlameDisplay()
      self.last_bet_update = false
    end
  end
end

-- HAND DETECTION AND PAYOUT LOGIC

function payoutBet(maxAmount)
  local hand_ratios = {
    ["Two Pair"] = 2.5,
    ["Three of a Kind"] = 2.0,
    ["Straight"] = 1.8,
    ["Flush"] = 1.5,
    ["Full House"] = 1.3,
    ["Four of a Kind"] = 1.1,
    ["Straight Flush"] = 1.0
  }
  
  local ratio = hand_ratios[G.HAND_BET_SELECTED] or 2.5
  G.WIN_AMT_EARNINGS = math.ceil(G.BET_SIZE / ratio)
  
  if G.WIN_AMT_EARNINGS > maxAmount then
    G.WIN_AMT_EARNINGS = maxAmount
  end
  
  local payout = G.WIN_AMT_EARNINGS + G.BET_SIZE
  ease_dollars(payout)
  play_sound('chips1')
  play_sound('coin1')
  
  if G.NOTIFICATION_QUEUE then
    G.NOTIFICATION_QUEUE:new_notification("Won $" .. payout .. " with " .. G.LAST_USED_HAND .. "!")
  end
  
  G.WIN_AMT_EARNINGS = 0
  G.HAND_BET_SELECTED = ''
  G.PAYOUT_CASH = false
  G.BET_SIZE = 0
  G.BET_ALREADY_PLACED = false
  removeBetFlameDisplay()
  
  if G.CONTROLLER and G.CONTROLLER.card_standard_matrix then
    G.CONTROLLER.card_standard_matrix = true
  end
end

function checkHandPayout()
  if not G.LAST_USED_HAND or not G.HAND_BET_SELECTED then return false end
  
  if G.HAND_BET_SELECTED == 'Two Pair' and 
    (G.LAST_USED_HAND == 'Two Pair' or G.LAST_USED_HAND == 'Full House' or 
     G.LAST_USED_HAND == 'Two Pair Plus' or G.LAST_USED_HAND == 'Four of a Kind') then
    payoutBet(25)
    return true
  end
  
  if G.HAND_BET_SELECTED == 'Three of a Kind' and
    (G.LAST_USED_HAND == 'Three of a Kind' or G.LAST_USED_HAND == 'Full House' or
     G.LAST_USED_HAND == 'Four of a Kind') then
    payoutBet(25)
    return true
  end
  
  if G.HAND_BET_SELECTED == 'Straight' and 
    (G.LAST_USED_HAND == 'Straight' or G.LAST_USED_HAND == 'Straight Flush' or
     G.LAST_USED_HAND == 'Royal Flush') then
    payoutBet(50)
    return true
  end
  
  if G.HAND_BET_SELECTED == 'Flush' and 
    (G.LAST_USED_HAND == 'Flush' or G.LAST_USED_HAND == 'Flush House' or
     G.LAST_USED_HAND == 'Straight Flush' or G.LAST_USED_HAND == 'Royal Flush' or
     G.LAST_USED_HAND == 'Flush Five') then
    payoutBet(50)
    return true
  end
  
  if G.HAND_BET_SELECTED == 'Full House' and
    (G.LAST_USED_HAND == 'Full House' or G.LAST_USED_HAND == 'Flush House') then
    payoutBet(50)
    return true
  end
  
  if G.HAND_BET_SELECTED == 'Four of a Kind' and
    (G.LAST_USED_HAND == 'Four of a Kind') then
    payoutBet(100)
    return true
  end
  
  if G.HAND_BET_SELECTED == 'Straight Flush' and
    (G.LAST_USED_HAND == 'Straight Flush' or G.LAST_USED_HAND == 'Royal Flush') then
    payoutBet(100)
    return true
  end
  
  return false
end

Game.updateHandPlayedImproved = Game.update_hand_played
function Game:update_hand_played(dt)
  self:updateHandPlayedImproved(dt)
  
  if G.PAYOUT_CASH and G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand then
    if G.GAME.current_round.current_hand.handname and G.GAME.current_round.current_hand.handname ~= '' then
      G.LAST_USED_HAND = G.GAME.current_round.current_hand.handname
      
      if G.GAME.round > G.SAVED_BLIND and G.GAME.current_round.hands_played == 1 then
        if not checkHandPayout() then
          G.WIN_AMT_EARNINGS = 0
          G.HAND_BET_SELECTED = ''
          G.PAYOUT_CASH = false
          G.BET_SIZE = 0
        end
      end
    end
  end
end

Game.updateShopRef = Game.update_shop
function Game:update_shop(dt)
  self:updateShopRef(dt)
  
  if not G.BET_SIZE_UI or G.BET_SIZE_UI <= 0 then
    G.BET_SIZE_UI = 5
  end
  
  if G.shop then
    local bet_amount_element = G.shop:get_UIE_by_ID("current_bet_amount")
    if bet_amount_element then
      bet_amount_element.config.text = "$" .. G.BET_SIZE_UI
    end
  end
  
  if G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played == 1 and 
     G.GAME.round > G.SAVED_BLIND and G.PAYOUT_CASH and G.LAST_USED_HAND and G.HAND_BET_SELECTED then
    checkHandPayout()
  end
end

-- SHOP TOGGLE AND STATE MANAGEMENT

local orig_toggle_shop = G.FUNCS.toggle_shop
G.FUNCS.toggle_shop = function(e)
  if orig_toggle_shop then
    orig_toggle_shop(e)
  end
  
  if G.STATE == G.STATES.SHOP then
    G.BET_ALREADY_PLACED = false
    -- Always reset shop hands when entering shop
    G.SHOP_HANDS_SET = false
    G.CURRENT_SHOP_HANDS = nil
    
    -- Reset UI state as well
    G.GAME.current_option_index = nil
    G.GAME.current_option = nil
    G.GAME.current_option2 = nil
    G.GAME.current_option3 = nil
    G.GAME.option_list = nil
    G.GAME.option_list2 = nil
    
    -- Reset any expired bets
    if G.PAYOUT_CASH and G.SAVED_BLIND < G.GAME.round then
      G.PAYOUT_CASH = false
      G.BET_SIZE = 0
      G.HAND_BET_SELECTED = ''
      G.SAVED_BLIND = 0
      G.WIN_AMT_EARNINGS = 0
      removeBetFlameDisplay()
    end
  end
end

-- BETTING CONTROL FUNCTIONS

function G.FUNCS.BET_DECREASE_5()
  if G.BET_SIZE_UI >= 6 then
    G.BET_SIZE_UI = G.BET_SIZE_UI - 5
    updateBetDisplay()
  end
end

function G.FUNCS.BET_DECREASE_1()
  if G.BET_SIZE_UI > 1 then
    G.BET_SIZE_UI = G.BET_SIZE_UI - 1
    updateBetDisplay()
  end
end

function G.FUNCS.BET_INCREASE_1()
  if G.GAME and G.GAME.dollars and G.BET_SIZE_UI < G.GAME.dollars then
    G.BET_SIZE_UI = G.BET_SIZE_UI + 1
    updateBetDisplay()
  end
end

function G.FUNCS.BET_INCREASE_5()
  if G.GAME and G.GAME.dollars and G.BET_SIZE_UI <= G.GAME.dollars - 5 then
    G.BET_SIZE_UI = G.BET_SIZE_UI + 5
    updateBetDisplay()
  elseif G.GAME and G.GAME.dollars and G.BET_SIZE_UI < G.GAME.dollars then
    G.BET_SIZE_UI = G.GAME.dollars
    updateBetDisplay()
  end
end

function G.FUNCS.BET_MAX()
  if G.GAME and G.GAME.dollars then
    G.BET_SIZE_UI = G.GAME.dollars
    updateBetDisplay()
  end
end

function G.FUNCS.CANCEL_BET()
  if not G.PAYOUT_CASH then
    if G.NOTIFICATION_QUEUE then
      G.NOTIFICATION_QUEUE:new_notification("No active bet to cancel")
    end
    return
  end
  
  ease_dollars(G.BET_SIZE)
  
  play_sound('coin2')
  
  if G.NOTIFICATION_QUEUE then
    G.NOTIFICATION_QUEUE:new_notification("Bet canceled! Refunded $" .. G.BET_SIZE)
  end
  
  G.PAYOUT_CASH = false
  G.BET_ALREADY_PLACED = false
  G.BET_SIZE = 0
  G.HAND_BET_SELECTED = ''
  G.SAVED_BLIND = 0
  G.WIN_AMT_EARNINGS = 0
  removeBetFlameDisplay()
end

function G.FUNCS.PLACE_BET()
  if G.BET_ALREADY_PLACED then
    if G.NOTIFICATION_QUEUE then
      G.NOTIFICATION_QUEUE:new_notification("You can only place one bet per round")
    end
    return
  end
  
  if G.GAME and G.GAME.dollars >= 5 and G.BET_SIZE_UI >= 5 then
    G.BET_SIZE = G.BET_SIZE_UI
    
    ease_dollars(-G.BET_SIZE_UI)

    play_sound('coin1')
    
    G.HAND_BET_SELECTED = G.GAME.current_option.option_text
    G.LAST_BET_HAND = G.HAND_BET_SELECTED  -- Track the last bet hand
    G.SAVED_BLIND = G.GAME.round
    G.PAYOUT_CASH = true
    initializeBetFlameDisplay()
    G.BET_ALREADY_PLACED = true
    
    if G.NOTIFICATION_QUEUE then
      G.NOTIFICATION_QUEUE:new_notification("Bet placed: $" .. G.BET_SIZE .. " on " .. G.HAND_BET_SELECTED)
    end
  else
    if not G.GAME or not G.GAME.dollars then
      return
    elseif G.GAME.dollars < 5 then
      if G.NOTIFICATION_QUEUE then
        G.NOTIFICATION_QUEUE:new_notification("Need at least $5 to place a bet")
      end
    elseif G.BET_SIZE_UI < 5 then
      if G.NOTIFICATION_QUEUE then
        G.NOTIFICATION_QUEUE:new_notification("Minimum bet is $5")
      end
    end
  end
end

function G.FUNCS.NEXT_OPTION()
  -- Hand-specific ratios
  local hand_ratios = {
    ["Two Pair"] = 2.5,
    ["Three of a Kind"] = 2.0,
    ["Straight"] = 1.8,
    ["Flush"] = 1.5,
    ["Full House"] = 1.3,
    ["Four of a Kind"] = 1.1,
    ["Straight Flush"] = 1.0
  }

  local max_payouts = {
    ["Two Pair"] = 25,
    ["Three of a Kind"] = 25,
    ["Straight"] = 50,
    ["Flush"] = 50,
    ["Full House"] = 50,
    ["Four of a Kind"] = 100,
    ["Straight Flush"] = 100
  }
  
  -- Cycle to next hand
  G.GAME.current_option_index = (G.GAME.current_option_index % #G.GAME.option_list) + 1
  G.GAME.current_option.option_text = G.GAME.option_list[G.GAME.current_option_index]
  
  -- Set ratio based on selected hand - only if current_option3 exists
  local selected_hand = G.GAME.current_option.option_text
  if G.GAME.current_option3 then
    G.GAME.current_option3.option_text3 = hand_ratios[selected_hand] or 2.5
  end
  
  -- Calculate payout with hand-specific ratio and max
  local max_payout = max_payouts[selected_hand] or 25
  local ratio = hand_ratios[selected_hand] or 2.5

  G.WIN_AMT_EARNINGS_UI = math.ceil(G.BET_SIZE_UI / ratio)
  if G.WIN_AMT_EARNINGS_UI > max_payout then
    G.WIN_AMT_EARNINGS_UI = max_payout
  end

  G.WIN_AMT_EARNINGS_UI = G.WIN_AMT_EARNINGS_UI + G.BET_SIZE_UI

  -- Update display
  for i, hand in ipairs(G.CURRENT_SHOP_HANDS) do
    local hand_max = max_payouts[hand]
    local hand_ratio = hand_ratios[hand] or 2.5
    local hand_payout = math.ceil(G.BET_SIZE_UI / hand_ratio)
    if hand_payout > hand_max then hand_payout = hand_max end
    hand_payout = hand_payout + G.BET_SIZE_UI
    
    G.GAME.option_list2[i] = string.format("$%d | $%d Max", hand_payout, hand_max)
  end
  
  G.GAME.current_option_index2 = (G.GAME.current_option_index2 % #G.GAME.option_list2) + 1
  G.GAME.current_option2.option_text2 = G.GAME.option_list2[G.GAME.current_option_index2]
end

function G.FUNCS.START_BET_ROLL()
  if G.GAME.dollars > 4 and G.BET_SIZE_UI >= 5 then
    G.START_BET_ROLL = true
  end
end

-- SAVE/LOAD FUNCTIONALITY

Game.gameExitRef = Game.exit
function Game:exit()
  if G.PAYOUT_CASH and G.BET_SIZE > 0 and G.HAND_BET_SELECTED ~= '' then
    G.GAME.p.bets = G.GAME.p.bets or {}
    G.GAME.p.bets.active = true
    G.GAME.p.bets.amount = G.BET_SIZE
    G.GAME.p.bets.hand = G.HAND_BET_SELECTED
    G.GAME.p.bets.saved_blind = G.SAVED_BLIND
    G.GAME.p.bets.already_placed = G.BET_ALREADY_PLACED
    G.GAME.p.bets.last_bet_hand = G.LAST_BET_HAND
  else
    if G.GAME.p and G.GAME.p.bets then
      G.GAME.p.bets.active = false
    end
  end
  
  self:gameExitRef()
end

Game.loadGameRef = Game.load_game
function Game:load_game(...)
  self:loadGameRef(...)
  
  if G.GAME and G.GAME.p and G.GAME.p.bets and G.GAME.p.bets.active then
    G.BET_SIZE = G.GAME.p.bets.amount
    G.HAND_BET_SELECTED = G.GAME.p.bets.hand
    G.SAVED_BLIND = G.GAME.p.bets.saved_blind
    G.PAYOUT_CASH = true
    G.BET_ALREADY_PLACED = G.GAME.p.bets.already_placed or true
    G.LAST_BET_HAND = G.GAME.p.bets.last_bet_hand or ''
    initializeBetFlameDisplay()
  else
    G.PAYOUT_CASH = false
    G.BET_SIZE = 0
    G.HAND_BET_SELECTED = ''
    G.BET_ALREADY_PLACED = false
    G.LAST_BET_HAND = ''
  end
end

-- SHOP UI DEFINITION

function G.UIDEF.shop()
  G.shop_jokers = CardArea(
    G.hand.T.x+0,
    G.hand.T.y+G.ROOM.T.y + 9,
    G.GAME.shop.joker_max*1.02*G.CARD_W,
    1.05*G.CARD_H, 
    {card_limit = G.GAME.shop.joker_max, type = 'shop', highlight_limit = 1}
  )

  G.shop_vouchers = CardArea(
    G.hand.T.x+0,
    G.hand.T.y+G.ROOM.T.y + 9,
    2.1*G.CARD_W,
    1.05*G.CARD_H, 
    {card_limit = 1, type = 'shop', highlight_limit = 1}
  )

  G.shop_booster = CardArea(
    G.hand.T.x+0,
    G.hand.T.y+G.ROOM.T.y + 9,
    2.4*G.CARD_W,
    1.15*G.CARD_H, 
    {card_limit = 2, type = 'shop', highlight_limit = 1, card_w = 1.27*G.CARD_W}
  )

  local shop_sign = AnimatedSprite(0, 0, 4.4, 2.2, G.ANIMATION_ATLAS['shop_sign'])
  shop_sign:define_draw_steps({
    {shader = 'dissolve', shadow_height = 0.05},
    {shader = 'dissolve'}
  })
  
  G.SHOP_SIGN = UIBox{
    definition = {
      n=G.UIT.ROOT, config = {colour = G.C.DYN_UI.MAIN, emboss = 0.05, align = 'cm', r = 0.1, padding = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", padding = 0.1, minw = 4.72, minh = 3.1, colour = G.C.DYN_UI.DARK, r = 0.1}, nodes={
          {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = shop_sign}}
          }},
          {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {localize('ph_improve_run')}, colours = {lighten(G.C.GOLD, 0.3)},shadow = true, rotate = true, float = true, bump = true, scale = 0.5, spacing = 1, pop_in = 1.5, maxw = 4.3})}}
          }},
        }},
      }
    },
    config = {
      align="cm",
      offset = {x=0,y=-15},
      major = G.HUD:get_UIE_by_ID('row_blind'),
      bond = 'Weak'
    }
  }
  
  G.E_MANAGER:add_event(Event({
    trigger = 'immediate',
    func = (function()
      G.SHOP_SIGN.alignment.offset.y = 0
      return true
    end)
  }))

  local hand_ratios = {
    ["Two Pair"] = 2.5,
    ["Three of a Kind"] = 2.0,
    ["Straight"] = 1.8,
    ["Flush"] = 1.5,
    ["Full House"] = 1.3,
    ["Four of a Kind"] = 1.1,
    ["Straight Flush"] = 1.0
  }

  local all_hands = {"Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"}

  -- Initialize/reset shop hands if needed
  if not G.CURRENT_SHOP_HANDS or not G.SHOP_HANDS_SET then
    math.randomseed(G.GAME.round * 1000 + G.GAME.round_resets.ante * 100)
    
    G.CURRENT_SHOP_HANDS = {}
    local available_hands = {}
    
    -- Copy all hands to available list
    for i, hand in ipairs(all_hands) do
      available_hands[i] = hand
    end
    
    -- Remove the last bet hand from available options if it exists
    if G.LAST_BET_HAND and G.LAST_BET_HAND ~= '' then
      for i = #available_hands, 1, -1 do
        if available_hands[i] == G.LAST_BET_HAND then
          table.remove(available_hands, i)
          break
        end
      end
    end
    
    -- Select 3 random hands from remaining options
    for i = 1, 3 do
      if #available_hands > 0 then
        local random_index = math.random(#available_hands)
        table.insert(G.CURRENT_SHOP_HANDS, available_hands[random_index])
        table.remove(available_hands, random_index)
      end
    end
    
    -- If we don't have enough hands (unlikely), fill from all hands
    while #G.CURRENT_SHOP_HANDS < 3 do
      local random_index = math.random(#all_hands)
      local hand = all_hands[random_index]
      
      -- Make sure we don't add duplicates
      local already_exists = false
      for _, existing_hand in ipairs(G.CURRENT_SHOP_HANDS) do
        if existing_hand == hand then
          already_exists = true
          break
        end
      end
      
      if not already_exists then
        table.insert(G.CURRENT_SHOP_HANDS, hand)
      end
    end
    
    local hand_difficulty = {
      ["Two Pair"] = 1,
      ["Three of a Kind"] = 2,
      ["Straight"] = 3,
      ["Flush"] = 4,
      ["Full House"] = 5,
      ["Four of a Kind"] = 6,
      ["Straight Flush"] = 7
    }
    
    table.sort(G.CURRENT_SHOP_HANDS, function(a, b)
      return hand_difficulty[a] < hand_difficulty[b]
    end)
    
    G.SHOP_HANDS_SET = true
    
    -- Clear G.LAST_BET_HAND after exclusion has been applied
    G.LAST_BET_HAND = ''
  end

  -- ALWAYS set the option list and force index to 1
  G.GAME.option_list = G.CURRENT_SHOP_HANDS
  G.GAME.current_option_index = 1
  
  -- Force regeneration of option object
  G.GAME.current_option = {option_text = G.GAME.option_list[1]}

  local selected_hand = G.GAME.current_option.option_text
  G.GAME.current_option3 = {option_text3 = hand_ratios[selected_hand] or 2.5}

  local max_payouts = {
    ["Two Pair"] = 25,
    ["Three of a Kind"] = 25,
    ["Straight"] = 50,
    ["Flush"] = 50,
    ["Full House"] = 50,
    ["Four of a Kind"] = 100,
    ["Straight Flush"] = 100
  }

  local max_payout = max_payouts[selected_hand] or 25
  local ratio = hand_ratios[selected_hand] or 2.5

  G.WIN_AMT_EARNINGS_UI = math.ceil(G.BET_SIZE_UI / ratio)
  if G.WIN_AMT_EARNINGS_UI > max_payout then
    G.WIN_AMT_EARNINGS_UI = max_payout
  end

  G.WIN_AMT_EARNINGS_UI = G.WIN_AMT_EARNINGS_UI + G.BET_SIZE_UI

  G.GAME.option_list2 = {}
  for i, hand in ipairs(G.CURRENT_SHOP_HANDS) do
    local hand_max = max_payouts[hand]
    local hand_ratio = hand_ratios[hand] or 2.5
    local hand_payout = math.ceil(G.BET_SIZE_UI / hand_ratio)
    if hand_payout > hand_max then hand_payout = hand_max end
    hand_payout = hand_payout + G.BET_SIZE_UI
    
    G.GAME.option_list2[i] = string.format("$%d | $%d Max", hand_payout, hand_max)
  end
  
  G.GAME.current_option_index2 = 1
  G.GAME.current_option2 = {option_text2 = G.GAME.option_list2[1]}

  local t = {
    n=G.UIT.ROOT, config = {align = 'cl', colour = G.C.CLEAR}, 
    nodes={
      UIBox_dyn_container({
        {n=G.UIT.C, config={align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, 
         nodes={
          {n=G.UIT.R, config={align = "cm", padding = 0}, 
           nodes={
            {n=G.UIT.C, config={align = "tm", padding = 0.05, r=0.2, colour = G.C.UI.LIGHT_BLUE, emboss = 0.05, minw = 3.5}, 
             nodes={
              {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
               nodes={
                {n=G.UIT.C, config={align = "cm", minw = 2.2, minh = 1, r=0.1, colour = G.C.RED, one_press = true, button = 'toggle_shop', hover = true, shadow = true}, 
                 nodes={{n=G.UIT.T, config={text = "Next Round", scale = 0.4, colour = G.C.WHITE}}}},
                {n=G.UIT.C, config={align = "cm", minw = 2.2, minh = 1, r=0.1, colour = G.C.GREEN, button = 'reroll_shop', func = 'can_reroll', hover = true, shadow = true}, 
                 nodes={
                  {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
                   nodes={
                    {n=G.UIT.T, config={text = "Reroll", scale = 0.4, colour = G.C.WHITE, shadow = true}}
                  }},
                  {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
                   nodes={
                    {n=G.UIT.T, config={text = "$", scale = 0.4, colour = G.C.WHITE, shadow = true}},
                    {n=G.UIT.T, config={ref_table = G.GAME.current_round, ref_value = 'reroll_cost', scale = 0.4, colour = G.C.WHITE, shadow = true}}
                  }}
                }}
              }},
              
              {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
               nodes={
                {n=G.UIT.T, config={ref_table = G.GAME.current_option, ref_value = 'option_text', scale = 0.45, colour = G.C.GOLD, shadow = true}}
              }},
              
              {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
               nodes={
                {n=G.UIT.T, config={ref_table = G.GAME.current_option2, ref_value = 'option_text2', scale = 0.3, colour = G.C.WHITE, shadow = true}}
              }},

              {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
               nodes={
                {n=G.UIT.C, config={align = "cm", minw = 0.88, minh = 0.3, r = 0.2, colour = G.C.RED, button = "BET_DECREASE_5", hover = true}, 
                 nodes={{n=G.UIT.T, config={text = "-5", scale = 0.35, colour = G.C.WHITE}}}},
                {n=G.UIT.C, config={align = "cm", minw = 0.88, minh = 0.3, r = 0.2, colour = G.C.RED, button = "BET_DECREASE_1", hover = true}, 
                 nodes={{n=G.UIT.T, config={text = "-1", scale = 0.35, colour = G.C.WHITE}}}},
                {n=G.UIT.C, config={align = "cm", minw = 0.88, minh = 0.3, r = 0.2, colour = G.C.BLUE, button = "BET_INCREASE_1", hover = true}, 
                 nodes={{n=G.UIT.T, config={text = "+1", scale = 0.35, colour = G.C.WHITE}}}},
                {n=G.UIT.C, config={align = "cm", minw = 0.88, minh = 0.3, r = 0.2, colour = G.C.BLUE, button = "BET_INCREASE_5", hover = true}, 
                 nodes={{n=G.UIT.T, config={text = "+5", scale = 0.35, colour = G.C.WHITE}}}},
                {n=G.UIT.C, config={align = "cm", minw = 0.88, minh = 0.3, r = 0.2, colour = G.C.GOLD, button = "BET_MAX", hover = true}, 
                 nodes={{n=G.UIT.T, config={text = "MAX", scale = 0.3, colour = G.C.WHITE}}}}
              }},
              
              {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
               nodes={
                {n=G.UIT.C, config={align = "cm", minw = 2.2, minh = 0.4, r=0.1, colour = G.C.BLUE, button = "NEXT_OPTION", hover = true, shadow = true}, 
                 nodes={{n=G.UIT.T, config={text = "Next Hand", scale = 0.3, colour = G.C.WHITE}}}},
                {n=G.UIT.C, config={align = "cm", minw = 2.2, minh = 0.4, r=0.1, colour = G.C.RED, button = "CANCEL_BET", hover = true, shadow = true}, 
                 nodes={{n=G.UIT.T, config={text = "Cancel Bet", scale = 0.3, colour = G.C.WHITE}}}}
              }},

              {n=G.UIT.R, config={align = "cm", padding = 0.02}, 
               nodes={
                {n=G.UIT.C, config={align = "cm", minw = 4.4, minh = 0.5, r = 0.1, colour = G.C.GOLD, button = "PLACE_BET", hover = true, shadow = true}, 
                 nodes={{n=G.UIT.T, config={id = "place_bet_text", text = "BET: $" .. G.BET_SIZE_UI, scale = 0.35, colour = HEX("564620")}}}}
              }}
            }},
            
            {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.L_BLACK, emboss = 0.05, minw = 6.0}, 
             nodes={
              {n=G.UIT.O, config={object = G.shop_jokers}}
            }}
          }},
          
          {n=G.UIT.R, config={align = "cm", minh = 0.2}, nodes={}},
          
          {n=G.UIT.R, config={align = "cm", padding = 0.1}, 
           nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0.15, r=0.2, colour = G.C.L_BLACK, emboss = 0.05}, 
             nodes={
              {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.BLACK, maxh = G.shop_vouchers.T.h+0.4}, 
               nodes={
                {n=G.UIT.T, config={text = localize{type = 'variable', key = 'ante_x_voucher', vars = {G.GAME.round_resets.ante}}, scale = 0.45, colour = G.C.L_BLACK, vert = true}},
                {n=G.UIT.O, config={object = G.shop_vouchers}}
              }}
            }},
            
            {n=G.UIT.C, config={align = "cm", padding = 0.15, r=0.2, colour = G.C.L_BLACK, emboss = 0.05}, 
             nodes={
              {n=G.UIT.O, config={object = G.shop_booster}}
            }}
          }}
        }}
      }, false)
    }
  }
 
  return t
end