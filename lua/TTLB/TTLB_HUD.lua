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
		
		surface.SetDrawColor(clr_dead)
		surface.DrawRect(60 + bs, h - bs * aspect - 50, h * 0.02, bs * aspect)
		
		draw.NoTexture()
		surface.SetDrawColor(clr_wounded)
	
		surface.DrawPoly({
			{x = math.floor(60 + bs), y = math.floor(h - bs * aspect - 50 + (bs * aspect))},
			{x = math.floor(60 + bs), y = math.floor( Lerp(TTLB.GetBloodFraction(LocalPlayer()), h - bs * aspect - 50 + (bs * aspect), h - bs * aspect - 50) )},
			{x = math.floor(60 + bs + (h * 0.02)), y = math.floor( Lerp(TTLB.GetBloodFraction(LocalPlayer()), h - bs * aspect - 50 + (bs * aspect), h - bs * aspect - 50) )},
			{x = math.floor(60 + bs + (h * 0.02)), y = math.floor(h - bs * aspect - 50 + (bs * aspect))}
		})
		
		surface.SetDrawColor(color_black)
		surface.DrawOutlinedRect(60 + bs, h - bs * aspect - 50, math.Round(h * 0.02), math.ceil(bs * aspect), 2)
	end
end)