local ACF = ACF
local Classes = ACF.Classes
local AircraftBaseplateType
local IMPACT_QUIET_TIME = 20
local IMPACT_CHECK_INTERVAL = 10
local ENTRY_GRACE_TIME = 3

local function IsAircraftBaseplate(Baseplate)
	if not IsValid(Baseplate) then return false end

	local Type = Baseplate:ACF_GetUserVar("BaseplateType")

	return Type and Type:GetType() == AircraftBaseplateType
end

ACF.Classes.DefineClass("ACF.Baseplates.Aircraft", "ACF.Baseplates.BaseplateType", function(CLASS, BASE)
	CLASS.Name        = "Aircraft"
	CLASS.Icon        = "icon16/weather_clouds.png"
	CLASS.Description = "A baseplate designed for aircraft."

	MENU_FIELD("Number", "GForceTicks", {Min = 1, Max = 7, Default = 1, Decimals = 0})

	function CLASS.CreateMenu(SubMenu, NestedData, PushData)
		local Opts  = ACF.Classes.GetTypeFieldByName(CLASS, "GForceTicks").Options
		local Ticks = SubMenu:AddSlider("G-Force Sample Rate", Opts.Min, Opts.Max, Opts.Decimals)
		Ticks:SetValue(NestedData.GForceTicks or Opts.Default or 1)
		function Ticks:OnValueChanged(Value)
			NestedData.GForceTicks = math.Round(Value, Opts.Decimals or 0)
			PushData()
		end
	end

	function CLASS:OnInitialize(Entity)
		Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)

		local Now = CurTime()

		Entity.AircraftLastDamageTime = Entity.AircraftLastDamageTime or Now
		Entity.AircraftNextImpactCheck = Entity.AircraftNextImpactCheck or (Now + IMPACT_CHECK_INTERVAL)
		Entity.AircraftImpactExplosionsDisabled = Entity.AircraftImpactExplosionsDisabled or false
		Entity.AircraftEntryGraceStarted = Entity.AircraftEntryGraceStarted or false
		Entity.AircraftEntryGraceUsed = Entity.AircraftEntryGraceUsed or false
	end

	function CLASS:Think(Entity)
		local Now = CurTime()

		if Now < (Entity.AircraftNextImpactCheck or 0) then return end

		Entity.AircraftNextImpactCheck = Now + IMPACT_CHECK_INTERVAL
		Entity.AircraftImpactExplosionsDisabled = Now - (Entity.AircraftLastDamageTime or Now) >= IMPACT_QUIET_TIME
	end

	function CLASS:PhysicsCollide(Entity, Data)
		if Entity.AircraftEntryGraceStarted and not Entity.AircraftEntryGraceUsed then
			Entity.AircraftEntryGraceUsed = true

			if CurTime() <= (Entity.AircraftEntryGraceEnds or 0) then
				return
			end
		end

		if Entity.AircraftImpactExplosionsDisabled then return end

		BASE.BP_PhysicsCollideExplosion(Entity, Data)
	end
end)

AircraftBaseplateType = Classes.GetTypeByName("ACF.Baseplates.Aircraft")

if SERVER then
	hook.Add("PlayerEnteredVehicle", "ACF_AircraftBaseplateEntryGrace", function(_, Vehicle)
		local Baseplate = ACF.GetEntityBaseplate(Vehicle)

		if not IsAircraftBaseplate(Baseplate) or Baseplate.AircraftEntryGraceStarted then return end

		Baseplate.AircraftEntryGraceStarted = true
		Baseplate.AircraftEntryGraceEnds = CurTime() + ENTRY_GRACE_TIME
	end)

	hook.Add("ACF_PostDamageEntity", "ACF_AircraftBaseplateDamageActivity", function(Entity)
		local Baseplate = Entity:GetClass() == "acf_baseplate" and Entity or ACF.GetEntityBaseplate(Entity)

		if not IsAircraftBaseplate(Baseplate) then return end

		local Now = CurTime()

		Baseplate.AircraftLastDamageTime = Now
		Baseplate.AircraftNextImpactCheck = Now + IMPACT_CHECK_INTERVAL
		Baseplate.AircraftImpactExplosionsDisabled = false
	end)
end