-----------------
--  SET OWNER  --
-----------------

-- SET OWNER OF TOOL-ENTS
if cleanup then

	function cleanup.Add( ply, enttype, ent )
		
		if ply.duplicate == true then
			if enttype != "duplicates" then
				ply.duplicate = false
			end
		end

		if IsEntity(ent) == false or ent:IsPlayer() then return end
		ent:CPPISetOwner(ply)

	end

end



--------------------
--  CHECK PLAYER  --
--------------------

-- CHECK ADMIN FUNCTION
function sv_PProtect.checkAdmin( ply )

	if sv_PProtect.Settings.PropProtection["use"] == false or ply:IsSuperAdmin() then return true end
	if ply:IsAdmin() and sv_PProtect.Settings.PropProtection["noantiadmin"] == true then return true end

end

-- GENERAL CHECK-PLAYER FUNCTION
function sv_PProtect.checkPlayer( ply, ent )

	if sv_PProtect.checkAdmin( ply ) then return true end

	local Owner = ent:CPPIGetOwner()

	if Owner == nil then return false end

	if !ent:IsWorld() and Owner == ply then
		return true
	else
		sv_PProtect.Notify( ply, "You are not allowed to do this!" )
		return false
	end

end
hook.Add( "PhysgunPickup", "AllowPhysPickup", sv_PProtect.checkPlayer )
hook.Add( "GravGunOnPickedUp", "AllowGravPickup", sv_PProtect.checkPlayer )
hook.Add( "CanDrive", "AllowDriving", sv_PProtect.checkPlayer )
hook.Add( "CanUse", "AllowUseing", sv_PProtect.checkPlayer )



----------------------------
--  TOOL PROP PROTECTION  --
----------------------------

function sv_PProtect.canToolProtection( ply, trace, tool )
	
	if sv_PProtect.checkAdmin( ply ) then return true end
	if tool == "creator" and sv_PProtect.Settings.PropProtection["blockcreatortool"] == true then return end

	local ent = trace.Entity
	if not ent:IsValid() and not ent:IsWorld() then return end

	local Owner = ent:CPPIGetOwner()
	
	if ent:IsWorld() and sv_PProtect.Settings.PropProtection["tool_world"] == false then return false end
	
	if Owner == ply or ent:IsWorld() then
		return true
	else
		sv_PProtect.Notify( ply, "You are not allowed to do this!" )
		return false
	end
 	
end



--------------------------------
--  PROPERTY PROP PROTECTION  --
--------------------------------

function sv_PProtect.playerProperty( ply, property, ent )

	if sv_PProtect.checkAdmin( ply ) then return true end
	if property == "drive" and sv_PProtect.Settings.PropProtection["cdrive"] == false then return false end

	local Owner = ent:CPPIGetOwner()

	if !ent:IsWorld() and Owner == ply and property != "persist" then
 		return true
 	else
 		sv_PProtect.Notify( ply, "You are not allowed to do this!" )
 		return false
 	end

end
hook.Add( "CanProperty", "AllowProperty", sv_PProtect.playerProperty )



------------------------------
--  DAMAGE PROP PROTECTION  --
------------------------------

function sv_PProtect.EntityDamage( ent, info )
	
	local Owner = ent:CPPIGetOwner()
	local Attacker = info:GetAttacker()

	if !ent:IsValid() or ent:IsPlayer() or sv_PProtect.Settings.PropProtection["use"] == false or sv_PProtect.Settings.PropProtection["damageprotection"] == false then return end

	if Attacker:IsPlayer() and Owner ~= Attacker then
		
		if Attacker:IsSuperAdmin() or Attacker:IsAdmin() and sv_PProtect.Settings.PropProtection["noantiadmin"] == true then return end

		info:SetDamage(0)
		timer.Simple( 0.1, function()
			if ent:IsOnFire() then
				ent:Extinguish()
			end
		end )

	end

end
hook.Add( "EntityTakeDamage", "EntityGetsDamage", sv_PProtect.EntityDamage )



---------------------------------
--  PHYSGUN-RELOAD PROTECTION  --
---------------------------------

function sv_PProtect.PhysgunReload( weapon, ply )
	
	if sv_PProtect.checkAdmin( ply ) then return end
	if sv_PProtect.Settings.PropProtection["reloadprotection"] == false then return false end

	local entity = ply:GetEyeTrace().Entity
	if !entity:IsValid() then return false end

	if ply != entity:CPPIGetOwner() then return false end

end
hook.Add( "OnPhysgunReload", "PhysgunReloading", sv_PProtect.PhysgunReload )



-------------------------------
--  GRAVGUN PUNT PROTECTION  --
-------------------------------

function sv_PProtect.checkPlayer( ply, ent )

	if sv_PProtect.checkAdmin( ply ) then return true end
	if sv_PProtect.Settings.PropProtection["gravgunprotection"] == false then return false end

	if ply != ent:CPPIGetOwner() then return false end

end
hook.Add( "GravGunPunt", "GravgunPunting", sv_PProtect.GravgunPunt )



------------------
--  NETWORKING  --
------------------

-- SET OWNER OVER PROPERTY MENU
net.Receive( "SetOwnerOverProperty", function( len, pl )

	local sentInformation = net.ReadTable()
	local ent = sentInformation[1]
	local Owner = ent:CPPIGetOwner()

	if pl != Owner then return end

	ent:CPPISetOwner( sentInformation[2] )

end )

-- SEND THE OWNER TO THE CLIENT
net.Receive( "getOwner", function( len, pl )
     
	local entity = net.ReadEntity()

	net.Start("sendOwner")
		net.WriteEntity( entity:CPPIGetOwner() )
	net.Send( pl )

end )
