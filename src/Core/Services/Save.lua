return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local HttpService = I.HttpService
    local Setting = I.Setting
    local fs = I.fs
    local HasFileSystem = I.HasFileSystem

    local SaveManager = {
        Folder = Setting.SaveFolder,
        File   = tostring(game.PlaceId) .. ".json",
        Data   = {},
        Delay  = 1,
    }
    SaveManager.DataChanged = I.Signal.new()

    do
        if HasFileSystem then
            pcall(fs.makefolder, SaveManager.Folder)
            local path = SaveManager.Folder .. "/" .. SaveManager.File
            if fs.isfile(path) then
                local ok, res = pcall(function()
                    return HttpService:JSONDecode(fs.readfile(path))
                end)
                if ok and type(res) == "table" then
                    SaveManager.Data = res
                else
                    local ok2, res2 = pcall(function()
                        return HttpService:JSONDecode(fs.readfile(path .. ".bak"))
                    end)
                    if ok2 and type(res2) == "table" then SaveManager.Data = res2 end
                end
            end
        end
    end

    local function IsInternalKey(key)
        return type(key) == "string" and key:sub(1, 2) == "__"
    end

    function SaveManager:Set(key, value)
        if self.Data[key] == value then return end
        self.Data[key] = value
        if not Setting.AutoSave then return end
        if self._pending then return end
        self._pending = true
        task.delay(self.Delay, function()
            self._pending = false
            self:Flush()
        end)
    end

    function SaveManager:Flush()
        if not HasFileSystem then return end
        local ok, err = pcall(function()
            local path = self.Folder .. "/" .. self.File
            if fs.isfile(path) then
                pcall(function() fs.writefile(path .. ".bak", fs.readfile(path)) end)
            end
            fs.writefile(path, HttpService:JSONEncode(self.Data))
        end)
        if not ok then warn("[Kailex] save failed: " .. tostring(err)) end
    end

    function SaveManager:Get(key, default)
        local v = self.Data[key]
        if v == nil then return default end
        if default ~= nil and typeof(v) ~= typeof(default) then return default end
        return v
    end

    function SaveManager:Clear()
        self.Data = {}
        self:Flush()
        self.DataChanged:Fire()
    end

    local function SaveValue(key, value)
        if key then SaveManager:Set(key, value) end
    end

    local Configs = { Folder = SaveManager.Folder .. "/Profiles" }

    function Configs:Path(name)
        return self.Folder .. "/" .. I.Sanitize(name) .. ".json"
    end

    function Configs:List()
        if not HasFileSystem then return {} end
        local names = {}
        local ok, files = pcall(fs.listfiles, self.Folder)
        if ok and type(files) == "table" then
            for _, f in ipairs(files) do
                local name = tostring(f):match("([^/\\]+)%.json$")
                if name then table.insert(names, name) end
            end
        end
        table.sort(names)
        return names
    end

    function Configs:Save(name)
        if not HasFileSystem or not name or name == "" then return false end
        pcall(fs.makefolder, self.Folder)
        return pcall(function()
            local export = {}
            for k, v in pairs(SaveManager.Data) do
                if not IsInternalKey(k) then export[k] = v end
            end
            fs.writefile(self:Path(name), HttpService:JSONEncode(export))
        end)
    end

    function Configs:Load(name)
        if not HasFileSystem or not name then return false end
        local ok, res = pcall(function()
            return HttpService:JSONDecode(fs.readfile(self:Path(name)))
        end)
        if ok and type(res) == "table" then
            local merged = {}
            for k, v in pairs(res) do merged[k] = v end
            for k, v in pairs(SaveManager.Data) do
                if IsInternalKey(k) then merged[k] = v end
            end
            SaveManager.Data = merged
            SaveManager:Flush()
            SaveManager.DataChanged:Fire()
            return true
        end
        return false
    end

    function Configs:Delete(name)
        if not HasFileSystem or not name then return false end
        return pcall(fs.delfile, self:Path(name))
    end

    local SaveReloadRegistry = {}
    I.SaveReloadRegistry = SaveReloadRegistry

    I.LibMaid:Give(SaveManager.DataChanged:Connect(function()
        for key, fns in pairs(SaveReloadRegistry) do
            local n = #fns
            if n > 0 then
                local v = SaveManager:Get(key, nil)
                if v ~= nil then
                    for i = 1, n do I.SafeCall(fns[i], v) end
                end
            end
        end
    end))

    I.SaveManager = SaveManager
    I.Configs = Configs
    Kailex.Configs = Configs
    I.SaveValue = SaveValue
    I.IsInternalKey = IsInternalKey
end
