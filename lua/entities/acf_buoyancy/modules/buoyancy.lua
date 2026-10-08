local ACF = ACF
local Classes = ACF.Classes
local Notify = ACF.Utilities.Notify
local NAVAL_BASEPLATE = Classes.GetTypeByName("ACF.Baseplates.NavalVehicle")
local BUOYANCY_UPDATE_INTERVAL = 0.25

local function GetNavalBaseplate(Entity)
	local Baseplate = ACF.GetEntityBaseplate(Entity)

	if not IsValid(Baseplate) then return end

	local BaseplateType = Baseplate:ACF_GetUserVar("BaseplateType")

	if BaseplateType and BaseplateType:GetType() == NAVAL_BASEPLATE then
		return Baseplate
	end
end

function ENT:UpdateBuoyancyRatio()
	local Phys = self:GetPhysicsObject()

	if not IsValid(Phys) then return end

	local Percent = math.Clamp(self.BuoyancyPercent or 0, 0, 100)
	local ACFData = self.ACF
	local HealthRatio = ACFData and ACFData.MaxHealth and ACFData.MaxHealth > 0
		and math.Clamp((ACFData.Health or 0) / ACFData.MaxHealth, 0, 1) or 1
	local Ratio = Percent / 60 * HealthRatio

	Phys:SetBuoyancyRatio(Ratio)
end

function ENT:Think()
	local Baseplate = ACF.GetEntityBaseplate(self)
	local IsNaval = IsValid(Baseplate) and GetNavalBaseplate(self) ~= nil

	if IsValid(Baseplate) and not IsNaval then
		local Owner = self:CPPIGetOwner()

		if IsValid(Owner) then
			Notify.WarningToPlayer(Owner, "Buoyancy compartment removed",
				"Naval buoyancy compartments can only be used on Naval Vehicle baseplates.")
		end

		self:Remove()
		return false
	end

	if IsNaval then
		self:UpdateBuoyancyRatio()
	else
		local Phys = self:GetPhysicsObject()

		if IsValid(Phys) then
			Phys:SetBuoyancyRatio(0)
		end
	end

	self:NextThink(CurTime() + BUOYANCY_UPDATE_INTERVAL)

	return true
end
