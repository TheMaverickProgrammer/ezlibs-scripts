
--Dialogue Types
local dialogue_types = {
    first={
        name = "first",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function()
                local dialogue_texts = helpers.extract_numbered_properties(dialogue,"Text ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local res = await(Async.message_player(player_id, dialogue_texts[1], mugshot.texture_path, mugshot.animation_path))
                local next_id = first_value_from_table(next_dialogues)
                return next_id
            end)
        end
    },
    question={
        name = "question",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local dialogue_texts = helpers.extract_numbered_properties(dialogue,"Text ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local res = await(Async.question_player(player_id, dialogue_texts[1], mugshot.texture_path, mugshot.animation_path))
                local next_id = next_dialogues[2-res]
                return next_id
            end)
        end
    },
    quiz={
        name = "quiz",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local dialogue_texts = helpers.extract_numbered_properties(dialogue,"Text ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local res = await(Async.quiz_player(player_id, dialogue_texts[1],dialogue_texts[2],dialogue_texts[3], mugshot.texture_path, mugshot.animation_path))
                local next_id = next_dialogues[res+1]
                return next_id
            end)
        end
    },
    random={
        name = "random",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local dialogue_texts = helpers.extract_numbered_properties(dialogue,"Text ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local rnd_text_index = math.random( #dialogue_texts)
                local res = await(Async.message_player(player_id, dialogue_texts[rnd_text_index], mugshot.texture_path, mugshot.animation_path))
                local next_id = next_dialogues[rnd_text_index] or next_dialogues[1]
                return next_id
            end)
        end
    },
    itemcheck={
        name = 'itemcheck',
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local required_item = dialogue.custom_properties["Required Item"]
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                if required_item ~= nil then
                    local required_amount = dialogue.custom_properties["Required Amount"]
                    if required_amount == nil then
                        required_amount = 1
                    end
                    local take_item = dialogue.custom_properties["Take Item"] == "true"
                    if required_item == "money" then
                        if Net.get_player_money(player_id) >= tonumber(required_amount) then
                            next_dialogue_id = next_dialogues[1]
                            if take_item then
                                ezmemory.spend_player_money(player_id,required_amount)
                            end
                        else
                            next_dialogue_id = next_dialogues[2]
                        end
                    else
                        if ezmemory.count_player_item(player_id, required_item) >= tonumber(required_amount) then
                            next_dialogue_id = next_dialogues[1]
                            if take_item then
                                ezmemory.remove_player_item(player_id, required_item, required_amount)
                            end
                        else
                            next_dialogue_id = next_dialogues[2]
                        end
                    end
                end
                return next_dialogue_id
            end)
        end
    },
    before={
        name = "before",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local dialogue_texts = helpers.extract_numbered_properties(dialogue,"Text ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local date_b = dialogue.custom_properties['Date']
                local message = dialogue_texts[2]
                local next_dialogue_id = next_dialogues[2]
                if helpers.is_now_before_date(date_b) then
                    message = dialogue_texts[1]
                    next_dialogue_id = next_dialogues[1]
                end
                if message then
                    await(Async.message_player(player_id, message, mugshot.texture_path, mugshot.animation_path))
                end
                return next_dialogue_id
            end)
        end
    },
    after={
        name = "after",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local dialogue_texts = helpers.extract_numbered_properties(dialogue,"Text ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local date_b = dialogue.custom_properties['Date']
                local message = dialogue_texts[2]
                local next_dialogue_id = next_dialogues[2]
                if not helpers.is_now_before_date(date_b) then
                    message = dialogue_texts[1]
                    next_dialogue_id = next_dialogues[1]
                end
                if message then
                    await(Async.message_player(player_id, message, mugshot.texture_path, mugshot.animation_path))
                end
                return next_dialogue_id
            end)
        end
    },
    shop={
        name = "shop",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local area_id = Net.get_player_area(player_id)
                local shop_item_object_ids = helpers.extract_numbered_properties(dialogue,"Item ")
                local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
                local mugshot = eznpcs.get_dialogue_mugshot(npc,player_id,dialogue)
                local shop_items = {}

                --create list of items for sale
                for i, item_object_id in ipairs(shop_item_object_ids) do
                    local item_info_object = Net.get_object_by_id(area_id,item_object_id)
                    local item_info = item_info_object.custom_properties
                    if item_info then
                        local shop_item = {
                            name=item_info["Name"] or "???",
                            price=tonumber(item_info["Price"] or 9999999),
                            description=item_info["Description"] or "???",
                            is_key=item_info["Is Key"] == 'true'
                        }
                        table.insert(shop_items,shop_item)
                    end
                end

                await(ezmemory.open_shop_async(player_id,shop_items,mugshot.texture_path,mugshot.animation_path))
                local next_id = first_value_from_table(next_dialogues)
                return next_id
            end)
        end
    },
    password={
        name = "password",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local correct_password = dialogue.custom_properties["Password"]
                local user_input = await(Async.prompt_player(player_id))
                if user_input == correct_password then
                    return dialogue.custom_properties["Next 1"]
                else
                    return dialogue.custom_properties["Next 2"]
                end
            end)
        end
    },
    item={
        name = "item",
        action = function(npc, player_id, dialogue, relay_object)
            return async(function ()
                local item_name = dialogue.custom_properties["Name"]
                local description = dialogue.custom_properties["Description"] or "???"
                local is_key = dialogue.custom_properties["Is Key"] == "true"
                local amount = tonumber(dialogue.custom_properties["Amount"]) or 1
                local notify_player = not dialogue.custom_properties["Dont Notify"] == "true"
                if not item_name then
                    return
                end
                ezmemory.create_or_update_item(item_name,description,is_key)
                ezmemory.give_player_item(player_id,item_name,amount)
                local message = ""
                if notify_player then
                    if amount == 1 then
                        message = "Got "..item_name.."!"
                    elseif amount > 1 then
                        message = "Got "..amount.." "..item_name.."!"
                    end
                    Net.play_sound_for_player(player_id, '/server/assets/ezlibs-assets/sfx/item_get.ogg')
                    await(Async.message_player(player_id, message))
                end
            end)
        end
    }
}

return dialogue_types