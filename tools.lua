local tools = {}

function tools.getSplittedByChunks(t, size)
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

function tools.getTableWithoutDublicates(tbl)
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

function tools.getFrequencyCount(t)
    local frequencies = {}
    for _, v in ipairs(t) do
        if not frequencies[v] then
            frequencies[v] = 0
        end
        frequencies[v] = frequencies[v] + 1
    end

    return frequencies
end

function tools.isFloatsEqual(value1, value2, accuracy)
    return math.abs(value1 - value2) < math.abs(accuracy)
end

function tools.isFloatInRange(value, from, to)
    return value >= from and value <= to
end

function tools.getClonedTable(t1)
    local t2 = {}
    for k, v in pairs(t1) do
        t2[k] = v
    end
    return t2
end

function tools.getPrettyTable(tbl, indent)
    if not indent then
        indent = 0
    end
    local text2print = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        text2print = text2print .. string.rep(" ", indent)
        if (type(k) == "number") then
            text2print = text2print .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            text2print = text2print .. k .. "= "
        end
        if (type(v) == "number") then
            text2print = text2print .. v .. ",\r\n"
        elseif (type(v) == "string") then
            text2print = text2print .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            text2print = text2print .. tprint(v, indent + 2) .. ",\r\n"
        else
            text2print = text2print .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    text2print = text2print .. string.rep(" ", indent - 2) .. "}"
    return text2print
end

return tools
