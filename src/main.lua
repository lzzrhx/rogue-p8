-------------------------------------------------------------------------------
-- todo
-------------------------------------------------------------------------------

-- animations: move and attack
-- character screen
-- inventory screen
-- main menu
-- locked doors and keys
-- chests
-- health potion
-- equipable items
-- ranged combat
-- talk to npcs
-- pet helps in battle
-- make stairs work
-- character stats
-- scrolls
-- rings
-- other potions
-- magic system
-- intro screen
-- field of view (shadowcasting)
-- pathfinding
-- score system
-- bones file


-------------------------------------------------------------------------------
-- globals
-------------------------------------------------------------------------------

-- constants
timer_grave = 20  -- timeout for grave
width=128   -- area width
height=64  -- area height
ui_h = 2   -- height of bottom ui

-- states
state_reset = "reset"
state_game = "game"
state_dead = "dead"
state_look = "look"
state_read = "read"
state_menu = "menu"

-- vars
state=nil
dt=0
frame=0    -- animation frame number
cam_x=0    -- camera y position
cam_y=0    -- camera x position
turn=1     -- turn number

-- sprites
sprites = {
    void=0,
    empty=1,
    grave=3,
    pet_cat=17,
    pet_dog=18,
    selection=2,
}

-- enum, flags
flags={
    collision=0,
    --unused_one=1,
    --unused_two=2,
    --unused_three=3,
    --unused_four=4,
    --unused_five=5,
    --unused_six=6,
    entity=7,
}


-------------------------------------------------------------------------------
-- built-in functions
-------------------------------------------------------------------------------

-- built-in init function
function _init()
    -- set initial state
    change_state(state_game)
    -- populate the world map with entities
    populate_map()
end

-- built-in update function
function _update()
    -- set animation frame
    frame = flr(t() * 2 % 2)
    -- update for the current state
    update[state]()
end

-- built-in draw function
function _draw()
    -- draw for the current state
    draw[state]()
    -- increment animation
    draw.anim = draw.anim >= 128 and 128 or draw.anim+4
    -- draw flash
    if (draw.flash_n > 0) then
        cls((player.hp < 5 and draw.flash_n==1 and 8) or 7)
        draw.flash_n-=1
    end
end


-------------------------------------------------------------------------------
-- init
-------------------------------------------------------------------------------

init = {
    -- reset state
    reset = function()
        timer_reset=1
    end,

    -- game state
    game = function()
    end,

    -- look state
    look = function()
        sel.look.x = player.x
        sel.look.y = player.y
        change_look()
    end,

    -- menu state
    menu = function()
        sel.menu.tab=0
        sel.menu.n=1
    end,

    -- read state
    read = function()
    end,

    -- game over state
    dead = function()
        sel.dead=0
    end,
}

-------------------------------------------------------------------------------
-- update
-------------------------------------------------------------------------------

update = {
    -- reset state
    reset = function()
        timer_reset=-1
        if(timer_reset <= 0) run()
    end,

    -- game state
    game = function()
        -- get input and perform turn
        if (input.game()) do_turn()
    end,

    -- look state
    look = function()
        if (input.look()) change_look()
    end,

    -- menu state
    menu = function()
        input.menu()
    end,

    -- read state
    read = function()
        input.read()
    end,

    -- game over state
    dead = function()
        input.dead()
    end,
}


-------------------------------------------------------------------------------
-- draw
-------------------------------------------------------------------------------

draw = {

    anim=0,

    -- flash the screen
    flash_n = 0,
    flash = function(self)
        self.flash_n = 2
    end,

    reset = function()
    end,

    -- frame
    frame = function()
        line(0,0,127,0,6)     -- top
        line(127,0,127,127,6) -- right
        line(0,127,127,127,6) -- bottom
        line(0,0,0,127,6)     -- left
        pset(0,0,0)
        pset(127,0,0)
        pset(0,127,0)
        pset(127,127,0)
    end,

    bottom_box = function()
        -- bottom ui box
        rectfill(0,111,127,127,1)
        line(0,111,127,111,6)
    end,

    -- shadow_mode
    shadow = function()
        -- screen memory as the sprite sheet
        poke(0x5f54,0x60)
        -- set overlay palette
        pal(split'0,1,1,1,1,1,1,1,1,1,1,1,1,1,1')
        -- draw screen to screen 
        -- (sprite sheet x,sprite sheet y,width,height,screen x,screen y)
        sspr(unpack(split"0,0,128,128,0,0")) 
        -- reset palette
        pal()
        -- reset spritesheet
        poke(0x5f54,0x00)
    end,

    -- game state
    game = function()
        -- clear screen
        cls()
        -- draw map
        map(cam_x,cam_y, 0, 0,16,16-ui_h)
        -- draw entities
        for e in all(entity.entities) do if (not e.collision) e:draw() end
        for e in all(entity.entities) do if (e.collision) e:draw() end
        -- bottom ui box
        draw.bottom_box()
        --line(0,119,128,119,6)
        hp_ratio=max(0,player.hp/player.max_hp)
        rectfill(2+12,113+7,2+80,117+7,5)
        --rectfill(2+12,113+7,2+12+68*hp_ratio,117+7+1,0)
        rectfill(2+12,113+7,2+12+68*hp_ratio,117+7,(hp_ratio < 0.25 and 8) or (hp_ratio < 0.5 and 9) or (hp_ratio < 0.75 and 10) or 11)
        print("hp:",2,127-7*1+1,5)
        print("hp:",2,127-7*1,6)
        --print(player.hp,2+12,127-7*3,0)
        --print("xp:" .. player.xp,2,127-7*2,6)
        -- bottom ui right text
        ui_z="menu 🅾️"
        ui_x="look ❎"
        print(ui_z,128-str_width(ui_z)-2,127-7*2+1,5)
        print(ui_z,128-str_width(ui_z)-2,127-7*2,6)
        print(ui_x,128-str_width(ui_x)-2,127-7*1+1,5)
        print(ui_x,128-str_width(ui_x)-2,127-7*1,6)

        -- message text
        
        --clip(0,0,draw.anim+1,128)
        --print(log.entries[#log.entries][2],2,127-7*3,10)
        clip(0,0,draw.anim,128)
        print(log.entries[#log.entries][2],2,127-7*2+1,5)
        print(log.entries[#log.entries][2],2,127-7*2,6)
        clip(draw.anim,0,3,128)
        print(log.entries[#log.entries][2],2,127-7*2-1,7)
        clip()
        -- draw frame
        draw.frame()
    end,

    -- look state
    look = function()
        draw.game()
        --line(pos_to_screen(player).x+4,pos_to_screen(player).y+4,pos_to_screen(sel[state]).x+4,pos_to_screen(sel[state]).y+4,7)
        if (state == state_look) draw.shadow()
        player:draw()
        if(sel.look.entity~=nil) sel.look.entity:draw()
        spr(sprites.selection,pos_to_screen(sel.look).x,pos_to_screen(sel.look).y)
        draw.bottom_box()
        -- bottom ui left text
        print("target:",2,127-7*2+1,5)
        print("target:",2,127-7*2,6)
        print(sel.look.name,2,127-7*1+1,5)
        if (sel.look.entity~=nil) then 
            print(sel.look.name,2,127-7*1+1,sel.look.entity.parent_class==creature.class and 0 or 5)
            print(sel.look.name,2,127-7*1,sel.look.color)
        end
        -- bottom ui right text
        ui_z="cancel 🅾️"
        ui_x=sel.look.text .. " ❎"
        print(ui_z,128-str_width(ui_z)-2,127-7*2+1,5)
        print(ui_z,128-str_width(ui_z)-2,127-7*2,6)
        print(ui_x,128-str_width(ui_x)-2,127-7*1+1,5)
        if (sel.look.usable)print(ui_x,128-str_width(ui_x)-2,127-7*1,6)
        -- draw frame
        draw.frame()
    end,

    -- menu state
    menu = function()
        draw.game()
        if (state == state_menu) draw.shadow()
        rectfill(23,8*3-1,103,8*13-1,1)
        line(23,8*3-2,103,8*3-2,6)
        line(23,8*13,103,8*13,6)
        s_btn="cancel 🅾️  select ❎"
        inv_num=tbl_len(player.inventory)
        print(s_btn,64-str_width(s_btn)*0.5,113+1,5)
        clip(64-str_width(s_btn)*0.5,113,(sel.menu.tab == 1 and inv_num > 0 and 80) or 40,6)
        print(s_btn,64-str_width(s_btn)*0.5,113+1,5)
        print(s_btn,64-str_width(s_btn)*0.5,113,6)
        clip()
        if (sel.menu.tab == 0) then
            s="⬅️ character ➡️"
            print(s,64-str_width(s)*0.5,26,5)
            print(s,64-str_width(s)*0.5,25,6)
            s2="hp: " .. player.hp .. "/" .. player.max_hp .. "\nxp: " .. player.xp
            print(s2,28,34,6)
        elseif (sel.menu.tab == 1) then
            s="⬅️ inventory ➡️"
            print(s,64-str_width(s)*0.5,26,5)
            print(s,64-str_width(s)*0.5,25,6)
            s_inv="empty"
            if inv_num > 0 do
                s_inv=""
                for i=1,inv_num do
                    s_inv=s_inv..((sel.menu.n==i and "▶ ") or " ")..player.inventory[i].."\n"
                end
            end
            print(s_inv,28,34,5)
            clip(23,28+6*sel.menu.n,80,6)
            print(s_inv,28,34,6)
            clip()
        end
    end,

    -- read state
    read = function()
        draw.look()
        draw.shadow()
        s=sel.read.text
        h=str_height(s)
        w=str_width(s)
        exp=((h>5 and h-5) or 0)*3
        s_off=((h<5 and 5-h) or 0)*3
        --rectfill(23+1,40-exp+1,103+1,70+exp+1,1)
        --line(24+1,71+exp+1,102+1,71+exp+1,1)
        rectfill(23,40-exp,103,70+exp,sel.read.bg)
        line(24,39-exp,102,39-exp,sel.read.bg)
        line(24,71+exp,102,71+exp,sel.read.bg)
        print(s,64-w*0.5,41-exp+s_off,sel.read.fg)
        s2="continue ❎"
        print(s2,64-str_width(s2)*0.5,80+exp+1,5)
        print(s2,64-str_width(s2)*0.5,80+exp,6)
    end,

    -- game over state
    dead = function()
        draw.game()
        draw.shadow()
        --for i=31,95 do line(i,70,i,70+rnd(8),8) end
        --rectfill(32,40,94,70,0)
        rect(24,44+8,103,83-8,7)
        --line(32,39,94,39,6)
        --line(32,71,94,71,6)
        --line(31,40,31,70,6)
        --line(95,40,95,70,6)
        s="g a m e   o v e r"
        print(s,64-str_width(s)*0.5,32+8+1,1)
        print(s,64-str_width(s)*0.5,32+8,8)
        print("▶",28,50+8+sel.dead*7,7)
        print("restart",34+((sel.dead==0 and 1) or 0),50+8,7)
        print("quit",34+((sel.dead==1 and 1) or 0),50+8+8,7)
        --print((sel.dead==1 and "▶" or " ") .. "quit",46,61,sel.dead==1 and 6 or 5)
        s="select ❎"
        print(s,64-str_width(s)*0.5,80+4+1,5)
        print(s,64-str_width(s)*0.5,80+4,6)
    end,
}


-------------------------------------------------------------------------------
-- input
-------------------------------------------------------------------------------
input = {
    -- game state
    game = function()
        valid = false
        if (btnp(⬆️)) valid = player:action_dir(player.x,player.y-1)
        if (btnp(➡️)) valid = player:action_dir(player.x+1,player.y)
        if (btnp(⬇️)) valid = player:action_dir(player.x,player.y+1)
        if (btnp(⬅️)) valid = player:action_dir(player.x-1,player.y)
        if (btnp(🅾️)) change_state(state_menu)
        if (btnp(❎)) change_state(state_look)
        return valid
    end,

    -- look state
    look = function()
        if (btnp(⬆️) and sel.look.y-cam_y > 0) sel.look.y-=1
        if (btnp(➡️) and sel.look.x-cam_x < 15) sel.look.x+=1
        if (btnp(⬇️) and sel.look.y-cam_y < 15-ui_h) sel.look.y+=1
        if (btnp(⬅️) and sel.look.x-cam_x > 0) sel.look.x-=1
        if (btnp(🅾️)) then 
            change_state(state_game)
            return false
        end
        if (btnp(❎) and sel.look.usable) then
            sel.look.entity:interact()
            return false
        end
        return true
    end,

    -- menu state
    menu = function()
        if (btnp(⬅️))sel.menu.tab=(sel.menu.tab-1)%2
        if (btnp(➡️))sel.menu.tab=(sel.menu.tab+1)%2
        if (btnp(🅾️))change_state(state_game)
        if (sel.menu.tab==1) then
            inv_num=tbl_len(player.inventory)
            if (btnp(⬆️) and sel.menu.n>1)sel.menu.n-=1
            if (btnp(⬇️) and sel.menu.n<inv_num)sel.menu.n+=1
        end
        --if (btnp(❎)) change_state(state_look)
    end,

    -- read state
    read = function()
        --if (btnp(🅾️)) state=state_look
        if (btnp(❎)) change_state(state_game)
    end,

    -- game over state
    dead = function()
        options={[0]=reset,[1]=quit}
        if (btnp(⬆️) and sel[state]>0)sel[state]-=1
        if (btnp(⬇️) and sel[state]<tbl_len(options)-1)sel[state]+=1
        if (btnp(❎))options[sel[state]]()
    end,
}


-------------------------------------------------------------------------------
-- selection
-------------------------------------------------------------------------------

sel = {
    look={},
    read={},
    menu={},
    dead=0,
}

-------------------------------------------------------------------------------
-- log
-------------------------------------------------------------------------------

log={
    -- initialize log entries table
    entries={{0,"welcome to game"}},

    -- add message to log
    add = function(self, message)
        draw.anim=0
        add(self.entries,{turn,message})
    end,
}


-------------------------------------------------------------------------------
-- utils
-------------------------------------------------------------------------------

-- calculate distance between two points
function dist(a,b)
    return sqrt((b.x-a.x)^2 + (b.y-a.y)^2)
end

-- calculate distance between two points (simple)
function dist_simp(a,b)
    return max(abs(b.x-a.x),abs(b.y-a.y))
end

-- calculate distance between two points (simple)
function dist_simp_xy(x0,y0,x1,y1)
    return max(abs(x1-x0),abs(y1-y0))
end

-- calculate string width
function str_width(s)
    return print(s,0,128)
end

-- calculate string height
function str_height(s)
    return tbl_len(split(s,"\n"))
end

-- merge table b into table a
function tbl_merge(a,b)
    for k,v in pairs(b) do
        a[k] = v
    end
end

-- check length of table
function tbl_len(t)
    num = 0
    for k,v in pairs(t) do num+=1 end
    return num
end

-- transform position to screen position
function pos_to_screen(pos)
    return {
        x = 8 * (pos.x-cam_x),
        y = 8 * (pos.y-cam_y),
    }
end


-------------------------------------------------------------------------------
-- system
-------------------------------------------------------------------------------

-- reset cart
function reset() 
    change_state(state_reset)
    for i=0x0,0x7fff,rnd(0xf) do
        poke(i, rnd(0xf))
    end
end

-- quit cart
function quit()
    cls()
    stop()
end

-- change state
function change_state(new_state)
    state=new_state
    init[state]()
end


-------------------------------------------------------------------------------
-- game state
-------------------------------------------------------------------------------

-- iterate through all map tiles and find entities
function populate_map()
    for x=0,127 do
        for y=0,63 do
            if (mget(x,y) == 0) mset(x,y,sprites.empty)
            if (fget(mget(x,y),flags.entity)) entity.spawn(mget(x,y),x,y)
        end
    end
end

-- check for collision
function collision(x,y)
    if (fget(mget(x,y),flags.collision)) return true
    for e in all(entity.entities) do if (e.collision and e.x==x and e.y==y) return true end
    return false
end

-- perform turn
function do_turn()
    -- update entities
    for e in all(entity.entities) do e:update() end
    -- update camera
    update_camera()
    -- increment turn counter
    turn+=1
end

-- update camera position
function update_camera()
    if (player.x - cam_x > 11 and cam_x < width-16) then
        cam_x = player.x - 11
    elseif (player.x - cam_x < 4 and cam_x > 0) then
        cam_x = player.x - 4
    elseif (player.y - cam_y > 8 and cam_y < height-16+ui_h) then
        cam_y = player.y - 8
    elseif (player.y - cam_y < 4 and cam_y > 0) then
        cam_y = player.y - 4
    end
end


-------------------------------------------------------------------------------
-- look state
-------------------------------------------------------------------------------

-- change look target
function change_look()
    e = entity.get(sel.look.x,sel.look.y)
    tbl = sel.look
    tbl.entity = (e ~= player and e) or nil
    tbl.name="none"
    tbl.usable=false
    tbl.text="interact"
    tbl.color=5
    if(tbl.entity~=nil) then
        tbl.name=(e.name~=nil and e.name) or e.class
        tbl.usable=e.interactable and dist_simp(player,e) <= e.interact_dist
        tbl.color=6
        tbl.text=e.interact_text
        if(e.class==door.class) then 
            tbl.usable = (tbl.usable and e.locked==0)
            tbl.text = (e.collision and "open") or "close"
        end
    if (e.parent_class==creature.class) tbl.color= (e.hostile and 2) or 3
    end
    return properties
end
