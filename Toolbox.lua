local HasFramework,Framework = pcall(require, "ToolboxModules/Menu") 
local HasChams,Chams = pcall(require, "ToolboxModules/Chams") 
local HasMisc,Misc = pcall(require, "ToolboxModules/Misc")
local HasCritIndicator,CritIndicator = pcall(require, "ToolboxModules/CritIndicator")

local function unrequire(m) package.loaded[m] = nil _G[m] = nil end -- stackoverflow :D

if (not(HasFramework)) then print("Menu module missing, failed to load Toolbox!") return end
if (not(HasChams)) then print("Chams module missing, continuing without...") end
if (not(HasMisc)) then print("Misc module missing, continuing without...") end
if (not(HasCritIndicator)) then print("CritIndicator module missing, continuing without...") end

------------------------------------------------------------------------------ VARIABLES ------------------------------------------------------------------------------

local ChamsTypes = {"Disabled", "Nitro", "Shine"}
local pLocal = entities.GetLocalPlayer()

Menu = Framework.Create("LMAOBOX Toolbox")
Vars = {
    Visuals = {
        PlayerChams = HasChams and Menu:AddComponent(Framework.Combo("Player Chams", ChamsTypes)) or 0,
        HandChams =  HasChams and Menu:AddComponent(Framework.Combo("Hand Chams", ChamsTypes)) or 0,
        ViewmodelX = HasMisc and Menu:AddComponent(Framework.Slider("Viewmodel X", -50, 50, 0)) or 0,
        ViewmodelY = HasMisc and Menu:AddComponent(Framework.Slider("Viewmodel Y", -50, 50, 0)) or 0,
        ViewmodelZ = HasMisc and Menu:AddComponent(Framework.Slider("Viewmodel Z", -50, 50, 0)) or 0,
        ViewmodelSway = HasMisc and Menu:AddComponent(Framework.Slider("Viewmodel Sway", 0, 100, 0)) or 0
    },

    Misc = {
        AutoMelee = HasMisc and Menu:AddComponent(Framework.Checkbox("Auto Melee", true)) or false,
        CritIndicatorToggle = HasCritIndicator and Menu:AddComponent(Framework.Checkbox("Crit Indicator", true)) or false
    }
}

------------------------------------------------------------------------------ VARIABLES ------------------------------------------------------------------------------

------------------------------------------------------------------------------ CALLBACKS ------------------------------------------------------------------------------

local function CreateMoveFunctions(pCmd)
    pLocal = entities.GetLocalPlayer() -- I assume this is more performant than calling it a billion times across multiple functions/callbacks, if not then please tell me :D

    if HasMisc then Misc.OnCreateMove(pLocal, Vars) end
end

local function OnDrawModel( DrawModelContext )
    if HasChams then Chams.OnDrawModel(pLocal, DrawModelContext, Vars) end
end


local function DrawFunctions()
    if HasMisc then Misc.OnDraw(Vars) end
    if HasCritIndicator then CritIndicator.OnDraw(pLocal, Vars) end
end

local function OnUnload() 
    Framework.RemoveMenu(Menu)

    unrequire("ToolboxModules/Menu")
    if HasChams then unrequire("ToolboxModules/Chams") end
    if HasMisc then Misc.OnUnload() unrequire("ToolboxModules/Misc") end
    if HasCritIndicator then unrequire("ToolboxModules/CritIndicator") end
end

------------------------------------------------------------------------------ CALLBACKS ------------------------------------------------------------------------------

callbacks.Unregister("CreateMove", "Toolbox_CreateMove") 
callbacks.Register("CreateMove", "Toolbox_CreateMove", CreateMoveFunctions)

callbacks.Unregister("Draw", "Toolbox_Draw")
callbacks.Register("Draw", "Toolbox_Draw", DrawFunctions)

callbacks.Unregister("DrawModel", "Toolbox_DrawModel")
callbacks.Register( "DrawModel", "Toolbox_DrawModel", OnDrawModel )

callbacks.Unregister("Unload", "Toolbox_Unload") 
callbacks.Register("Unload", "Toolbox_Unload", OnUnload)