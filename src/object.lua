-------------------------------------------------------------------------------
-- object
-------------------------------------------------------------------------------
object={
  -- static vars
  class="object",
  parent_class=nil,

  -- metatable setup
  inherit=function(self,tbl)
    return setmetatable(tbl or {},{__index=self})
  end,

}



-------------------------------------------------------------------------------
-- drawable
-------------------------------------------------------------------------------
drawable=object:inherit({
  -- static vars
  class="drawable",
  parent_class=object.class,

  -- vars
  sprite=0,
  flash_frame=0,
  pal_swap={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
  pal_swap_enable=false,

  -- (static) get drawable data from entity data
  data_from_entity=function(e)
    return {sprite=e.sprite or drawable.sprite, pal_swap=e.pal_swap or drawable.pal_swap, pal_swap_enable=e.pal_swap_enable or drawable.pal_swap_enable}
  end,

  vec2_spr=function(self,pos,sprite)
    sprite=sprite or self.sprite
    self:spr(pos.x,pos.y,sprite)
  end,

  -- draw at given screen position
  spr=function(self,x,y,sprite)
    sprite=sprite or self.sprite
    if (self.flash_frame>0) then
      self.flash_frame-=1
      pal_all(7)
    elseif (self.pal_swap_enable) then
      pal_set(self.pal_swap)
    end
    spr(sprite,x,y)
    pal_set()
  end,
})



-------------------------------------------------------------------------------
-- entity
-------------------------------------------------------------------------------
entity=drawable:inherit({
  -- static vars
  class="entity",
  parent_class=drawable.class,
  entities={},
  num=0,

  -- vars
  x=0,
  y=0,
  name=nil,
  collision=true,
  interactable=true,
  interact_text="interact",

  -- (static) get name or class name of any entity
  entity_name=function(e)
    return(e.name and e.name) or (e.item_class and e.item_class) or e.class
  end,

  -- (static) get entity at coordinate
  entity_at=function(x,y)
    for e in all(entity.entities) do if (e.x==x and e.y==y) return e end
    return nil
  end,

  -- (static) spawn entity on map
  entity_spawn=function(sprite,x,y)
    mset(x,y,sprite_empty)
    tbl={x=x,y=y,sprite=sprite}
    entity_data=data_entities[sprite]
    if (entity_data) then
      if (entity_data.class==player.class) then
        tbl_merge(player,tbl)
        companion_sprite=(rnd()>0.5 and sprite_companion_cat) or sprite_companion_dog
        companion:new(tbl_merge_new({x=x,y=y,sprite=companion_sprite},data_entities[companion_sprite]))
      else
        tbl_merge(tbl,entity_data)
        _ENV[tbl.class]:new(tbl)
      end
    end
  end,

  -- constructor
  new=function(self,tbl)
    tbl=self:inherit(tbl)
    entity.num=entity.num+1
    tbl["id"]=entity.num
    tbl["prev_x"],tbl["prev_y"]=tbl.x,tbl.y
    add(entity.entities,tbl)
    return tbl
  end,

  -- destructor
  destroy=function(self)
    del(entity.entities,self)
  end,

  -- update entity
  update=function(self) end,

  -- draw entity at world position (if in frame)
  draw=function(self,offset,pos,sprite)
    if (self:in_frame(offset)) then
      self:vec2_spr(vec2_add((pos or pos_to_screen(self)),vec2_scale(offset or {x=0,y=0},8)),sprite)
      return true
    end
    return false
  end,

  -- get name or class name of this entity
  get_name=function(self)
    return entity.entity_name(self)
  end,

  -- look at entity
  look_at=function(self,tbl)
      tbl_merge(tbl,{entity=self,name=self:get_name(),color=6,text=self.interact_text,usable=self.interactable and dist(player,self)<=1})
  end,

  -- interact with entity
  interact=function(self) end,

  -- perform turn actions
  do_turn=function(self) end,

  -- check if entity is on screen
  in_frame=function(self,offset)
    pos=vec2_add(self,offset or {x=0,y=0})
    return (pos.x>=cam_x-1 and pos.x<cam_x+17 and pos.y>=cam_y-1 and pos.y<cam_y+17-ui_h)
  end,

})



-------------------------------------------------------------------------------
-- creature
-------------------------------------------------------------------------------
creature=entity:inherit({
  -- static vars
  class="creature",
  parent_class=entity.class,
  anims={move={frames=3,dist=8},attack={frames=5,dist=6}},
  anim_queue={},
  anim_playing=false,

  -- vars
  dead=false,
  hostile=false,
  attacked=false,
  blink_delay=0,
  anim=nil,
  anim_frame=0,
  anim_x=0,
  anim_y=0,
  anim_x1=0,
  anim_y1=0,
  dhp=0,
  dhp_turn=0,
  target=nil,
  target_turn=0,

  -- stats
  max_hp=10,
  ap=2,

  -- constructor
  new=function(self,tbl)
    tbl=entity.new(self,tbl)
    tbl["hp"]=tbl.max_hp
    return tbl
  end,

  -- update creature
  update=function(self)
    if(self.anim_frame>0 and creature.anim_queue[1]==self.id) then self:anim_step()
    elseif(prev_frame~=frame and self.blink_delay>0) then self.blink_delay-=1 end
  end,

  -- draw creature
  draw=function(self,offset)
    if (self:in_frame(offset)) then
      sprite=self.sprite+frame*16
      if (self.anim_frame<=0) then
        if (self.dead) then sprite=((frame==1 and (turn-self.dhp_turn)<=1 and self.blink_delay<=0 and not creature.anim_playing) and sprite_void) or sprite_grave
        elseif (self.attacked and frame==1 and self.blink_delay<=0 and not creature.anim_playing) then
          sprite=sprite_void
          if(state==state_game)print(abs(self.dhp),self:screen_pos().x+4-str_width(abs(self.dhp))*0.5,self:screen_pos().y+1,self.dhp<0 and 8 or 11)
        end
      end
      entity.draw(self,offset,self:screen_pos(),sprite)
      return true
    end
    return false
  end,

  -- position on screen (position and animation position summed)
  screen_pos=function(self)
    return vec2_add(pos_to_screen(self),{x=self.anim_x,y=self.anim_y})
  end,

  -- look at creature
  look_at=function(self,tbl)
    if (not self.dead) then
      entity.look_at(self,tbl)
      tbl.color=(self.hostile and 2) or 3
    end
  end,

  -- perform turn actions
  do_turn=function(self)
    if(turn>self.dhp_turn)self.attacked=false
    if(self.dead and (turn-self.dhp_turn)>timer_corpse)self:destroy()
    if(self.target and self.target.dead or (turn-self.target_turn)>timer_target)self.target=nil
    return (not self.dead and self:in_frame())
  end,

  -- start playing animation
  play_anim=function(self,a,x,y,x1,y1)
    tbl_merge(self,{anim=a,anim_frame=a.frames,anim_x=x*a.dist,anim_y=y*a.dist,anim_x1=(x1 or 0)*a.dist,anim_y1=(y1 or 0)*a.dist})
    add(creature.anim_queue,self.id)
    creature.anim_playing=true
  end,

  -- perform animation step
  anim_step=function(self)
    anim_pos=smoothstep(self.anim_frame/self.anim.frames)
    x,y=self.anim_x,self.anim_y
    if (self.anim==creature.anims.attack) then
      x,y=self.anim_x1,self.anim_y1
      if (self.target) then
        if(self.anim_frame==self.anim.frames and self.target==player)flash_frame=2
        if(self.anim_frame==self.anim.frames-3)self.target.flash_frame=2
      end
    end
    self.anim_x=self.anim.dist*anim_pos*((x<-0.1 and -1) or (x>0.1 and 1) or 0)
    self.anim_y=self.anim.dist*anim_pos*((y<-0.1 and -1) or (y>0.1 and 1) or 0)
    self.anim_frame-=1
    if (self.anim_frame<=0) then
      del(creature.anim_queue,self.id)
      if(#creature.anim_queue==0)creature.anim_playing=false
      self.anim_x,self.anim_y=0
    end
  end,

  -- try to move the creature to a given map coordinate
  move=function(self,x,y)
    if (not collision(x,y) and x>=0 and x<128 and y>=0 and y<64 and (x~=0 or y~=0)) then
      self:play_anim(creature.anims.move,self.x-x,self.y-y)
      tbl_merge(self,{prev_x=self.x,prev_y=self.y,x=x,y=y})
      return true
    end
    return false
  end,

  -- follow another entity
  follow=function(self,other)
    if(in_reach(self,{x=other.prev_x,y=other.prev_y})) then self:move(other.prev_x,other.prev_y)
    else self:move_towards(other) end
  end,

  -- move towards another creature and attack when close
  move_towards_and_attack=function(self,other)
    if (in_reach(self,other)) then self:attack(other)
    else self:move_towards(other) end
  end,

  -- try to move an towards another entity
  move_towards=function(self,other)
    diff_x=other.x-self.x
    diff_y=other.y-self.y
    desire_x=(diff_x>0 and 1) or (diff_x<0 and -1) or 0
    desire_y=(diff_y>0 and 1) or (diff_y<0 and -1) or 0
    valid=((abs(diff_x)<abs(diff_y)) and self:move(self.x,self.y+desire_y) or (self:move(self.x+desire_x,self.y) or self:move(self.x,self.y+desire_y)))
  end,

  -- perform attack
  attack=function(self,other)
    msg.add(self:get_name().." attacked "..other:get_name())
    if (other:take_dmg(flr(self.ap*(0.5+rnd())+0.5))) then
      msg.add(self:get_name().." killed "..other:get_name())
      if(self==player)self.xp+=other.xp
    else 
      self.target=other
      self.target_turn=turn
    end
    self:play_anim(creature.anims.attack,0,0,other.x-self.x,other.y-self.y)
  end,

  -- take damage
  take_dmg=function(self,dmg)
    self.blink_delay=(frame==0 and 2) or 1
    self.attacked=true
    self.dhp=(self.dhp_turn==turn and self.dhp-dmg) or dmg*-1
    self.dhp_turn=turn
    self.hp-=dmg
    if (self.hp <= 0) then
      self:kill()
      return true
    end
    return false
  end,

  -- kill creature
  kill=function(self)
    self.dead=true
    self.collision=false
    if(self==player)change_state(state_dead)
  end,
})



-------------------------------------------------------------------------------
-- player
-------------------------------------------------------------------------------
player=creature:new({
  -- static vars
  class="player",
  parent_class=creature.class,
  interactable=false,
  name="you",

  -- vars
  xp=0,

  -- look at player
  look_at=function(self,tbl) end,

  -- move the player or attack if there is an enemy in the target tile
  action_dir=function(self,x,y)
    valid=self:move(x,y)
    for e in all(entity.entities) do
      if (e.x==x and e.y==y) do
        if (e.class==enemy.class and e.hostile and not e.dead) then
          self:attack(e)
          valid=true
        elseif (e.class==stairs.class) then
          e:trigger()
          valid=true
        end
      end
    end
    return valid
  end,

  -- wait one turn
  action_wait=function(self)
    msg.add("you waited")
    return true
  end,
})



-------------------------------------------------------------------------------
-- companion
-------------------------------------------------------------------------------
companion=creature:inherit({
  -- static vars
  class="companion",
  parent_class=creature.class,
  collision=false,

  -- vars
  ap=1,

  -- perform turn actions
  do_turn=function(self)
    if (creature.do_turn(self)) then
      if (player.target and player.target_turn<turn) then
        self:move_towards_and_attack(player.target)
      else
        self:follow(player)
      end
    elseif not self:in_frame() then
      self.x,self.y=player.prev_x,player.prev_y
    end
  end,
})



-------------------------------------------------------------------------------
-- npc
-------------------------------------------------------------------------------
npc=creature:inherit({
  -- static vars
  class="npc",
  parent_class=creature.class,

  -- perform turn actions
  do_turn=function(self)
    if (creature.do_turn(self)) then 
    end 
  end,
})



-------------------------------------------------------------------------------
-- enemy
-------------------------------------------------------------------------------
enemy = creature:inherit({
  -- static vars
  class="enemy",
  parent_class=creature.class,

  -- vars
  hostile=true,
  ap=1,
  max_hp=5,
  xp=1,

  -- perform turn actions
  do_turn=function(self)
    if (creature.do_turn(self)) then
      if(self.hostile)self:move_towards_and_attack(player)
    end
  end,
})



-------------------------------------------------------------------------------
-- door
-------------------------------------------------------------------------------
door=entity:inherit({
  -- static vars
  class="door",
  parent_class=entity.class,

  -- vars
  lock=0,

  -- constructor
  new=function(self,tbl)
    if(tbl.lock) then
      if (tbl.lock>0) then
        for d in all(data_locks.doors) do if(d.x==tbl.x and d.y==tbl.y)then tbl.lock=d.lock or 1 break end end
        key.set_variant(tbl,tbl.lock)
      end
    end
    return entity.new(self,tbl)
  end,

  -- look at door
  look_at=function(self,tbl)
    entity.look_at(self,tbl)
    if (self.lock==0) then 
      tbl.text=(self.collision and "open") or "close"
    else
      tbl.text="unlock"
      tbl.name="locked "..tbl.name
      if (tbl.usable) then
        tbl.usable=false
        for itm in all(inventory.items) do if(itm.class==key.class and itm.lock==e.lock) then tbl_merge(tbl,{usable=true,possession=itm}) break end end
      end
    end
  end,

  -- interact action
  interact=function(self)
    self.collision=not self.collision
    self.sprite=(self.collision and sprite_door_closed) or sprite_door_open
    if (self.lock>0) then
      self.lock=0
      self.pal_swap_enable=false
      msg.add("unlocked door")
    else
      msg.add(((self.collision and "closed") or "opened").." door")
    end
    change_state(state_game)
  end,
})



-------------------------------------------------------------------------------
-- stairs
-------------------------------------------------------------------------------
stairs=entity:inherit({
  -- static vars
  class="stairs",
  parent_class=entity.class,
  interactable=false,
  collision=false,

  -- trigger action
  trigger=function(self)
    stair=nil
    for e in all(data_floors.stairs) do if (e.x==player.x and e.y==player.y) stair=e break end
    target_stair=data_floors.stairs[stair.target]
    delta_z=(room and room.z) or 0
    room=data_floors.rooms[target_stair.room]
    delta_z=((room and room.z) or 0) - delta_z
    cam_x_min,cam_y_min=(room and target_stair.x-player.x) or 0,(room and target_stair.y-player.y) or 0
    cam_x_diff,cam_y_diff=target_stair.x-stair.x,target_stair.y-stair.y
    player.x,player.y=target_stair.x,target_stair.y
    cam_x,cam_y=cam_x+target_stair.x-stair.x,cam_y+target_stair.y-stair.y
    msg.add("went "..(delta_z>0 and "up" or "down").." stairs")
    draw.play_fade(change_room,room)
  end,
})



-------------------------------------------------------------------------------
-- sign
-------------------------------------------------------------------------------
sign=entity:inherit({
  -- static vars
  class="sign",
  parent_class=entity.class,

  --vars
  interact_text="read",
  message="...",
  bg=15,
  fg=0,

  -- constructor
  new=function(self,tbl)
    for d in all(data_signs) do if(d.x==tbl.x and d.y==tbl.y)then tbl.message=d.message break end end
    return entity.new(self,tbl)
  end,

  -- interact action
  interact=function(self)
    change_state(state_read,self)
  end,
})



-------------------------------------------------------------------------------
-- chest
-------------------------------------------------------------------------------
chest=entity:inherit({
  -- static vars
  class="chest",
  parent_class=entity.class,
  interact_text="open",
  anim_playing=false,

  -- vars
  anim_frame=0,
  anim_this=false,
  open=false,
  content={},

  -- constructor
  new=function(self,tbl)
    for d in all(data_chests) do
      if (d.x==tbl.x and d.y==tbl.y) then
        tbl.content={}
        for itm in all(d.content) do
          e_data=tbl_merge_new(data_entities[itm.sprite],itm)
          if(e_data.item_class==key.class)key.set_variant(e_data,e_data.item_data.lock)
          add(tbl.content,possession.new_from_entity(e_data))
        end
        return entity.new(self,tbl)
      end 
    end
    return nil
  end,

  -- look at chest
  look_at=function(self,tbl)
      entity.look_at(self,tbl)
      tbl.usable=tbl.usable and not e.open
  end,

  -- interact action
  interact = function(self)
    self.open=true
    self.sprite=sprite_chest_open
    self.anim_frame=45
    self.anim_this=true
    chest.anim_playing=true
    sel={entity=self,anim_frame={}}
    for itm in all(self.content) do 
      add(sel.anim_frame,60)
      inventory.add_possession(itm)
      msg.add("got "..itm.name)
    end
    change_state(state_chest,sel)
  end,

  -- perform animation step
  anim_step=function(self) if(self.anim_frame>0)self.anim_frame-=1 end,

  -- get content item animation position
  item_anim_pos=function(self, anim_pos, target) return {x=lerp(anim_pos+sin(anim_pos*-0.5)*0.75,pos_to_screen(self).x,target.x),y=lerp(anim_pos+cos(anim_pos*0.9+0.1)*0.3-0.3,pos_to_screen(self).y,target.y)} end,

  -- draw chest
  draw=function(self,offset)
    if (entity.draw(self,offset) and (self.anim_this)) then
      x,y=pos_to_screen(self).x,pos_to_screen(self).y
      draw_lid=true
      if(self.anim_frame<30)draw_lid=(self.anim_frame>10 and blink) or false
      if(blink)rectfill(x+1,y+2,x+5,y+3,7)
      if(draw_lid) then
        y-=(45-self.anim_frame)*0.25
        clip(x,y,8,5)
        spr(sprite_chest_closed,x,y)
        clip()
      end
    end
  end,

})



-------------------------------------------------------------------------------
-- item (in world)
-------------------------------------------------------------------------------
item = entity:inherit({
  -- static vars
  class="item",
  parent_class=entity.class,
  collision=false,
  interact_text="pick up",

  -- constructor
  new=function(self,tbl)
    tbl.item_data=tbl.item_data and tbl_copy(tbl.item_data) or {}
    if(tbl.item_class==key.class)key.get_data(tbl)
    return entity.new(self,tbl)
  end,

  -- interact action
  interact=function(self)
    msg.add("picked up "..self:get_name())
    inventory.add_item(self)
    self:destroy()
    change_state(state_game)
  end,

})



-------------------------------------------------------------------------------
-- possession (item in inventory)
-------------------------------------------------------------------------------
possession=drawable:inherit({
  -- static vars
  class="possession",
  parent_class=drawable.class,
  num=0,

  -- vars
  name=nil,
  sprite=0,
  interactable=true,

  -- constructor
  new=function(self,tbl)
    tbl=self:inherit(tbl)
    possession.num=possession.num+1
    tbl["id"]=possession.num
    return tbl
  end,

  -- create new possession from data
  new_from_entity=function(e)
    return _ENV[e.item_class]:new(tbl_merge_new(tbl_merge_new({name=entity.entity_name(e)},drawable.data_from_entity(e)),e.item_data))
  end,

  -- interact with possession
  interact=function(self) end,
})



-------------------------------------------------------------------------------
-- key
-------------------------------------------------------------------------------
key=possession:inherit({
  -- static vars
  class="key",
  parent_class=possession.class,
  interactable=false,
  colors={
    {"steel",6,13},
    {"gold",10,9},
    {"green",11,3},
  },

  -- lookup key data for a given map coordinate
  get_data=function(tbl)
    for d in all(data_locks.keys) do if(d.x==tbl.x and d.y==tbl.y)then tbl.item_data["lock"]=d.lock or 1 break end end 
    key.set_variant(tbl,tbl.item_data.lock)
  end,

  -- set entity color swap to match key color
  set_variant=function(tbl,i)
    if (i>1) then
      tbl["pal_swap_enable"]=true
      tbl["pal_swap"]={[key.colors[1][2]]=key.colors[i][2],[key.colors[1][3]]=key.colors[i][3]}
    end
    if(entity.entity_name(tbl)=="key")tbl.name=key.colors[i][1].." key"
  end,
})



-------------------------------------------------------------------------------
-- consumable
-------------------------------------------------------------------------------
consumable=possession:inherit({
  class="consumable",
  parent_class=possession.class,
})



-------------------------------------------------------------------------------
-- equippable
-------------------------------------------------------------------------------
equippable=possession:inherit({
  class="equippable",
  parent_class=possession.class,
})