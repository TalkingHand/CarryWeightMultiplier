-- Taking down curtains and light bulbs: the menu compares the item's full weight with the free
-- capacity and greys the option out. Both happen inside vanilla menu code, so the result is corrected.
require "ISUI/ISWorldObjectContextMenu"

local function hasRoom(playerObj, weight)
	return playerObj:getInventory():hasRoomFor(playerObj, weight * CarryWeightMultiplier.multiplier())
end

local addRemoveCurtainOption = ISWorldObjectContextMenu.addRemoveCurtainOption
ISWorldObjectContextMenu.addRemoveCurtainOption = function(context, worldobjects, curtain, player)
	local option = addRemoveCurtainOption(context, worldobjects, curtain, player)
	if option and option.notAvailable and hasRoom(getSpecificPlayer(player), getScriptManager():FindItem("Base.Sheet"):getActualWeight()) then
		option.notAvailable = false
		local tooHeavy = "<LINE> <LINE> <RGB:1,0,0>" .. getText("IGUI_ToHeavy")
		local description = option.toolTip.description
		option.toolTip.description = description:sub(1, #description - #tooHeavy)
	end
	return option
end

-- option.param3 is the light switch: addGetUpOption puts its callback and target first.
local function fixBulbOptions(playerObj, menu)
	local removeBulb = getText("ContextMenu_RemoveLightbulb")
	for _, option in ipairs(menu.options) do
		if option.subOption then
			fixBulbOptions(playerObj, menu:getSubMenu(option.subOption))
		elseif option.name == removeBulb and option.notAvailable then
			local bulb = getScriptManager():FindItem(option.param3:getBulbItem())
			if bulb and hasRoom(playerObj, bulb:getActualWeight()) then
				option.notAvailable = false
				option.toolTip = nil
			end
		end
	end
end

function CarryWeightMultiplier.fillMenu(player, context)
	fixBulbOptions(getSpecificPlayer(player), context)
end

Events.OnFillWorldObjectContextMenu.Add(CarryWeightMultiplier.fillMenu)
