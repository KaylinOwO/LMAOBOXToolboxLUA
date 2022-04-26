
client.RemoveConVarProtection( "tf_viewmodels_offset_override")
client.RemoveConVarProtection( "cl_wpn_sway_interp")

------------------------------------------------ VARIABLES ------------------------------------------------

-- Vars --

local PlayerChams = 1   
local HandChams = 2
local IgnoreZ = false
local AutoMelee = true
local ViewmodelX = 12
local ViewmodelY = 7
local ViewmodelZ = -4
local ViewmodelSway = 75

-- Other -- 
local TahomaBold = draw.CreateFont("Tahoma Bold", 14, 700 , FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW)
local MenuSelection = 0
local CurrentFPS = 0
local ServerTicks = 0
local PlayerPing = 0
local ShouldBackupMelee = true
local AimKey = 0
local AutoShoot = 0

------------------------------------------------ VARIABLES ------------------------------------------------

------------------------------------------------ ENTITY CACHE ------------------------------------------------

local CMoveEntities = {}
local DrawEntities = {}

local function CacheEntities(Entities) -- Unsure if caching entities has any form of performance benefit in this case but it's definitely more efficient coding wise :D
    local players = entities.FindByClass("CTFPlayer")
    for k, pPlayer in pairs(players) do
        if (not(pPlayer:IsValid() and not(pPlayer:IsDormant()) and pPlayer:IsAlive())) then goto continue end

        table.insert(Entities, pPlayer)

        ::continue::
    end
end

local function ClearCachedEntities(Entities)
    for k,v in pairs(Entities) do Entities[k] = nil end
end

------------------------------------------------ ENTITY CACHE ------------------------------------------------

------------------------------------------------ CHAMS ------------------------------------------------

NitroMaterial = materials.Create( "NitroMaterial", [["VertexLitGeneric"
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
    $envmaptint "[ 0 0 0 ]"
    $selfillumtint "[ 0.03 0.03 0.03 ]"
    
}
]])

ShineMaterial = materials.Create( "ShineMaterial", [["VertexLitGeneric"
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

NitroMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, IgnoreZ )
ShineMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, IgnoreZ )

local IgnoreZSet = false 
local function CallChams(pLocal, DrawModelContext)
    local pEntity = DrawModelContext:GetEntity()
    if (pEntity and pEntity:IsValid() and not(pEntity:IsDormant())) then
        if (not(IgnoreZSet == IgnoreZ)) then 
            NitroMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, IgnoreZ )
            ShineMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, IgnoreZ )
            IgnoreZSet = IgnoreZ
        end

        NitroMaterial:SetShaderParam( "$envmaptint", (pEntity:GetTeamNumber() == 3 and Vector3(0.05, 0.05, 1) or Vector3(1, 0.05, 0.05)))
        ShineMaterial:SetShaderParam( "$color2", (pEntity:GetTeamNumber() == 3 and Vector3(0.05, 0.05, 1) or Vector3(1, 0.05, 0.05)))

        if (HandChams > 0 and pEntity:GetClass() == "CTFViewModel") then
            DrawModelContext:ForcedMaterialOverride ( (HandChams == 2) and ShineMaterial or NitroMaterial ) 
        end

        if (PlayerChams > 0 and (pEntity == pLocal or (pEntity:GetTeamNumber() ~= pLocal:GetTeamNumber()))) then
            if ( (pEntity:IsPlayer() and pEntity:IsAlive()) or pEntity:IsWeapon()) then
                gui.SetValue("colored players", 0)
                DrawModelContext:ForcedMaterialOverride ( (PlayerChams == 2) and ShineMaterial or NitroMaterial ) 
            end
        end


    end   
end

------------------------------------------------ CHAMS ------------------------------------------------

------------------------------------------------ MISC ------------------------------------------------

local function CallAutoMelee(pLocal)
    if (not(AutoMelee)) then
        if ( AutoShoot ~= gui.GetValue("auto shoot") ) then
            gui.SetValue("aim key", AimKey)
            gui.SetValue("auto shoot", AutoShoot)

            AimKey = gui.GetValue("aim key")
            AutoShoot = gui.GetValue("auto shoot")
        end
        return 
    end
    
    if (ShouldBackupMelee) then
         AimKey = gui.GetValue("aim key")
         AutoShoot = gui.GetValue("auto shoot")
    end

     local pWeapon = pLocal:GetPropEntity( "m_hActiveWeapon" )
     if (pWeapon and pWeapon:IsValid()) then
         if (pWeapon:IsMeleeWeapon()) then
             ShouldBackupMelee = false
             gui.SetValue("aim key", 0)
             gui.SetValue("auto shoot", 1)
         else
             if (not(ShouldBackupMelee)) then
                 gui.SetValue("aim key", AimKey)
                 gui.SetValue("auto shoot", AutoShoot)
                 ShouldBackupMelee = true
             end
         end
     end
end

------------------------------------------------ MISC ------------------------------------------------

------------------------------------------------ MENU ------------------------------------------------

WHITE = {R = 255, G = 255, B = 255, A = 255}
BLUE = {R = 30, G = 144, B = 255, A = 255}
YELLOW = {R = 255, G = 255, B = 0, A = 255}

local function ButtonReleased(button) -- Can't believe I had to paste this shit lmaooo. c: https://github.com/lnx00/Lmaobox-LUA/blob/7f0c6296f6a0aba8a1c04e5b43cf956bf2b994d7/FreeMenu.lua#L55
    if input.IsButtonDown(button) and button ~= LastButton then
        LastButton = button
        AnyButtonDown = true
    end

    if input.IsButtonDown(button) == false and button == LastButton then
        LastButton = 0
        AnyButtonDown = false
        return true
    end

    if AnyButtonDown == false then
        LastButton = 0
    end

    return false
end

local function ChamsType(ChamVar)

    if (ChamVar == 1) then
        return "NITRO"
    elseif (ChamVar == 2) then
        return "SHINE"
    end

    return "OFF"
end

local function Text(x, y, string, color)
    draw.SetFont(TahomaBold)
    draw.Color(color.R, color.G, color.B, color.A) 
    draw.Text(x, y, string)
end

local function Menu()
    local iY = 0
    local MenuOptions = 0
    local Multiplier = 15 

    Text(20, 55 + 5, "Callie's Toolbox", {R = 213, G = 119, B = 123, A = 255});

    Text(300, 20, "Hello Callie :)", YELLOW);
    Text(300, 35, "Hello ReD :)", YELLOW);
	
	Text(450, 65, "FrameRate:  " .. CurrentFPS .."",  WHITE);
	Text(450, 80, "Ticks:  " .. ServerTicks .."",  WHITE);
	Text(450, 95, "Ping:  " .. PlayerPing .."",  WHITE);
  
    iY = 60;

    Text(300, iY + 5, ((MenuSelection <= MenuOptions) and ">> Plyr Chams:" or "Plyr Chams:"), WHITE);
    Text(400, 50 + (Multiplier), ChamsType(PlayerChams), (PlayerChams > 0) and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> VM Chams:" or "VM Chams:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)), ChamsType(HandChams), (HandChams > 0) and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> IgnoreZ:" or "IgnoreZ:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)), IgnoreZ and "ON" or "OFF", IgnoreZ and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> VM X:" or "VM X:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)), tostring(ViewmodelX), not(ViewmodelX == 0) and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> VM Y:" or "VM Y:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)), tostring(ViewmodelY), not(ViewmodelY == 0) and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> VM Z:" or "VM Z:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)), tostring(ViewmodelZ), not(ViewmodelZ == 0) and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> VM Sway:" or "VM Sway:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)), tostring(ViewmodelSway), not(ViewmodelSway == 0) and BLUE or WHITE);

    MenuOptions = MenuOptions + 1; iY = iY + 15;

    Text(300, iY + 5, ((MenuSelection == MenuOptions) and ">> Auto Melee:" or "Auto Melee:"), WHITE);
    Text(400, 50 + (Multiplier * (MenuOptions + 1)),    AutoMelee  and "ON" or "OFF", AutoMelee and BLUE or WHITE);

    if (ButtonReleased(KEY_UP)) then MenuSelection = MenuSelection - 1 elseif (ButtonReleased(KEY_DOWN)) then MenuSelection = MenuSelection + 1; end
    if (MenuSelection == 0) then if (ButtonReleased(KEY_LEFT)) then PlayerChams = PlayerChams - 1 elseif (ButtonReleased(KEY_RIGHT)) then PlayerChams = PlayerChams + 1; end end
    if (MenuSelection == 1) then if (ButtonReleased(KEY_LEFT)) then HandChams = HandChams - 1 elseif (ButtonReleased(KEY_RIGHT)) then HandChams = HandChams + 1; end end
    if (MenuSelection == 2) then if (ButtonReleased(KEY_LEFT)) then IgnoreZ = false elseif (ButtonReleased(KEY_RIGHT)) then IgnoreZ = true; end end
    if (MenuSelection == 3) then if (ButtonReleased(KEY_LEFT)) then ViewmodelX = ViewmodelX - 1 elseif (ButtonReleased(KEY_RIGHT)) then ViewmodelX = ViewmodelX + 1; end end
    if (MenuSelection == 4) then if (ButtonReleased(KEY_LEFT)) then ViewmodelY = ViewmodelY - 1 elseif (ButtonReleased(KEY_RIGHT)) then ViewmodelY = ViewmodelY + 1; end end
    if (MenuSelection == 5) then if (ButtonReleased(KEY_LEFT)) then ViewmodelZ = ViewmodelZ - 1 elseif (ButtonReleased(KEY_RIGHT)) then ViewmodelZ = ViewmodelZ + 1; end end
    if (MenuSelection == 6) then if (ButtonReleased(KEY_LEFT)) then ViewmodelSway = ViewmodelSway - 1 elseif (ButtonReleased(KEY_RIGHT)) then ViewmodelSway = ViewmodelSway + 1; end end
    if (MenuSelection == 7) then if (ButtonReleased(KEY_LEFT)) then AutoMelee = false elseif (ButtonReleased(KEY_RIGHT)) then AutoMelee = true; end end

    if (MenuSelection > MenuOptions) then MenuSelection = 0 elseif (MenuSelection < 0) then MenuSelection = MenuOptions end
    if (PlayerChams > 2) then PlayerChams = 0 elseif (PlayerChams < 0) then PlayerChams = 2 end
    if (HandChams > 2) then HandChams = 0 elseif (HandChams < 0) then HandChams = 2 end
    if (ViewmodelX > 20) then ViewmodelX = -20 elseif (ViewmodelX < -20) then ViewmodelX = 20 end
    if (ViewmodelY > 20) then ViewmodelY = -20 elseif (ViewmodelY < -20) then ViewmodelY = 20 end
    if (ViewmodelZ > 20) then ViewmodelZ = -20 elseif (ViewmodelZ < -20) then ViewmodelZ = 20 end
    if (ViewmodelSway > 100) then ViewmodelSway = 0 elseif (ViewmodelSway < 0) then ViewmodelSway = 100 end
end

------------------------------------------------ MENU ------------------------------------------------

------------------------------------------------ CALLBACKS ------------------------------------------------

local function CreateMoveFunctions(pCmd)

    local pLocal = entities.GetLocalPlayer();
    if (not(pLocal and pLocal:IsValid() and not(pLocal:IsDormant()) and pLocal:IsAlive())) then
        if ( AutoShoot ~= gui.GetValue("auto shoot") ) then
            gui.SetValue("aim key", AimKey)
            gui.SetValue("auto shoot", AutoShoot)

            AimKey = gui.GetValue("aim key")
            AutoShoot = gui.GetValue("auto shoot")
        end
        return 
    end

    CurrentFPS = math.floor(1 / globals.FrameTime())
    ServerTicks = math.floor(1 / globals.TickInterval())
    PlayerPing = math.floor(clientstate.GetLatencyOut() * 1000)

    CacheEntities(CMoveEntities)

    --[[ Example usage of Entity Cache
        for k,v in pairs(CMoveEntities) do
            local pEntity = CMoveEntities[k]
            print(pEntity:GetName() .. " has " .. pEntity:GetHealth() .. "HP")
        end
    --]]

    ClearCachedEntities(CMoveEntities)

    CallAutoMelee(pLocal)

    local VMString =  ViewmodelX .. " " .. ViewmodelY .. " " .. ViewmodelZ 
    local VMSway = (ViewmodelSway / 1000)

    if (client.GetConVar("tf_viewmodels_offset_override") ~= VMString) then client.SetConVar( "tf_viewmodels_offset_override", VMString) end
    if (client.GetConVar("cl_wpn_sway_interp") ~= VMSway) then client.SetConVar( "cl_wpn_sway_interp", VMSway) end -- love u spook c: https://www.unknowncheats.me/forum/3290406-post6.html
end

local function OnDrawModel( DrawModelContext )
    local pLocal = entities.GetLocalPlayer();
    if (not(pLocal and pLocal:IsValid() and not(pLocal:IsDormant()) and pLocal:IsAlive())) then return end

    CallChams(pLocal, DrawModelContext)
end

local function DrawFunctions()
    local pLocal = entities.GetLocalPlayer();

    Menu(pLocal)

    if (not(pLocal and pLocal:IsValid() and not(pLocal:IsDormant()))) then return end

    CacheEntities(DrawEntities)



    ClearCachedEntities(DrawEntities)
end

local function Unload() -- Let's make sure we don't cause problems for the user on unload :D
    gui.SetValue("aim key", AimKey)
    gui.SetValue("auto shoot", AutoShoot)

    client.SetConVar( "tf_viewmodels_offset_override", "0 0 0" )
    client.SetConVar( "cl_wpn_sway_interp", 0)
end

callbacks.Unregister("CreateMove", "Toolbox_CreateMove") 
callbacks.Register("CreateMove", "Toolbox_CreateMove", CreateMoveFunctions)

callbacks.Unregister("Draw", "Toolbox_Draw")
callbacks.Register("Draw", "Toolbox_Draw", DrawFunctions)

callbacks.Unregister("DrawModel", "Toolbox_DrawModel")
callbacks.Register( "DrawModel", "Toolbox_DrawModel", OnDrawModel )

callbacks.Unregister("Unload", "Toolbox_Unload") 
callbacks.Register("Unload", "Toolbox_Unload", Unload)

------------------------------------------------ CALLBACKS ------------------------------------------------
