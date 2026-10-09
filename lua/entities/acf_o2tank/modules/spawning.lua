local ACF = ACF
local Classes = ACF.Classes
local WireLib = WireLib

local MODEL = "models/acf/core/s_fuel.mdl"
local MATERIAL = "models/props_canal/metalcrate001d"
local STANDARD_MAX_SIZE = 70
local NAVAL_MAX_SIZE = 120
local MAX_CREW_SECONDS = 600
local STANDARD_MAX_CUBE_VOLUME = STANDARD_MAX_SIZE ^ 3
local NAVAL_BASEPLATE = Classes.GetTypeByName("ACF.Baseplates.NavalVehicle")

local function GetBoxShape()
	local Shape = Classes.GetTypeByName("ACF.ContainerShapes.Box")

	if not Shape or not Shape.ShapeCalculation then
		error("ACF oxygen tanks require the ACF container box shape.")
	end

	return Shape
end

function ENT:ACF_PreSpawn()
	local Shape = GetBoxShape()

	self.ACF = { Model = Shape.Model or MODEL }
	self:SetScaledModel(self.ACF.Model)
	self:SetMaterial(MATERIAL)
end

function ENT:ACF_OnSpawn()
	self.Crews = {}
	self.CrewsByType = {}
	self.OxygenCapacity = 0
	self.OxygenAmount = nil

	duplicator.ClearEntityModifier(self, "mass")
end

function ENT:GetMaximumOxygenTankSize()
	for Crew in pairs(self.Crews or {}) do
		if not IsValid(Crew) then continue end

		local Baseplate = ACF.GetEntityBaseplate(Crew)

		if not IsValid(Baseplate) then continue end

		local Type = Baseplate:ACF_GetUserVar("BaseplateType")

		if Type and Type:GetType() == NAVAL_BASEPLATE then
			return NAVAL_MAX_SIZE
		end
	end

	return STANDARD_MAX_SIZE
end

function ENT:GetOxygenTankCapacity(Size)
	local Volume = Size.x * Size.y * Size.z

	return MAX_CREW_SECONDS * Volume / STANDARD_MAX_CUBE_VOLUME
end

function ENT:ACF_PostUpdateEntityData()
	local Shape = self:ACF_GetUserVar("Shape") or GetBoxShape()
	local MaximumSize = self:GetMaximumOxygenTankSize()
	local Size = Vector(
		math.Clamp(ACF.CheckNumber(self:ACF_GetUserVar("OxygenSizeX"), 35), 6, MaximumSize),
		math.Clamp(ACF.CheckNumber(self:ACF_GetUserVar("OxygenSizeY"), 35), 6, MaximumSize),
		math.Clamp(ACF.CheckNumber(self:ACF_GetUserVar("OxygenSizeZ"), 35), 6, MaximumSize)
	)
	local Wall = ACF.ContainerArmor * ACF.MmToInch
	local _, SurfaceArea = Shape.ShapeCalculation(Size, Wall)
	local Capacity = self:GetOxygenTankCapacity(Size)
	local Percentage = self.OxygenCapacity and self.OxygenCapacity > 0
		and math.Clamp((self.OxygenAmount or 0) / self.OxygenCapacity, 0, 1) or 1

	self.ACF = self.ACF or {}
	self.ACF.Model = Shape.Model or MODEL
	self:SetScaledModel(self.ACF.Model)
	self:SetSize(Size)
	self:SetMaterial(MATERIAL)
	self:ACF_SetEntityName("ACF Oxygen Tank")

	self.OxygenSize = Size
	self.OxygenCapacity = Capacity
	self.OxygenAmount = Capacity * Percentage
	self.EmptyMass = (SurfaceArea * Wall) * ACF.InchToCmCu * ACF.SteelDensity

	ACF.Contraption.SetMass(self, self.EmptyMass)
	self:UpdateGForceBonus()

	if self.UpdateOverlay then
		self:UpdateOverlay()
	end

	self:UpdateOxygenOutputs()
end

function ENT:RefreshOxygenTank()
	if not self.OxygenSize then return end

	self:ACF_PostUpdateEntityData()
end

function ENT:OnResized(Size)
	local Shape = self:ACF_GetUserVar("Shape") or GetBoxShape()
	local Wall = ACF.ContainerArmor * ACF.MmToInch
	local _, SurfaceArea = Shape.ShapeCalculation(Size, Wall)

	self.EmptyMass = (SurfaceArea * Wall) * ACF.InchToCmCu * ACF.SteelDensity
	ACF.Contraption.SetMass(self, self.EmptyMass)
end

function ENT:ConsumeOxygen(Amount)
	if self.Disabled or self.Exploding or self.OxygenAmount <= 0 then return 0 end

	local Consumed = math.min(math.max(Amount, 0), self.OxygenAmount)

	self.OxygenAmount = self.OxygenAmount - Consumed
	self:UpdateOxygenOutputs()

	return Consumed
end

function ENT:GetPilotGForceBonus()
	local Size = self.OxygenSize

	if not Size then return 0 end

	return math.min(math.max(Size.x, Size.y, Size.z) / STANDARD_MAX_SIZE * 2, 2)
end

function ENT:UpdateGForceBonus()
	self.PilotGForceBonus = self:GetPilotGForceBonus()

	for Crew in pairs(self.Crews or {}) do
		if not IsValid(Crew) or not Crew.UpdateOxygenTankGForceBonus then continue end

		Crew:UpdateOxygenTankGForceBonus()
	end
end

function ENT:UpdateOxygenOutputs()
	if not WireLib then return end

	WireLib.TriggerOutput(self, "Oxygen", self.OxygenAmount or 0)
	WireLib.TriggerOutput(self, "Capacity", self.OxygenCapacity or 0)
	WireLib.TriggerOutput(self, "Crews", table.Count(self.Crews or {}))
end

function ENT:ACF_UpdateOverlayState(State)
	local Oxygen = self.OxygenAmount or 0
	local Capacity = self.OxygenCapacity or 0
	local Crews = table.Count(self.Crews or {})
	local Size = self.OxygenSize or Vector()

	State:AddNumber("Length", Size.x, " in")
	State:AddNumber("Width", Size.y, " in")
	State:AddNumber("Height", Size.z, " in")
	State:AddProgressBar("Oxygen supply", Oxygen, Capacity, " crew-seconds")
	State:AddNumber("Linked crew", Crews)
	State:AddNumber("Estimated duration", Crews > 0 and Oxygen / Crews or 0, " seconds")
end

function ENT:OnRemove()
	local Crews = self.Crews

	if Crews then
		for Crew in pairs(Crews) do
			if IsValid(Crew) and Crew.Unlink then
				Crew:Unlink(self)
			end
		end
	end

	if WireLib then
		WireLib.Remove(self)
	end
end

ACF.RegisterLinkSource("acf_o2tank", "Crews")
