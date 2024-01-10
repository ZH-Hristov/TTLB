TTLB = TTLB or {BleedEnts = {}, BleedHook = false}

TTLB.BPEnums = {
	[0] = "Generic",
	[1] = "Head",
	[2] = "Chest",
	[3] = "Stomach",
	[4] = "LArm",
	[5] = "RArm",
	[6] = "LLeg",
	[7] = "RLeg"
}

-- Default health values and starting blood level.
local HPConVars = {
	HeadHP = 10,
	ChestHP = 100,
	StomachHP = 100,
	RArmHP = 75,
	LArmHP = 75,
	RLegHP = 80,
	LLegHP = 80,
	StartBlood = 5000
}

TTLB.Attributes = {
	DisabledLegs = {
		OnAdd = function(ply)
			ply:ViewPunch(Angle(10, 0, 0))
		end
	}
}

TTLB.GenericHandlers = {
	[1] = function(ply, info)
		local lpos = ply:WorldToLocal(info:GetDamagePosition())
		if lpos.z >= 64 then return {1} end
		if lpos.z <= 35 and !ply:Crouching() then return {6, 7} end
		return {2, 3}
	end,

	[4] = function(ply, info)
		local atkrclass = info:GetAttacker():GetClass()
		local swcase = {
			npc_antlionguard = {2, 3, 4, 5},
			npc_headcrab = {1},
			npc_headcrab_fast = {1},
			npc_zombie_torso = function() 
				if TTLB.GetBodyPartHealth(ply, "RLeg") <= 0 and TTLB.GetBodyPartHealth(ply, "LLeg") <= 0 then
					return {1} end 
				return {6, 7} 
			end
		}
		swcase["npc_fastzombie_torso"] = swcase.npc_zombie_torso
		if swcase[atkrclass] then return (type(swcase[atkrclass]) == "function" and swcase[atkrclass]()) or swcase[atkrclass] end
		return {2}
	end,
	
	[8] = function() return {1, 2, 3, 4, 5, 6, 7} end,
	
	[16] = function() return {2, 3, 6, 7} end,
	
	[64] = function(ply, info)
		ply:SetDSP(math.random(35, 37), true)
		ply:SetVelocity(info:GetDamageForce())
		return {2, 3, 4, 5, 6, 7}
	end,
	
	[128] = function(ply, info)
		local atkrclass = info:GetAttacker():GetClass()
		local swcase = {
			npc_antlionguard = {2, 3, 4, 5},
			npc_hunter = {2, 3}
		}
		if swcase[atkrclass] then return (type(swcase[atkrclass]) == "function" and swcase[atkrclass]()) or swcase[atkrclass] end
		return {2}
	end,
	
	[1024] = function(ply, info)
		local lpos = ply:WorldToLocal(info:GetDamagePosition())
		if lpos.z >= 64 then return {1} end
		if lpos.z <= 35 and !ply:Crouching() then return {6, 7} end
		return {2, 3}
	end,
	
	[16384] = function() return {1, 2} end,
	
	[32768] = function() return {2, 3} end,
	
	[131072] = function() return {2, 3} end,
	
	[262144] = function() return {1, 2, 3, 4, 5, 6, 7} end,
	
	[1048576] = function() return {2, 3} end,
}

local BodyParts = {
	"Head", "Chest", "Stomach", "RArm", "LArm", "RLeg", "LLeg"
}

for bpname, defaultval in pairs(HPConVars) do
	CreateConVar("TTLB_"..bpname, defaultval, bit.band(FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_PROTECTED))
end

function TTLB.InitBody(ply)
	for _, BP in pairs(BodyParts) do
		ply:SetNW2Int("TTLB_"..BP.."HP", GetConVar("TTLB_"..BP.."HP"):GetInt())
	end
	ply:SetNW2Int("TTLB_Blood", GetConVar("TTLB_StartBlood"):GetInt())
end

function TTLB.GetBodyPartByHitgroup(ply, hitgroup)
	local bpname = TTLB.BPEnums[hitgroup]
	return bpname, ply:GetNW2Int("TTLB_"..bpname.."HP")
end

function TTLB.GetBodyPartHealth(ply, bodypart)
	return ply:GetNW2Int("TTLB_"..bodypart.."HP")
end

function TTLB.GetBodyPartMaxHealth(ply, bodypart)
	return GetConVar("TTLB_"..bodypart.."HP"):GetInt()
end

function TTLB.GetBodyPartHealthFraction(ply, bodypart)
	return TTLB.GetBodyPartHealth(ply, bodypart) / TTLB.GetBodyPartMaxHealth(ply, bodypart)
end

function TTLB.GetBlood(ply)
	return ply:GetNW2Int("TTLB_Blood")
end

function TTLB.GetMaxBlood(ply)
	return GetConVar("TTLB_StartBlood"):GetInt()
end

function TTLB.GetBloodFraction(ply)
	return TTLB.GetBlood(ply) / TTLB.GetMaxBlood(ply)
end

function TTLB.TakeBlood(ply, amt)
	ply:SetNW2Int("TTLB_Blood", math.Approach(TTLB.GetBlood(ply), 0, amt))
end

function TTLB.AddBlood(ply, amt)
	ply:SetNW2Int("TTLB_Blood", math.Approach(TTLB.GetBlood(ply), TTLB.GetMaxBlood(ply), amt))
end

function TTLB.SetBlood(ply, amt)
	ply:SetNW2Int("TTLB_Blood", amt)
end

local function HandleBleedsHook()
	for ply, _ in pairs(TTLB.BleedEnts) do
		for id, bleed in pairs(ply.TTLB_Bleeds) do
			if CurTime() >= bleed.nexttick then
				if bleed.taken < bleed.target then
					bleed.taken = bleed.taken + 1
					TTLB.TakeBlood(ply, 1)
					bleed.nexttick = CurTime() + bleed.next
				else
					table.remove(ply.TTLB_Bleeds, id)
					print(TTLB.GetBlood(ply))
					if table.IsEmpty(ply.TTLB_Bleeds) then
						TTLB.BleedEnts[ply] = nil
					end
					if table.IsEmpty(TTLB.BleedEnts) then
						hook.Remove("Tick", "TTLB_HandleBleeds")
						TTLB.BleedHook = false
					end
				end
			end
		end
	end
end

function TTLB.ClearBleeds(ply)
	if ply.TTLB_Bleeds then
		table.Empty(ply.TTLB_Bleeds)
	end
end

function TTLB.AddBleed(ply, time, amt)
	if !TTLB.BleedEnts[ply] then TTLB.BleedEnts[ply] = true end
	ply.TTLB_Bleeds = ply.TTLB_Bleeds or {}
	table.insert(ply.TTLB_Bleeds, {
		taken = 0,
		target = amt,
		next = time / amt,
		nexttick = CurTime()
	})
	if !TTLB.BleedHook then hook.Add("Tick", "TTLB_HandleBleeds", HandleBleedsHook) end
end

function TTLB.DamageBodyPart(ply, bp, info, extra)
	if type(bp) == "number" then bp = {bp} end
	for _, bpnum in pairs(bp) do
		if bpnum == 0 then
			local genericaffected = (TTLB.GenericHandlers[info:GetDamageType()] and TTLB.GenericHandlers[info:GetDamageType()](ply, info))
			if genericaffected then
				for _, bpnumgeneric in pairs(genericaffected) do
					local bpname, bphp = TTLB.GetBodyPartByHitgroup(ply, bpnumgeneric)
					ply:SetNW2Int("TTLB_"..bpname.."HP", math.Approach(bphp, 0, info:GetDamage()))
				end
			end
		else
			local bpname, bphp = TTLB.GetBodyPartByHitgroup(ply, bpnum)
			ply:SetNW2Int("TTLB_"..bpname.."HP", math.Approach(bphp, 0, info:GetDamage()))
		end
	end
	TTLB.CheckDamages(ply)
end

function TTLB.HasAttribute(ply, attr)
	return ply.TTLBAttributes[attr]
end

function TTLB.AddAttribute(ply, attr)
	if TTLB.HasAttribute(ply, attr) then return end
	ply.TTLBAttributes[attr] = true
	if TTLB.Attributes[attr].OnAdd then TTLB.Attributes[attr].OnAdd(ply) end
end

function TTLB.RemoveAttribute(ply, attr)
	ply.TTLBAttributes[attr] = nil
	if TTLB.Attributes[attr].OnRemove then TTLB.Attributes[attr].OnRemove(ply) end
end

function TTLB.CheckDamages(ply)
	local ghp = TTLB.GetBodyPartHealth
	local gbl = TTLB.GetBlood(ply)
	
	if ghp(ply, "LLeg") <= 0 and ghp(ply, "RLeg") <= 0 then
		TTLB.AddAttribute(ply, "DisabledLegs")
	end
	
	if ghp(ply, "Head") <= 0 or ghp(ply, "Chest") <= 0 or gbl <= 0 then
		ply:Kill()
	end
end