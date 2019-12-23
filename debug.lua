debugging = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1"

if debugging then
    local separator = string.sub(package.config, 1, 1)
    local filePath = debug.getinfo(1).short_src
    local rootFolder = string.gsub(filePath, "^(.+"..separator..")[^"..separator.."]+$", "%1");
    package.path = rootFolder .. [[?.lua]]
end

dofile("game.lua")