-------------------------------------------------------------------------------
-- globals
-------------------------------------------------------------------------------

-- constants
timer_corpse=20 -- timeout for grave
timer_target=3 -- timeout for target
width=128 -- area width
height=64 -- area height
ui_h=2 -- row height of bottom ui box

-- vars
state=nil -- game state
turn=1 -- turn number
frame=0 -- animation frame
prev_frame=0 -- previous animation frame
cam_x=0 -- camera x position
cam_y=0 -- camera y position
cam_offset=4 -- camera scroll offset
blink_frame=0

-- game states
state_reset="reset"
state_game="game"
state_menu="menu"
state_look="look"
state_chest="chest"
state_read="read"
state_dead="dead"

-- selection
sel={menu={},look={},chest={},read={},dead=0,}

-- sprites
sprites={
  void=0,
  empty=1,
  selection=2,
  grave=3,
  chest_closed=11,
  chest_open=12,
  companion_cat=17,
  companion_dog=18,
  door_closed=82,
  door_open=81,
}

-- flags
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

-- options
options={
  disable_flash=false,
}

-------------------------------------------------------------------------------
-- built-in functions
-------------------------------------------------------------------------------

-- init
function _init()
  change_state(state_game)
  populate_map()
end

-- update
function _update()
  if(state==state_reset)then
    run()
  else
    blink_frame=(blink_frame+1)%2
    blink=blink_frame%2==0
    prev_frame=frame
    frame=flr(t()*2%2)
    update[state]()
  end
end

-- draw
function _draw()
  if(state~=state_reset)then
    draw[state]()
    draw.flash_step()
  end
end



-------------------------------------------------------------------------------
-- init
-------------------------------------------------------------------------------
init={
  -- game state
  game=function() end,

  -- menu state
  menu=function()
    sel.menu.tab=0
    sel.menu.i=1
  end,

  -- look state
  look=function()
    sel.look.x=player.x
    sel.look.y=player.y
    set_look()
  end,

  -- chest state
  chest=function()
    sel.chest.anim_frame={}
    sel.chest.anim_playing=true
    for itm in all(sel.chest.entity.content) do add(sel.chest.anim_frame,60) end
  end,

  -- read state
  read=function() end,

  -- dead state
  dead=function() sel.dead=0 end,
}



-------------------------------------------------------------------------------
-- update
-------------------------------------------------------------------------------
update={
  -- game state
  game=function()
    if(not creature.anim_playing and input.game())do_turn()
    for e in all(entity.entities) do e:update() end
  end,

  -- menu state
  menu=function() input.menu() end,

  -- look state
  look=function() if(input.look())set_look() end,

  -- chest state
  chest=function()
    if(sel.chest.entity.play_anim)sel.chest.entity:anim_step()
    if(sel.chest.anim_frame[num]<=0)input.chest()
    end,

  -- read state
  read=function() input.read() end,

  -- dead state
  dead=function() input.dead() for e in all(entity.entities) do e:update() end end,
}



-------------------------------------------------------------------------------
-- draw
-------------------------------------------------------------------------------
draw={
  -- flash the screen
  flash_n=0,
  flash_step=function()
    if(not options.disable_flash and draw.flash_n>0)then
      cls((state==state_game and player.hp<5 and draw.flash_n==1 and 8) or 7)
      draw.flash_n-=1
    end
  end,

  -- monochrome mode
  monochrome=function(c)
    c=c or 1
    -- screen memory as the sprite sheet
    poke(0x5f54,0x60)
    pal({0,c,c,c,c,c,c,c,c,c,c,c,c,c,c})
    sspr(0,0,128,128,0,0)
    pal()
    -- reset spritesheet
    poke(0x5f54,0x00)
  end,

  -- window frame
  window_frame=function()
    rectfill(0,111,127,127,1)
    line(0,111,127,111,6)
    rect(0,0,127,127,6)
    pset(0,0,0)
    pset(127,0,0)
    pset(0,127,0)
    pset(127,127,0)
  end,

  -- game state
  game=function()
    -- draw map and entities
    cls()
    update_camera()
    map(cam_x-1,cam_y-1,-8,-8,18,18-ui_h)
    for e in all(entity.entities) do if (not e.collision) e:draw() end
    for e in all(entity.entities) do if (e.collision) e:draw() end
    camera()
    draw.window_frame()
    -- vars
    hp=max(0,player.hp/player.max_hp)
    s_z="menu 🅾️"
    s_x="look ❎"
    -- animated message
    clip(0,0,msg.frame,128)
    if(state==state_game)print(msg.txt,2,114,5)
    print(msg.txt,2,113,6)
    clip(msg.frame,0,(msg.frame>msg.width-3 and msg.width-msg.frame) or 3,128)
    print(msg.txt,2,112,7)
    clip()
    if(state==state_game or state==state_dead)msg.anim_step()
    -- ui elements (shadow)
    if(state==state_game)then
      print("hp:",2,121,5)
      rectfill(14,120,82,124,5)
      print(s_z,126-str_width(s_z),114,5)
      print(s_x,126-str_width(s_x),121,5)
    end
    -- ui elements
    print("hp:",2,120,6)
    if(hp>0)rectfill(14,120,14+68*hp,124,(hp<0.25 and 8) or (hp<0.5 and 9) or (hp<0.75 and 10) or 11)
    print(s_z,126-str_width(s_z),113,6)
    print(s_x,126-str_width(s_x),120,6)
  end,

  -- menu state
  menu=function()
    -- draw map and entities
    draw.game()
    draw.monochrome()
    -- vars
    s_btn="cancel 🅾️  select ❎"
    s_chr="⬅️ character ➡️"
    s_inv="⬅️ inventory ➡️"
    s_items="empty"
    -- bg box
    rectfill(23,23,103,103,1)
    line(23,22,103,22,6)
    line(23,104,103,104,6)
    -- button legend
    print(s_btn,64-str_width(s_btn)*0.5,114,5)
    clip(64-str_width(s_btn)*0.5,113,(sel.menu.tab==1 and inventory.num>0 and inventory.items[sel.menu.i].interactable and 80) or 40,6)
    print(s_btn,64-str_width(s_btn)*0.5,113,6)
    clip()
    -- character tab
    if (sel.menu.tab==0) then
      print(s_chr,64-str_width(s_chr)*0.5,26,5)
      print(s_chr,64-str_width(s_chr)*0.5,25,6)
      print("hp: "..player.hp.."/"..player.max_hp.."\nxp: "..player.xp,28,34,6)
    -- inventory tab
    elseif (sel.menu.tab==1) then
      print(s_inv,64-str_width(s_inv)*0.5,26,5)
      print(s_inv,64-str_width(s_inv)*0.5,25,6)
      if (inventory.num>0) do for i=1,inventory.num do s_items=((i==1 and "") or s_items)..((sel.menu.i==i and "▶ ") or " ")..inventory.items[i].name.."\n" end end
      print(s_items,28,34,5)
      clip(23,28+6*sel.menu.i,80,6)
      print(s_items,28,34,6)
      clip()
    end
  end,

  -- look state
  look=function()
    -- draw map, entities and selection
    draw.game()
    if(state==state_look)draw.monochrome()
    player:draw()
    if(sel.look.entity~=nil)sel.look.entity:draw()
    if(state==state_look)spr(sprites.selection,pos_to_screen(sel.look).x,pos_to_screen(sel.look).y)
    draw.window_frame()
    -- vars
    s_z="cancel 🅾️"
    s_x=sel.look.text.." ❎"
    -- ui elements (shadow)
    if(state==state_look)then
      print("target:",2,114,5)
      print(sel.look.name,2,121,(sel.look.entity~=nil and sel.look.entity.parent_class==creature.class and 0) or 5)
      print(s_z,128-str_width(s_z)-2,114,5)
      print(s_x,128-str_width(s_x)-2,121,5)
    end
    -- ui elements
    print("target:",2,113,6)
    if(sel.look.entity~=nil)print(sel.look.name,2,120,sel.look.color)
    print(s_z,128-str_width(s_z)-2,113,6)
    if(sel.look.usable)print(s_x,126-str_width(s_x),120,6)
  end,

  -- chest state
  chest=function()
    -- draw map, entities and selection
    cls()
    player:draw()
    sel.chest.entity:draw()
    if (not sel.chest.anim_playing)draw.monochrome()
    -- vars
    s_x="take items ❎"
    num=tbl_len(sel.chest.entity.content)
    if (sel.chest.entity.anim_frame<=0) then
      for i=1,num do
        target={x=68-num*8+(i-1)*16,y=52}
        if (i==1 or sel.chest.anim_frame[i-1]<=0) then
          if (sel.chest.anim_frame[i]>0) then
            if(i==num)sel.chest.entity.play_anim=false
            pal({0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7})
            for j=0,10 do
              pos=sel.chest.entity:item_anim_pos(smoothstep(min(1,(1-(sel.chest.anim_frame[i]/60))+0.025*j)),target)
              if(blink)spr(sel.chest.entity.content[i].sprite,pos.x,pos.y)
            end
            pal()
            sel.chest.anim_frame[i]-=1
            if (sel.chest.anim_frame[num]<=0) then 
              sel.chest.anim_playing=false
              draw.flash_n=2
            end
          else
            if(not sel.chest.anim_playing or blink)wavy_spr(sel.chest.entity.content[i].sprite,target.x,target.y)
          end
        end
      end
    end
    if (not sel.chest.anim_playing) then
      wavy_print(s_x,64-str_width(s_x)*0.5,87,5)
      wavy_print(s_x,64-str_width(s_x)*0.5,86,6)
    end
  end,

  -- read state
  read=function()
    -- draw map, entities and selection
    draw.look()
    draw.monochrome()
    -- vars
    s_x="continue ❎"
    s_txt=sel.read.text
    h=str_height(s_txt)
    w=str_width(s_txt)
    exp=((h>5 and h-5) or 0)*3
    s_off=((h<5 and 5-h) or 0)*3
    -- bg and message text
    rectfill(23,39-exp,103,71+exp,sel.read.bg)
    line(24,38-exp,102,38-exp,sel.read.bg)
    line(24,72+exp,102,72+exp,sel.read.bg)
    print(s_txt,64-w*0.5,41-exp+s_off,sel.read.fg)
    -- button legend
    print(s_x,64-str_width(s_x)*0.5,82+exp,5)
    print(s_x,64-str_width(s_x)*0.5,81+exp,6)
  end,

  -- dead state
  dead=function()
    -- draw map, entities and selection
    draw.game()
    draw.monochrome()
    -- vars
    s="g a m e   o v e r"
    s_x="select ❎"
    -- title and menu box
    print(s,64-str_width(s)*0.5,41,1)
    print(s,64-str_width(s)*0.5,40,8)
    rect(24,52,103,75,7)
    print("▶",28,58+sel.dead*7,7)
    print("restart",34+((sel.dead==0 and 1) or 0),58,7)
    print("quit",34+((sel.dead==1 and 1) or 0),66,7)
    -- button legend
    print(s_x,64-str_width(s_x)*0.5,85,5)
    print(s_x,64-str_width(s_x)*0.5,84,6)
  end,
}



-------------------------------------------------------------------------------
-- input
-------------------------------------------------------------------------------
input={
  -- game state
  game=function()
    valid = false
    if(btnp(⬆️))valid=player:action_dir(player.x,player.y-1)
    if(btnp(➡️))valid=player:action_dir(player.x+1,player.y)
    if(btnp(⬇️))valid=player:action_dir(player.x,player.y+1)
    if(btnp(⬅️))valid=player:action_dir(player.x-1,player.y)
    if(btnp(🅾️))change_state(state_menu)
    if(btnp(❎))change_state(state_look)
    return valid
  end,

  -- look state
  look=function()
    if(btnp(⬆️)and sel.look.y-cam_y>0)sel.look.y-=1
    if(btnp(➡️)and sel.look.x-cam_x<15)sel.look.x+=1
    if(btnp(⬇️)and sel.look.y-cam_y<15-ui_h)sel.look.y+=1
    if(btnp(⬅️)and sel.look.x-cam_x>0)sel.look.x-=1
    if (btnp(🅾️)) then 
      change_state(state_game)
      return false
    end
    if (btnp(❎) and sel.look.usable) then
      sel.look.entity:interact()
      inventory.remove(sel.look.possession)
      return false
    end
    return true
  end,

  -- menu state
  menu=function()
    if(btnp(⬅️))sel.menu.tab=(sel.menu.tab-1)%2
    if(btnp(➡️))sel.menu.tab=(sel.menu.tab+1)%2
    if(btnp(🅾️))change_state(state_game)
    if (sel.menu.tab==1) then
      if(btnp(⬆️) and sel.menu.i>1)sel.menu.i-=1
      if(btnp(⬇️) and sel.menu.i<inventory.num)sel.menu.i+=1
      --if(btnp(❎) and inventory.num>0 and inventory.items[sel.menu.i].interactable)
    end
  end,

  -- chest state
  chest=function() if (btnp(❎)) change_state(state_game) end,

  -- read state
  read=function() if (btnp(❎)) change_state(state_game) end,

  -- dead state
  dead=function()
    options={[0]=reset,[1]=quit}
    if(btnp(⬆️) and sel[state]>0)sel[state]-=1
    if(btnp(⬇️) and sel[state]<tbl_len(options)-1)sel[state]+=1
    if(btnp(❎))options[sel[state]]()
  end,
}



-------------------------------------------------------------------------------
-- message
-------------------------------------------------------------------------------
msg={
  width=94,
  queue={},
  txt="welcome to game",
  turn=0,
  frame=0,
  delay=0,

  -- add message
  add=function(s)
    if (msg.turn<turn) then 
      msg.queue={}
      msg.turn=turn
      msg.txt_set(s)
    else
      add(msg.queue,s)
    end
  end,

  -- set the active message
  txt_set=function(s)
    msg.txt=s
    msg.frame=0
    msg.delay=8
  end,

  -- animate the active massage
  anim_step=function() if (msg.frame>=msg.width) then msg.frame=msg.width if (#msg.queue>0) then msg.delay-=1 if (msg.delay<=0) then msg.txt_set(deli(msg.queue,1)) end end else msg.frame+=3 end end,
}



-------------------------------------------------------------------------------
-- inventory
-------------------------------------------------------------------------------
inventory={
  items={},
  num=0,

  -- add item to inventory (from world)
  add=function(e)
    tbl=tbl_merge_new({name=e:get_name(),sprite=e.sprite},e.item_data)
    if(e.item_class==key.class)add(inventory.items,key:new(tbl))
    inventory.num+=1
  end,

  -- remove item from inventory
  remove=function(itm)
    if (itm~=nil) then
      del(inventory.items,itm)
      inventory.num-=1
    end
  end
}



-------------------------------------------------------------------------------
-- utils
-------------------------------------------------------------------------------

-- calculate distance between two points (simple)
function dist(a,b) return max(abs(b.x-a.x),abs(b.y-a.y)) end

-- calculate string width
function str_width(s) return print(s,0,128) end

-- calculate string height
function str_height(s) return tbl_len(split(s,"\n")) end

-- copy a table
function tbl_copy(a)
  tbl={}
  for k,v in pairs(a) do tbl[k]=v end
  return tbl
end

-- merge table a and b into a new table
function tbl_merge_new(a,b)
  tbl={}
  for k,v in pairs(a) do tbl[k]=v end
  for k,v in pairs(b) do tbl[k]=v end
  return tbl
end

-- merge table b into table a
function tbl_merge(a,b) for k,v in pairs(b) do a[k]=v end end

-- check length of table
function tbl_len(t)
  num=0
  for k,v in pairs(t) do num+=1 end
  return num
end

-- transform position to screen position
function pos_to_screen(pos) return {x=8*(pos.x-cam_x),y=8*(pos.y-cam_y)} end

-- quadratic rational smoothstep
--function smoothstep(x) return x*x/(2*x*x-2*x+1) end

-- cubic polynomial smoothstep
function smoothstep(x) return x*x*(3-2*x) end

-- linear interpolation
function interp(val,min,max)
  return (max-min)*val+min
end

-- wavy text
function wavy_print(s,x,y,c,h)
  for i=1,#s do
    print(sub(s,i,i),x+i*4,y+sin(t()*1.25+i*0.06)*(h or 3),c)
  end
end

-- wavy sprite
function wavy_spr(s,x,y,i,o,h)
    spr(s,x,y+sin(t()*1.25+(i or 1)*(o or 0.06))*(h or 3))
end



-------------------------------------------------------------------------------
-- system
-------------------------------------------------------------------------------

-- reset cart
function reset() 
  state=state_reset
  for i=0x0,0x7fff,rnd(0xf) do poke(i,rnd(0xf)) end
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
  for x=0,127 do for y=0,63 do
      if(mget(x,y)==0)mset(x,y,sprites.empty)
      if(fget(mget(x,y),flags.entity))entity.spawn(mget(x,y),x,y)
  end end
end

-- check for collision
function collision(x,y)
  if(fget(mget(x,y),flags.collision))return true
  for e in all(entity.entities) do if (e.collision and e.x==x and e.y==y) return true end
  return false
end

-- check if neighbour tile is in reach
function in_reach(a,b) return ((dist(a,b)<=1) and ((a.x==b.x or a.y==b.y) or (not collision(a.x,b.y)) or (not collision(b.x,a.y)))) end

-- perform turn
function do_turn()
  for e in all(entity.entities) do e:do_turn() end
  turn+=1
end

-- update camera position
function update_camera()
  t_x=cam_x
  t_y=cam_y
  if (player.x-cam_x>15-cam_offset and cam_x<width-16) then 
    t_x=player.x-15+cam_offset
  elseif (player.x-cam_x<cam_offset and cam_x>0) then 
    t_x=player.x-cam_offset
  elseif (player.y-cam_y>15-cam_offset-ui_h and cam_y<height-16+ui_h) then 
    t_y=player.y-15+cam_offset+ui_h
  elseif (player.y-cam_y<cam_offset and cam_y>0) then 
    t_y=player.y-cam_offset 
  end
  if (t_x~=cam_x or t_y ~= cam_y) then
    if (player.anim_frame>0) then
      camera((t_x-cam_x)*8+player.anim_x,(t_y-cam_y)*8+player.anim_y)
    else
      cam_x=t_x
      cam_y=t_y
    end
  end
end


-------------------------------------------------------------------------------
-- look state
-------------------------------------------------------------------------------

-- change look target
function set_look()
  e=entity.get(sel.look.x,sel.look.y)
  tbl=sel.look
  tbl.entity=(e~=player and e) or nil
  tbl.name="none"
  tbl.usable=false
  tbl.text="interact"
  tbl.color=5
  tbl.possession=nil
  if(e~=nil and e~= player) then 
    if (e.parent_class==creature.class and e.dead) then
      tbl.entity=nil
    else
      tbl.name=e:get_name()
      tbl.usable=e.interactable and dist(player,e)<=e.interact_dist
      tbl.color=6
      tbl.text=e.interact_text
      if(e.class==chest.class) then
        tbl.usable=tbl.usable and not e.open
      elseif(e.class==door.class) then 
        if (e.lock==0) then
          tbl.text=(e.collision and "open") or "close"
        else
          if (tbl.usable) then
            tbl.usable=false
            for itm in all(inventory.items) do 
              if(itm.class==key.class and itm.lock==e.lock) then 
                tbl.usable=true 
                tbl.possession=itm
                break 
              end 
            end
          end
          tbl.text="unlock"
        end
      end
      if(e.parent_class==creature.class)tbl.color=(e.hostile and 2) or 3
    end
  end
end