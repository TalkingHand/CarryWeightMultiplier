-- Single-player in-game test, test environment only: pzt installs this file into the test copy
-- of the mod (TEST_FILES in pzt.conf); the script calls CarryWeightMultiplierTest.run().
-- Vanilla values below are from media/scripts/generated/items (42.21).
-- Results: "[CarryWeightMultiplierTest]" lines (failures also "[PZTest] FAIL").

local function log(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
	print("[CarryWeightMultiplierTest] " .. table.concat(parts, " "))
end

local T = { pass = 0, fail = 0 }
CarryWeightMultiplierTest = T

local function check(label, ok, extra)
	if ok then T.pass = T.pass + 1 else T.fail = T.fail + 1 end
	log(ok and "PASS" or "FAIL", label, extra or "")
	if not ok and PZTest then PZTest.fail("CarryWeightMultiplierTest " .. label .. " " .. tostring(extra or "")) end
end

local function near(label, got, want)
	check(label, got ~= nil and math.abs(got - want) < 0.0005, "got=" .. tostring(got) .. " want=" .. tostring(want))
end

local function inv() return getPlayer():getInventory() end
local function equippedMult() return ZomboidGlobals.equippedOrWornEncumbranceMultiplier or 0.3 end

function T.single()
	local plank = instanceItem("Base.Plank")
	near("plank actual stays vanilla", plank:getActualWeight(), 3.0)
	near("plank getWeight stays vanilla", plank:getWeight(), 3.0)
	near("plank unequipped", plank:getUnequippedWeight(), 0.3)
	near("plank equipped", plank:getEquippedWeight(), 3.0 * equippedMult() / 10)
	near("plank hotbar", plank:getHotbarEquippedWeight(), 3.0 * 0.7 / 10)
end

function T.carried()
	local i = inv()
	local before = getPlayer():getInventoryWeight()
	local items = {}
	for n = 1, 20 do items[n] = i:AddItem("Base.Log") end
	near("20 logs in the character total", getPlayer():getInventoryWeight() - before, 18.0)
	near("20 logs in capacity weight", i:getCapacityWeight() - before, 18.0)
	log("max weight", getPlayer():getMaxWeight())
	for n = 1, 20 do i:Remove(items[n]) end
	near("logs removed", getPlayer():getInventoryWeight(), before)
end

function T.bag()
	local bag = instanceItem("Base.Bag_Schoolbag")
	local contents = bag:getInventory()
	near("empty bag", bag:getUnequippedWeight(), bag:getActualWeight() / 10)
	contents:AddItem("Base.Plank")
	near("contents counted once", contents:getContentsWeight(), 0.3)
	near("bag with plank", bag:getUnequippedWeight(), bag:getActualWeight() / 10 + 0.3)

	local reduction = 1 - bag:getWeightReduction() / 100
	near("worn bag with plank", bag:getEquippedWeight(), bag:getActualWeight() * equippedMult() / 10 + 0.3 * reduction)
	near("hotbar bag with plank", bag:getHotbarEquippedWeight(), bag:getActualWeight() * 0.7 / 10 + 0.3 * 0.7)

	-- a bag inside a bag must not shrink twice
	local outer = instanceItem("Base.Bag_Schoolbag")
	outer:getInventory():AddItem(bag)
	near("nested bag", outer:getUnequippedWeight(), outer:getActualWeight() / 10 + bag:getActualWeight() / 10 + 0.3)

	-- vanilla refuses this: planks weigh 3 each, over the bag's capacity
	local big = instanceItem("Base.Bag_Schoolbag")
	local room = big:getInventory()
	local capacity = room:getCapacity()
	local fit = math.floor(capacity / 0.3) - 1
	for _ = 1, fit do room:AddItem("Base.Plank") end
	log("capacity", capacity, "planks", fit, "counted", room:getCapacityWeight())
	check("bag has room for ten times the planks", room:hasRoomFor(getPlayer(), instanceItem("Base.Plank")), "planks=" .. fit)
	for _ = 1, 3 do room:AddItem("Base.Plank") end
	check("bag is full past a tenth", not room:hasRoomFor(getPlayer(), instanceItem("Base.Plank")), "counted=" .. room:getCapacityWeight())
end

function T.weapon()
	local rifle = instanceItem("Base.VarmintRifle")
	local bare = rifle:getActualWeight()
	near("rifle unequipped", rifle:getUnequippedWeight(), (bare + rifle:getContentsWeight()) / 10)
	rifle:attachWeaponPart(getPlayer(), instanceItem("Base.x8Scope"))
	near("scope adds its vanilla weight to actual", rifle:getActualWeight() - bare, 0.8)
	near("axe weight for stamina stays vanilla", instanceItem("Base.Axe"):getWeight(), 3.0)
end

function T.fluid()
	local bottle = instanceItem("Base.WaterBottle")
	local fc = bottle:getFluidContainer()
	fc:Empty()
	near("empty bottle", bottle:getUnequippedWeight(), 0.01)
	fc:addFluid(Fluid.Water, 0.5)
	near("bottle with 0.5 L", bottle:getUnequippedWeight(), 0.06)
end

-- These read the vanilla weights: they must not have moved.
function T.others()
	near("fuel Plank hours", ISCampingMenu.getFuelDurationForItemInHours(instanceItem("Base.Plank")), 2.0)
	near("forage size", forageSystem.getItemDefSize({ type = "Base.Plank", itemSizeModifier = 0 }), 3.0)
	near("script Plank", ScriptManager.instance:getItem("Base.Plank"):getActualWeight(), 3.0)
	near("script FishFillet", ScriptManager.instance:getItem("Base.FishFillet"):getActualWeight(), 0.2)
end

-- The real timed action, with a load vanilla refuses: 10 logs weigh 90 in a bag of capacity 15.
function T.transferStart()
	local p = getPlayer()
	T.bagItem = inv():AddItem("Base.Bag_Schoolbag")
	T.logs = {}
	for n = 1, 10 do
		T.logs[n] = inv():AddItem("Base.Log")
		ISTimedActionQueue.add(ISInventoryTransferAction:new(p, T.logs[n], inv(), T.bagItem:getInventory()))
	end
	log("queued", #T.logs, "logs")
end

function T.transferCheck()
	local room = T.bagItem:getInventory()
	log("actions left", #ISTimedActionQueue.getTimedActionQueue(getPlayer()).queue)
	check("10 logs moved into the bag", room:getItems():size() == 10, "in bag=" .. room:getItems():size())
	near("bag counts them as 9", room:getContentsWeight(), 9.0)
end

-- Furniture: the check before picking up reads the sprite's weight, not an item's.
local FURNITURE = { "appliances_refrigeration_01_0", "furniture_storage_01_0", "furniture_storage_02_0",
	"furniture_shelving_01_0", "furniture_seating_indoor_01_0", "furniture_tables_low_01_0" }

-- A load that leaves about half of weight free: too little for it in full, plenty for a tenth.
local function setRoom(weight)
	local i = inv()
	for _, item in ipairs(T.filler or {}) do i:Remove(item) end
	T.filler = {}
	for _, fullType in ipairs({ "Base.Log", "Base.Plank", "Base.LightBulb" }) do
		local counted = instanceItem(fullType):getUnequippedWeight()
		while i:getEffectiveCapacity(getPlayer()) - i:getCapacityWeight() - counted >= weight / 2 do
			T.filler[#T.filler + 1] = i:AddItem(fullType)
		end
	end
	log("room", i:getEffectiveCapacity(getPlayer()) - i:getCapacityWeight(), "for", weight)
end

function T.furnitureStart()
	local p = getPlayer()
	for _, name in ipairs(FURNITURE) do
		local props = ISMoveableSpriteProps.new(name)
		log("sprite", name, "moveable", props.isMoveable, "weight", props.weight, "multi", props.isMultiSprite, "tool", props.pickUpTool)
		if props.isMoveable and not props.isMultiSprite and not props.pickUpTool
			and (not T.props or props.weight > T.props.weight) then
			T.props = props
			T.spriteName = name
		end
	end
	check("a heavy single-tile furniture sprite", T.props ~= nil and T.props.weight >= 2, tostring(T.spriteName))
	if not T.props then return end

	local w, i, sq = T.props.weight, inv(), p:getSquare()
	setRoom(w)
	check("room for a tenth, not for the full weight", i:hasRoomFor(p, w / 10) and not i:hasRoomFor(p, w),
		"weight=" .. w .. " load=" .. i:getCapacityWeight() .. " of " .. i:getEffectiveCapacity(p))
	check("can pick it up", T.props:canPickUpMoveable(p, sq, nil))
	InfoPanelFlags.tooHeavy = false
	T.props:getInfoPanelFlagsPerTile(sq, nil, p, "pickup")
	check("cursor does not say too heavy", not InfoPanelFlags.tooHeavy)
	T.props:getInfoPanelFlagsGeneral(sq, nil, p, "pickup")
	check("cursor shows a tenth", InfoPanelFlags.weight == tostring(round(w / 10, 3)), "shown=" .. tostring(InfoPanelFlags.weight))
	near("sprite weight stays vanilla", T.props.weight, w)

	-- placed the way vanilla places it, so it is the real kind of object
	T.props:placeMoveableInternal(p, sq, T.props:instanceItem(T.spriteName), T.spriteName)
	T.object = T.props:findOnSquare(sq, T.spriteName)
	log("placed", tostring(T.object))
	T.loadBefore = i:getCapacityWeight()
	ISTimedActionQueue.add(ISMoveablesAction:new(p, sq, "pickup", T.spriteName, T.object, "N"))
	log("queued pickup", T.spriteName)
end

function T.furnitureCheck()
	if not T.props then return end
	local items, item = inv():getItems(), nil
	for n = 0, items:size() - 1 do
		if instanceof(items:get(n), "Moveable") then item = items:get(n) end
	end
	log("actions left", #ISTimedActionQueue.getTimedActionQueue(getPlayer()).queue)
	check("furniture is in the inventory", item ~= nil)
	if not item then return end
	near("real weight stays vanilla", item:getActualWeight(), T.props.weight)
	near("counts a tenth", item:getUnequippedWeight(), T.props.weight / 10)
	near("load grew by a tenth", inv():getCapacityWeight() - T.loadBefore, T.props.weight / 10)
end

-- The options are built by hand here: no curtain or lamp in the test save.
function T.curtainObject()
	return IsoObject.new(getPlayer():getSquare(), T.spriteName, T.spriteName)
end

function T.curtain()
	local p, num = getPlayer(), getPlayer():getPlayerNum()
	local w = getScriptManager():FindItem("Base.Sheet"):getActualWeight()
	setRoom(w)
	check("vanilla would refuse the sheet", not inv():hasRoomFor(p, w), "weight=" .. w)
	local option = ISWorldObjectContextMenu.addRemoveCurtainOption(ISContextMenu.get(num, 0, 0), {}, T.curtainObject(), num)
	check("curtain option is available", not option.notAvailable)
	check("curtain tooltip has no too heavy", not option.toolTip.description:find(getText("IGUI_ToHeavy"), 1, true), option.toolTip.description)

	setRoom(0)
	check("no room for a tenth of the sheet", not inv():hasRoomFor(p, w / 10))
	option = ISWorldObjectContextMenu.addRemoveCurtainOption(ISContextMenu.get(num, 0, 0), {}, T.curtainObject(), num)
	check("curtain option stays refused when really full", option.notAvailable)
end

function T.bulb()
	local p, num = getPlayer(), getPlayer():getPlayerNum()
	local w = getScriptManager():FindItem("Base.LightBulb"):getActualWeight()
	setRoom(w)
	check("vanilla would refuse the bulb", not inv():hasRoomFor(p, w), "weight=" .. w)
	local context = ISContextMenu.get(num, 0, 0)
	local sub = ISContextMenu:getNew(context)
	context:addSubMenu(context:addOption("light"), sub)
	local lamp = { getBulbItem = function() return "Base.LightBulb" end }
	local option = sub:addGetUpOption(getText("ContextMenu_RemoveLightbulb"), {}, nil, lamp, num, true)
	option.notAvailable = true
	option.toolTip = ISWorldObjectContextMenu.addToolTip()
	CarryWeightMultiplier.fillMenu(num, context)
	check("bulb option is available", not option.notAvailable)
end

-- The sandbox option, changed the way a loaded setting changes it.
local function setMultiplier(value)
	getSandboxOptions():set("CarryWeightMultiplier.Multiplier", value)
	getSandboxOptions():toLua()
	near("lua reads " .. value, CarryWeightMultiplier.multiplier(), value)
end

function T.multiplierOption()
	near("default on a save from before the option", CarryWeightMultiplier.multiplier(), 0.1)
	local plank = instanceItem("Base.Plank")
	local bag = instanceItem("Base.Bag_Schoolbag")
	bag:getInventory():AddItem("Base.Plank")
	local bagWeight = bag:getActualWeight()

	for _, m in ipairs({ 0.5, 1, 0 }) do
		setMultiplier(m)
		near("plank unequipped x" .. m, plank:getUnequippedWeight(), 3.0 * m)
		near("plank equipped x" .. m, plank:getEquippedWeight(), 3.0 * equippedMult() * m)
		near("plank hotbar x" .. m, plank:getHotbarEquippedWeight(), 3.0 * 0.7 * m)
		near("bag with plank x" .. m, bag:getUnequippedWeight(), (bagWeight + 3.0) * m)
		near("plank actual stays x" .. m, plank:getActualWeight(), 3.0)
		if T.props then
			T.props:getInfoPanelFlagsGeneral(getPlayer():getSquare(), nil, getPlayer(), "pickup")
			check("cursor shows x" .. m, InfoPanelFlags.weight == tostring(round(T.props.weight * m, 3)), "shown=" .. tostring(InfoPanelFlags.weight))
		end
	end

	-- at 0 nothing fills up
	check("logs fit at 0", inv():hasRoomFor(getPlayer(), instanceItem("Base.Log")))
	near("total is 0 at 0", getPlayer():getInventoryWeight(), 0)
	setMultiplier(0.1)
end

function T.menus()
	for _, name in ipairs({ "curtain", "bulb", "multiplierOption" }) do
		local ok, err = pcall(T[name])
		if not ok then check("section " .. name, false, err) end
	end
	log("RESULT pass=" .. T.pass .. " fail=" .. T.fail)
end

function T.run()
	for _, name in ipairs({ "single", "carried", "bag", "weapon", "fluid", "others" }) do
		local ok, err = pcall(T[name])
		if not ok then check("section " .. name, false, err) end
	end
	log("RESULT pass=" .. T.pass .. " fail=" .. T.fail)
end
