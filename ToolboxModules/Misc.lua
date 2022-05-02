-- Anything that doesn't deserve it's own dedicated module will go here to avoid clutter

Misc = {
    AimKey = gui.GetValue("aim key"),
    AutoShoot = gui.GetValue("auto shoot"),
    ShouldBackupMelee = true
}

function AutoMelee(pLocal, Vars)
    if (ShouldBackupMelee) then
        Misc.AimKey = gui.GetValue("aim key")
        Misc.AutoShoot = gui.GetValue("auto shoot")
    end

     local pWeapon = pLocal:GetPropEntity( "m_hActiveWeapon" )
     if (pLocal:IsAlive() and Vars.Misc.AutoMelee:GetValue() and pWeapon:IsMeleeWeapon()) then
        ShouldBackupMelee = false
        gui.SetValue("aim key", 0)
        gui.SetValue("auto shoot", 1)
    else
        if (not(ShouldBackupMelee)) then
            gui.SetValue("aim key", Misc.AimKey)
            gui.SetValue("auto shoot", Misc.AutoShoot)
            ShouldBackupMelee = true
        end
    end
end

function Misc.OnCreateMove(pLocal, Vars)
    AutoMelee(pLocal, Vars)
end

function Misc.OnDraw(Vars)
    local VMString =  Vars.Visuals.ViewmodelX:GetValue()  .. " " .. Vars.Visuals.ViewmodelY:GetValue()  .. " " .. Vars.Visuals.ViewmodelZ:GetValue() 
    local VMSway = (Vars.Visuals.ViewmodelSway:GetValue()  / 1000)

    if (client.GetConVar("tf_viewmodels_offset_override") ~= VMString) then client.SetConVar( "tf_viewmodels_offset_override", VMString) end
    if (client.GetConVar("cl_wpn_sway_interp") ~= VMSway) then client.SetConVar( "cl_wpn_sway_interp", VMSway) end -- love u spook c: https://www.unknowncheats.me/forum/3290406-post6.html
end

function Misc.OnUnload()
    gui.SetValue("aim key", Misc.AimKey)
    gui.SetValue("auto shoot", Misc.AutoShoot)

    client.SetConVar( "tf_viewmodels_offset_override", "0 0 0")
    client.SetConVar( "cl_wpn_sway_interp", 0)
end

print("Loaded Misc Module")

return Misc