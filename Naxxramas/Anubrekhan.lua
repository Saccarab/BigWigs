----------------------------------
--      Module Declaration      --
----------------------------------
local mod = BigWigs:NewBoss("Anub'Rekhan", "Naxxramas")
if not mod then return end
mod:RegisterEnableMob(15956)
mod.toggleOptions = {28785, "bosskill"}

------------------------------
--      Are you local?      --
------------------------------

local locustTime = 90
local started = nil

----------------------------
--      Localization      --
----------------------------

local L = mod:NewLocale("enUS", true)
if L then
	L.starttrigger1 = "Just a little taste..."
	L.starttrigger2 = "Yes, run! It makes the blood pump faster!"
	L.starttrigger3 = "There is no way out."
	L.engagewarn = "Anub'Rekhan engaged! Locust Swarm in ~%d sec"

	L.gainendwarn = "Locust Swarm ended!"
	L.gainnextwarn = "Next Locust Swarm in ~85 sec"
	L.gainwarn10sec = "~10 sec until Locust Swarm"
	L.gainincbar = "~Next Locust Swarm"

	L.castwarn = "Incoming Locust Swarm!"
end
L = mod:GetLocale()

------------------------------
--      Initialization      --
------------------------------

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "GainSwarm", 28785, 54021)
	self:Log("SPELL_CAST_START", "Swarm", 28785, 54021)
	self:Death("Win", 15956)

	started = nil
	self:Yell("Engage", L["starttrigger1"], L["starttrigger2"], L["starttrigger3"])
end

function mod:OnEngage()
	if started then return end
	started = true
	locustTime = GetRaidDifficulty() == 1 and 102 or 90
	self:Message(28785, L["engagewarn"]:format(locustTime), "Urgent")
	self:DelayedMessage(28785, locustTime - 10, L["gainwarn10sec"], "Important")
	self:Bar(28785, L["gainincbar"], locustTime, 28785)
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:GainSwarm(unit, spellId, _, _, spellName, _, _, _, dGUID)
	local target = QueryQuestsCompleted and tonumber(dGUID:sub(-12, -9), 16) or tonumber(dGUID:sub(-12, -7), 16)
	if target == 15956 then
		self:DelayedMessage(28785, 20, L["gainendwarn"], "Important")
		self:Bar(28785, spellName, 20, spellId)
		self:DelayedMessage(28785, 75, L["gainwarn10sec"], "Important")
		self:Bar(28785, L["gainincbar"], 85, spellId)
	end
end

function mod:Swarm(_, spellId)
	self:Message(28785, L["castwarn"], "Attention", spellId)
	self:Bar(28785, L["castwarn"], 3, spellId)
end
