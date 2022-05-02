CritIndicator = {
    Font = draw.CreateFont("Tahoma", 14, 700, FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW)
}

function CritIndicator.OnDraw(pLocal, Vars)
    if (not(pLocal)) then return end

    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if pLocal:IsAlive() and pWeapon then
        draw.SetFont(CritIndicator.Font)

        local DamageStats = pWeapon:GetWeaponDamageStats()
        local CritChance = pWeapon:GetCritChance() + 0.1
        local Damage = ((DamageStats["critical"] * (2.0 * CritChance + 1.0)) / CritChance / 3.0) - DamageStats["total"]
        local CanCrit = CritChance > pWeapon:CalcObservedCritChance() 

        local ScrW, ScrH = draw.GetScreenSize()
        local MidW = ScrW / 2
        local MidH = ScrH / 2

        local CritText = CanCrit and "Crit Ready" or "Crit Banned"
        local TxtW, TxtH = draw.GetTextSize(CritText);

        local DamageTxt = "Deal " .. math.floor(Damage) .. " damage"
        local DmgTxtW, DmgTxtH = draw.GetTextSize(DamageTxt);
        
        if CanCrit then 
            draw.Color(59, 206, 58, 255) 
            draw.Text( MidW - (TxtW / 2), MidH + TxtH + 24, CritText)
        else 
            draw.Color(235, 123, 107, 255)
            draw.Text( MidW - (TxtW / 2), MidH + TxtH - DmgTxtH + 24, CritText)
            draw.Color(255, 255, 255, 255)
            draw.Text(MidW - (DmgTxtW / 2), MidH + DmgTxtH + 24, DamageTxt)
        end
    end
end

print("Loaded CritIndicator Module")

return CritIndicator