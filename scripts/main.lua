function _init()

    -- constants
    empty=48
    width=128
    height=64

    log={}

    -- player
    player = add(entities, entity:new({ x = 1, y = 1, sprite = 0}))

    -- flags
    flags={}
    flags.coll=0
    flags.entity=1

    cam_x=0
    cam_y=0

    -- vars
    pbtn=0
    no=0
    frame=0
    
    -- iterate through map and find entities
    for x=0,127 do
        for y=0,63 do
            if (fget(mget(x,y),flags.entity)) spawn(mget(x,y),x,y)
        end
    end

    add(log,"game started")
end

function _update()
    -- get player input
    if (input()) turn()
    frame = flr(t() * 2 % 2)
end

function _draw()
    cls()
    -- draw map
    map(cam_x,cam_y)
    -- draw entities
    for entity in all(entities) do entity:draw() end
    -- draw gui
    --fillp(0x8016)
    rectfill(0,104,128,128,0)
    line(0,104,128,104,6)
    --fillp()
    print("no: " .. no,2,128-7*3,6)
    print("hp: " .. player.hp,2,128-7*2,6)
    print(log[#log],2,128-7*1,6)
    --print(menu_text(),2,128-7*1,6)
    --print("p.x:" .. player.x,2,128-7*2,6)
    --print("p.y:" .. player.y,2,128-7*1,6)
end

--[[
function menu_text()
    result = ""
    for k,v in pairs(menu) do
        if (k == sel) then
            result = result .. " >"
        else
            result = result .. "  "
        end
        result = result .. v
    end
    return result
end

menu = {
    [0] = "wait",
    [1] = "...",
}
]]--

-- handle input
function input()
    valid = false
    if (pbtn ~= btn()) then
        if (btn(⬆️)) valid = move(player,player.x, player.y-1)
        if (btn(➡️)) valid = move(player,player.x+1,player.y)
        if (btn(⬇️)) valid = move(player,player.x, player.y+1)
        if (btn(⬅️)) valid = move(player,player.x-1,player.y)
    end
    pbtn=btn()
    return valid
end

-- try to move entity
function move(a,x,y)
    if not coll(x,y) and x >= 0 and x < width and y >= 0 and y < height then
        a.x = x
        a.y = y
        --add(log,"moved")
        return true
    end
    return false
end

function move_random(a)
    x = 1
    if (rnd() < 0.5) x = -1
    y = 1
    if (rnd() < 0.5) y = -1
    move(a,a.x+x,a.y+y)
end

function move_towards_player(a)
    x = player.x - a.x
    y = player.y - a.y
    if (abs(x) > abs(y)) then
        if (x > 0) then
            move(a,a.x+1, a.y)
        else
            move(a,a.x-1, a.y)
        end
    else
        if (y > 0) then
            move(a,a.x, a.y+1)
        else
            move(a,a.x, a.y-1)
        end
    end
end

function attack(a,b)
    b.hp-=1
    b.attacked=true
end

-- check for collision
function coll(x,y)
    if (fget(mget(x,y),flags.coll)) return true
    if (player.x == x and player.y == y) return true
    for entity in all(entities) do
        if (entity.x == x and entity.y == y) return true
    end
    return false
end

-- update camera
function camera()
    if (player.x - cam_x > 16-4 and cam_x < width-16) then
        cam_x = player.x - (16-4)
    elseif (player.x - cam_x < 4 and cam_x > 0) then
        cam_x = player.x - 4
    elseif (player.y - cam_y > 16-4 and cam_y < height-16) then
        cam_y = player.y - (16-4)
    elseif (player.y - cam_y < 4 and cam_y > 0) then
        cam_y = player.y - 4
    end
end

-- do turn
function turn()
    for entity in all(entities) do entity.attacked = false end
    -- update entities
    for entity in all(entities) do entity:update() end
    -- update camera
    camera()
    no+=1
end

-- spawn entity
function spawn(s,x,y)
    mset(x,y,empty)
    if (s == 20) then
        enemy:new({sprite=s,x=x,y=y})
    else
        entity:new({sprite=s,x=x,y=y})
    end
end

-- class
object = {
    inherit = function(self, table)
        table=table or {}
        setmetatable(table,{
            __index=self
        })
        return table
    end,
}

-- entity
entities={}
entity = object:inherit({
    x = 0,
    y = 0,
    sprite = 0,
    attackable = false,
    attacked = false,
    hp = 10,

    new = function(self, table)
        local new_entity = self:inherit(table)
        add(entities, new_entity)
        return new_entity
    end,

    update = function(self)
    end,

    draw = function(self)
        if (self.x >= cam_x and self.x < cam_x+16 and self.y >= cam_y and self.y < cam_y+16) then
            spr(self.attacked and (frame == 0 and self.sprite+2 or empty) or self.sprite+frame,8*(self.x-cam_x),8*(self.y-cam_y))
        end
    end,
})

-- enemy
enemy = entity:inherit({
    hostile = true,

    update = function(self)
        if (self.hostile) then
            if (dist(self,player) <= 1) then
                attack(self,player)
            else
                move_towards_player(self)
            end
        end
    end,
})
