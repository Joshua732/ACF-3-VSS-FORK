local ACF = ACF
local Classes = ACF.Classes
local Clamp = math.Clamp
local Floor = math.floor
local WATER_DENSITY = 1000

local BOX_SHAPE = "ACF.ContainerShapes.Box"

local function GetBoxShape()
	local Shape = Classes.GetTypeByName(BOX_SHAPE)

	if not Shape or not Shape.Model or not Shape.ShapeCalculation then
		error("ACF buoyancy compartments require the ACF container box shape.")
	end

	return Shape
end

local function ReadNumber(Entity, Name, Default, Min, Max, Round)
	local Value = ACF.CheckNumber(Entity:ACF_GetUserVar(Name), Default)

	Value = Clamp(Value, Min, Max)

	if Round then
		Value = Floor(Value + 0.5)
	end

	return Value
end

function ENT:ACF_PreSpawn()
	local Shape = GetBoxShape()

	self.ACF = { Model = Shape.Model }
	self:SetScaledModel(Shape.Model)
	self:SetMaterial("models/props_canal/metalcrate001d")
end

function ENT:ACF_PostUpdateEntityData()
	local Shape = self:ACF_GetUserVar("Shape") or GetBoxShape()
	local Size = Vector(
		ReadNumber(self, "BuoyancySizeX", 120, 6, 1000, true),
		ReadNumber(self, "BuoyancySizeY", 60, 6, 1000, true),
		ReadNumber(self, "BuoyancySizeZ", 36, 6, 120, true)
	)
	local Count = ReadNumber(self, "CompartmentCount", 0, 0, 20, true)
	local Buoyancy = ReadNumber(self, "BuoyancyPercent", 100, 0, 100)
	local Wall = ACF.ContainerArmor * ACF.MmToInch
	local Volume = Shape.ShapeCalculation(Size, Wall)
	self.ACF = self.ACF or {}
	self.ACF.Model = Shape.Model
	self:SetScaledModel(Shape.Model)
	self:SetSize(Size)
	self:SetMaterial("models/props_canal/metalcrate001d")
	self:ACF_SetEntityName("ACF Naval Buoyancy Compartment")

	self.BuoyancySize = Size
	self.CompartmentCount = Count
	self.ConfiguredBuoyancyPercent = Buoyancy
	self.BuoyancyPercent = self.BuoyancyInputActive and self.BuoyancyInputValue or Buoyancy
	self.MaxBuoyancyMass = Volume * (0.0254 ^ 3) * WATER_DENSITY

	ACF.Contraption.SetMass(self, 5000 + Count * 500)

	if self.UpdateOverlay then
		self:UpdateOverlay()
	end
end

function ENT:SetBuoyancyInput(Value)
	self.BuoyancyInputValue = math.Clamp(tonumber(Value) or 0, 0, 100)
	self.BuoyancyInputActive = true
	self.BuoyancyPercent = self.BuoyancyInputValue

	if self.UpdateBuoyancyRatio then
		self:UpdateBuoyancyRatio()
	end

	if self.UpdateOverlay then
		self:UpdateOverlay()
	end
end

function ENT:ACF_UpdateOverlayState(State)
	local Count = self.CompartmentCount or 0
	local ACFData = self.ACF
	local HealthRatio = ACFData and ACFData.MaxHealth and ACFData.MaxHealth > 0
		and math.Clamp((ACFData.Health or 0) / ACFData.MaxHealth, 0, 1) or 1
	local EffectivePercent = (self.BuoyancyPercent or 0) * HealthRatio
	local Capacity = (self.MaxBuoyancyMass or 0) * EffectivePercent / 100
	local Size = self.BuoyancySize or Vector()

	State:AddNumber("Length", Size.x, " in")
	State:AddNumber("Width", Size.y, " in")
	State:AddNumber("Height", Size.z, " in")
	State:AddNumber("Compartments", Count)
	State:AddNumber("Effective buoyancy", math.Round(EffectivePercent, 1), "%")
	State:AddNumber("Lift capacity", math.Round(Capacity / 1000, 2), " tonnes")
	State:AddNumber("Mass", 5 + Count * 0.5, " tonnes")
	State:AddNumber("Hull health", math.Round(HealthRatio * 100, 1), "%")
	State:AddKeyValue("Required baseplate", "Naval Vehicle")
end
