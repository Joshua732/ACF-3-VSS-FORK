local ACF = ACF
local Damage = ACF.Damage
local Objects = Damage.Objects

local OXYGEN_TANK_HE_FILLER_MASS = 2.5
local OXYGEN_TANK_HE_FRAG_MASS = 1.25

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitResult = Damage.doPropDamage(self, DmgResult, DmgInfo)

	if self.Exploding or (HitResult.Damage or 0) <= 0 then
		return HitResult
	end

	self.Attacker = DmgInfo.Attacker or DmgInfo:GetAttacker()
	self.Inflictor = DmgInfo.Inflictor or DmgInfo:GetInflictor()

	self:Detonate()

	return HitResult
end

function ENT:Detonate()
	if self.Exploding then return end

	local CanExplode = hook.Run("ACF_PreExplodeOxygenTank", self)

	if CanExplode == false then return end

	self.Exploding = true

	local Position = self:LocalToWorld(self:OBBCenter())
	local DmgInfo = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

	ACF.KillChildProps(self, Position, OXYGEN_TANK_HE_FILLER_MASS)
	Damage.createExplosion(Position, OXYGEN_TANK_HE_FILLER_MASS, OXYGEN_TANK_HE_FRAG_MASS, { self }, DmgInfo)
	Damage.explosionEffect(Position, nil, OXYGEN_TANK_HE_FILLER_MASS)

	constraint.RemoveAll(self)
	self:Remove()
end
