local ACF = ACF
local Classes = ACF.Classes
local WireLib = WireLib

local MODEL = "models/acf/core/s_fuel.mdl"
local MATERIAL = "models/props_canal/metalcrate001d"
local MAX_SIZE = 70
local MAX_CREW_SECONDS = 600
local MAX_CUBE_VOLUME = MAX_SIZE ^ 3

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

function ENT:ACF_PostUpdateEntityData()
	local Shape = self:ACF_GetUserVar("Shape") or GetBoxShape()
	local Size = Vector(
		math.Clamp(ACF.CheckNumber(self:ACF_GetUserVar("OxygenSizeX"), 35), 6, MAX_SIZE),
		math.Clamp(ACF.CheckNumber(self:ACF_GetUserVar("OxygenSizeY"), 35), 6, MAX_SIZE),
		math.Clamp(ACF.CheckNumber(self:ACF_GetUserVar("OxygenSizeZ"), 35), 6, MAX_SIZE)
	)
	local Wall = ACF.ContainerArmor * ACF.MmToInch
	local _, SurfaceArea = Shape.ShapeCalculation(Size, Wall)
	local Volume = Size.x * Size.y * Size.z
	local Capacity = MAX_CREW_SECONDS * math.Clamp(Volume / MAX_CUBE_VOLUME, 0, 1)

	self.ACF = self.ACF or {}
	self.ACF.Model = Shape.Model or MODEL
	self:SetScaledModel(self.ACF.Model)
	self:SetSize(Size)
	self:SetMaterial(MATERIAL)
	self:ACF_SetEntityName("ACF Oxygen Tank")

	self.OxygenSize = Size
	self.OxygenCapacity = Capacity
	self.OxygenAmount = self.OxygenAmount == nil and Capacity or math.min(self.OxygenAmount, Capacity)
	self.EmptyMass = (SurfaceArea * Wall) * ACF.InchToCmCu * ACF.SteelDensity

	ACF.Contraption.SetMass(self, self.EmptyMass)

	if self.UpdateOverlay then
		self:UpdateOverlay()
	end

	self:UpdateOxygenOutputs()
end

function ENT:OnResized(Size)
	local Shape = self:ACF_GetUserVar("Shape") or GetBoxShape()
	local Wall = ACF.ContainerArmor * ACF.MmToInch
	local _, SurfaceArea = Shape.ShapeCalculation(Size, Wall)

	self.EmptyMass = (SurfaceArea * Wall) * ACF.InchToCmCu * ACF.SteelDensity
	ACF.Contraption.SetMass(self, self.EmptyMass)
end

function ENT:ConsumeOxygen(Amount)
	if self.Disabled or self.Exploding or self.OxygenAmount <= 0 then return false end
	if self.OxygenAmount < Amount then
		self.OxygenAmount = 0
		self:UpdateOxygenOutputs()

		return false
	end

	self.OxygenAmount = self.OxygenAmount - Amount
	self:UpdateOxygenOutputs()

	return true
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
