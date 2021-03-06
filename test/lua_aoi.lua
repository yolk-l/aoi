
local AoiTower = {}
AoiTower.__index = AoiTower

function AoiTower:new(row, col)
    local o = {}
    setmetatable(o, self)
    o:init(row, col)
    return o
end

function AoiTower:init(row, col)
    self.row = row
    self.col = col
    self.obj_tbl = {}
end

function AoiTower:add(uuid, x, z)
    self.obj_tbl[uuid] = {x = x, z = z}
end

function AoiTower:get(uuid)
    return self.obj_tbl[uuid]
end

function AoiTower:delete(uuid)
    self.obj_tbl[uuid] = nil
end

local AoiMgr = {}
AoiMgr.__index = AoiMgr

function AoiMgr:new(...)
    local o = {}
    setmetatable(o, self)
    o:init(...)
    return o
end

function AoiMgr:init(max_x, max_z, view_x, view_z, view_grid)
    self.view_x = view_x
    self.view_z = view_z
    self.max_x = max_x
    self.max_z = max_z
    self.max_row = self.max_z / self.view_z
    if (self.max_z%self.view_z) ~= 0 then
        self.max_row = self.max_row + 1
    end
    self.max_col = self.max_x / self.view_x
    if (self.max_x%self.view_x) ~= 0 then
        self.max_col = self.max_col + 1
    end
    self.aoi_grid = view_grid
    self.tower_tbl = {}
    self.uuid_tbl = {}
end

function AoiMgr:get_tower(row, col)
    if not (row>=0 and row<self.max_row and col>=0 and col<self.max_col) then
        return
    end
    local key = row*self.max_col + col
    if not self.tower_tbl[key] then
        self.tower_tbl[key] = AoiTower:new(row, col)
    end
    return self.tower_tbl[key]
end

function AoiMgr:add(id, x, z)
    local enter_tbl = {}
    local row = z // self.view_z
    local col = x // self.view_x
    local oTower = self:get_tower(row, col)
    if not oTower then
        return
    end
    for i=-self.aoi_grid,self.aoi_grid do
        for j=-self.aoi_grid,self.aoi_grid do
            local r = row + i
            local c = col + j
            local t = self:get_tower(r, c)
            if t then
                for uuid in pairs(t.obj_tbl) do
                    enter_tbl[uuid] = 1
                end
            end
        end
    end
    oTower:add(id, x, z)
    self.uuid_tbl[id] = oTower
    return enter_tbl
end

function AoiMgr:update(id, x, z)
    local oTower = self.uuid_tbl[id]
    if not oTower then
        return
    end
    local new_row = z // self.view_z
    local new_col = x // self.view_x
    local old_row = oTower.row
    local old_col = oTower.col
    if old_row == new_row and old_col == new_col then
        return
    end
    local oNewTower = self:get_tower(new_row, new_col)
    if not oNewTower then
        return
    end
    oTower:delete(id)
    oNewTower:add(id, x, z)
    self.uuid_tbl[id] = oNewTower
    local leave_tbl = {}
    for i=-self.aoi_grid,self.aoi_grid do
        for j=-self.aoi_grid,self.aoi_grid do
            local r = old_row + i
            local c = old_col + j
            local t = self:get_tower(r, c)
            if t and (math.abs(new_row - r)>self.aoi_grid or math.abs(new_col - c)>self.aoi_grid) then
                for uuid in pairs(t.obj_tbl) do
                    if uuid ~= id then
                        leave_tbl[uuid] = 1
                    end
                end
            end
        end
    end
    local enter_tbl = {}
    for i=-self.aoi_grid,self.aoi_grid do
        for j=-self.aoi_grid,self.aoi_grid do
            local r = new_row + i
            local c = new_col + j
            local t = self:get_tower(r, c)
            if t and (math.abs(old_row - r)>self.aoi_grid or math.abs(old_col - c)>self.aoi_grid) then
                for uuid in pairs(t.obj_tbl) do
                    if uuid ~= id then
                        enter_tbl[uuid] = 1
                    end
                end
            end
        end
    end
    return {leave_tbl,enter_tbl}
end

function AoiMgr:delete(id)
    local oTower = self.uuid_tbl[id]
    if not oTower then
        return
    end
    oTower:delete(id)
    self.uuid_tbl[id] = nil
    local leave_tbl = {}
    for i=-self.aoi_grid,self.aoi_grid do
        for j=-self.aoi_grid,self.aoi_grid do
            local r = oTower.row + i
            local c = oTower.col + j
            local t = self:get_tower(r, c)
            if t then
                for uuid in pairs(t.obj_tbl) do
                    leave_tbl[uuid] = 1
                end
            end
        end
    end
    return leave_tbl
end

function AoiMgr:release()
    self.tower_tbl = {}
    self.uuid_tbl = {}
end

local M = {}
function M.create(max_x, max_z, view_x, view_z, view_grid)
    return AoiMgr:new(max_x, max_z, view_x, view_z, view_grid)
end
return M