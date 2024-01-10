hook.Add("PlayerSpawn", "TTLB_InitBody", function(ply)
	TTLB.ClearBleeds(ply)
	TTLB.InitBody(ply)
	ply.TTLBAttributes = {}
end)

hook.Add("PlayerDeath", "TTLB_HandleDeath", function(ply)
	TTLB.ClearBleeds(ply)
end)

hook.Add("EntityTakeDamage", "TTLB_HandleGenericDamage", function(ply, info)
	if ply:IsPlayer() then
		TTLB.DamageBodyPart(ply, 0, info)
		return true
	end
end)

local viewpunches = {
	[1] = Angle(10),
	[2] = Angle(2),
	[3] = Angle(2),
	[4] = Angle(0, -4),
	[5] = Angle(0, 4)
}

hook.Add("ScalePlayerDamage", "TTLB_HandleDamage", function(ply, hitgr, info, extra)
	TTLB.DamageBodyPart(ply, hitgr, info, extra)
	TTLB.AddBleed(ply, 5, 1000)
	local dot = info:GetAttacker():GetForward():Dot(ply:GetForward())
	local dir = 1
	if dot < 0 then dir = -1 end
	if viewpunches[hitgr] then ply:ViewPunch(viewpunches[hitgr] * dir) end
	return true
end)

hook.Add("StartCommand", "TTLB_HandleUserCMD", function(ply, cmd)
	if TTLB.HasAttribute(ply, "DisabledLegs") then cmd:AddKey(IN_DUCK) cmd:RemoveKey(IN_JUMP) end
end)

hook.Add("GetFallDamage", "TTLB_FallDamage", function(ply, speed)
	local d = DamageInfo()
	local dmg = math.Round(speed / 9)
	local affected = {6, 7}
	local rhp, lhp = TTLB.GetBodyPartHealth(ply, "RLeg"), TTLB.GetBodyPartHealth(ply, "LLeg")
	if dmg >= 80 or rhp <= 0 and lhp <= 0 then
		table.insert(affected, 2)
		table.insert(affected, 3)
		ply:EmitSound("Flesh.Break")
	end
	d:SetDamage(dmg)
	d:SetDamageType(DMG_FALL)
	TTLB.DamageBodyPart(ply, affected, d)
	ply:EmitSound("Flesh.ImpactHard")
	return false
end)