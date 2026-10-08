local ACF = ACF
local Notify = ACF.Utilities.Notify
local NavalBaseplateType = ACF.Classes.GetTypeByName("ACF.Baseplates.NavalVehicle")
local MAX_NAVAL_BASEPLATE_MASS = 110000
local WEIGHT_LIMIT_REASON = "Naval baseplate overweight"
local WEIGHT_LIMIT_MESSAGE = "This naval baseplate exceeds its 110,000 kg contraption weight limit."

local function GetBaseplateType(Baseplate)
	local Type = Baseplate:ACF_GetUserVar("BaseplateType")

	return Type and Type:GetType()
end

local function DisableContraption(Baseplate)
	local Contraption = Baseplate:CFW_GetContraption()
	local Entities = Contraption and Contraption.ents

	if not Entities then
		Entities = { [Baseplate] = true }
	end

	for Entity in pairs(Entities) do
		if not IsValid(Entity) or not Entity.IsACFEntity then continue end

		local Disabled = Entity.Disabled

		if Disabled and Disabled.Reason == WEIGHT_LIMIT_REASON then continue end

		ACF.DisableEntity(Entity, WEIGHT_LIMIT_REASON, WEIGHT_LIMIT_MESSAGE)
	end
end

local function EnableContraption(Baseplate)
	local Contraption = Baseplate:CFW_GetContraption()
	local Entities = Contraption and Contraption.ents

	if not Entities then
		Entities = { [Baseplate] = true }
	end

	for Entity in pairs(Entities) do
		if not IsValid(Entity) then continue end

		local Disabled = Entity.Disabled

		if not Disabled or Disabled.Reason ~= WEIGHT_LIMIT_REASON then continue end

		Entity.Disabled = nil

		if ACF.CheckLegal(Entity) then
			if Entity.Enable then Entity:Enable() end
			if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end
		end
	end
end

function ENT:UpdateWeightLimit()
	local IsNaval = GetBaseplateType(self) == NavalBaseplateType
	local Contraption = self:CFW_GetContraption()
	local Mass = Contraption and Contraption.totalMass

	if not isnumber(Mass) then
		local Phys = self:GetPhysicsObject()

		if not IsValid(Phys) then return end

		Mass = Phys:GetMass()
	end

	local WasOverweight = self.NavalBaseplateOverweight
	local IsOverweight = IsNaval and Mass > MAX_NAVAL_BASEPLATE_MASS

	self.NavalBaseplateOverweight = IsOverweight

	if not IsOverweight then
		self.NavalBaseplateOverweightNotified = nil

		if WasOverweight then EnableContraption(self) end

		return
	end

	if not self.NavalBaseplateOverweightNotified then
		local Owner = self:CPPIGetOwner()

		if IsValid(Owner) then
			self.NavalBaseplateOverweightNotified = true

			local Message = string.format(
				"Contraption weight: %.0f kg. Limit: %.0f kg. ACF components have been disabled until the weight is reduced.",
				Mass,
				MAX_NAVAL_BASEPLATE_MASS
			)

			Notify.WarningToPlayer(Owner, WEIGHT_LIMIT_REASON, Message)
		end
	end

	DisableContraption(self)
end

hook.Add("ACF_OnCheckLegal", "ACF_NavalBaseplateWeightLimit", function(Entity)
	local Baseplate = Entity:GetClass() == "acf_baseplate" and Entity or ACF.GetEntityBaseplate(Entity)

	if not IsValid(Baseplate) or not Baseplate.NavalBaseplateOverweight then return end
	if GetBaseplateType(Baseplate) ~= NavalBaseplateType then return end

	return false, WEIGHT_LIMIT_REASON, WEIGHT_LIMIT_MESSAGE
end)
