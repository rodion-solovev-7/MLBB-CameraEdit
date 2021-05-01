local tools = {}

function tools.split_by_chunks(t, size)
		if #t % size ~= 0 then
				print('AE7Z93: table size must be a multiple of the chunk size')
				os.exit(-1)
		end

		local chunks = {}

		local next_t = {}
		for i, v in ipairs(t) do
				table.insert(next_t, v)
				if (i - 1) % size == size - 1 then
						table.insert(chunks, next_t)
						next_t = {}
				end
		end

		return chunks
end

function tools.remove_dublicates(tbl)
    local result = {}

    local hash = {}
    for _, v in ipairs(tbl) do
        if not hash[v] then
            hash[v] = true
            table.insert(result, v)
        end
    end

    return result
end

function tools.frequency_count(t)
    local frequency = {}
    for _, v in ipairs(t) do
        if not frequency[v] then
            frequency[v] = 0
        end
        frequency[v] = frequency[v] + 1
    end

    return frequency
end

function tools.is_floats_equal(value1, value2, accuracy)
    return math.abs(value1 - value2) < math.abs(accuracy)
end

function tools.is_float_in_range(value, from, to)
    return value >= from and value <= to
end

function tools.clone_table(t1)
    local t2 = {}
    for k, v in pairs(t1) do
        t2[k] = v
    end
    return t2
end

return tools
