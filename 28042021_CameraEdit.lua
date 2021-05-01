gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)

local tools = require "tools"
local camera = require "camera"

do
		local r

		-- search for possible entries
		do
				gg.clearResults()
				gg.searchNumber(tostring(-0.07), gg.TYPE_FLOAT)
				r = gg.getResults(1024)
				gg.clearResults()
		end

		-- get full camera's data (not single entries)
		do
				local tmp = {}

				for _, var in ipairs(r) do
						local end_address = var.address

						local FLOAT_SIZE = 4
						for offset=-20, 0, FLOAT_SIZE do
							 table.insert(tmp, {
								 address = end_address + offset,
								 flags = gg.TYPE_FLOAT
							 })
						end
				end

				r = gg.getValues(tmp)
		end

		-- split r by camera's chunks
		do
				local chunks = tools.split_by_chunks(r, 6)

				-- simple validation
				r = {}

				local allowed_sets = {
					{
						name = 'LOW BLUE',
						values = {6.54, -9.37, 6.27, 42.86, 44.90, -0.07}},
					{
						name = 'LOW RED',
						values = {-6.54, -9.37, -6.27, 42.86, -134.10, -0.07}
					},
					{
						name = 'HIGH BLUE',
						values = {7.66, -10.98, 7.62, 42.86, 44.90, -0.07}
					},
					{
						name = 'HIGH RED',
						values = {-7.66, -10.98, -7.62, 42.86, -134.10, -0.07}
					},
				}

				for _, chunk in ipairs(chunks) do
						for _, set in ipairs(allowed_sets) do
								local is_set_equal = true
								for i, var in ipairs(chunk) do
										local val1 = tonumber(var.value)
										local val2 = set.values[i]

										local is_equal = tools.is_floats_equal(val1, val2, 1e-3)
										is_set_equal = is_set_equal and is_equal
								end

								if is_set_equal then
										-- add labels (remove it before compile)
										for _, var in ipairs(chunk) do
												var.name = set.name
										end
										-- end of remove

										table.insert(r, chunk)
										break
								end
						end
				end
		end

		-- insert camera's into save list (remove it before compile)
		do
				local tmp = {}
				for _, chunk in ipairs(r) do
						for _, var in ipairs(chunk) do
								table.insert(tmp, var)
						end
				end
				gg.addListItems(tmp)
		end
		-- end of remove

		-- camera init
		camera:init_by_structs(r)
end

-- main ui loop
is_exit = false

if camera.count == 0 then
		print('Ничего не найдено')
		is_exit = true
end

local menu_buttons = {
	'Настройки',
	'Восстановить',
	'Выход'
}

local menu_actions = {
	function()
			local input = gg.prompt({
				'Множитель расстояния: [10; 25]',
				'Добавочный угол: [0; 30]',
				'Обнулить вращение проекции:'},
				{tonumber(string.format('%i', camera.distance * 10 // 1)), camera.a_degree, true},
				{'number', 'number', 'checkbox'})

			if not input then
					return nil
			end

			camera:set_rotate_vertical(input[2])
			camera:set_distance(input[1] * 0.1)
			
			if input[3] then
					camera:set_rotate_image(0.07)
			end

			camera:update()
	end,
	function()
			camera:reset()
			camera:update()
	end,
	function()
			is_exit = true
	end,
}

gg.showUiButton()
while not is_exit do
		if gg.isClickedUiButton() then
				gg.hideUiButton()

				local info, way
				info = string.format('found: %i / 8 | dist: %.2f | angle: %.2f', camera.count, camera.distance, camera.a_degree)
				way = gg.choice(menu_buttons, nil, info)

				if way then
						menu_actions[way]()
				end

				gg.showUiButton()
		end
		gg.sleep(250)
end
