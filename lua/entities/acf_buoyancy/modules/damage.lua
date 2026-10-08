local ACF = ACF
local Damage = ACF.Damage
local Clamp = math.Clamp
local Floor = math.floor

local COMPARTMENT_PROTECTION = 0.5

function ENT:ACF_OnDamage(DmgResult)
	local Count = Clamp(Floor(tonumber(self.CompartmentCount) or 0), 0, 20)

	if Count > 0 then
		local OriginalDamage = DmgResult:Compute().Damage
		local Protection = 1 + Count * COMPARTMENT_PROTECTION

		DmgResult:SetDamage(OriginalDamage / Protection)
	end

	local HitResult = Damage.doPropDamage(self, DmgResult)

	if HitResult.Kill then
		HitResult.Kill = false
		self.ACF.Health = 1

		if Damage.Network then
			Damage.Network(self, nil, self.ACF.Health, self.ACF.MaxHealth)
		end
	end

	if self.UpdateBuoyancyRatio then
		self:UpdateBuoyancyRatio()
	end

	if self.UpdateOverlay then
		self:UpdateOverlay()
	end

	return HitResult
end
