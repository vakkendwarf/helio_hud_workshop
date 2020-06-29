-- Made by Helios,
-- Do not publish this code in whole or any part of it,
-- Except when with direct permission from its author.
-- Copyright @ 2020

-- 3rd of February, 2020
-- Version 1.7

if SERVER then

	util.AddNetworkString("NewMaxHP")
	util.AddNetworkString("NewMaxHPEnt")


	net.Receive("NewMaxHPEnt", function()
	
		net.ReadEntity():SetMaxHealth(net.ReadInt(32))
	
	end)


	net.Receive("NewMaxHP", function(len, ply)

		ply:SetMaxHealth(net.ReadInt(32))

	end)


	hook.Add("PlayerInitialSpawn", "HideDefaultOverhead", function(ply)

		ply:SendLua("function GAMEMODE:HUDDrawTargetID() return false end")

	end)


end

AddCSLuaFile()

if CLIENT then

if IsValid(modelpanel) then modelpanel:Remove() end

local clientside_only = true
local overhead_scale = 0.1
modelpanel_enabled = true
local ply_lastmodel = nil

hook.Add("Think", "HelioHUD_RemoveModelpanelIfModelIsError", function()
	if modelpanel and ply_lastmodel ~= LocalPlayer():GetModel() then
		ply_lastmodel = LocalPlayer():GetModel()
		if modelpanel.Entity and modelpanel.Entity:LookupBone("ValveBiped.Bip01_Head1") == nil and modelpanel_enabled == true then
			print("[Visage] Oops, model is not properly loaded! Disabling modelpanel.")
			modelpanel_enabled = false
		elseif !modelpanel.Entity or modelpanel.Entity:LookupBone("ValveBiped.Bip01_Head1") ~= nil and modelpanel_enabled == false then
			modelpanel_enabled = true
			CreateModelPanel()
		end
	end
end)

CreateClientConVar("visage_lang", "en")
CreateClientConVar("visage_overhead_mode", 2)
CreateClientConVar("visage_overhead_radius", 500)

CreateClientConVar("visage_style", 1)
CreateClientConVar("visage_location", 1)
CreateClientConVar("visage_roundedness", 1)
CreateClientConVar("visage_gradient", 0)

local h = ScrH()/GetConVar("visage_location"):GetFloat()
local w = ScrW()
local pad = 20

if IsValid(XeninUI) && file.Exists("autorun/xeninui.lua", "LUA") then

	CreateClientConVar("visage_font_big", "XeninUI.Frame.Title")
	CreateClientConVar("visage_font_small", "XeninUI.Checkbox.Small")
	CreateClientConVar("visage_font_default", "XeninUI.CheckboxV2")

	print("[HeliOS] XeninUI has been detected. VisageHUD will use its fonts.")

	CreateClientConVar("visage_font_offset", -2.5)

else

	CreateClientConVar("visage_font_big", "DermaLarge")
	CreateClientConVar("visage_font_small", "DermaDefaultBold")
	CreateClientConVar("visage_font_default", "DermaDefault")

	CreateClientConVar("visage_font_offset", 0)

end

CreateClientConVar("visage_color_hp", "171,48,48")
CreateClientConVar("visage_color_armor", "26,126,175")
CreateClientConVar("visage_color_bg", "180,180,180") -- Background
CreateClientConVar("visage_color_ddd", "255,153,0") -- Dynamic Damage Display

local font_big = GetConVar("visage_font_big"):GetString()
local font_small = GetConVar("visage_font_small"):GetString()
local font_default = GetConVar("visage_font_default"):GetString()
local font_hOffset = GetConVar("visage_font_offset"):GetFloat()


cvars.AddChangeCallback("visage_font_big", function()

	font_big = GetConVar("visage_font_big"):GetString()

end)

cvars.AddChangeCallback("visage_location", function()

	h = ScrH()/GetConVar("visage_location"):GetString()

end)


cvars.AddChangeCallback("visage_font_small", function()

	font_small = GetConVar("visage_font_small"):GetString()

end)


cvars.AddChangeCallback("visage_font_default", function()

	font_default = GetConVar("visage_font_default"):GetString()

end)


cvars.AddChangeCallback("visage_font_offset", function()

	font_hOffset = GetConVar("visage_font_offset"):GetFloat()

end)


resource.AddSingleFile("materials/vgui/gradient.png")
local gradient = Material("vgui/gradient.png", "noclamp smooth")

local nice_numbers_pl = {
	["4-6"] = " tys. ",
	["7-9"] = " mln. ",
	["10-12"] = " mld. "
}

local nice_numbers_en = {
	["4-6"] = "k ",
	["7-9"] = "M ",
	["10-12"] = "B "
}

local number_formats = {
	["pl"] = nice_numbers_pl,
	["en"] = nice_numbers_en
}

-- Do not edit below this line

local NumberFormat = number_formats[GetConVar("visage_lang"):GetString()]

cvars.AddChangeCallback("visage_lang", function()

	NumberFormat = number_formats[GetConVar("visage_lang"):GetString()]

end)

cvars.AddChangeCallback("cl_drawhud", function(name, old, new)

	if IsValid(modelpanel) && tonumber(new) == 0 then

		modelpanel:Hide()

	elseif IsValid(modelpanel) && tonumber(new) == 1 then

		modelpanel:Show()

	end

end)

local EntHealths = {}
local EntDeaths = {}

hook.Add("PlayerDeath", "RemoveDeadFromMaxHP", function(ply)

	if table.HasValue(ply) then

		table.RemoveByValue(EntHealths, ply)

	end

end)

	local hide = {

		["CHudHealth"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true,
		["CHudBattery"] = true,
		["CHudVoiceSelfStatus"] = true,
		["CHudVoiceStatus "] = true

	}

	local function nice_number (deci, num)

		l = #tostring(num)

		if l <= 3 then 

			return tostring(num)

		elseif l == 4 or l == 5 or l == 6 then 

			return math.Round(num/1000, deci) .. NumberFormat["4-6"]

		elseif l == 7 or l == 8 or l == 9 then

			return math.Round(num/1000000, deci) .. NumberFormat["7-9"]

		elseif l == 10 or l == 11 or l == 12 then

			return math.Round(num/1000000000, deci) .. NumberFormat["10-12"]

		end

	end

	local function DrawBar(r, X, Y, W, H, rgb, frame, offset, shapemode) -- Bar drawing function
	
		local frame = frame or false
		local offset = offset or 0
		local shapemode = shapemode or ""
		local mode = GetConVar("visage_style"):GetInt()
		local gradient_on = GetConVar("visage_gradient"):GetBool()
		local roundedness = GetConVar("visage_roundedness"):GetFloat()

		if mode == 1 then
	
			return draw.RoundedBox(r * roundedness, X, Y, W, H, rgb)

		end

		if mode == 2 then

			surface.SetDrawColor(rgb.r, rgb.g, rgb.b, rgb.a)

			if gradient_on then
			
				surface.SetMaterial(gradient)
				surface.DrawTexturedRect(X, Y, W, H)

			else

				surface.DrawRect(X, Y, W, H)

			end

		end

		if mode == 3 then

			surface.SetDrawColor(rgb.r, rgb.g, rgb.b, rgb.a)

			if gradient_on then

				surface.SetMaterial(gradient)

			else

				draw.NoTexture()

			end

			local mod = 15 + offset

			if frame == true then mod = 0 end

			local shape = {

				{x = X, y = Y, u = 0, v = 0},
				{x = X+W, y = Y, u = 1, v = 0},
				{x = X+W+mod, y = Y+H, u = 0, v = 1},
				{x = X, y = Y+H, u = 1, v = 1}

			}

			surface.DrawPoly(shape)

		end

		if mode == 4 then

			surface.SetDrawColor(rgb.r, rgb.g, rgb.b, rgb.a)

			if gradient_on then

				surface.SetMaterial(gradient)

			else

				draw.NoTexture()

			end

			local mod = 15 + offset

			if frame == true then mod = 0 end

			
			local shape = {

				{x = X-mod*0.6, y = Y, u = 0, v = 0},
				{x = X+W, y = Y, u = 1, v = 0},
				{x = X+W+mod*0.6, y = Y+H, u = 0, v = 1},
				{x = X, y = Y+H, u = 1, v = 1}

			}

			if shapemode == "inverted" then

				shape = {

					{x = X, y = Y, u = 0, v = 0},
					{x = X+W+mod*0.6, y = Y, u = 1, v = 0},
					{x = X+W, y = Y+H, u = 0, v = 1},
					{x = X-mod*0.6, y = Y+H, u = 1, v = 1}

				}

			end

			if shapemode == "hexagon" then

				shape = {

					{x = X, y = Y, u = 0, v = 0},
					{x = X+W-0.26*W, y = Y, u = 1, v = 0},
					{x = X+W*1.25-0.26*W, y = Y+H/2, u = 0.5, v = 1},
					{x = X+W-0.26*W, y = Y+H, u = 0, v = 1},
					{x = X, y = Y+H, u = 1, v = 1},
					{x = X-W*0.25, y = Y+H/2, u = 0.5, v = 1}

				}

			end

			if shapemode == "rect" then

				shape = {

					{x = X, y = Y, u = 0, v = 0},
					{x = X+W, y = Y, u = 1, v = 0},
					{x = X+W, y = Y+H, u = 0, v = 1},
					{x = X, y = Y+H, u = 1, v = 1}

				}

			end

			surface.DrawPoly(shape)

		end

	end

	modelpanel = nil

	function CreateModelPanel(altmode)

		if !modelpanel_enabled then return end

		local altmode = altmode or nil

		if IsValid(modelpanel) then modelpanel:Remove() end

		modelpanel = vgui.Create("DModelPanel")
		modelpanel:SetPos(50+pad, h-pad-170+2.33)
		modelpanel:SetSize(80,80)
		if altmode then modelpanel:SetSize(60,60) end
		modelpanel:SetModel(LocalPlayer():GetModel())

		function modelpanel:LayoutEntity( Entity ) return end

		local headbone = modelpanel.Entity:LookupBone("ValveBiped.Bip01_Head1")
		local headpos = nil
		if headbone ~= nil and modelpanel.Entity:GetBonePosition(headbone) ~= nil then
			headpos = modelpanel.Entity:GetBonePosition(headbone)
			modelpanel:SetLookAt(headpos)
			modelpanel:SetCamPos(headpos-Vector(-16,0,0))
			modelpanel.Entity:SetEyeTarget(headpos-Vector(-15, 0, 0))
		else
			modelpanel_enabled = false
			print("Oops, model is not loaded correctly, disabling modelpanel.")
			modelpanel:Remove()
		end

		if GetConVar("visage_style"):GetInt() == 4 then

			local StockPaint = modelpanel.Paint

			function modelpanel:Paint(w, h)

				render.ClearStencil()
				render.SetStencilEnable(true)
				render.SetStencilTestMask(255)
				render.SetStencilWriteMask(255)
				render.SetStencilReferenceValue(10)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)
				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.OverrideColorWriteEnable(true, false)

				local X, Y = 10, 0
				local H = modelpanel:GetTall()
				local W = modelpanel:GetWide()-6
				shape = {

					{x = X, y = Y, u = 0, v = 0},
					{x = X+W-0.26*W, y = Y, u = 1, v = 0},
					{x = X+W*1.25-0.26*W, y = Y+H/2, u = 0.5, v = 1},
					{x = X+W-0.26*W, y = Y+H, u = 0, v = 1},
					{x = X, y = Y+H, u = 1, v = 1},
					{x = X-W*0.25, y = Y+H/2, u = 0.5, v = 1}

				}
				surface.SetDrawColor(255,255,255,255)
				surface.DrawPoly(shape)

				render.OverrideColorWriteEnable(false)
				render.SetStencilCompareFunction(STENCIL_EQUAL)

				StockPaint(self, w, h)

				render.SetStencilEnable(false)
				
			end

		end

		modelpanel:SetPaintedManually(true)
		modelpanel:Hide()

	end


	cvars.AddChangeCallback("visage_style", function(name, from, to)

		if tonumber(to) == 4 && DarkRP then

			CreateModelPanel(true)

		elseif DarkRP then

			CreateModelPanel(false)

		end

	end)


	hook.Add("HUDShouldDraw", "HelioHUDHide", function( name )

		if (hide[name]) then return false end

	end)


	local lasthp = nil
	local lastsuit = nil
	local lhp = nil
	local lhpr = nil
	local lst = nil
	local lstr = nil
	local gray_cvar = string.Split(GetConVar("visage_color_bg"):GetString(), ",")
	local gray = Color(gray_cvar[1],gray_cvar[2],gray_cvar[3],125)
	local red_cvar = string.Split(GetConVar("visage_color_hp"):GetString(), ",")
	local red = Color(red_cvar[1], red_cvar[2], red_cvar[3])
	local blue_cvar = string.Split(GetConVar("visage_color_armor"):GetString(), ",")
	local blue = Color(blue_cvar[1], blue_cvar[2], blue_cvar[3])
	local ddd_cvar = string.Split(GetConVar("visage_color_ddd"):GetString(), ",")
	local ddd = Color(ddd_cvar[1], ddd_cvar[2], ddd_cvar[3])
	local lasthp_ext = {}
	local lhp_ext = {}
	local lhpr_ext = {}

	-- Color setup callbacks

	cvars.AddChangeCallback("visage_color_hp", function()
	
		red_cvar = string.Split(GetConVar("visage_color_hp"):GetString(), ",")
		red = Color(red_cvar[1], red_cvar[2], red_cvar[3])
		
	end)

	cvars.AddChangeCallback("visage_color_armor", function()
	
		blue_cvar = string.Split(GetConVar("visage_color_armor"):GetString(), ",")
		blue = Color(blue_cvar[1], blue_cvar[2], blue_cvar[3])
	
	end)

	cvars.AddChangeCallback("visage_color_bg", function()
	
		gray_cvar = string.Split(GetConVar("visage_color_bg"):GetString(), ",")
		gray = Color(gray_cvar[1],gray_cvar[2],gray_cvar[3],125)
	
	end)

	cvars.AddChangeCallback("visage_color_ddd", function()

		local ddd_cvar = string.Split(GetConVar("visage_color_ddd"):GetString(), ",")
		local ddd = Color(ddd_cvar[1], ddd_cvar[2], ddd_cvar[3])	
	
	end)

	hook.Add("PostDrawTranslucentRenderables", "HelioHUDOverhead", function() -- Overhead HUD

		if GetConVar("cl_drawhud"):GetInt() == 0 then return end

		local mode = GetConVar("visage_overhead_mode"):GetInt()
		local targets = {}

		if mode == 0 then return

		elseif mode == 1 then

			table.insert(targets, LocalPlayer():GetEyeTrace().Entity)

		elseif mode == 2 then

			local temp = ents.FindInSphere(LocalPlayer():GetPos(), math.Clamp(GetConVar("visage_overhead_radius"):GetInt(),0,500))

			for k,v in pairs(temp) do

				if v:IsNPC() or v:IsPlayer() then 
				
					table.insert(targets, v)
				
				end
	
			end

		end

		for _, ent in pairs(targets) do

			if ent == LocalPlayer() then continue end

			local dist = LocalPlayer():GetPos():DistToSqr(ent:GetPos())
--			local ent = LocalPlayer():GetEyeTrace().Entity

			local otherentpos = ent:EyePos()
			otherentpos:Sub(LocalPlayer():EyePos())

			local mypos = LocalPlayer():EyePos()
			
--			local tr = util.QuickTrace(mypos, otherentpos, LocalPlayer())

--			print(tr.Entity)


			local trdata = {
				start = LocalPlayer():EyePos(),
				endpos = ent:EyePos(),
				filter = LocalPlayer(),
				mask = MASK_VISIBLE
			}

			local tr = util.TraceLine(trdata)

			-- DEBUGGING
			--[[

			local trace = LocalPlayer():GetEyeTrace()
			local angle = trace.HitNormal:Angle()
				
			render.DrawLine( trace.HitPos, trace.HitPos + 8 * angle:Forward(), Color( 255, 0, 0 ), true )
			render.DrawLine( trace.HitPos, trace.HitPos + 8 * -angle:Right(), Color( 0, 255, 0 ), true )
			render.DrawLine( trace.HitPos, trace.HitPos + 8 * angle:Up(), Color( 0, 0, 255 ), true )

			local ang = trace.Normal:Angle()
			ang:RotateAroundAxis(trace.Normal, 90)
			ang:RotateAroundAxis(ang:Right(), 90)

			cam.Start3D2D(trace.HitPos, ang, 0.3)

				draw.DrawText(tostring(tr.Entity), "DermaDefault", 0, -20, Color(255,255,255,255), TEXT_ALIGN_LEFT)
				draw.DrawText(tr.Fraction, "DermaDefault", 0, -10, Color(255,255,255,255), TEXT_ALIGN_LEFT)

			cam.End3D2D()

			if tostring(tr.Entity) ~= "[NULL Entity]" then

				render.DrawLine( tr.HitPos, tr.StartPos, Color(255,0,0), true)

			else

				render.DrawLine( tr.HitPos, tr.StartPos, Color(255,255,255), true)

			end

			]]--
			-- END DEBUGGING

			if tostring(tr.Entity) ~= "[NULL Entity]" then continue end

			if LocalPlayer():GetPos():DistToSqr(ent:GetPos()) < 250000 then

				if dist < 62500 then alpha = 255 else

					alpha = math.Clamp(-0.00136 * dist + 340,0,255)

				end

				if ent:IsPlayer() && EntDeaths[ent] && EntDeaths[ent] < ent:Deaths() then

					EntHealths[ent] = nil
				
				end

				if ent:IsPlayer() then

					EntDeaths[ent] = ent:Deaths()

				end

				if clientside_only && EntHealths[ent] == nil then

					EntHealths[ent] = ent:GetMaxHealth()

				end

				local maxhp = EntHealths[ent]
				local hp = ent:Health()/maxhp
				local lasthpr_ext = (lasthp_ext[ent] or hp)/maxhp
				local gray = Color(gray.r,gray.g,gray.b,alpha/2)
				local graydark = Color(gray.r*0.55,gray.g*0.55,gray.b*0.55,alpha/3)
				local red = Color(red.r, red.g, red.b,alpha)
				local trace = LocalPlayer():GetEyeTrace()
				local angle = trace.HitNormal:Angle()
				local angle2 = trace.Normal:Angle()
				angle2:RotateAroundAxis(trace.Normal, 90)
				angle2:RotateAroundAxis(angle2:Right(), 90)

				if ent:Health() > maxhp then

					if clientside_only then

						EntHealths[ent] = ent:Health()

					elseif !ent:IsPlayer() then

						net.Start("NewMaxHPEnt")
						net.WriteEntity(ent)
						net.WriteInt(ent:Health(), 32)
						net.SendToServer()

					end

				end

				local distf = nil

				if dist < 5500 then

					distf = 5500

				elseif dist > 8500 then

					distf = 8500

				else

					distf = dist

				end

				local style4Offset = 0

				if GetConVar("visage_style"):GetInt() == 4 then 
		
					style4Offset = 1
		
				end

				cam.Start3D2D(Vector(ent:GetPos().x, ent:GetPos().y, ent:GetPos().z+(1.7*ent:BoundingRadius())), angle2, overhead_scale * distf / 5000)
				cam.IgnoreZ(true)

				if lasthp_ext[ent] && ent:Health() < lasthp_ext[ent] then

					lhp_ext[ent] = hp
					lhpr_ext[ent] = lasthpr_ext
					timer.Destroy("LerpHPExt_" .. ent:EntIndex())
					timer.Create("LerpHPExt_" .. ent:EntIndex(), 2.001, 1, function() end)
					timer.Start("LerpHPExt_" .. ent:EntIndex())


				elseif timer.Exists("LerpHPExt_" .. ent:EntIndex()) then

					local frac = Lerp(1 - (timer.TimeLeft("LerpHPExt_" .. ent:EntIndex()) / 2.001), lhpr_ext[ent], lhp_ext[ent])
					local alphafrac = Lerp(1 - (timer.TimeLeft("LerpHPExt_" .. ent:EntIndex()) / 2.001), 255, 0)
					DrawBar(15, -138, -61, math.Clamp(275*frac,0,275), 28, Color(ddd.r, ddd.g, ddd.b, alpha))
					draw.SimpleTextOutlined((lhp_ext[ent] * maxhp) - (lhpr_ext[ent] * maxhp), font_big, 145+(style4Offset*10), -62-font_hOffset*-0.5, Color(255,255,255, alpha/255 * alphafrac), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0,0,0,alpha/255 * alphafrac))

				end

				DrawBar(15, -140, -63, 280, 32, graydark, false, 2)
				DrawBar(15, -138, -61, math.Clamp(275*hp,0,275), 28, red)
				draw.DrawText(nice_number(1, ent:Health()), font_big, -125, -62+font_hOffset*0.4, Color(255,255,255, alpha), TEXT_ALIGN_LEFT) -- nice hp

				if ent:IsPlayer() then

					draw.SimpleTextOutlined(ent:Name(), font_big, 2, -94+font_hOffset, Color(255,255,255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0,0,0,alpha))

					if TeamTable then

						hook.Remove("HUDPaint", "drawnamesabovehead")

						draw.DrawText(ent:Numbers() .. " " .. team.GetName(ent:Team()), font_big, 2, -31+font_hOffset, Color(0,0,0, alpha), TEXT_ALIGN_CENTER)
						draw.DrawText(ent:Numbers() .. " " .. team.GetName(ent:Team()), font_big, 0, -32+font_hOffset, Color(255,255,255, alpha), TEXT_ALIGN_CENTER)

					elseif DarkRP then

						local teamcolor = RPExtraTeams[ent:Team()].color
						draw.SimpleTextOutlined(team.GetName(ent:Team()), font_big, 2, -31-font_hOffset, Color(255,255,255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1.2, Color(teamcolor.r,teamcolor.g,teamcolor.b,alpha/2))

					end

				end

				lasthp_ext[ent] = ent:Health()
				cam.IgnoreZ(false)
				cam.End3D2D()

				
			end

		end

	end)

	local maxhp = nil

	hook.Add("HUDPaint", "HelioHUDMain", function() -- Player HUD

		if LocalPlayer():Alive() && GetConVar("cl_drawhud"):GetInt() == 0 then return end

		if !LocalPlayer():Alive() then 

			if maxhp ~= nil then

				maxhp = nil

			end

			return

		end

		if maxhp == nil then

			maxhp = LocalPlayer():GetMaxHealth()

		end

		local hp = LocalPlayer():Health()/maxhp
		local lasthpr = (lasthp or hp)/maxhp
		local arm = LocalPlayer():Armor()/255
		local lastsuitr = (lastsuit or arm)/255

		local hp_lenmod = 1

		if GetConVar("visage_style"):GetInt() == 3 then hp_lenmod = 1.075 end

		if lasthp && LocalPlayer():Health() > maxhp then
		
			if clientside_only then

				maxhp = LocalPlayer():Health()

			else

				net.Start("NewMaxHP")
				net.WriteInt(LocalPlayer():Health(), 32)
				net.SendToServer()

			end

		end

		local baroffset = 0
		local style4Offset = 0
		local newStyle4Offset = 240

		if GetConVar("visage_style"):GetInt() == 4 then 
		
			baroffset = 290 - newStyle4Offset
			style4Offset = 1
		
		end

		DrawBar(8, 50+pad+baroffset, h-pad-50, 250*hp_lenmod, 20, gray, false, 2, "inverted")

		if DarkRP then -- DARKRP Mode assets

			local offset = 0
			local offset_nomodelpanel = 0

			if LocalPlayer():Armor() == 0 && GetConVar("visage_style"):GetInt() != 4 then offset = 30 end
			if !modelpanel_enabled and GetConVar("visage_style"):GetInt() ~= 4 then offset_nomodelpanel = 85 end

			local money = LocalPlayer():getDarkRPVar("money")
			local money_td = {text = nice_number(3, (money)) .. "$", font = font_small,pos = {100+pad+40-offset_nomodelpanel, h-pad-100+offset+font_hOffset}, xalign = TEXT_ALIGN_LEFT, yalign = TEXT_ALIGN_TOP, color = Color(255,255,255,255)}
			local moneylen = draw.SimpleTextOutlined(nice_number(3, (money)) .. "$", font_small, 100+pad+40+(style4Offset*-45)-offset_nomodelpanel, h-pad-100+offset+font_hOffset+(style4Offset*75), Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0))
			draw.SimpleTextOutlined(tostring("+" .. nice_number(3, LocalPlayer():getDarkRPVar("salary"))) .. "$/ " .. math.Round(GAMEMODE.Config.paydelay/60, 1) .. "min", font_small, 100+pad+40-offset_nomodelpanel + (style4Offset*-45) + moneylen + 5, h-pad-100+offset+font_hOffset+(style4Offset*75), Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,125,0))

			if GetConVar("visage_style"):GetInt() == 4 then

				local panel1 = draw.SimpleTextOutlined(tostring(LocalPlayer():getDarkRPVar("job")), font_default, 50+pad+285-newStyle4Offset, h-pad-95+offset+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, RPExtraTeams[LocalPlayer():Team()].color)
				draw.SimpleTextOutlined(tostring(LocalPlayer():Name()), font_default, 50+pad+285-newStyle4Offset + panel1 + 10, h-pad-95+offset+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0))
				DrawBar(8, 115 + panel1 + 3.33, h-pad-97, 3, 18, gray, false, 0, "rect")

			else

				draw.SimpleTextOutlined(tostring(LocalPlayer():getDarkRPVar("job")), font_small, 100+pad+40 - offset_nomodelpanel, h-pad-115+offset+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, RPExtraTeams[LocalPlayer():Team()].color)
				draw.SimpleTextOutlined(tostring(LocalPlayer():Name()), font_small, 100+pad+40 - offset_nomodelpanel, h-pad-130+offset+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0))

			end

			local altmode = false

			if GetConVar("visage_style"):GetInt() == 4 then 

				DrawBar(8, 298.5 - newStyle4Offset, h-pad-82, 60, 60, gray, false, 0, "hexagon")
				altmode = true

			end

			if !IsValid(modelpanel) and modelpanel_enabled then

				CreateModelPanel(altmode)
				modelpanel:PaintManual()
			
			elseif modelpanel_enabled then

				modelpanel:PaintManual()

				if !modelpanel:IsVisible() then

					modelpanel:Show()

				end

				local correctmppos = {50+pad+(style4Offset*221.5)-newStyle4Offset*style4Offset, h-pad-(style4Offset*-85)-170+offset+2.33}

				if modelpanel:GetPos() ~= correctmppos then

					modelpanel:SetPos(correctmppos[1], correctmppos[2])

				end

				if modelpanel.Entity:GetModel() ~= LocalPlayer():GetModel() then

					modelpanel.Entity:SetModel(LocalPlayer():GetModel())
					local headbone = modelpanel.Entity:LookupBone("ValveBiped.Bip01_Head1")
					if headbone == nil then
						modelpanel:Remove()
						modelpanel_enabled = false
						return
					end
					local headpos = modelpanel.Entity:GetBonePosition(headbone)
					modelpanel:SetLookAt(headpos)
					modelpanel:SetCamPos(headpos-Vector(-16,0,0))
					modelpanel.Entity:SetEyeTarget(headpos-Vector(-15, 0, 0))

				end

			end
			

		end

		if lasthp && LocalPlayer():Health() < lasthp then

			lhp = hp
			lhpr = lasthpr
			timer.Create("LerpHP", 2.001, 1, function() end)
			timer.Start("LerpHP")


		elseif timer.Exists("LerpHP") then

			frac = Lerp(1 - (timer.TimeLeft("LerpHP") / 2.001), lhpr, lhp)
			alphafrac = Lerp(1 - (timer.TimeLeft("LerpHP") / 2.001), 255, 0)
			DrawBar(8, 50+pad+2+baroffset, h-pad-50+2, 246*hp_lenmod*frac, 16, ddd, false, 0, "inverted") -- HP DDD Bar
			draw.SimpleTextOutlined((lhp * maxhp) - (lhpr * maxhp), font_default, 50+pad+256+baroffset*1.05+hp_lenmod*30, h-pad-50+2+font_hOffset, Color(255,255,255,alphafrac), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,alphafrac)) -- HP DIN

		end

		DrawBar(8, 50+pad+2+baroffset, h-pad-50+2, 246*hp_lenmod*hp, 16, red, false, 0, "inverted")

		draw.DrawText(tostring(nice_number(1, LocalPlayer():Health())), font_default, 50+pad+15+baroffset, h-pad-50+2.33+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_LEFT) -- HP Text

		if LocalPlayer():Armor() != 0 or GetConVar("visage_style"):GetInt() == 4 then

			DrawBar(8, 50+pad+baroffset, h-pad*2-50-5, 250, 20, gray, false, 2) -- Armor Bar background

		end

		if lastsuit && LocalPlayer():Armor() < lastsuit then

			local i = 0
			lst = arm
			lstr = lastsuitr
			timer.Create("LerpARM", 2.001, 1, function() end)
			timer.Start("LerpARM")


		elseif timer.Exists("LerpARM") then

			frac = Lerp(1 - (timer.TimeLeft("LerpARM") / 2.001), lstr, lst)
			alphafrac = Lerp(1 - (timer.TimeLeft("LerpARM") / 2.001), 255, 0)
			DrawBar(8, 50+pad+2+baroffset, h-pad*2-50+2-5, 246*frac, 16, ddd) -- Armor DDD
			draw.SimpleTextOutlined((lst * 255) - (lstr * 255), font_default, 50+pad+256+baroffset*1.05, h-pad*2-50+2.33-5+font_hOffset, Color(255,255,255,alphafrac), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,alphafrac)) -- Armor DIN

		end

		if LocalPlayer():Armor() != 0 then

			DrawBar(8, 50+pad+2+baroffset, h-pad*2-50+2-5, 246*arm, 16, blue) -- Armor bar
			draw.DrawText(tostring(nice_number(1, LocalPlayer():Armor())), font_default, 50+pad+15+baroffset, h-pad*2-50+2.33-5+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_LEFT) -- Armor Text

		end

		DrawBar(8, w-pad-280, h-pad-70, 248, 50, gray, true, 2) -- Weapon background
		lasthp = LocalPlayer():Health()
		lastsuit = LocalPlayer():Armor()
		local wep = LocalPlayer():GetActiveWeapon()
		local clip = nil
		local ammo = nil
		local ammo2 = nil

		if !IsValid(wep) then

			clip = -1
			ammo = 0
			ammo2 = 0

		else

			clip = wep:Clip1()
			ammo = LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType())
			ammo2 = LocalPlayer():GetAmmoCount(wep:GetSecondaryAmmoType())

		end



		if clip > -1 then

			draw.SimpleTextOutlined(clip .. "/" .. ammo, font_big, w-pad-160, h-pad-70-font_hOffset*1.1, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1.5, Color(0,0,0))

			if ammo2 > 0 then

				draw.SimpleTextOutlined("(" .. ammo2 .. ")", font_big, w-pad-80, h-pad-70+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1.5, Color(0,0,0))

			end

			draw.SimpleTextOutlined(wep:GetPrintName(), font_default, w-pad-160, h-pad-38+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0,0,0))

		elseif IsValid(wep) then

			draw.SimpleTextOutlined(wep:GetPrintName(), font_big, w-pad-160, h-pad-59+font_hOffset, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1.5, Color(0,0,0))

		end

	end)

end

print("[heliOS] VisageHUD Loaded!")