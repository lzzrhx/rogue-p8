function _init()

    -- constants
    empty=48
    width=128
    height=64

    -- list of entities
    entities={}

    -- player
    player=entity:new({ x = 1, y = 1, sprite = 0})
    player.attacked=false

    -- flags
    flags={}
    flags.coll=0
    flags.entity=1

    cam={}
    cam.x=0
    cam.y=0

    pbtn=0
    no=0
    frame=0

    -- iterate through map and find entities
    for x=0,127 do
        for y=0,63 do
            if (fget(mget(x,y),flags.entity)) spawn(mget(x,y),x,y)
        end
    end
end

function _update()
    -- get player input
    if (input()) turn()
        frame = flr(t() * 2 % 2)
end

function _draw()
    cls()
    -- draw map
    map(cam.x,cam.y)
    -- draw player
    --draw(player)
    player:draw()
    -- draw entities
    for entity in all(entities) do entity:draw() end
    -- draw gui
    --print("tst:" .. dist(entities[3], player),0,128-8*8)
    --print("ani:" .. frame,0,128-8*7)
    print("no: " .. no,0,128-8*3)
    print("p.x:" .. player.x,0,128-8*2)
    print("p.y:" .. player.y,0,128-8*1)
    --print("c.x:" .. cam.x,0,128-8*3)
    --print("c.y:" ..cam.y,0,128-8*2)
    --print("btn:" .. pbtn,0,128-8*1)
end

-- handle input
function input()
    acted = false
    if (pbtn ~= btn()) then
        if (btn(⬆️)) acted = move(player,player.x, player.y-1)
        if (btn(➡️)) acted = move(player,player.x+1,player.y)
        if (btn(⬇️)) acted = move(player,player.x, player.y+1)
        if (btn(⬅️)) acted = move(player,player.x-1,player.y)
    end
    pbtn=btn()
    return acted
end

-- try to move entity
function move(a,x,y)
    if not coll(x,y) and x >= 0 and x < width and y >= 0 and y < height then
        a.x = x
        a.y = y
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

function dist(a,b)
    return sqrt((b.x-a.x)^2 + (b.y-a.y)^2)
end

function attack(a,b)
    player.attacked=true
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
    if (player.x - cam.x > 16-4 and cam.x < width-16) then
        cam.x = player.x - (16-4)
    elseif (player.x - cam.x < 4 and cam.x > 0) then
        cam.x = player.x - 4
    elseif (player.y - cam.y > 16-4 and cam.y < height-16) then
        cam.y = player.y - (16-4)
    elseif (player.y - cam.y < 4 and cam.y > 0) then
        cam.y = player.y - 4
    end
end

-- do turn
function turn()
    --player.attacked = false
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
    add(entities,entity:new({sprite=s,x=x,y=y}))
end


--global
global=_ENV

-- class
class = setmetatable({
    new = function(self,tbl)
        tbl=tbl or {}
        setmetatable(tbl,{
            __index=self
        })
        return tbl
    end,
}, {__index=_ENV})

-- entity
entity = class:new({
    x = 0,
    y = 0,
    sprite = 0,

    new = function(self,tbl)
        tbl=tbl or {}
        setmetatable(tbl,{
            __index=self
        })
        return tbl
    end,

    update = function(_ENV)
    end,

    draw = function(_ENV)
        if (x >= cam.x and x < cam.x+16 and y >= cam.y and y < cam.y+16) then
            spr(attacked and (frame == 0 and sprite+2 or empty) or sprite+frame,8*(x-cam.x),8*(y-cam.y))
        end
    end,
})

-- enemy
enemy = entity:new({
    attacked = false,
    hostile = false,
    ranged = false,
    move_random = false,
    --[[
        if (self.hostile) then
            if (self.ranged) then
                -- ...
            else
                if (dist(self,player) <= 1) then
                    attack(self,player)
                else
                    move_towards_player(self)
                end
            end
        end
    ]]--
})

--[[
function draw(self)
    if (self.x >= cam.x and self.x < cam.x+16 and self.y >= cam.y and self.y < cam.y+16) then
        spr(self.attacked and (frame == 0 and self.sprite+2 or empty) or self.sprite+frame,8*(self.x-cam.x),8*(self.y-cam.y))
    end
end
]]--
