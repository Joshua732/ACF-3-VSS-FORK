DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Naval Waterjet"
ENT.WireDebugName  = "ACF Naval Waterjet"
ENT.PluralName     = "ACF Naval Waterjets"
ENT.ACF_Limit      = 4
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegister(2026100801, function()
    MENU_FIELD("Number", "NavalWaterjetSize", {Min = 1, Max = 4, Default = 2, Decimals = 2})
    MENU_FIELD("String", "NavalWaterjetSoundPath", {Default = "ambient/machines/spin_loop.wav"})
    MENU_FIELD("Number", "NavalWaterjetSoundPitch", {Min = 0.1, Max = 2, Default = 1, Decimals = 2})
    MENU_FIELD("Number", "NavalWaterjetSoundVolume", {Min = 0.1, Max = 1, Default = 0.2, Decimals = 2})
end)

ENT.ACF_StaticWireInputs = {
    "Pitch (Horizontal Steer Angle, -1 to 1)",
    "Yaw (Vertical Steer Angle, -1 to 1)",
}