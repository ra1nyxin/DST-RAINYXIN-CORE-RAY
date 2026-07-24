local M = {}

M.menu_visible = true
M.menu_position = {
    x = -420,
    y = 190,
}

M.base_target_rows = {
    { key = "pigking", label = "猪王", default_enabled = true },
    { key = "touchstone", label = "试金石", default_enabled = true },
    { key = "butterfly", label = "蝴蝶", default_enabled = true },
    { key = "players", label = "玩家(近距)", default_enabled = true },
}

M.topology_target_order = {
    "archive",
    "atrium",
    "beeclearing",
    "beequeen",
    "dragonfly",
    "oasis",
    "antlion",
    "walrus",
    "graveyard",
    "chess",
    "toadstool",
    "caveexit",
    "ruins",
    "military",
    "sacred",
    "barracks",
    "altar",
    "labyrinth",
    "crabking",
    "portal",
    "monkey",
    "hermit",
    "bunnymen",
    "moonaltar",
}

M.topology_targets = {
    archive = {
        menu_label = "档案室",
        label = "档案室",
        color = { 0.94, 0.78, 1.00, 0.96 },
        node_patterns = { "ArchiveMazeEntrance", "ArchiveMazeRooms", "Archive" },
        default_enabled = false,
    },
    atrium = {
        menu_label = "中庭",
        label = "中庭",
        color = { 0.75, 1.00, 0.80, 0.96 },
        node_patterns = { "AtriumMazeEntrance", "AtriumMazeRooms", "TentaclePillarToAtrium", "Atrium" },
        default_enabled = false,
    },
    beeclearing = {
        menu_label = "蜜蜂区",
        label = "蜜蜂区",
        color = { 1.00, 0.91, 0.44, 0.95 },
        node_patterns = { "BeeClearing" },
        default_enabled = false,
    },
    beequeen = {
        menu_label = "蜂后",
        label = "蜂后",
        color = { 1.00, 0.77, 0.26, 0.96 },
        node_patterns = { "BeeQueenBee", "BeeQueen" },
        default_enabled = false,
    },
    dragonfly = {
        menu_label = "龙蝇",
        label = "龙蝇",
        color = { 1.00, 0.42, 0.20, 0.96 },
        node_patterns = { "DragonflyArena" },
        default_enabled = false,
    },
    oasis = {
        menu_label = "绿洲",
        label = "绿洲",
        color = { 0.47, 0.93, 0.91, 0.96 },
        node_patterns = { "LightningBluffOasis", "SandstormOasis", "Oasis" },
        default_enabled = false,
    },
    antlion = {
        menu_label = "蚁狮",
        label = "蚁狮",
        color = { 0.99, 0.81, 0.48, 0.96 },
        node_patterns = { "LightningBluffAntlion", "AntlionSpawningGround", "Antlion" },
        default_enabled = false,
    },
    walrus = {
        menu_label = "海象营",
        label = "海象营",
        color = { 0.83, 0.93, 1.00, 0.96 },
        node_patterns = { "WalrusHut_Plains", "WalrusHut_Grassy", "WalrusHut_Rocky", "WalrusHut" },
        default_enabled = false,
    },
    graveyard = {
        menu_label = "墓地",
        label = "墓地",
        color = { 0.86, 0.86, 0.96, 0.96 },
        node_patterns = { "Graveyard" },
        default_enabled = false,
    },
    chess = {
        menu_label = "发条区",
        label = "发条区",
        color = { 0.82, 0.82, 0.90, 0.96 },
        node_patterns = { "ChessArea", "ChessBarrens", "ChessForest", "ChessMarsh", "ChessSpot", "Chessy", "Chess" },
        default_enabled = false,
    },
    toadstool = {
        menu_label = "毒菌蟾蜍",
        label = "蟾蜍",
        color = { 0.88, 0.55, 1.00, 0.96 },
        node_patterns = { "ToadstoolArena", "Toadstool" },
        default_enabled = false,
    },
    caveexit = {
        menu_label = "洞穴出口",
        label = "洞口",
        color = { 0.78, 0.92, 1.00, 0.96 },
        node_patterns = { "CaveExitTask", "CaveExit" },
        default_enabled = false,
    },
    ruins = {
        menu_label = "远古遗迹",
        label = "遗迹",
        color = { 0.68, 0.88, 1.00, 0.96 },
        node_patterns = { "RuinsStart", "RuinsCamp", "Ruins" },
        default_enabled = false,
    },
    military = {
        menu_label = "军事区",
        label = "军区",
        color = { 1.00, 0.70, 0.54, 0.96 },
        node_patterns = { "MilitaryEntrance", "MilitaryMaze", "Military" },
        default_enabled = false,
    },
    sacred = {
        menu_label = "神圣区",
        label = "神圣区",
        color = { 1.00, 0.89, 0.60, 0.96 },
        node_patterns = { "SacredBarracks", "BGSacredRoom", "BGSacred", "Sacred" },
        default_enabled = false,
    },
    barracks = {
        menu_label = "兵营",
        label = "兵营",
        color = { 0.93, 0.77, 0.62, 0.96 },
        node_patterns = { "Barracks2", "Barracks" },
        default_enabled = false,
    },
    altar = {
        menu_label = "远古祭坛",
        label = "祭坛",
        color = { 1.00, 0.95, 0.74, 0.96 },
        node_patterns = { "AltarRoom", "BrokenAltar", "SacredAltar", "Altar" },
        default_enabled = false,
    },
    labyrinth = {
        menu_label = "迷宫",
        label = "迷宫",
        color = { 0.74, 0.84, 1.00, 0.96 },
        node_patterns = { "LabyrinthEntrance", "Labyrinth" },
        default_enabled = false,
    },
    crabking = {
        menu_label = "蟹王",
        label = "蟹王",
        color = { 0.76, 0.95, 1.00, 0.96 },
        node_patterns = { "CrabKing" },
        default_enabled = false,
    },
    portal = {
        menu_label = "海上大门",
        label = "大门",
        color = { 0.72, 0.98, 1.00, 0.96 },
        node_patterns = { "OceanWhirlBigPortal" },
        default_enabled = false,
    },
    monkey = {
        menu_label = "猴群区域",
        label = "猴区",
        color = { 1.00, 0.87, 0.53, 0.96 },
        node_patterns = { "StaticLayoutIsland:MonkeyIsland", "MonkeyIsland", "MonkeyMeadow" },
        default_enabled = false,
    },
    hermit = {
        menu_label = "珍珠岛",
        label = "珍珠岛",
        color = { 0.78, 1.00, 0.86, 0.96 },
        node_patterns = { "StaticLayoutIsland:HermitcrabIsland", "HermitcrabIsland" },
        default_enabled = false,
    },
    bunnymen = {
        menu_label = "兔人村",
        label = "兔人村",
        color = { 0.92, 0.92, 1.00, 0.96 },
        node_patterns = { "RabbitHermit" },
        default_enabled = false,
    },
    moonaltar = {
        menu_label = "天体祭坛",
        label = "月祭坛",
        color = { 0.86, 0.93, 1.00, 0.96 },
        node_patterns = { "MoonAltarRockGlass", "MoonAltarRockIdol", "MoonAltarRockSeed", "MoonAltarRock" },
        default_enabled = false,
    },
}

M.target_rows = {}
M.targets = {}

for i = 1, #M.base_target_rows do
    local row = M.base_target_rows[i]
    M.target_rows[#M.target_rows + 1] = {
        key = row.key,
        label = row.label,
    }
    M.targets[row.key] = row.default_enabled == true
end

for i = 1, #M.topology_target_order do
    local key = M.topology_target_order[i]
    local def = M.topology_targets[key]
    if def ~= nil then
        M.target_rows[#M.target_rows + 1] = {
            key = key,
            label = def.menu_label or def.label or key,
        }
        M.targets[key] = def.default_enabled == true
    end
end

function M:IsEnabled(key)
    return self.targets[key] == true
end

function M:SetEnabled(key, enabled)
    self.targets[key] = enabled == true
end

function M:ToggleEnabled(key)
    self:SetEnabled(key, not self:IsEnabled(key))
end

function M:SetMenuVisible(visible)
    self.menu_visible = visible == true
end

function M:SetMenuPosition(x, y)
    if type(x) == "number" then
        self.menu_position.x = x
    end
    if type(y) == "number" then
        self.menu_position.y = y
    end
end

return M
