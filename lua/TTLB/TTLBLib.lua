TTLB = TTBL or {}

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
	HeadHP = 50,
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

function TTLB.DamageBodyPart(ply, bp, info, extra)
	if type(bp) == "number" then bp = {bp} end
	for _, bpnum in pairs(bp) do
		local bpname, bphp = TTLB.GetBodyPartByHitgroup(ply, bpnum)
		ply:SetNW2Int("TTLB_"..bpname.."HP", math.Approach(bphp, 0, info:GetDamage()))
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
	
	if ghp(ply, "LLeg") <= 0 and ghp(ply, "RLeg") <= 0 then
		TTLB.AddAttribute(ply, "DisabledLegs")
	end
	
	if ghp(ply, "Head") <= 0 or ghp(ply, "Chest") <= 0 then
		ply:Kill()
	end
end