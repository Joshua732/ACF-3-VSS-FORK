local ACF = ACF
local Damage = ACF.Damage
local Objects = Damage.Objects

local BASE_HE_FILLER_MASS = 2.5
local BASE_HE_FRAG_MASS = 1.25
local MAX_BLAST_SCALE = 120 / 70

local function GetBlastScale(Entity)
	local Size = Entity.OxygenSize

	if not Size then return 1 end

	return math.Clamp(math.max(Size.x, Size.y, Size.z) / 70, 1, MAX_BLAST_SCALE)
end

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

	local BlastScale = GetBlastScale(self)
	local FillerMass = BASE_HE_FILLER_MASS * BlastScale
	local FragMass = BASE_HE_FRAG_MASS * BlastScale
	local Position = self:LocalToWorld(self:OBBCenter())
	local DmgInfo = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

	ACF.KillChildProps(self, Position, FillerMass)
	Damage.createExplosion(Position, FillerMass, FragMass, { self }, DmgInfo)
	Damage.explosionEffect(Position, nil, FillerMass)

	constraint.RemoveAll(self)
	self:Remove()
end
