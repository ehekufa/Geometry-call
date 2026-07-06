-- ==========================================
-- GEOMETRY DASH CLONE + РЕДАКТОР УРОВНЕЙ
-- Управление в игре: Пробел / ЛКМ / Тап
-- Управление в редакторе: см. описание
-- ==========================================

local BLOCK = 40
local GRAVITY = 1800
local JUMP_HEIGHT = 3.3
local levelFile = "level.txt"

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ====================
local function checkCollision(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x and
           a.y < b.y + b.h and a.y + a.h > b.y
end

-- ==================== ГЛОБАЛЬНЫЕ ДАННЫЕ ====================
local player = {}
local ground = { x = 0, y = 550, w = 2000, h = 50 }
local spikes = {}
local portals = {}
local gameOver = false
local gameWin = false
local progress = 0
local levelLength = 2000

-- Режимы
local isEditor = false          -- true = редактор, false = игра
local selectedObject = "spike"  -- "spike", "portal_ship", "portal_ball"
local editorMessage = ""

-- ==================== ФУНКЦИИ СОХРАНЕНИЯ/ЗАГРУЗКИ ====================
local function saveLevel()
    local data = {
        spikes = spikes,
        portals = portals,
        levelLength = levelLength
    }
    local str = love.data.compress("string", "zlib", love.data.encode("string", "base64", serpent.dump(data)))
    love.filesystem.write(levelFile, str)
    editorMessage = "Level saved!"
end

local function loadLevel()
    if love.filesystem.getInfo(levelFile) then
        local str = love.filesystem.read(levelFile)
        str = love.data.decode("string", "base64", love.data.decompress("string", "zlib", str))
        local data = serpent.load(str)
        if data then
            spikes = data.spikes or {}
            portals = data.portals or {}
            levelLength = data.levelLength or 2000
            ground.w = levelLength
            editorMessage = "Level loaded!"
        else
            editorMessage = "Load failed!"
        end
    else
        editorMessage = "No saved level!"
    end
end

-- ==================== ПОСТРОЕНИЕ УРОВНЯ ====================
local function buildLevel()
    -- Очищаем при загрузке игры (не в редакторе)
    if not isEditor then
        spikes = {}
        portals = {}
        -- Строим демо-уровень (как раньше)
        local function addSpike(x, y)
            table.insert(spikes, { x = x, y = y, w = 25, h = 30, type = "spike" })
        end
        addSpike(300, ground.y - 30)
        addSpike(420, ground.y - 30)
        addSpike(540, ground.y - 30)
        addSpike(900, ground.y - 30)
        addSpike(1020, ground.y - 30)
        addSpike(1500, 0)

        table.insert(portals, { x = 700, y = ground.y - 60, w = 30, h = 60, mode = "ship", color = {1, 0.8, 0} })
        table.insert(portals, { x = 1300, y = ground.y - 60, w = 30, h = 60, mode = "ball", color = {0, 0.5, 1} })
    end
end

local function resetGame()
    player = {
        x = 100, y = ground.y - 30, w = 30, h = 30,
        vy = 0, isOnGround = true,
        mode = "cube", gravity = GRAVITY,
        jumpPower = -(JUMP_HEIGHT * 40)
    }
    gameOver = false
    gameWin = false
    progress = 0
    if not isEditor then
        buildLevel()
    end
end

-- ==================== LÖVE: ЗАГРУЗКА ====================
function love.load()
    love.window.setTitle("Geometry Dash - Editor")
    love.window.setMode(800, 600)
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    -- Загружаем уровень при старте
    if love.filesystem.getInfo(levelFile) then
        loadLevel()
    else
        buildLevel()
    end
    resetGame()
end

-- ==================== РЕДАКТОР: ЛОГИКА ====================
local function editorAddObject(x, y)
    -- Привязываем к сетке (необязательно, но удобно)
    local grid = 10
    x = math.floor(x / grid) * grid
    y = math.floor(y / grid) * grid

    if selectedObject == "spike" then
        table.insert(spikes, { x = x, y = y, w = 25, h = 30, type = "spike" })
        editorMessage = "Spike added"
    elseif selectedObject == "portal_ship" then
        table.insert(portals, { x = x, y = y, w = 30, h = 60, mode = "ship", color = {1, 0.8, 0} })
        editorMessage = "Ship portal added"
    elseif selectedObject == "portal_ball" then
        table.insert(portals, { x = x, y = y, w = 30, h = 60, mode = "ball", color = {0, 0.5, 1} })
        editorMessage = "Ball portal added"
    end
end

local function editorRemoveObject(x, y)
    -- Проверяем шипы
    for i = #spikes, 1, -1 do
        local s = spikes[i]
        if x >= s.x and x <= s.x + s.w and y >= s.y and y <= s.y + s.h then
            table.remove(spikes, i)
            editorMessage = "Spike removed"
            return
        end
    end
    -- Проверяем порталы
    for i = #portals, 1, -1 do
        local p = portals[i]
        if x >= p.x and x <= p.x + p.w and y >= p.y and y <= p.y + p.h then
            table.remove(portals, i)
            editorMessage = "Portal removed"
            return
        end
    end
    editorMessage = "Nothing removed"
end

-- ==================== LÖVE: ОБНОВЛЕНИЕ ====================
function love.update(dt)
    if isEditor then return end  -- в редакторе игра заморожена

    if gameOver or gameWin then return end

    -- Гравитация
    player.vy = player.vy + player.gravity * dt
    player.y = player.y + player.vy * dt

    -- Пол
    if player.y + player.h > ground.y then
        player.y = ground.y - player.h
        player.vy = 0
        player.isOnGround = true
    else
        player.isOnGround = false
    end

    -- Режимы
    if player.mode == "ship" then
        -- Управление через keypressed/released
    elseif player.mode == "ball" then
        if player.vy > 0 then
            if player.y + player.h > ground.y then
                player.y = ground.y - player.h
                player.vy = 0
                player.isOnGround = true
            end
        else
            if player.y < 0 then
                player.y = 0
                player.vy = 0
                player.isOnGround = true
            end
        end
    end

    -- Портал
    for _, portal in ipairs(portals) do
        if checkCollision(player, portal) then
            if player.mode ~= portal.mode then
                player.mode = portal.mode
                player.vy = 0
                if player.mode == "ball" then
                    player.gravity = GRAVITY
                else
                    player.gravity = GRAVITY
                end
            end
        end
    end

    -- Шипы
    for _, spike in ipairs(spikes) do
        if checkCollision(player, spike) then
            gameOver = true
            return
        end
    end

    -- Прогресс
    progress = math.min((player.x / ground.w) * 100, 100)
    if player.x >= ground.w - player.w then
        gameWin = true
    end
end

-- ==================== LÖVE: ОТРИСОВКА ====================
function love.draw()
    -- Смещение камеры
    local offsetX = 400 - player.x - player.w / 2
    local offsetY = 300 - player.y - player.h / 2

    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)

    -- Пол
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", ground.x, ground.y, ground.w, ground.h)

    -- Шипы
    love.graphics.setColor(1, 0, 0)
    for _, spike in ipairs(spikes) do
        love.graphics.polygon("fill",
            spike.x, spike.y + spike.h,
            spike.x + spike.w / 2, spike.y,
            spike.x + spike.w, spike.y + spike.h
        )
    end

    -- Порталы
    for _, portal in ipairs(portals) do
        love.graphics.setColor(portal.color)
        love.graphics.rectangle("fill", portal.x, portal.y, portal.w, portal.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(">", portal.x + 5, portal.y + 15)
    end

    -- Игрок
    if player.mode == "cube" then
        love.graphics.setColor(0, 1, 0)
    elseif player.mode == "ship" then
        love.graphics.setColor(1, 0.8, 0)
    elseif player.mode == "ball" then
        love.graphics.setColor(0, 0.5, 1)
    end
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    love.graphics.pop() -- камера выключена

    -- UI
    love.graphics.setColor(1, 1, 1)
    if isEditor then
        love.graphics.print("=== EDITOR MODE ===", 10, 10)
        love.graphics.print("Left click: add object", 10, 30)
        love.graphics.print("Right click: remove object", 10, 50)
        love.graphics.print("Tab: switch to game", 10, 70)
        love.graphics.print("S: save   L: load   C: clear", 10, 90)
        love.graphics.print("Selected: " .. selectedObject, 10, 110)
        love.graphics.print("Message: " .. editorMessage, 10, 130)
        love.graphics.print("Objects: spikes=" .. #spikes .. " portals=" .. #portals, 10, 150)
    else
        love.graphics.print("Progress: " .. string.format("%.1f", progress) .. "%", 10, 10)
        love.graphics.print("Mode: " .. player.mode, 10, 30)
        love.graphics.print("Tab: editor", 10, 50)
        if gameOver then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("GAME OVER", 0, 250, 800, "center")
            love.graphics.printf("Press R to restart", 0, 300, 800, "center")
        end
        if gameWin then
            love.graphics.setColor(0, 1, 0)
            love.graphics.printf("YOU WIN!", 0, 250, 800, "center")
            love.graphics.printf("Press R to restart", 0, 300, 800, "center")
        end
    end
end

-- ==================== ВВОД В ИГРЕ ====================
local function doAction()
    if isEditor or gameOver or gameWin then return end
    if player.mode == "cube" then
        if player.isOnGround then
            player.vy = player.jumpPower
            player.isOnGround = false
        end
    elseif player.mode == "ship" then
        player.vy = -300
    elseif player.mode == "ball" then
        player.gravity = -player.gravity
        player.vy = 0
        if player.gravity > 0 then
            player.y = ground.y - player.h
        else
            player.y = 0
        end
    end
end

local function releaseAction()
    if isEditor or gameOver or gameWin then return end
    if player.mode == "ship" then
        player.vy = 0
    end
end

-- ==================== КЛАВИАТУРА ====================
function love.keypressed(key)
    if key == "tab" then
        isEditor = not isEditor
        if isEditor then
            -- Переключаемся в редактор (сохраняем текущее состояние игры)
        else
            -- Возвращаемся в игру, сбрасываем позицию игрока
            resetGame()
        end
    end

    if isEditor then
        if key == "s" then saveLevel() end
        if key == "l" then loadLevel() resetGame() end
        if key == "c" then
            spikes = {}
            portals = {}
            editorMessage = "Level cleared"
        end
        -- Переключение объекта
        if key == "1" then selectedObject = "spike" end
        if key == "2" then selectedObject = "portal_ship" end
        if key == "3" then selectedObject = "portal_ball" end
        return
    end

    -- Игровые клавиши
    if key == "space" then doAction() end
    if key == "r" then resetGame() end
    if key == "escape" then love.event.quit() end
end

function love.keyreleased(key)
    if not isEditor and key == "space" then
        releaseAction()
    end
end

-- ==================== МЫШЬ ====================
function love.mousepressed(x, y, button)
    if isEditor then
        -- Получаем координаты с учётом камеры
        local offsetX = 400 - player.x - player.w / 2
        local offsetY = 300 - player.y - player.h / 2
        local wx = x - offsetX
        local wy = y - offsetY

        if button == 1 then -- левая кнопка
            editorAddObject(wx, wy)
        elseif button == 2 then -- правая
            editorRemoveObject(wx, wy)
        end
        return
    end

    if button == 1 then
        doAction()
    end
end

function love.mousereleased(x, y, button)
    if not isEditor and button == 1 then
        releaseAction()
    end
end

-- ==================== СЕНСОР (Android) ====================
function love.touchpressed(id, x, y, dx, dy)
    if isEditor then
        -- В редакторе на Android пока не поддерживаем (можно добавить позже)
        return
    end
    doAction()
end

function love.touchreleased(id, x, y, dx, dy)
    if not isEditor then
        releaseAction()
    end
end
