local w, h = ScrW(), ScrH()
local bs = h * 0.12
local clr_healthy = Color(153, 255, 153)
local clr_wounded = Color(255, 80, 80)
local clr_dead = Color(50, 50, 50)

local function LerpColor(frac,from,to)
	local col = Color(
		Lerp(frac,from.r,to.r),
		Lerp(frac,from.g,to.g),
		Lerp(frac,from.b,to.b),
		Lerp(frac,from.a,to.a)
	)
	return col
end

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

local BodyParts = {
	"Head", "Chest", "Stomach", "RArm", "LArm", "RLeg", "LLeg"
}

local bpmats = {}
for _, bpname in pairs(BodyParts) do
	bpmats[bpname] = Material("TTLB/body/"..bpname..".png", "smooth")
end

local aspect = bpmats.Head:Height() / bpmats.Head:Width()
print(aspect)

hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if ( hide[ name ] ) then
		return false
	end
end)

hook.Add("HUDPaint", "TTLB_HUD", function()
	for _, bpname in pairs(BodyParts) do
		local hpfrac = TTLB.GetBodyPartHealthFraction(LocalPlayer(), bpname)
		surface.SetMaterial(bpmats[bpname])
		surface.SetDrawColor( (hpfrac <= 0 and clr_dead) or LerpColor(hpfrac, clr_wounded, clr_healthy) )
		surface.DrawTexturedRect(50, h - bs * aspect - 50, bs, bs * aspect)
	end
end)