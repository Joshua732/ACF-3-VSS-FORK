DEFINE_BASECLASS("acf_container")

ENT.PrintName     = "ACF Naval Buoyancy Compartment"
ENT.WireDebugName = "ACF Naval Buoyancy Compartment"
ENT.PluralName    = "ACF Naval Buoyancy Compartments"
ENT.ACF_Limit     = 2
ENT.ACF_StaticWireInputs = {
	"Buoyancy (%) (Overrides the menu buoyancy setting; 0 to 100.)",
}

ACF.Entities.AutoRegister(2026100802, function()
	FIELD("ACF.ContainerShapes.Box", "Shape", {
		InstantiateTypeForDefault = "ACF.ContainerShapes.Box",
	})
	MENU_FIELD("Number", "BuoyancySizeX", { Min = 6, Max = 1000, Default = 120, Decimals = 0 })
	MENU_FIELD("Number", "BuoyancySizeY", { Min = 6, Max = 1000, Default = 60, Decimals = 0 })
	MENU_FIELD("Number", "BuoyancySizeZ", { Min = 6, Max = 120, Default = 36, Decimals = 0 })
	MENU_FIELD("Number", "CompartmentCount", { Min = 0, Max = 20, Default = 0, Decimals = 0 })
	MENU_FIELD("Number", "BuoyancyPercent", { Min = 0, Max = 100, Default = 100, Decimals = 0 })
end, "Naval Buoyancy Compartment")
