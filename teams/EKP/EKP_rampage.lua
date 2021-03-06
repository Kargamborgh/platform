local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib

local tinsert = _G.table.insert

behaviorLib.StartingItems = { "3 Item_HealthPotion", "Item_IronBuckler"}
behaviorLib.LaneItems = {"Item_Steamboots", "Item_Lifetube"}
behaviorLib.MidItems = { "Item_Shield2", "Item_Pierce"}
behaviorLib.LateItems = {"Item_Weapon3", "Item_DaemonicBreastplate"}

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {

  2, 1, 0, 2, 2,
  3, 2, 1, 1, 1,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
function rampage:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilCharge == nil then
    skills.abilCharge = unitSelf:GetAbility(0)
    skills.abilSlow = unitSelf:GetAbility(1)
    skills.abilBash = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--joku
----------------------------------------------

local function advancedThinkUtility(botBrain)				--## HATCHET TOSS
        return 95; --always ridiculously important. Though, this rarly returns true.
end
 
local function advancedThinkExecute(botBrain)
        local unitSelf = core.unitSelf
        local vecSelfPos = unitSelf:GetPosition()
        local vecWellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
        local distToWellSq=Vector3.Distance2DSq(vecSelfPos, vecWellPos)
        local bActionTaken=false

  if core.itemHatchet ~= nil and not core.itemHatchet:IsValid() then
                core.itemHatchet = nil
        end
        --hatchet
        if not bActionTaken and core.unitCreepTarget and core.itemHatchet and core.itemHatchet:CanActivate() and --can activate
          Vector3.Distance2DSq(unitSelf:GetPosition(), core.unitCreepTarget:GetPosition()) <= 600*600 and --in range of hatchet.
          unitSelf:GetBaseDamage()*(1-core.unitCreepTarget:GetPhysicalResistance())>(core.unitCreepTarget:GetHealth()) and --low enough hp, 10 hp marginal for projectile
          string.find(core.unitCreepTarget:GetTypeName(), "Creep") then-- viable creep (this makes it ignore minions etc, some of which aren't hatchetable.)
                bActionTaken=botBrain:OrderItemEntity(core.itemHatchet.object or core.itemHatchet, core.unitCreepTarget.object or core.unitCreepTarget, false)--use hatchet.
        end
       
        return bActionTaken
end
behaviorLib.advancedThink = {}
behaviorLib.advancedThink["Utility"] = advancedThinkUtility
behaviorLib.advancedThink["Execute"] = advancedThinkExecute
behaviorLib.advancedThink["Name"] = "advancedThink"
tinsert(behaviorLib.tBehaviors, behaviorLib.advancedThink)
 


----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none

--  function AttackCreepsExecuteOverride(botBrain)					
--	local unitSelf = core.unitSelf						
--	local currentTarget = core.unitCreepTarget					
--	local nDamageAverage = core.GetFinalAttackDamageAverage(unitSelf)
	
--	if core.itemHatchet then
--		nDamageAverage = nDamageAverage * core.itemHatchet.creepDamageMul
--	end

--	if skills.abilBash:CanActivate() then
--		nDamageAverage = nDamageAverage + 40 + 20*(skills.abilBash:GetLevel())
--	end

--	if currentTarget and core.CanSeeUnit(botBrain, currentTarget) and skills.abilBash:CanActivate() and currentTarget:GetHealth()<nDamageAverage+50 then	
--		local vecTargetPos = currentTarget:GetPosition()
--		local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
--		local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)

--		if currentTarget ~= nil then
--			if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() then
--				--only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
--				core.OrderAttackClamp(botBrain, unitSelf, currentTarget)
--				Echo("Bash Lasthit")
--			else
--				local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
--				core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
--				Echo("Liiku")
--			end
--		end
--	else
--		Echo("en jaksa bashaa")
--		return rampage.AttackCreepsExecuteOld
--	end
--  end
  
--  rampage.AttackCreepsExecuteOld = behaviorLib.AttackCreepsBehavior["Execute"]
--  behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride
--tinsert(behaviorLib.tBehaviors, behaviorLib.BashLasthitOverride)


function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  if EventData.Type == "Ability" and EventData.InflictorName == "Ability_Rampage1" then
    self.charged = CHARGE_STARTED
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Timer" then
    if self.charged == CHARGE_STARTED then
      self.charged = CHARGE_NONE
    end
  elseif EventData.Type == "State" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_WARP
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_NONE
  elseif EventData.Type == "Death" then
    self.charged = CHARGE_NONE
  end
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilBash:IsReady() then
    nUtil = nUtil + 40
  end

  if skills.abilCharge:CanActivate() then
    nUtil = nUtil + 20
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local abilCharge = skills.abilCharge
  local abilUltimate = skills.abilUltimate
  local abilSlow = skills.abilSlow

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return rampage.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then

    if abilUltimate:CanActivate() then
      local nRange = abilUltimate:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
      end
    end

    if abilCharge:CanActivate() then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
    end

    if abilSlow:CanActivate() then
      local nRange = 300
      if nTargetDistanceSq < (nRange * nRange) then
        return core.OrderAbility(botBrain, abilSlow)
      end
    end

  end

  if not bActionTaken then
    return rampage.harassExecuteOld(botBrain)
  end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function ChargeTarget(botBrain, unitSelf, abilCharge)
  local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
  local utility = 0
  local unitTarget = nil
  local nTarget = 0
  for nUID, unit in pairs(tEnemyHeroes) do
    if core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and (not unitTarget or unit:GetHealth() < unitTarget:GetHealth()) then
      unitTarget = unit
      nTarget = nUID
    end
  end
  if unitTarget then
    local damageLevels = {100,140,180,220}
    local chargeDamage = damageLevels[abilCharge:GetLevel()]
    local estimatedHP = unitTarget:GetHealth() - chargeDamage
    if estimatedHP < 200 then
      utility = 20
    end
    if unitTarget:GetManaPercent() < 30 then
      utility = utility + 5
    end
    local level = unitTarget:GetLevel()
    local ownLevel = unitSelf:GetLevel()
    if level < ownLevel then
      utility = utility + 5 * (ownLevel - level)
    else
      utility = utility - 10 * (ownLevel - level)
    end
    local vecTarget = unitTarget:GetPosition()
    for nUID, unit in pairs(tEnemyHeroes) do
      if nUID ~= nTarget and core.CanSeeUnit(botBrain, unit) and Vector3.Distance2DSq(vecTarget, unit:GetPosition()) < (500 * 500) then
        utility = utility - 5
      end
    end
  end
  return unitTarget, utility
end

local function ChargeUtility(botBrain)
  local abilCharge = skills.abilCharge
  local unitSelf = core.unitSelf
  if rampage.charged ~= CHARGE_NONE then
    return 9999
  end
  if not abilCharge:CanActivate() then
    return 0
  end
  local unitTarget, utility = ChargeTarget(botBrain, unitSelf, abilCharge)
  if unitTarget then
    rampage.chargeTarget = unitTarget
    return utility
  end
  return 0
end

local function ChargeExecute(botBrain)
  local bActionTaken = false
  if botBrain.charged ~= CHARGE_NONE then
    return true
  end
  if not rampage.chargeTarget then
    return false
  end
  local abilCharge = skills.abilCharge
  if abilCharge:CanActivate() then
    bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, rampage.chargeTarget)
  end
  return bActionTaken
end

local ChargeBehavior = {}
ChargeBehavior["Utility"] = ChargeUtility
ChargeBehavior["Execute"] = ChargeExecute
ChargeBehavior["Name"] = "Charge like a boss"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)
