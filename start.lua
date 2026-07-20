-- start.lua - Universal HTTP Server (CMD + Python/PHP)
print("========================================")
print("   🌐 LUAX SERVER")
print("========================================")
print()

local port = 8080
print("🚀 Server at http://localhost:" .. port)
print("📁 Serving: dist/")
print("Press Ctrl+C to stop")
print()
print("========================================")
print("Read Docs https://luax.axcora.com")
print("========================================")
print()
-- ============================================================
-- OPEN BROWSER (UNIVERSAL)
-- ============================================================
if package.config:sub(1,1) == "\\" then
    os.execute("start http://localhost:" .. port)
else
    os.execute("open http://localhost:" .. port .. " 2>/dev/null || xdg-open http://localhost:" .. port .. " 2>/dev/null")
end

-- ============================================================
-- CEK PYTHON (UNIVERSAL!)
-- ============================================================
local python_cmd = nil
local f = io.popen("python --version 2>&1")
if f then
    local result = f:read("*all")
    f:close()
    if result:match("Python") then
        python_cmd = "python"
    end
end

if not python_cmd then
    local f = io.popen("python3 --version 2>&1")
    if f then
        local result = f:read("*all")
        f:close()
        if result:match("Python") then
            python_cmd = "python3"
        end
    end
end

if python_cmd then
    print("🐍 Using Python HTTP Server")
    print("   " .. python_cmd .. " -m http.server " .. port .. " --directory dist")
    print()
    os.execute(python_cmd .. " -m http.server " .. port .. " --directory dist")
    os.exit(0)
end

-- ============================================================
-- CEK PHP (UNIVERSAL!)
-- ============================================================
local php_cmd = nil
local f = io.popen("php -v 2>&1")
if f then
    local result = f:read("*all")
    f:close()
    if result:match("PHP") then
        php_cmd = "php"
    end
end

if php_cmd then
    print("🐘 Using PHP HTTP Server")
    print("   php -S localhost:" .. port .. " -t dist")
    print()
    os.execute("php -S localhost:" .. port .. " -t dist")
    os.exit(0)
end

-- ============================================================
-- NO SERVER!
-- ============================================================
print("❌ No server found!")
print()
print("📦 Install Python atau PHP:")
print("   • Python: https://python.org")
print("   • PHP: https://php.net")
print()
print("Atau pake Node.js:")
print("   npm install -g serve")
print("   npx serve dist")
print()

if package.config:sub(1,1) == "\\" then
    os.execute("pause")
else
    os.execute("read -p 'Press Enter to exit'")
end