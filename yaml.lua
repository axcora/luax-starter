local yaml = {}

function yaml.parse(content)
    local lines = {}
    for line in content:gmatch("[^\n]+") do
        if not line:match("^%s*#") and line:match("%S") then
            table.insert(lines, {
                text = line,
                indent = line:match("^%s*") and #line:match("^%s*") or 0,
                stripped = line:gsub("^%s*", ""):gsub("%s*$", "")
            })
        end
    end
    
    local function parse_block(start_idx, base_indent)
        local result = {}
        local i = start_idx
        local current_key = nil
        local current_list = nil
        
        while i <= #lines do
            local line = lines[i]
            if line.indent < base_indent then
                break
            end
            
            local stripped = line.stripped
            
            -- Check if it's a list item
            if stripped:match("^- ") then
                local value = stripped:gsub("^- ", "")
                value = value:gsub('"', ''):gsub("'", "")
                
                -- Check if list item contains key:value
                local k, v = value:match("^(.-):%s*(.+)$")
                if k and v then
                    local item = {}
                    k = k:gsub("^%s*(.-)%s*$", "%1")
                    v = v:gsub('"', ''):gsub("'", "")
                    v = v:gsub("^%s*(.-)%s*$", "%1")
                    item[k] = v
                    
                    -- Check for nested content in this list item
                    if i + 1 <= #lines and lines[i+1].indent > line.indent then
                        local nested, next_i = parse_block(i + 1, line.indent + 2)
                        for nk, nv in pairs(nested) do
                            item[nk] = nv
                        end
                        i = next_i - 1
                    end
                    
                    table.insert(result, item)
                else
                    -- Simple list item
                    local item = value
                    
                    -- Check for nested content
                    if i + 1 <= #lines and lines[i+1].indent > line.indent then
                        local nested, next_i = parse_block(i + 1, line.indent + 2)
                        item = nested
                        i = next_i - 1
                    end
                    
                    table.insert(result, item)
                end
            else
                -- Key: value pair
                local key, value = stripped:match("^(.-):%s*(.*)$")
                if key then
                    key = key:gsub("^%s*(.-)%s*$", "%1")
                    value = value:gsub('"', ''):gsub("'", "")
                    value = value:gsub("^%s*(.-)%s*$", "%1")
                    
                    -- Check for nested content (multiline or list)
                    if i + 1 <= #lines and lines[i+1].indent > line.indent then
                        local nested, next_i = parse_block(i + 1, line.indent + 2)
                        
                        -- If nested is a list, use it directly
                        if #nested > 0 and nested[1] and type(nested[1]) == "table" then
                            result[key] = nested
                        else
                            -- Merge nested values
                            if type(result[key]) == "table" then
                                for nk, nv in pairs(nested) do
                                    result[key][nk] = nv
                                end
                            else
                                result[key] = nested
                            end
                        end
                        i = next_i - 1
                    else
                        -- Simple key:value
                        result[key] = value
                    end
                end
            end
            
            i = i + 1
        end
        
        return result, i
    end
    
    local data, _ = parse_block(1, 0)
    return data
end

return yaml