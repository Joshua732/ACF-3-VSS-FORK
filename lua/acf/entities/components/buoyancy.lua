local ACF     = ACF
local Classes = ACF.Classes

local MODEL = "models/acf/core/s_fuel.mdl"

local function AddSizeSlider(Menu, Context, Label, Field, Min, Max)
	local Slider = Menu:AddSlider(Label, Min, Max)

	function Slider:OnValueChanged(Value)
		Value = math.Round(Value)

		self:SetValue(Value)
		Context:Set(Field, Value)

		if Menu.ComponentPreview then
			Menu.ComponentPreview:SetModelScale(Vector(
				Context:Get("BuoyancySizeX") or 120,
				Context:Get("BuoyancySizeY") or 60,
				Context:Get("BuoyancySizeZ") or 36
			))
		end
	end

	Slider:SetValue(Context:Get(Field))
end

function ACF.CreateBuoyancyMenu(_, Menu, Context)
	AddSizeSlider(Menu, Context, "Length (in)", "BuoyancySizeX", 6, 1000)
	AddSizeSlider(Menu, Context, "Width (in)", "BuoyancySizeY", 6, 1000)
	AddSizeSlider(Menu, Context, "Height (in)", "BuoyancySizeZ", 6, 120)

	local Compartments = Menu:AddSlider("Compartments", 0, 20, 0)

	function Compartments:OnValueChanged(Value)
		Value = math.Round(Value)

		self:SetValue(Value)
		Context:Set("CompartmentCount", Value)
	end

	Compartments:SetValue(Context:Get("CompartmentCount") or 0)

	local Buoyancy = Menu:AddSlider("Buoyancy (%)", 0, 100, 0)

	function Buoyancy:OnValueChanged(Value)
		Value = math.Round(Value)

		self:SetValue(Value)
		Context:Set("BuoyancyPercent", Value)
	end

	Buoyancy:SetValue(Context:Get("BuoyancyPercent") or 100)

	Menu:AddLabel("Wire input Buoyancy (%) overrides the menu setting from 0 to 100.")

	Menu:AddLabel("Naval Vehicle baseplates only. Maximum 2 per player.")

	if Menu.ComponentPreview then
		Menu.ComponentPreview:UpdateModel(MODEL, "models/props_canal/metalcrate001d")
		Menu.ComponentPreview:SetModelScale(Vector(
			Context:Get("BuoyancySizeX") or 120,
			Context:Get("BuoyancySizeY") or 60,
			Context:Get("BuoyancySizeZ") or 36
		))
	end
end

Classes.DefineClass("ACF.Components.NavalBuoyancy", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Naval Buoyancy Compartment"
	CLASS.Description = "A scalable, damageable flotation compartment for Naval Vehicle baseplates."
	CLASS.Model       = MODEL
	CLASS.Material    = "models/props_canal/metalcrate001d"
	CLASS.Entity      = "acf_buoyancy"
	CLASS.CreateMenu  = ACF.CreateBuoyancyMenu
end)
