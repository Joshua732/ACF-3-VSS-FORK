local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.Fuze.Cluster", "ACF.Missiles.Fuze.Optical", function(CLASS, BASE)
	CLASS.Name = "Cluster"
	CLASS.MinDistance = 500
	CLASS.MaxDistance = 5000
	CLASS.Spread = 55 --sorry if this is wack

	MENU_FIELD("Number", "FuzeDistance", {Default = 0})

	function CLASS:WriteDisplayConfig(State)
		BASE.WriteDisplayConfig(self, State)
		State:AddSubKeyValue("Distance", math.Round(self.Distance * ACF.InchToMeter, 2) .. " m")
	end

	if CLIENT then
		CLASS.Description = "This fuze fires a beam directly ahead and releases bomblets when the beam hits something close-by. Distance in inches." -- or does it????

		function CLASS:AddMenuControls(Base, ToolData, ...)
			BASE.AddMenuControls(self, Base, ToolData, ...)

			local Distance = Base:AddSlider("Fuze Distance", self.MinDistance, self.MaxDistance, 2)
			ACF.MissileMenu.FuzeSlider(Distance, "FuzeDistance")
		end
	else
		local function PrepareBullet(BulletData)
			local Caliber = BulletData.Caliber
			local Projectile = BulletData.ProjMass
			local Rows = math.max(1, math.floor(Projectile / Caliber))

			local Data = table.Copy(BulletData)

			Data.Weapon = "C"
			Data.WeaponType = "C"
			Data.Caliber = Caliber
			Data.ProjMass = Projectile / Rows
			Data.PropMass = 0
			Data.Propellant = 0
			Data.Destiny = "Weapons"
			Data.Bomblets = math.min(Rows, 10)
			return Data
		end

		function CLASS:VerifyData(Weapon)
			BASE.VerifyData(self, Weapon)

			self.FuzeDistance = math.Clamp(self.FuzeDistance or 0, self.MinDistance, self.MaxDistance)
		end

		function CLASS:OnFirst(Entity)
			BASE.OnFirst(self, Entity)

			self.Distance = self.FuzeDistance
		end

		function CLASS:GetDetonate(Missile)
			if not self:IsArmed() then return false end

			local Position = Missile:GetPos()

			local TraceData = {
				start = Position,
				endpos = Position + Missile:GetForward() * self.Distance,
				filter = Missile.Filter or { Missile }
			}

			return ACF.trace(TraceData).Hit
		end

		function CLASS:HandleDetonation(Entity, BulletData)
			local Bullet = PrepareBullet(BulletData)
			local Bomblets = Bullet.Bomblets
			local Velocity = BulletData.Flight
			local Ammo = Entity.RoundData

			Bullet.Crate = BulletData.Crate
			Bullet.Owner = BulletData.Owner
			Bullet.Gun = BulletData.Gun
			Bullet.Pos = BulletData.Pos
			Bullet.Flight = Velocity
			Bullet.Filter = BulletData.Filter

			local Effect = EffectData()
			Effect:SetOrigin(Entity:GetPos())
			Effect:SetNormal(Entity.CurDir)
			Effect:SetScale(math.max(Bomblets ^ 0.33 * 35.37, 1))
			Effect:SetRadius(BulletData.Caliber)

			util.Effect("ACF_Explosion", Effect)

			local Round = Ammo

			if not Round then return end

			for _ = 1, Bomblets do
				local Cone = math.tan(math.rad(self.Spread * ACF.GunInaccuracyScale))
				local Spread = (Entity:GetUp() * math.Rand(-1, 1) + Entity:GetRight() * math.Rand(-1, 1)):GetNormalized()
				local ShootDir = (Velocity:GetNormalized() + Cone * Spread * (math.random() ^ (1 / ACF.GunInaccuracyBias))):GetNormalized()

				Bullet.Flight = ShootDir * Velocity:Length()
--did on notepad like a boss
			local Bomblet = table.Copy(Bullet)
			Bomblet.Caliber = Bullet.Caliber
			Bomblet.ProjMass = Bullet.ProjMass
			Bomblet.PropMass = 0
			Bomblet.FillerMass = Bullet.FillerMass
			Bomblet.AmmoType = BulletData.AmmoType

			local AmmoData = Round:ServerConvert()

			AmmoData.Crate = Bullet.Crate
			AmmoData.Owner = Bullet.Owner
			AmmoData.Gun = Bullet.Gun
			AmmoData.Pos = Bullet.Pos
			AmmoData.Flight = Bullet.Flight
			AmmoData.Filter = Bullet.Filter
			AmmoData.Caliber = Bomblet.Caliber
			AmmoData.ProjMass = Bomblet.ProjMass
			AmmoData.PropMass = 0
			AmmoData.FillerMass = Bomblet.FillerMass 

			ACF.Ballistics.CreateBullet(AmmoData)
			end
		end

		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.FuzeDistance = nil
		end
	end
end)