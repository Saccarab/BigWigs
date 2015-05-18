
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Kromog", 988, 1162)
if not mod then return end
mod:RegisterEnableMob(77692)
mod.engageId = 1713
mod.respawnTime = 29.5

--------------------------------------------------------------------------------
-- Locals
--

local breathCount = 1
local callOfTheMountainCount = 1
local tank1Skull, tank2Cross = nil, nil
local handsMarks = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.custom_off_hands_marker = "Grasping Earth tank marker"
	L.custom_off_hands_marker_desc = "Mark the Grasping Earth that picks up the tanks with {rt7}{rt8}, requires promoted or leader."
	L.custom_off_hands_marker_icon = 8
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Mythic ]]--
		173917, -- Rune of Trembling Earth
		-9706, -- Call of the Mountain
		--[[ General ]]--
		{156766, "TANK"}, -- Warped Armor
		156852, -- Stone Breath
		156704, -- Slam
		157592, -- Rippling Smash
		-9702, -- Rune of Crushing Earth
		157060, -- Rune of Grasping Earth
		"custom_off_hands_marker",
		157054, -- Thundering Blows
		156861, -- Frenzy
		"berserk",
	}, {
		[173917] = "mythic",
		[156766] = "general"
	}
end

local function updateTanks(self)
	if self:GetOption("custom_off_hands_marker") then
		local _, _, _, myMapId = UnitPosition("player")
		for unit in self:IterateGroup() do
			local _, _, _, tarMapId = UnitPosition(unit)
			if tarMapId == myMapId and self:Tank(unit) then
				if not tank1Skull then
					tank1Skull = UnitGUID(unit)
				else
					tank2Cross = UnitGUID(unit)
					break
				end
			end
		end
	end
end

function mod:OnBossEnable()
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
	self:Log("SPELL_AURA_APPLIED", "WarpedArmor", 156766)
	self:Log("SPELL_AURA_APPLIED_DOSE", "WarpedArmor", 156766)
	self:Log("SPELL_CAST_SUCCESS", "StoneBreath", 156852)
	self:Log("SPELL_CAST_START", "Slam", 156704)
	self:Log("SPELL_CAST_START", "RipplingSmash", 157592)
	self:Log("SPELL_CAST_START", "GraspingEarth", 157060)
	self:Log("SPELL_CAST_START", "ThunderingBlows", 157054)
	self:Log("SPELL_AURA_REMOVED", "ThunderingBlowsOver", 157054)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 156861)
	-- Mythic
	self:Log("SPELL_CAST_SUCCESS", "TremblingEarth", 173917)
	self:Log("SPELL_CAST_START", "CallOfTheMountain", 158217)
	self:Log("SPELL_CAST_SUCCESS", "CallOfTheMountainBar", 158217)

	updateTanks(self) -- Backup for disconnecting mid-combat
end

function mod:OnEngage()
	breathCount = 1
	callOfTheMountainCount = 1
	tank1Skull, tank2Cross = nil, nil
	self:CDBar(156852, 9, CL.count:format(self:SpellName(156852), breathCount)) -- Stone Breath
	self:CDBar(156766, 14) -- Warped Armor
	--self:CDBar(157592, 23) -- Rippling Smash -- Varies between 23 and 38 seconds...
	--self:CDBar(156704, 17) -- Slam -- Varies between 15 and 30 seconds...
	self:CDBar(157060, 50) -- Grasping Earth
	if self:Mythic() then
		self:CDBar(173917, 82) -- Trembling Earth
	end
	self:Berserk(540)
	self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1")

	updateTanks(self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- Mythic

function mod:TremblingEarth(args)
	callOfTheMountainCount = 1
	self:Message(args.spellId, "Attention")
	self:CDBar(156852, 61, CL.count:format(self:SpellName(156852), breathCount)) -- Stone Breath
	self:CDBar(157592, 72) -- Rippling Smash
	self:CDBar(173917, 180) -- Trembling Earth
	self:Bar(-9706, 30, CL.count:format(self:SpellName(-9706), callOfTheMountainCount)) -- Call of the Mountain
end

function mod:CallOfTheMountain(args)
	self:Message(-9706, "Important", nil, CL.casting:format(CL.count:format(self:SpellName(-9706), callOfTheMountainCount)))
	callOfTheMountainCount = callOfTheMountainCount + 1
end

function mod:CallOfTheMountainBar(args)
	if callOfTheMountainCount < 4 then
		self:Bar(-9706, 11.5, CL.count:format(self:SpellName(-9706), callOfTheMountainCount))
	end
end

-- General

function mod:UNIT_HEALTH_FREQUENT(unit)
	local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
	if hp < 35 then
		self:UnregisterUnitEvent("UNIT_HEALTH_FREQUENT", unit)
		self:Message(156861, "Neutral", "Info", CL.soon:format(self:SpellName(156861))) -- Frenzy
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, _, _, spellId)
	if spellId == 156980 then -- Rune of Crushing Earth
		self:Message(-9702, "Attention")
		--self:Bar(spellId, 5, "Clap!")
	end
end

function mod:WarpedArmor(args)
	self:StackMessage(args.spellId, args.destName, args.amount, "Attention", args.amount and "Warning") -- swap at 2 or 3 stacks
	self:CDBar(args.spellId, 14)
end

function mod:StoneBreath(args)
	self:Message(args.spellId, "Urgent", nil, CL.casting:format(CL.count:format(args.spellName, breathCount)))
	breathCount = breathCount + 1
	self:CDBar(args.spellId, 24, CL.count:format(args.spellName, breathCount))
end

function mod:Slam(args)
	self:Message(args.spellId, "Urgent", (self:Tank() or self:Damager() == "MELEE") and "Alarm", CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 24)
end

function mod:RipplingSmash(args)
	self:Message(args.spellId, "Urgent", "Alert")
	self:CDBar(args.spellId, self:Mythic() and 41 or 24) -- 22-29
	-- XXX second cast is always skipped in mythic, it comes off cd during a stone breath->pillars->call combo
	-- next cast happens 72-88s after pillars, so what happened to the third cast? sigh.
end

do
	function mod:UNIT_TARGET(_, firedUnit)
		local unit = firedUnit and firedUnit.."target" or "mouseover"
		local guid = UnitGUID(unit)
		if not handsMarks[guid] and self:MobId(guid) == 77893 then -- Grasping Earth
			local unitTarget = unit.."target"
			local tarGuid = UnitGUID(unitTarget)
			if tarGuid then
				handsMarks[guid] = true
				if tarGuid == tank1Skull then
					SetRaidTarget(unit, 8)
				elseif tarGuid == tank2Cross then
					SetRaidTarget(unit, 7)
				end
			end
		end
	end

	function mod:GraspingEarth(args)
		self:Message(args.spellId, "Positive", "Info")
		self:CDBar(args.spellId, 112) -- 112-114
		self:CDBar(157054, 13) -- Thundering Blows

		self:StopBar(156766) -- Warped Armor
		self:StopBar(156704) -- Slam
		self:StopBar(157592) -- Rippling Smash

		self:CDBar(156852, 31, CL.count:format(self:SpellName(156852), breathCount)) -- Stone Breath

		if self:GetOption("custom_off_hands_marker") then
			wipe(handsMarks)
			self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "UNIT_TARGET")
			self:RegisterEvent("UNIT_TARGET")
		end
	end

	function mod:ThunderingBlowsOver()
		if self:GetOption("custom_off_hands_marker") then
			self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
			self:UnregisterEvent("UNIT_TARGET")
		end
	end
end

function mod:ThunderingBlows(args)
	self:Message(args.spellId, "Important", nil, CL.casting:format(args.spellName))
	self:Bar(args.spellId, 7, CL.cast:format(args.spellName))
end

function mod:Frenzy(args)
	self:Message(args.spellId, "Important", "Alarm")
end

