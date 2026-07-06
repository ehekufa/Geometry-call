function love.conf(t)
    -- Основные настройки приложения
    t.title = "Geometry Dash Clone"          -- Название в заголовке окна
    t.author = "Your Name"                   -- Автор (опционально)
    t.version = "12.0"                       -- Версия LÖVE, для которой написана игра (совместимость)

    -- Разрешение окна (будет масштабироваться на Android)
    t.window.width = 800
    t.window.height = 600
    t.window.fullscreen = false              -- Не полноэкранный режим (можно включить позже)
    t.window.resizable = false               -- Запрещаем изменение размера окна

    -- Настройки для мобильных устройств
    t.identity = "geometry_dash_clone"       -- Имя папки для сохранений (внутренняя память)
    t.console = false                        -- Отключаем консоль (для релиза)
    t.accelerometerjoystick = false          -- Отключаем акселерометр (не используется)

    -- Для Android — чтобы экран не вращался и не обрезался
    t.window.display = 1                     -- Основной дисплей
    t.window.vsync = 1                       -- Вертикальная синхронизация (для плавности)
    t.window.msaa = 0                        -- Отключаем сглаживание (экономия ресурсов)
    t.window.icon = nil                      -- Можно указать путь к иконке, если нужно

    -- Для мобильных — автоматическое масштабирование
    t.window.highdpi = true                  -- Поддержка экранов с высокой плотностью пикселей
    t.window.usedpiscale = false             -- Не используем DPI-масштаб (оставляем как есть)

    -- Ключевое для Android: ориентация экрана
    -- "portrait" — вертикальная, "landscape" — горизонтальная
    t.window.orientation = "landscape"       -- Геометрия Дэш — горизонтальная игра!
    t.window.fullscreen = false
end
