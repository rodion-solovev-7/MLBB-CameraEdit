tools = require("tools")

function getPossibleEntries()
    -- возвращает потенциальные вхождения структур для камеры

    gg.clearResults()
    gg.searchNumber(tostring(-0.07), gg.TYPE_FLOAT)
    local result = gg.getResults(1024)
    gg.clearResults()

    return result
end

function getVariablesFromPossibleEntries(entries)
    -- возвращает переменные структур камеры из областей памяти
    -- с потенциальными вхождениями

    local variables = {}

    for _, var in ipairs(entries) do
        local max_address = var.address

        local FLOAT_SIZE = 4
        for offset = -5 * FLOAT_SIZE, 0, FLOAT_SIZE do
            table.insert(variables, {
                address = max_address + offset,
                flags = gg.TYPE_FLOAT,
            })
        end
    end

    variables = gg.getValues(variables)
    return variables
end

function getValidatedStructs(structs)
    -- простейшая валидация найденных структур
    local results = {}

    local allowed_structs = {
        {
            name = 'LOW BLUE',
            values = { 6.54, -9.37, 6.27, 42.86, 44.90, -0.07 }
        },
        {
            name = 'LOW RED',
            values = { -6.54, -9.37, -6.27, 42.86, -134.10, -0.07 }
        },
        {
            name = 'HIGH BLUE',
            values = { 7.66, -10.98, 7.62, 42.86, 44.90, -0.07 }
        },
        {
            name = 'HIGH RED',
            values = { -7.66, -10.98, -7.62, 42.86, -134.10, -0.07 }
        },
    }

    for _, struct in ipairs(structs) do
        for _, set in ipairs(allowed_structs) do
            local is_set_equal = true
            for i, var in ipairs(struct) do
                local val1 = tonumber(var.value)
                local val2 = set.values[i]

                local is_equal = tools.isFloatsEqual(val1, val2, 1e-3)
                is_set_equal = is_set_equal and is_equal
            end

            if is_set_equal then
                -- добавляем подписи к переменным
                for _, var in ipairs(struct) do
                    var.name = set.name
                end

                -- сохраняем структуру, если она валидна
                table.insert(results, struct)
                break
            end
        end
    end

    return results
end

function getCamera(structs)
    -- инициализируем камеру найденными структурами
    local camera = require("camera")
    camera:initFromStructs(structs)
    return camera
end

function runUIMenuLoop(interactWithUser)
    -- Бесконечный цикл с меню и действиями.
    -- Для выхода необходимо действие с os.exit()

    gg.showUiButton()

    -- бесконечный цикл в котором выполняются действия,
    -- привязанные к определённым кнопкам
    while true do
        interactWithUser()
        gg.sleep(250)
    end
end

function main()
    -- главная функция

    -- чистим список поиска
    gg.clearResults()
    -- настраиваем регионы для быстрого поиска
    gg.setRanges(gg.REGION_ANONYMOUS)

    -- находим потенциальные вхождения концов структур
    local possible_entries = getPossibleEntries()
    -- извлекаем все переменные из потенциальных структур
    local variables = getVariablesFromPossibleEntries(possible_entries)
    -- делим все переменные на отдельные структуры
    local structs = tools.getSplittedByChunks(variables, 6)
    -- отфильтровываем некорректные структуры
    structs = getValidatedStructs(structs)

    -- добавляем структуры камеры в список сохранённых переменных GG
    --[[
    do
        local tmp = {}
        for _, chunk in ipairs(r) do
            for _, var in ipairs(chunk) do
                table.insert(tmp, var)
            end
        end
        gg.addListItems(tmp)
    end
    ]]--

    -- поиск структур и сохранение их в камеру
    local camera = getCamera(structs)

    if camera.count == 0 then
        print('Ничего не найдено')
        os.exit(0)
    end

    local menu_labels = {
        [1] = 'Настройки',
        [2] = 'Восстановить',
        [3] = 'Выход',
    }

    local menu_actions = {
        [1] = function()
            local input = gg.prompt(
                    {
                        'Множитель расстояния: [10; 25]',
                        'Добавочный угол: [0; 30]',
                        'Обнулить вращение проекции:',
                    },
                    {
                        tonumber(string.format('%i', camera.distance * 10 // 1)),
                        camera.a_degree,
                        true,
                    },
                    { 'number', 'number', 'checkbox' }
            )

            if input == nil then
                return nil
            end

            camera:setRotateVertical(input[2])
            camera:setDistanceToPlayer(input[1] * 0.1)

            if input[3] then
                camera:setRotateProjection(0.07)
            end

            camera:update()
        end,
        [2] = function()
            camera:reset()
            camera:update()
        end,
        [3] = function()
            print("Завершено пользователем")
            os.exit(0)
        end,
    }

    local function interactWithUser()
        if gg.isClickedUiButton() then
            gg.hideUiButton()

            local info_text = string.format(
                    'found: %i / 8 | dist: %.2f | angle: %.2f',
                    camera.count, camera.distance, camera.a_degree
            )
            print(info_text)

            local selected_way = gg.choice(menu_labels, nil, info_text)
            if selected_way ~= nil then
                menu_actions[selected_way]()
            end

            gg.showUiButton()
        end
    end

    gg.showUiButton()

    runUIMenuLoop(interactWithUser)
end

-- Начало выполнения

if gg == nil then
    print("WARN: 'gg' недоступен. Используется mock-версия для теста")
    gg = require("mock_gg")
end

main()
