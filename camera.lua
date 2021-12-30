local camera = {}

local tools = require "tools"

function camera._init(self)
    self.base_angles = { {}, {}, {} }
    self.base_angles.a = self.base_angles[1]
    self.base_angles.b = self.base_angles[2]
    self.base_angles.c = self.base_angles[3]

    self.angles = { {}, {}, {} }
    self.angles.a = self.angles[1]
    self.angles.b = self.angles[2]
    self.angles.c = self.angles[3]

    self.base_offsets = { {}, {}, {} }
    self.base_offsets.x = self.base_offsets[1]
    self.base_offsets.y = self.base_offsets[2]
    self.base_offsets.z = self.base_offsets[3]

    self.offsets = { {}, {}, {} }
    self.offsets.x = self.offsets[1]
    self.offsets.y = self.offsets[2]
    self.offsets.z = self.offsets[3]

    self.distance = 1
    self.base_distances = {}

    self.a_degree = 0
    self.b_degree = 0
    self.c_degree = 0

    self.count = 0
end

function camera._setAngles(self, a, b, c)
    local pi2 = 360.0
    for i, var in ipairs(self.base_angles.a) do
        self.angles.a[i] = tools.getClonedTable(self.base_angles.a[i])

        local value = var.value
        self.angles.a[i].value = (pi2 + value + a) % pi2
    end
    for i, var in ipairs(self.base_angles.b) do
        self.angles.b[i] = tools.getClonedTable(self.base_angles.b[i])

        local value = var.value
        self.angles.b[i].value = (pi2 + value + b) % pi2
    end
    for i, var in ipairs(self.base_angles.c) do
        self.angles.c[i] = tools.getClonedTable(self.base_angles.c[i])

        local value = var.value
        self.angles.c[i].value = (pi2 + value + c) % pi2
    end
    self:_recalc_offsets()
end

function camera._setOffsets(self, x, y, z)
    for i, var in ipairs(self.base_offsets.x) do
        self.offsets.x[i] = tools.getClonedTable(self.base_offsets.x[i])

        local value = var.value
        self.offsets.x[i].value = value * x
    end
    for i, var in ipairs(self.base_offsets.y) do
        self.offsets.y[i] = tools.getClonedTable(self.base_offsets.y[i])

        local value = var.value
        self.offsets.y[i].value = value * y
    end
    for i, var in ipairs(self.base_offsets.z) do
        self.offsets.z[i] = tools.getClonedTable(self.base_offsets.z[i])

        local value = var.value
        self.offsets.z[i].value = value * z
    end
end

function camera._invalidate(self)
    local variables = {}
    for _, t in ipairs(self.angles) do
        for _, var in ipairs(t) do
            table.insert(variables, var)
        end
    end
    for _, t in ipairs(self.offsets) do
        for _, var in ipairs(t) do
            table.insert(variables, var)
        end
    end
    gg.setValues(variables)
end

function camera._recalcOffsets(self)
    -- пересчитывает смещения для камеры по каждой из осей
    -- в зависимости от угла и расстояния до игрока
    for i, d in ipairs(self.base_distances) do
        -- x = d * cos(a) * sin(b)
        -- y = d * sin(a)
        -- z = d * cos(a) * cos(b)
        d = d * self.distance

        local a, b, c
        a = self.angles.a[i].value / 180 * math.pi
        b = self.angles.b[i].value / 180 * math.pi
        c = self.angles.c[i].value / 180 * math.pi
        local x, y, z
        x = d * math.cos(a) * math.sin(b)
        y = d * math.sin(a + math.pi)
        z = d * math.cos(a) * math.cos(b)

        self.offsets.x[i].value = x
        self.offsets.y[i].value = y
        self.offsets.z[i].value = z
    end
end

function camera.initFromStructs(self, t)
    self:_init()

    self.count = #t

    for _, struct in ipairs(t) do
        local x, y, z, a, b, c
        x = struct[1].value
        y = struct[2].value
        z = struct[3].value
        a = struct[4].value
        b = struct[5].value
        c = struct[6].value

        table.insert(self.base_offsets.x, struct[1])
        table.insert(self.base_offsets.y, struct[2])
        table.insert(self.base_offsets.z, struct[3])

        table.insert(self.base_angles.a, struct[4])
        table.insert(self.base_angles.b, struct[5])
        table.insert(self.base_angles.c, struct[6])

        table.insert(self.offsets.x, struct[1])
        table.insert(self.offsets.y, struct[2])
        table.insert(self.offsets.z, struct[3])

        table.insert(self.angles.a, struct[4])
        table.insert(self.angles.b, struct[5])
        table.insert(self.angles.c, struct[6])

        local distance = math.sqrt(x * x + y * y + z * z)
        table.insert(self.base_distances, distance)
    end
end

function camera.setDistanceToPlayer(self, d)
    -- устанавливает множитель расстояния до игрока
    self:_set_offsets(d, d, d)
    self.distance = d
end

function camera.setRotateVertical(self, degree)
    -- устанавливает смещение угла взгляда (выше, ниже) на игрока
    self.a_degree = degree
    self:_set_angles(self.a_degree, self.b_degree, self.c_degree)
end

function camera.setRotateHorizontal(self, degree)
    -- устанавливает смещение угла взгляда (правее, левее) на игрока
    self.b_degree = degree
    self:_set_angles(self.a_degree, self.b_degree, self.c_degree)
end

function camera.setRotateProjection(self, degree)
    -- устанавливает смещение угла проекции изображение
    -- (насколько картинка поворачивается вокруг своей оси)
    self.c_degree = degree
    self:_set_angles(self.a_degree, self.b_degree, self.c_degree)
end

function camera.reset(self)
    -- восстанавливает положение камеры до исходного
    -- (на момент инициализации камеры)
    self:setDistanceToPlayer(1)
    self:setRotateVertical(0)
    self:setRotateHorizontal(0)
    self:setRotateProjection(0)
end

camera.update = camera._invalidate

return camera
