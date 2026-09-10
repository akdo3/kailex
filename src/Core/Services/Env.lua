return function(ctx)
    local I = ctx.Internal

    pcall(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
    end)

    local Players          = game:GetService("Players")
    local CoreGui          = game:GetService("CoreGui")
    local GuiService       = game:GetService("GuiService")
    local SoundService     = game:GetService("SoundService")
    local TextService      = game:GetService("TextService")
    local TweenService     = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService       = game:GetService("RunService")
    local HttpService      = game:GetService("HttpService")
    local Workspace        = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer

    local Device = {}
    do
        local touch = UserInputService.TouchEnabled
        local mouse = UserInputService.MouseEnabled
        Device.IsTouch   = touch and not mouse
        Device.IsDesktop = mouse
        Device.IsConsole = false
        pcall(function() Device.IsConsole = GuiService:IsTenFootInterface() end)
    end

    local ROW_H = Device.IsTouch and 40 or 32

    local function Getgenv()
        local ok, g = pcall(function() return getgenv end)
        if ok and type(g) == "function" then
            local ok2, res = pcall(g)
            if ok2 and type(res) == "table" then return res end
        end
        return nil
    end

    local genv = Getgenv()
    if genv and genv.kailex then
        pcall(function() genv.kailex:Unload() end)
        genv.kailex = nil
    end

    local HasFileSystem = type(isfile) == "function" and type(writefile) == "function"
    local fs = {
        isfolder  = isfolder  or function() return false end,
        makefolder= makefolder or function() end,
        writefile = writefile or function() end,
        readfile  = readfile  or function() return "{}" end,
        isfile    = isfile    or function() return false end,
        delfile   = delfile or removefile or function() end,
        listfiles = listfiles or function() return {} end,
    }

    local SafeParent = (function()
        local ok, ui = pcall(function() return (gethui and gethui()) end)
        if ok and ui then return ui end
        local ok2, cg = pcall(function() return CoreGui end)
        if ok2 and cg then
            local test = Instance.new("Frame")
            local okSet = pcall(function() test.Parent = cg end)
            test:Destroy()
            if okSet then return cg end
        end
        if LocalPlayer then
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then return pg end
        end
        return game
    end)()

    local protect_gui = function() end
    do
        local ok, pg = pcall(function() return protectgui end)
        if ok and type(pg) == "function" then
            protect_gui = pg
        else
            local ok2, syn = pcall(function() return syn end)
            if ok2 and type(syn) == "table" and type(syn.protect_gui) == "function" then
                protect_gui = syn.protect_gui
            end
        end
    end

    I.Players = Players
    I.SoundService = SoundService
    I.TextService = TextService
    I.TweenService = TweenService
    I.UserInputService = UserInputService
    I.RunService = RunService
    I.HttpService = HttpService
    I.Workspace = Workspace
    I.LocalPlayer = LocalPlayer
    I.Device = Device
    I.ROW_H = ROW_H
    I.Getgenv = Getgenv
    I.HasFileSystem = HasFileSystem
    I.fs = fs
    I.SafeParent = SafeParent
    I.protect_gui = protect_gui
end
