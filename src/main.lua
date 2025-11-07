-------------------------------------------------------------------------------
-- globals
-------------------------------------------------------------------------------

-- constants
timer_corpse=20 -- timeout for grave (turns)
timer_target=3 -- timeout for target (turns)
width=103 -- area width
height=64 -- area height
ui_h=2 -- row height of bottom ui box

-- game states
state_reset="reset"
state_title="title"
state_game="game"
state_menu="menu"
state_look="look"
state_chest="chest"
state_read="read"
state_dead="dead"

-- sprites
sprite_void=0
sprite_empty=1
sprite_selection=2
sprite_grave=3
sprite_chest_closed=11
sprite_chest_open=12
sprite_door_closed=82
sprite_door_open=81
sprite_companion_cat=17
sprite_companion_dog=18

-- sprite flags
flag_collision=0
--flag_unused_one=1
--flag_unused_two=2
--flag_unused_three=3
--flag_unused_four=4
--flag_unused_five=5
--flag_unused_six=6
flag_entity=7

-- vars
state=nil -- game state
turn=1 -- turn number
frame=0 -- animation frame (increments twice per second)
prev_frame=0 -- previous animation frame (increments twice per second)
blink_frame=0 -- frame for fast blink animations (updates 30 times per soncond)
blink=false
flash_frame=0
fade_frame=0
fade_chars={"░","▒"}
fade_action=nil
cam_x=0 -- camera x position
cam_y=0 -- camera y position
cam_offset=4 -- camera scroll offset
title_effect_num_points=96
title_effect_colors={8,9,10,11,12,13,14,15}

-- options
option_disable_flash=false



-------------------------------------------------------------------------------
-- built-in functions
-------------------------------------------------------------------------------

-- init
function _init()
  populate_map()
  change_state(state_title)
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
    draw.fade_step()
  end
end



-------------------------------------------------------------------------------
-- init
-------------------------------------------------------------------------------
init={
  -- menu state
  menu=function(sel)
    sel_menu={tab=0,i=1}
  end,

  -- look state
  look=function(sel)
    sel_look={x=player.x,y=player.y}
    set_look()
  end,

  -- chest state
  chest=function(sel)
    sel_chest=sel
  end,

  -- read state
  read=function(sel)
    sel_read=sel
  end,

  -- dead state
  dead=function(sel) sel_dead=0 end,
}



-------------------------------------------------------------------------------
-- update
-------------------------------------------------------------------------------
update={
  -- title state
  title=function()
    input.title()
  end,

  -- game state
  game=function()
    for e in all(entity.entities) do e:update() end
    if(not creature.anim_playing and input.game())do_turn()
  end,

  -- menu state
  menu=function()
    input.menu()
  end,

  -- look state
  look=function()
    if(input.look())set_look()
  end,

  -- chest state
  chest=function()
    if(sel_chest.entity.anim_this)sel_chest.entity:anim_step()
    if(not chest.anim_playing)input.chest()
  end,

  -- read state
  read=function()
    input.read()
  end,

  -- dead state
  dead=function()
    for e in all(entity.entities) do e:update() end
    input.dead()
  end,
}



-------------------------------------------------------------------------------
-- draw
-------------------------------------------------------------------------------
draw={
  -- start playing fade
  play_fade=function(func,param)
    fade_frame=5
    fade_action=(func and {func=func,param=param}) or nil
  end,

  -- perform fade animation step
  fade_step=function()
    if(fade_frame>0)then
      if (fade_frame==3) do cls(0)
      else for j=1,16 do for k=1,16 do print("\014"..fade_chars[(fade_frame>#fade_chars) and (6-fade_frame) or fade_frame],(j-1)*8,(k-1)*8,0) end end end
      fade_frame-=1
      if(fade_frame==3 and fade_action)fade_action.func(fade_action.param)
    end
  end,

  -- perform screen flash animation step
  flash_step=function()
    if(not option_disable_flash and flash_frame>0)then
      cls((state==state_game and player.hp<5 and flash_frame==1 and 8) or 7)
      flash_frame-=1
    end
  end,

  -- monochrome mode
  monochrome=function(c)
    c=c or 1
    -- screen memory as the sprite sheet
    poke(0x5f54,0x60)
    pal_all(c)
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
  title=function()
    cls(0)
    -- title effect
    for i=1,title_effect_num_points do
      x=cos(t()/8+i/title_effect_num_points)*56
      y=sin(t()/8+i/title_effect_num_points)*16+sin(t()+i*(1/title_effect_num_points)*5)*4
      c=title_effect_colors[i%(#title_effect_colors)+1]
      for j=1,3 do pset(64+x+j,42+y+j,c) end
    end
    -- main title
    s_title="\014magus magicus"
    print(s_title,68-str_width(s_title)*0.5,38,4)
    print(s_title,68-str_width(s_title)*0.5,37,7)
    -- button legend
    s_btn_x="start game ❎"
    if (frame==0) then
      print(s_btn_x,64-str_width(s_btn_x)*0.5,71,5)
      print(s_btn_x,64-str_width(s_btn_x)*0.5,70,6)
    end
  end,

  -- game state
  game=function()
    -- draw map and entities
    cls()
    update_camera()
    map(cam_x-1,cam_y-1,-8,-8,18,18-ui_h)
    for e in all(entity.entities) do if (not e.collision) e:draw() end
    for e in all(entity.entities) do if (e.collision) e:draw() end
    -- vars
    hp_ratio=max(0,player.hp/player.max_hp)
    s_btn_z="menu 🅾️"
    s_btn_x="look ❎"
    camera()
    draw.window_frame()
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
      print(s_btn_z,126-str_width(s_btn_z),114,5)
      print(s_btn_x,126-str_width(s_btn_x),121,5)
    end
    -- ui elements
    print("hp:",2,120,6)
    if(hp_ratio>0)rectfill(14,120,14+68*hp_ratio,124,(hp_ratio<0.25 and 8) or (hp_ratio<0.5 and 9) or (hp_ratio<0.75 and 10) or 11)
    print(s_btn_z,126-str_width(s_btn_z),113,6)
    print(s_btn_x,126-str_width(s_btn_x),120,6)
  end,

  -- menu state
  menu=function()
    -- draw map and entities
    draw.game()
    draw.monochrome()
    -- vars
    s_btns="cancel 🅾️  select ❎"
    s_chr="⬅️ character ➡️"
    s_inv="⬅️ inventory ➡️"
    s_itms="empty"
    -- bg box
    rectfill(23,23,103,103,1)
    line(23,22,103,22,6)
    line(23,104,103,104,6)
    -- button legend
    print(s_btns,64-str_width(s_btns)*0.5,114,5)
    clip(64-str_width(s_btns)*0.5,113,(sel_menu.tab==1 and inventory.num>0 and inventory.items[sel_menu.i].interactable and 80) or 40,6)
    print(s_btns,64-str_width(s_btns)*0.5,113,6)
    clip()
    -- character tab
    if (sel_menu.tab==0) then
      print(s_chr,64-str_width(s_chr)*0.5,26,5)
      print(s_chr,64-str_width(s_chr)*0.5,25,6)
      print("hp: "..player.hp.."/"..player.max_hp.."\nxp: "..player.xp,28,34,6)
    -- inventory tab
    elseif (sel_menu.tab==1) then
      print(s_inv,64-str_width(s_inv)*0.5,26,5)
      print(s_inv,64-str_width(s_inv)*0.5,25,6)
      if (inventory.num>0) do
        print("▶",28,34+(sel_menu.i-1)*6,6)
        for i=1,inventory.num do s_itms=((i==1 and "") or s_itms)..inventory.items[i].name.."\n" end
      end
      print(s_itms,28+(inventory.num>0 and 6 or 0),34,5)
      clip(23,28+6*sel_menu.i,80,6)
      print(s_itms,28+(inventory.num>0 and 6 or 0),34,6)
      clip()
    end
  end,

  -- look state
  look=function()
    -- draw map, entities and selection
    draw.game()
    if(state==state_look)draw.monochrome()
    player:draw()
    if(sel_look.entity)sel_look.entity:draw()
    if(state==state_look)vec2_spr(sprite_selection,pos_to_screen(sel_look))
    draw.window_frame()
    -- vars
    s_btn_z="cancel 🅾️"
    s_btn_x=sel_look.text.." ❎"
    -- ui elements (shadow)
    if(state==state_look)then
      print("target:",2,114,5)
      print(sel_look.name,2,121,(sel_look.entity and sel_look.entity.parent_class==creature.class and 0) or 5)
      print(s_btn_z,128-str_width(s_btn_z)-2,114,5)
      print(s_btn_x,128-str_width(s_btn_x)-2,121,5)
    end
    -- ui elements
    print("target:",2,113,6)
    if(sel_look.entity)print(sel_look.name,2,120,sel_look.color)
    print(s_btn_z,128-str_width(s_btn_z)-2,113,6)
    if(sel_look.usable)print(s_btn_x,126-str_width(s_btn_x),120,6)
  end,

  -- chest state
  chest=function()
    -- vars
    chest_e=sel_chest.entity
    num_itms=tbl_len(chest_e.content)
    s_btn_x="take items ❎"
    -- draw player and chest
    cls()
    player:draw()
    chest_e:draw()
    if (not chest.anim_playing)draw.monochrome()
    -- wait for chest open animation to finish
    if (chest_e.anim_frame<=0) then
      -- iterate through chest items
      for i=1,num_itms do
        target_pos={x=68-num_itms*8+(i-1)*16,y=52}
        -- wait for animation of previous item to finish before playing the next
        if (i==1 or sel_chest.anim_frame[i-1]<=0) then
          itm=chest_e.content[i]
          -- play animation for current item
          if (sel_chest.anim_frame[i]>0) then
            -- stop chest blinking on last item
            if(i==num_itms)chest_e.anim_this=false
            -- set item color to white
            pal_all(7)
            -- draw animated item with trailing echoes
            for j=0,10 do
              pos=chest_e:item_anim_pos(smoothstep(min(1,(1-(sel_chest.anim_frame[i]/60))+0.025*j)),target_pos)
              if(blink)vec2_spr(itm.sprite,pos)
            end
            -- reset palette and decrement animation frame
            pal()
            sel_chest.anim_frame[i]-=1
            -- flash the screen and set chest animation to finished after last item animation is done
            if (sel_chest.anim_frame[num_itms]<=0) then 
              chest.anim_playing=false
              flash_frame=2
            end
          -- draw the item bobbing up and down after the popping out of chest animation has finished
          else
            if(not chest.anim_playing or blink)itm:spr(target_pos.x,target_pos.y+wavy())
          end
        end
      end
    end
    -- show wavy button press text after the whole chest animation is complete
    if (not chest.anim_playing) then
      wavy_print(s_btn_x,64-str_width(s_btn_x)*0.5,87,5)
      wavy_print(s_btn_x,64-str_width(s_btn_x)*0.5,86,6)
    end
  end,

  -- read state
  read=function()
    -- draw map, entities and selection
    draw.look()
    draw.monochrome()
    -- vars
    s_btn_x="continue ❎"
    e=sel_read
    txt_w=str_width(sel_read.message)
    txt_h=str_height(sel_read.message)
    txt_expand=((txt_h>5 and txt_h-5) or 0)*3
    txt_offset=((txt_h<5 and 5-txt_h) or 0)*3
    -- bg and message text
    rectfill(23,39-txt_expand,103,71+txt_expand,sel_read.bg)
    line(24,38-txt_expand,102,38-txt_expand,sel_read.bg)
    line(24,72+txt_expand,102,72+txt_expand,sel_read.bg)
    print(sel_read.message,64-txt_w*0.5,41-txt_expand+txt_offset,sel_read.fg)
    -- button legend
    print(s_btn_x,64-str_width(s_btn_x)*0.5,82+txt_expand,5)
    print(s_btn_x,64-str_width(s_btn_x)*0.5,81+txt_expand,6)
  end,

  -- dead state
  dead=function()
    -- draw map, entities and selection
    draw.game()
    draw.monochrome()
    -- vars
    s_title="g a m e   o v e r"
    s_btn_x="select ❎"
    -- title and menu box
    print(s_title,64-str_width(s_title)*0.5,41,1)
    print(s_title,64-str_width(s_title)*0.5,40,8)
    rect(24,52,103,75,7)
    print("▶",28,58+sel_dead*7,7)
    print("restart",34+((sel_dead==0 and 1) or 0),58,7)
    print("quit",34+((sel_dead==1 and 1) or 0),66,7)
    -- button legend
    print(s_btn_x,64-str_width(s_btn_x)*0.5,85,5)
    print(s_btn_x,64-str_width(s_btn_x)*0.5,84,6)
  end,
}



-------------------------------------------------------------------------------
-- input
-------------------------------------------------------------------------------
input={
  -- title state
  title=function()
    if(btnp(❎)) then 
      draw.play_fade(change_state,state_game)
    end
  end,

  -- game state
  game=function()
    valid = false
    x,y=player.x,player.y
    if(btnp(⬆️))valid=player:action_dir(x,y-1)
    if(btnp(➡️))valid=player:action_dir(x+1,y)
    if(btnp(⬇️))valid=player:action_dir(x,y+1)
    if(btnp(⬅️))valid=player:action_dir(x-1,y)
    if(btnp(🅾️))change_state(state_menu)
    if(btnp(❎))change_state(state_look)
    return valid
  end,

  -- menu state
  menu=function()
    if(btnp(⬅️))sel_menu.tab=(sel_menu.tab-1)%2
    if(btnp(➡️))sel_menu.tab=(sel_menu.tab+1)%2
    if(btnp(🅾️))change_state(state_game)
    if (sel_menu.tab==1) then
      if(btnp(⬆️) and sel_menu.i>1)sel_menu.i-=1
      if(btnp(⬇️) and sel_menu.i<inventory.num)sel_menu.i+=1
      --if(btnp(❎) and inventory.num>0 and inventory.items[sel_menu.i].interactable)
    end
  end,

  -- look state
  look=function()
    if(btnp(⬆️)and sel_look.y-cam_y>0)sel_look.y-=1
    if(btnp(➡️)and sel_look.x-cam_x<15)sel_look.x+=1
    if(btnp(⬇️)and sel_look.y-cam_y<15-ui_h)sel_look.y+=1
    if(btnp(⬅️)and sel_look.x-cam_x>0)sel_look.x-=1
    if (btnp(🅾️)) then 
      change_state(state_game)
      return false
    end
    if (btnp(❎) and sel_look.usable) then
      sel_look.entity:interact()
      inventory.remove(sel_look.possession)
      return false
    end
    return true
  end,

  -- chest state
  chest=function()
    if (btnp(❎)) change_state(state_game)
  end,

  -- read state
  read=function()
    if (btnp(❎)) change_state(state_game)
  end,

  -- dead state
  dead=function()
    sel_options={[0]=reset,[1]=quit}
    if(btnp(⬆️) and sel_dead>0)sel_dead-=1
    if(btnp(⬇️) and sel_dead<tbl_len(sel_options)-1)sel_dead+=1
    if(btnp(❎))sel_options[sel_dead]()
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

  -- convert item (from world) to possession and add to inventory
  add_item=function(e)
    add(inventory.items,possession.new_from_entity(e))
    inventory.num+=1
  end,

  -- add possession to inventory
  add_possession=function(itm)
    add(inventory.items,itm)
    inventory.num+=1
  end,

  -- remove possession from inventory
  remove=function(itm)
    if (itm) then
      del(inventory.items,itm)
      inventory.num-=1
    end
  end
}



-------------------------------------------------------------------------------
-- system
-------------------------------------------------------------------------------

-- reset cart
function reset() 
  change_state(state_reset)
  for i=0x0,0x7fff,rnd(0xf) do poke(i,rnd(0xf)) end
end

-- quit cart
function quit()
  cls()
  stop()
end

-- change state
function change_state(new_state,sel)
  state=new_state
  if(init[state])init[state](sel)
end



-------------------------------------------------------------------------------
-- game state
-------------------------------------------------------------------------------

-- iterate through all map tiles and find entities
function populate_map()
  for x=0,127 do for y=0,63 do
      if(fget(mget(x,y),flag_entity))entity.entity_spawn(mget(x,y),x,y)
      if(mget(x,y)==sprite_void)mset(x,y,sprite_empty)
  end end
end

-- check for collision
function collision(x,y)
  if(x<0 or x>127 or y<0 or y>127 or fget(mget(x,y),flag_collision))return true
  for e in all(entity.entities) do if (e.collision and e.x==x and e.y==y) return true end
  return false
end

-- check if neighbour tile is in reach
function in_reach(a,b)
  return ((dist(a,b)<=1) and ((a.x==b.x or a.y==b.y) or (not collision(a.x,b.y)) or (not collision(b.x,a.y))))
end

-- perform turn
function do_turn()
  for e in all(entity.entities) do e:do_turn() end
  turn+=1
end

-- update camera position
function update_camera()
  x,y=cam_x,cam_y
  p_x,p_y=player.x,player.y
  if (p_x-cam_x>15-cam_offset and cam_x<width-16) then 
    x=p_x-15+cam_offset
  elseif (p_x-cam_x<cam_offset and cam_x>0) then 
    x=p_x-cam_offset
  elseif (p_y-cam_y>15-cam_offset-ui_h and cam_y<height-16+ui_h) then 
    y=p_y-15+cam_offset+ui_h
  elseif (p_y-cam_y<cam_offset and cam_y>0) then 
    y=p_y-cam_offset 
  end
  if (x~=cam_x or y ~= cam_y) then
    if (player.anim_frame>0) then
      camera((x-cam_x)*8+player.anim_x,(y-cam_y)*8+player.anim_y)
    else
      cam_x,cam_y=x,y
    end
  end
end


-------------------------------------------------------------------------------
-- look state
-------------------------------------------------------------------------------

-- change look target
function set_look()
  tbl_merge(sel_look,{name="none",usable=false,text="interact",color=5,possession=nil})
  sel_look.entity=nil
  e=entity.entity_at(sel_look.x,sel_look.y)
  if(e)e:look_at(sel_look)
end