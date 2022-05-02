Chams = {
    Materials = { 
        materials.Create( "NitroMaterial", [["VertexLitGeneric"
        {
            $basetexture "vgui/white_additive"
            $bumpmap "models/player/shared/shared_normal"
            $envmap "skybox/sky_dustbowl_01"
            $envmapfresnel "1"
            $phong "1"
            $phongfresnelranges "[0 0.05 0.1]"
            $selfillum "1"
            $selfillumfresnel "1"
            $selfillumfresnelminmaxexp "[0.4999 0.5 0]"
            $envmaptint "[ 1 0.05 0.05 ]"
            $selfillumtint "[ 0.03 0.03 0.03 ]"
            
        }
        ]]),
    
        materials.Create( "ShineMaterial", [["VertexLitGeneric"
        {
        $basetexture "vgui/white_additive"
        $bumpmap "vgui/white_additive"
        $color2 "[25 0.5 0.5]"
    
        $envmap "cubemaps/cubemap_sheen002"
        $phong "1"
    
    
        $selfillum "1"
        $selfillumfresnel "1"
        $selfillumfresnelminmaxexp "[0.1 0.2 0.3]"
        $selfillumtint "[0 0.3 0.6]"
    
        }
        ]])
    }    
}


local function SetTeamColor(Entity)
    Chams.Materials[1]:SetShaderParam( "$envmaptint", (Entity:GetTeamNumber() == 3 and Vector3(0.05, 0.05, 1) or Vector3(1, 0.05, 0.05)))
    Chams.Materials[2]:SetShaderParam( "$color2", (Entity:GetTeamNumber() == 3 and Vector3(0.05, 0.05, 1) or Vector3(1, 0.05, 0.05)))
end

function Chams.OnDrawModel(pLocal, DrawModelContext, Vars)
    if (Vars.Visuals.PlayerChams:GetSelectedIndex() <= 1 and Vars.Visuals.HandChams:GetSelectedIndex() <= 1) then return end

    if (client.GetConVar("mat_hdr_level") ~= 2) then client.SetConVar( "mat_hdr_level", 2) end

    local pEntity = DrawModelContext:GetEntity()
    if (not(pLocal) or not(pEntity)) then return end

    if Vars.Visuals.HandChams:GetSelectedIndex() > 1 then
        if pEntity:GetClass() == "CTFViewModel" then
            SetTeamColor(pEntity)
            DrawModelContext:ForcedMaterialOverride(Chams.Materials[Vars.Visuals.HandChams:GetSelectedIndex() - 1]) 
        end
    end

    if Vars.Visuals.PlayerChams:GetSelectedIndex() > 1 then
        if pEntity:GetClass() == "CTFWearable" then
            local OwnerEntity = pEntity:GetPropEntity("m_hOwnerEntity")
            if (OwnerEntity and OwnerEntity:GetTeamNumber() ~= pLocal:GetTeamNumber()) then SetTeamColor(OwnerEntity) DrawModelContext:ForcedMaterialOverride(Chams.Materials[Vars.Visuals.Chams:GetSelectedIndex() + 1]) end
        elseif pEntity:GetTeamNumber() ~= pLocal:GetTeamNumber() and (pEntity:IsPlayer() or pEntity:IsWeapon()) then
            SetTeamColor(pEntity)
            DrawModelContext:ForcedMaterialOverride(Chams.Materials[Vars.Visuals.PlayerChams:GetSelectedIndex() - 1]) 
        end
    end
end

print("Loaded Chams Module")

return Chams