local Lax = {}
Lax.__index = Lax

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

function Lax.new(template)
    if not template then template = "" end
    return setmetatable({template = template, context = {}, partials = {}}, Lax)
end

function Lax:set(key, value) 
    self.context[key] = value
    return self 
end

function Lax:partial(name, content) 
    self.partials[name] = content
    return self 
end

function Lax:resolve_var(path)
    local val = self.context
    for part in path:gmatch("[^%.]+") do
        if type(val) == "table" then
            val = val[part]
        else
            return nil
        end
    end
    return val
end

function Lax:render()
    local output = self.template or ""
    
    -- 1. Cek @layout
    local layout_name = nil
    output = output:gsub("@layout%((.-)%)", function(name)
        layout_name = name:gsub('"', ''):gsub("'", ""):gsub("^%s*(.-)%s*$", "%1")
        return ""
    end)
    
    -- 2. Include
    output = output:gsub("@include%((.-)%)", function(n)
        local name = n:gsub('"', ''):gsub("'", ""):gsub("^%s*(.-)%s*$", "%1")
        return self.partials[name] or ""
    end)
    
    -- 3. If Block
    output = output:gsub("@if%s+(.-)\r?\n(.-)@end", function(v, b)
        local val = self:resolve_var(v)
        return (val and val ~= "" and val ~= false) and b or ""
    end)
    
    -- 4. For Block
    output = output:gsub("@for%s+(.-)\r?\n(.-)@end", function(path, block)
        local list = self:resolve_var(path)
        if type(list) ~= "table" then return "" end
        
        local result = ""
        for _, item in ipairs(list) do
            local row = block
            row = row:gsub("@([%w_]+)", function(prop)
                if type(item) == "table" then
                    return tostring(item[prop] or "")
                else
                    return tostring(item or "")
                end
            end)
            result = result .. row
        end
        return result
    end)
    
    -- 5. Variables
    output = output:gsub("@([%w_%.]+)", function(v)
        if v == "os.date" then return os.date("%Y") end
        
        local val = self:resolve_var(v)
        if val ~= nil then
            if type(val) == "table" then
                return ""
            end
            return tostring(val)
        end
        return ""
    end)
    
    -- 6. Render dengan layout
    if layout_name then
        local layout_paths = {
            "templates/layouts/" .. layout_name,
            "templates/layouts/" .. layout_name .. ".lax",
        }
        
        local layout = nil
        for _, path in ipairs(layout_paths) do
            layout = read_file(path)
            if layout then break end
        end
        
        if layout then
            local engine = Lax.new(layout)
            for k, v in pairs(self.context) do 
                engine:set(k, v) 
            end
            engine:set("content", output)
            for name, content in pairs(self.partials) do 
                engine:partial(name, content) 
            end
            return engine:render()
        end
    end
    
    return output
end

return Lax