hook.Add("PlayerSpawn", "TTLB_InitBody", function(ply)
	TTLB.InitBody(ply)
	ply.TTLBAttributes = {}
end)

hook.Add("EntityTakeDamage", "TTLB_HandleGenericDamage", function(ply, info)
	if ply:IsPlayer() then
		
		return true
	end
end)

hook.Add("ScalePlayerDamage", "TTLB_HandleDamage", function(ply, hitgr, info, extra)
	TTLB.DamageBodyPart(ply, hitgr, info, extra)
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
	TTLB.DamageBodyPart(ply, affected, d)
	ply:EmitSound("Flesh.ImpactHard")
	return false
end)