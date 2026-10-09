DEFINE_BASECLASS("acf_container")

ENT.PrintName     = "ACF Oxygen Tank"
ENT.WireDebugName = "ACF Oxygen Tank"
ENT.PluralName    = "ACF Oxygen Tanks"
ENT.ACF_Limit     = 32

ACF.Entities.AutoRegister(2026100803, function()
	FIELD("ACF.ContainerShapes.Box", "Shape", {
		InstantiateTypeForDefault = "ACF.ContainerShapes.Box",
	})
	MENU_FIELD("Number", "OxygenSizeX", { Min = 6, Max = 70, Default = 35, Decimals = 0 })
	MENU_FIELD("Number", "OxygenSizeY", { Min = 6, Max = 70, Default = 35, Decimals = 0 })
	MENU_FIELD("Number", "OxygenSizeZ", { Min = 6, Max = 70, Default = 35, Decimals = 0 })
end, "Oxygen Tank")

ENT.ACF_StaticWireOutputs = {
	"Oxygen (Remaining oxygen supply in crew-seconds)",
	"Capacity (Total oxygen supply in crew-seconds)",
	"Crews (Number of linked crew members)",
	"Entity (The oxygen tank itself) [ENTITY]",
}
