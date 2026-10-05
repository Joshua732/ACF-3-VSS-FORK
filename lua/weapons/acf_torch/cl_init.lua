local ACF             = ACF
local RT              = GetRenderTarget("GModToolgunScreen", 256, 256)
local ToolGunMaterial = Material("models/weapons/v_toolgun/screen")
local Texture         = surface.GetTextureID("models/props_combine/combine_interface_disp")
local LogoMaterial    = Material("vssicon/vsslogo.jpg", "noclamp smooth ignorez")
local Center          = TEXT_ALIGN_CENTER


include("shared.lua")

surface.CreateFont("torchfont", {
	size = 40,
	weight = 1000,
	antialias = true,
	additive = false,
	font = "arial"
})

surface.CreateFont("torchsmall", {
	size = 19,
	weight = 1000,
	antialias = true,
	additive = false,
	font = "arial"
})

surface.CreateFont("torchvalue", {
	size = 29,
	weight = 1000,
	antialias = true,
	additive = false,
	font = "arial"
})

surface.CreateFont("torchaction", {
	size = 31,
	weight = 1000,
	antialias = true,
	additive = false,
	font = "arial"
})

killicon.Add(
	"acf_torch",
	"HUD/killicons/acf_torch",
	ACF.KillIconColor
)

SWEP.WepSelectIcon = surface.GetTextureID(
	"vgui/acf_torch_wepselect"
)

if not LogoMaterial:IsError() then
	LogoMaterial:SetInt("$ignorez", 1)
end

local function DrawSpinner(x, y, radius, color)
	local Time = CurTime()

	for I = 1, 16 do
		local Angle = math.rad(
			((I - 1) / 16) * 360 +
			Time * 240
		)

		local Alpha = 25 + I * 10

		local X1 = x + math.cos(Angle) * radius
		local Y1 = y + math.sin(Angle) * radius

		local X2 = x + math.cos(Angle) * (radius - 5)
		local Y2 = y + math.sin(Angle) * (radius - 5)

		surface.SetDrawColor(
			color.r,
			color.g,
			color.b,
			math.min(Alpha, 220)
		)

		surface.DrawLine(
			X1,
			Y1,
			X2,
			Y2
		)
	end
end

local function DrawBar(x, y, width, height, ratio, fillColor, alpha)
	ratio = math.Clamp(ratio or 0, 0, 1)

	draw.RoundedBox(
		5,
		x,
		y,
		width,
		height,
		Color(200, 200, 200, alpha)
	)

	if ratio > 0 then
		draw.RoundedBox(
			5,
			x + 5,
			y + 5,
			math.max((width - 10) * ratio, 1),
			height - 10,
			Color(
				fillColor.r,
				fillColor.g,
				fillColor.b,
				alpha
			)
		)
	end
end

function SWEP:PostDrawViewModel()
	local Health = math.Round(
		self:GetNWFloat("HP", 0),
		1
	)

	local MaxHealth = math.Round(
		self:GetNWFloat("MaxHP", 0),
		1
	)

	local Armor = math.Round(
		self:GetNWFloat("Armour", 0),
		1
	)

	local MaxArmor = math.Round(
		self:GetNWFloat("MaxArmour", 0),
		1
	)

	local ActionMode = self:GetActionMode()

	local Flicker = math.random(220, 240)

	local TextColor = Color(
		224,
		224,
		255,
		Flicker
	)

	local OutColor = Color(
		0,
		0,
		0,
		Flicker
	)

	local Text = language.GetPhrase(
		"acf.torch.stats"
	)

	local Title = language.GetPhrase(
		"acf.torch.stats_title"
	)

	local ArmorText = Text:format(
		Armor,
		MaxArmor
	)

	local HealthText = Text:format(
		Health,
		MaxHealth
	)

	local ArmorRatio = 0
	local HealthRatio = 0

	if MaxArmor > 0 then
		ArmorRatio = math.Clamp(
			Armor / MaxArmor,
			0,
			1
		)
	end

	if MaxHealth > 0 then
		HealthRatio = math.Clamp(
			Health / MaxHealth,
			0,
			1
		)
	end

	ToolGunMaterial:SetTexture(
		"$basetexture",
		RT
	)

	local OldRT = render.GetRenderTarget()

	render.SetRenderTarget(RT)
	render.SetViewPort(
		0,
		0,
		256,
		256
	)

	render.Clear(
		0,
		0,
		0,
		255
	)

	cam.Start2D()

		surface.SetTexture(Texture)
		surface.SetDrawColor(
			255,
			255,
			255,
			Flicker
		)

		surface.DrawTexturedRect(
			0,
			0,
			256,
			256
		)

		surface.SetFont("torchfont")

		local TitleWidth = surface.GetTextSize(
			Title
		)

		local LogoSize = 42
		local LogoGap = 8

		local GroupWidth =
			TitleWidth +
			LogoGap +
			LogoSize

		local GroupStartX =
			(256 - GroupWidth) * 0.5

		local TitleX =
			GroupStartX +
			TitleWidth * 0.5

		local LogoX =
			GroupStartX +
			TitleWidth +
			LogoGap

		local LogoY =
			48 -
			LogoSize * 0.5

		draw.SimpleTextOutlined(
			Title,
			"torchfont",
			TitleX,
			48,
			TextColor,
			Center,
			Center,
			4,
			OutColor
		)

		if not LogoMaterial:IsError() then
			surface.SetMaterial(LogoMaterial)

			surface.SetDrawColor(
				255,
				255,
				255,
				Flicker
			)

			surface.DrawTexturedRect(
				LogoX,
				LogoY,
				LogoSize,
				LogoSize
			)
		end

		if ActionMode == 1 then
			local ActionColor = Color(
				80,
				200,
				255,
				Flicker
			)

			draw.SimpleTextOutlined(
				"REPAIRING",
				"torchaction",
				128,
				82,
				ActionColor,
				Center,
				Center,
				4,
				OutColor
			)

			DrawSpinner(
				128,
				111,
				14,
				ActionColor
			)

			local Eta

			if MaxHealth > Health and MaxHealth > 0 then
				local RepairRate

				if MaxArmor > 0 then
					RepairRate =
						600 / MaxArmor
				else
					RepairRate = 20
				end

				if RepairRate > 0 then
					Eta =
						(MaxHealth - Health) /
						RepairRate
				end
			end

			local EtaText = "CALCULATING"

			if Eta then
				EtaText = string.format(
					"%.1f SEC",
					math.max(Eta, 0)
				)
			end

			draw.SimpleTextOutlined(
				EtaText,
				"torchvalue",
				128,
				135,
				ActionColor,
				Center,
				Center,
				4,
				OutColor
			)

			draw.RoundedBox(
				6,
				8,
				154,
				240,
				42,
				Color(0, 0, 0, 120)
			)

			draw.SimpleTextOutlined(
				"ARMOR",
				"torchsmall",
				18,
				164,
				TextColor,
				TEXT_ALIGN_LEFT,
				TEXT_ALIGN_CENTER,
				2,
				OutColor
			)

			draw.SimpleTextOutlined(
				string.format(
					"%.1f / %.1f",
					Armor,
					MaxArmor
				),
				"torchvalue",
				238,
				176,
				Color(100, 180, 255, Flicker),
				TEXT_ALIGN_RIGHT,
				TEXT_ALIGN_CENTER,
				3,
				OutColor
			)

			DrawBar(
				10,
				202,
				236,
				20,
				ArmorRatio,
				Color(0, 80, 255),
				Flicker
			)

			draw.RoundedBox(
				6,
				8,
				226,
				240,
				30,
				Color(0, 0, 0, 120)
			)

			draw.SimpleTextOutlined(
				"HP",
				"torchsmall",
				18,
				241,
				TextColor,
				TEXT_ALIGN_LEFT,
				TEXT_ALIGN_CENTER,
				2,
				OutColor
			)

			draw.SimpleTextOutlined(
				string.format(
					"%.1f / %.1f",
					Health,
					MaxHealth
				),
				"torchvalue",
				238,
				241,
				Color(255, 100, 100, Flicker),
				TEXT_ALIGN_RIGHT,
				TEXT_ALIGN_CENTER,
				3,
				OutColor
			)

		elseif ActionMode == 2 then
			local ActionColor = Color(
				255,
				110,
				70,
				Flicker
			)

			draw.SimpleTextOutlined(
				"CUTTING",
				"torchaction",
				128,
				82,
				ActionColor,
				Center,
				Center,
				4,
				OutColor
			)

			DrawSpinner(
				128,
				111,
				14,
				ActionColor
			)

			draw.SimpleTextOutlined(
				"ARMOR",
				"torchsmall",
				128,
				137,
				TextColor,
				Center,
				Center,
				2,
				OutColor
			)

			draw.SimpleTextOutlined(
				string.format(
					"%.1f / %.1f",
					Armor,
					MaxArmor
				),
				"torchvalue",
				128,
				160,
				Color(100, 180, 255, Flicker),
				Center,
				Center,
				3,
				OutColor
			)

			DrawBar(
				10,
				174,
				236,
				22,
				ArmorRatio,
				Color(0, 80, 255),
				Flicker
			)

			draw.SimpleTextOutlined(
				"HEALTH",
				"torchsmall",
				128,
				204,
				TextColor,
				Center,
				Center,
				2,
				OutColor
			)

			draw.SimpleTextOutlined(
				string.format(
					"%.1f / %.1f",
					Health,
					MaxHealth
				),
				"torchvalue",
				128,
				226,
				Color(255, 100, 100, Flicker),
				Center,
				Center,
				3,
				OutColor
			)

			DrawBar(
				10,
				237,
				236,
				14,
				HealthRatio,
				Color(200, 0, 0),
				Flicker
			)

		else
			if MaxHealth > 0 then
				if MaxArmor > 0 then
					DrawBar(
						10,
						83,
						236,
						64,
						ArmorRatio,
						Color(0, 0, 200),
						Flicker
					)

					draw.SimpleTextOutlined(
						"#acf.menu.armor",
						"torchfont",
						128,
						100,
						TextColor,
						Center,
						Center,
						4,
						OutColor
					)

					draw.SimpleTextOutlined(
						ArmorText,
						"torchfont",
						128,
						150,
						TextColor,
						Center,
						Center,
						4,
						OutColor
					)
				end

				DrawBar(
					10,
					183,
					236,
					64,
					HealthRatio,
					Color(200, 0, 0),
					Flicker
				)

				draw.SimpleTextOutlined(
					"#acf.menu.health",
					"torchfont",
					128,
					200,
					TextColor,
					Center,
					Center,
					4,
					OutColor
				)

				draw.SimpleTextOutlined(
					HealthText,
					"torchfont",
					128,
					250,
					TextColor,
					Center,
					Center,
					4,
					OutColor
				)
			else
				draw.SimpleTextOutlined(
					"#acf.torch.no_target",
					"torchfont",
					128,
					140,
					TextColor,
					Center,
					Center,
					4,
					OutColor
				)
			end
		end

	cam.End2D()

	render.SetRenderTarget(OldRT)
end