-- Furniture: the pickup check and the cursor panel use the sprite's full weight; the check goes
-- through hasRoomFor(character, float), which takes the number as given. Once picked up the item
-- counts the multiplied weight through the Java patches, so only these three need it.
require "Moveables/ISMoveableSpriteProps"

CarryWeightMultiplier = {}

function CarryWeightMultiplier.multiplier()
	return SandboxVars.CarryWeightMultiplier and SandboxVars.CarryWeightMultiplier.Multiplier or 0.1
end

-- self is cached per sprite and also sets the item's real weight, so these get a stand-in.
local function counted(props)
	if not props.weight then return props end
	return setmetatable({ weight = props.weight * CarryWeightMultiplier.multiplier() }, { __index = props, __newindex = props })
end

local function useCounted(name)
	local vanilla = ISMoveableSpriteProps[name]
	ISMoveableSpriteProps[name] = function(self, ...)
		return vanilla(counted(self), ...)
	end
end

useCounted("canPickUpMoveableInternal")
useCounted("getInfoPanelFlagsPerTile")
useCounted("getInfoPanelFlagsGeneral")
