local ACF = ACF
local Classes = ACF.Classes

local MODEL = "models/acf/core/s_fuel.mdl"

local function AddSizeSlider(Menu, Context, Label, Field)
	local Slider = Menu:AddSlider(Label, 6, 120, 0)

	function Slider:OnValueChanged(Value)
		Value = math.Round(Value)

		self:SetValue(Value)
		Context:Set(Field, Value)

		if Menu.ComponentPreview then
			Menu.ComponentPreview:SetModelScale(Vector(
				Context:Get("OxygenSizeX") or 35,
				Context:Get("OxygenSizeY") or 35,
				Context:Get("OxygenSizeZ") or 35
			))
		end
	end

	Slider:SetValue(Context:Get(Field) or 35)
end

function ACF.CreateOxygenTankMenu(_, Menu, Context)
	AddSizeSlider(Menu, Context, "Length (in)", "OxygenSizeX")
	AddSizeSlider(Menu, Context, "Width (in)", "OxygenSizeY")
	AddSizeSlider(Menu, Context, "Height (in)", "OxygenSizeZ")

	Menu:AddLabel("Maximum size is 70 in per dimension normally, or 120 in when linked to crew on a Naval Vehicle baseplate. Tanks larger than 70 in increase explosion strength, capped at about 1.7x.")

	if Menu.ComponentPreview then
		Menu.ComponentPreview:UpdateModel(MODEL, "models/props_canal/metalcrate001d")
		Menu.ComponentPreview:SetModelScale(Vector(
			Context:Get("OxygenSizeX") or 35,
			Context:Get("OxygenSizeY") or 35,
			Context:Get("OxygenSizeZ") or 35
		))
	end
end

Classes.DefineClass("ACF.Components.OxygenTank", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Oxygen Tank"
	CLASS.Description = "Provides linked crew with a finite oxygen supply underwater. Explodes when damaged by ACF."
	CLASS.Model       = MODEL
	CLASS.Material    = "models/props_canal/metalcrate001d"
	CLASS.Entity      = "acf_o2tank"
	CLASS.CreateMenu  = ACF.CreateOxygenTankMenu
end)
