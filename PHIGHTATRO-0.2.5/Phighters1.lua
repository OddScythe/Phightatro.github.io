
SMODS.Atlas {
	key = "Phighters1",
	path = "Phighters1.png",
	px = 71,
	py = 95
}

SMODS.Atlas {
  key = "modicon",
  path = "IconPhight.png",
  px = 34,
  py = 34
}

SMODS.Joker {
    key = "sword",
    blueprint_compat = true,
    perishable_compat = false,
    rarity = 3,
    cost = 10,
    pos = { x = 0, y = 0 },
    atlas = 'Phighters1',
    config = { extra = { Xmult = 1 } },
    loc_txt = {
        name = 'Sword',
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "Destroy joker to the {C:attention}LEFT{},",
            "and gains one tenth of its sell value",
            "as Xmult.",
            "{C:inactive}-Prepare Yourself!-{}"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local my_pos
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card then
                    my_pos = i
                    break
                end
            end

            if my_pos and G.jokers.cards[my_pos - 1] 
               and not SMODS.is_eternal(G.jokers.cards[my_pos - 1], card) 
               and not G.jokers.cards[my_pos - 1].getting_sliced then

                local sliced_card = G.jokers.cards[my_pos - 1]
                sliced_card.getting_sliced = true

                local gain = math.floor((sliced_card.sell_cost or 0) / 10)

                G.GAME.joker_buffer = G.GAME.joker_buffer - 1
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.GAME.joker_buffer = 0
                        card.ability.extra.Xmult = card.ability.extra.Xmult + gain
                        card:juice_up(0.8, 0.8)
                        sliced_card:start_dissolve({ HEX("57ecab") }, nil, 1.6)
                        play_sound('slice1', 0.96 + math.random() * 0.08)
                        return true
                    end
                }))

                return {
                    message = "X" .. tostring(card.ability.extra.Xmult + gain),
                    colour = G.C.RED,
                    no_juice = true
                }
            end
        end

        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult
            }
        end
    end
}



SMODS.Joker {
    key = "rocketlauncher",
    loc_txt = {
        name = 'Rocket',
        text = {
            "{C:green}#1# in #2#{} chance for",
            "each played {C:attention}7{} to create a",
            "{C:blue}Planet{} card when scored",
            "{C:inactive}(Must have room.){}",
            "{C:inactive}-It's showtime!-{}"
        }
    },
    blueprint_compat = true,
    rarity = 1, --common
    cost = 5,
    pos = { x = 1, y = 0 },
    atlas = 'Phighters1',
    config = { extra = { chance_num = 1, chance_den = 2 } }, -- odds stored here
    loc_vars = function(self, info_queue, card)
        local num = (card.ability and card.ability.extra and card.ability.extra.chance_num) or 1
        local den = (card.ability and card.ability.extra and card.ability.extra.chance_den) or 2
        local numerator, denominator = SMODS.get_probability_vars(card, num, den, 'RocketLaunch')
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and
            #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            local num = card.ability.extra.chance_num
            local den = card.ability.extra.chance_den
            if (context.other_card:get_id() == 7) and
                SMODS.pseudorandom_probability(card, 'RocketLaunch', num, den) then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                return {
                    extra = {
                        message = localize('k_plus_planet'),
                        message_card = card,
                        func = function()
                            G.E_MANAGER:add_event(Event({
                                func = (function()
                                    SMODS.add_card {
                                        set = 'Planet',
                                        key_append = 'RocketLaunch'
                                    }
                                    G.GAME.consumeable_buffer = 0
                                    return true
                                end)
                            }))
                        end
                    }
                }
            end
        end
    end
}



SMODS.Joker {
    key = "medkit",
    loc_txt = {
        name = 'Medkit',
        text = {
            "Earn {C:money}$#1#{} per",
            "scoring {C:orange}Enhanced card{} played,",
            "removes card {C:orange}Enhancement.{}",
            "{C:inactive}-Let's not do that again.--{}"
        }
    },
    blueprint_compat = true,
    rarity = 2, --Uncommon
    cost = 7,
    atlas = 'Phighters1',
    pos = { x = 2, y = 0 },
    config = { extra = { dollars = 3 } },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } } -- matches #1#
    end,

    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local enhanced = {}
            for _, scored_card in ipairs(context.scoring_hand) do
                if next(SMODS.get_enhancements(scored_card)) and not scored_card.debuff and not scored_card.vampired then
                    enhanced[#enhanced + 1] = scored_card
                    scored_card.vampired = true
                    scored_card:set_ability('c_base', nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            scored_card:juice_up()
                            scored_card.vampired = nil
                            return true
                        end
                    }))
                end
            end

            if #enhanced > 0 then
                local payout = card.ability.extra.dollars * #enhanced
                card.ability.extra._payout = payout -- store for joker_main
                return {
                    message = "$" .. payout,
                    colour = G.C.MONEY
                }
            end
        end

        if context.joker_main then
            local payout = card.ability.extra._payout
            if payout and payout > 0 then
                card.ability.extra._payout = nil
                return {
                    dollars = payout,
                    remove = true
                }
            end
        end
    end,
}


SMODS.Joker {
    key = 'darkheart',
    loc_txt = {
        name = 'DARKHEART',
        text = {
    "Played cards have a {C:green}#1# in #2#{} chance to",
    "become a {C:dark_edition}Negative{} card.",
    "{C:inactive}-It\'s rude to follow deities when they aren\'t looking.-{}",
       }
    },
    config = { extra = { odds = 8 } },
    rarity = 4, -- Legendary
    atlas = 'Phighters1',
    pos = { x = 0, y = 1 },
    soul_pos = { x = 4, y = 1 },
    cost = 20,
    --why are you here?
    blueprint_compat = false,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME.probabilities.normal or 1), card.ability.extra.odds } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.other_card and context.cardarea == G.play and not context.blueprint then
            local target = context.other_card
            if target and target.edition ~= 'e_negative' then
                if pseudorandom('darkheart') < (G.GAME.probabilities.normal or 1) / card.ability.extra.odds then
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            -- Yorick-style juice + sound
                            play_sound('tarot1')
                            if target and target.juice_up then target:juice_up(0.3, 0.4) end

                            -- flip to Negative after a small delay
                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                delay = 0.1,
                                blockable = false,
                                func = function()
                                    if target and target.set_edition then
                                        target:set_edition('e_negative', true)
                                        card_eval_status_text(card, 'extra', nil, nil, nil,
                                            { message = "CHAOS!", colour = G.C.GREEN })
                                    end
                                    return true
                                end
                            }))
                            return true
                        end
                    }))
                end
            end
        end

        -- no return here: Joker contributes nothing to chips/mult
        return nil
    end
}


SMODS.Joker {
    key = 'the_broker',
    loc_txt = {
        name = "The Broker",
        text = {
            "At end of round, earn {C:money}$2{} per",
            "{C:green}Uncommon{} Joker, {C:money}$3{} per {C:red}Rare{} Joker,",
            "{C:money}$5{} per {C:legendary}Legendary{} Joker.",
            "{C:inactive}-Don't mess this up.-{}",
        }
    },
      blueprint_compat = true,
    rarity = 2,
    cost = 6,
    config = {},
    atlas = 'Phighters1',
    pos = { x = 3, y = 0 },
    loc_vars = function(self, info_queue, card)
        return {}
    end,
    calculate = function(self, card, context)
        -- Only trigger once at the true end of round in Joker area
        if context.end_of_round and context.cardarea == G.jokers and not context.individual then
            local payout = 0
            for _, j in ipairs(G.jokers.cards) do
                if j ~= card then
                    local r = j.config.center.rarity
                    if r == 2 then payout = payout + 2 end -- Uncommon
                    if r == 3 then payout = payout + 3 end -- Rare
                    if r == 4 then payout = payout + 5 end -- Legendary
                    if r > 4 then payout = payout + 7 end -- Other rarities (modded)
                end
            end
            if payout > 0 then
                ease_dollars(payout)
                return {
                    message = "$" .. payout,
                    colour = G.C.MONEY,
                    repetitions = 1
                }
            end
        end
    end
}


----------------------------------------------
------------MOD CODE END----------------------
