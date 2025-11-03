-------------------------------------------------------------------------------
-- object
-------------------------------------------------------------------------------
object={
  -- static vars
  class="object",
  parent_class=nil,

  -- metatable setup
  inherit=function(self,tbl)
    tbl=tbl or {}
    setmetatable(tbl,{__index=self})
    return tbl
  end,

}



-------------------------------------------------------------------------------
-- entity
-------------------------------------------------------------------------------
entity=object:inherit({
  -- static vars
  class="entity",
  parent_class=object.class,
  entities={},
  num=0,

  -- vars
  name=nil,
  sprite=0,
  x=0,
  y=0,
  collision=true,
  interactable=true,
  interact_dist=1,
  interact_text="interact",
  color_swap={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
  color_swap_enable=false,

  -- get name or class name
  get_name=function(self)
    return(self.name~=nil and self.name) or (self.item_class~=nil and self.item_class) or self.class
  end,

  -- constructor
  new=function(self,tbl)
    local e=self:inherit(tbl)
    entity.num=entity.num+1
    e["id"]=entity.num
    e["prev_x"]=e.x
    e["prev_y"]=e.y
    add(self.entities,e)
    return e
  end,

  -- destructor
  destroy=function(self)
    del(entity.entities,self)
  end,

  -- update entity
  update=function(self) end,

  -- draw entity
  draw=function(self)
    if (self:in_frame()) then
      if(self.color_swap_enable)pal(self.color_swap)
      spr(self.sprite,pos_to_screen(self).x,pos_to_screen(self).y)
      if(self.color_swap_enable)pal()
    end
  end,

  -- interact with entity
  interact=function(self) end,

  -- perform turn actions
  do_turn=function(self) end,

  -- check if entity is on screen
  in_frame=function(self) return (self.x>=cam_x-1 and self.x<cam_x+17 and self.y>=cam_y-1 and self.y<cam_y+17-ui_h) end,

  -- get entity at coordinate
  get=function(x,y)
    for e in all(entity.entities) do if (e.x==x and e.y==y) return e end
    return nil
  end,

  -- spawn entity on map
  spawn=function(sprite,x,y)
    mset(x,y,sprites.empty)
    tbl={x=x,y=y,sprite=sprite}
    entity_data=data_entities[sprite]
    if (entity_data ~= nil) then
      if (entity_data.class==player.class) then
        tbl_merge(player,tbl)
        companion_sprite=(rnd()>0.5 and sprites.companion_cat) or sprites.companion_dog
        companion:new(tbl_merge_new({x=x,y=y,sprite=companion_sprite},data_entities[companion_sprite]))
      else
        tbl_merge(tbl,entity_data)
        if(tbl.class==companion.class)then companion:new(tbl)
        elseif(tbl.class==npc.class)then npc:new(tbl)
        elseif(tbl.class==enemy.class)then enemy:new(tbl)
        elseif(tbl.class==sign.class)then sign:new(tbl)
        elseif(tbl.class==chest.class)then chest:new(tbl)
        elseif(tbl.class==stairs.class)then stairs:new(tbl)
        elseif(tbl.class==door.class)then door:new(tbl)
        elseif(tbl.class==item.class)then item:new(tbl)
        else entity:new(tbl) end
      end
    end
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
  flash_n=0,
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
    local e=entity.new(self,tbl)
    e["hp"]=e.max_hp
    return e
  end,

  -- update creature
  update=function(self)
    if(self.anim_frame>0 and creature.anim_queue[1]==self.id) then self:anim_step()
    elseif(prev_frame~=frame and self.blink_delay>0) then self.blink_delay-=1 end
  end,

  -- draw creature
  draw=function(self)
    if (self:in_frame()) then
      sprite=self.sprite+frame*16
      if (self.anim_frame<=0) then
        if (self.dead) then sprite=((frame==1 and (turn-self.dhp_turn)<=1 and self.blink_delay<=0 and not creature.anim_playing) and sprites.void) or sprites.grave
        elseif (self.attacked and frame==1 and self.blink_delay<=0 and not creature.anim_playing) then
          sprite=sprites.void
          if(state==state_game)print(abs(self.dhp),pos_to_screen(self).x+self.anim_x+4-str_width(abs(self.dhp))*0.5,pos_to_screen(self).y+self.anim_y+1,self.dhp<0 and 8 or 11)
        end
      end
      if (self.flash_n>0) then
        self.flash_n-=1
        pal({0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7})
      end
      spr(sprite,pos_to_screen(self).x+self.anim_x,pos_to_screen(self).y+self.anim_y)
      pal()
    end
  end,

  -- perform turn actions
  do_turn=function(self)
    if(turn>self.dhp_turn)self.attacked=false
    if(self.dead and (turn-self.dhp_turn)>timer_corpse)self:destroy()
    if(self.target~=nil and self.target.dead or (turn-self.target_turn)>timer_target)self.target=nil
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
    if (self.anim==creature.anims.move) then
      self.anim_x=self.anim.dist*anim_pos*((self.anim_x<-0.1 and -1) or (self.anim_x>0.1 and 1) or 0)
      self.anim_y=self.anim.dist*anim_pos*((self.anim_y<-0.1 and -1) or (self.anim_y>0.1 and 1) or 0)
    elseif (self.anim==creature.anims.attack) then
      if (self.target~=nil) then
        if(self.anim_frame==self.anim.frames and self.target==player)draw.flash_n=2
        if(self.anim_frame==self.anim.frames-3)self.target.flash_n=2
      end
      self.anim_x=self.anim.dist*anim_pos*((self.anim_x1<-0.1 and -1) or (self.anim_x1>0.1 and 1) or 0)
      self.anim_y=self.anim.dist*anim_pos*((self.anim_y1<-0.1 and -1) or (self.anim_y1>0.1 and 1) or 0)
    end
    
    self.anim_frame-=1
    if (self.anim_frame<=0) then
      del(creature.anim_queue,self.id)
      if(#creature.anim_queue==0)creature.anim_playing=false
      self.anim_x=0
      self.anim_y=0
    end
  end,

  -- try to move the creature to a given map coordinate
  move=function(self,x,y)
    if (not collision(x,y) and x>=0 and x<width and y>=0 and y<height and (x~=0 or y~=0)) then
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
player = creature:new({
  -- static vars
  class="player",
  parent_class=creature.class,
  interactable=false,
  name="you",

  -- vars
  xp=0,

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
      if (player.target~=nil and player.target_turn<turn) then
        self:move_towards_and_attack(player.target)
      else
        self:follow(player)
      end
    elseif not self:in_frame() then
      self.x=player.prev_x
      self.y=player.prev_y
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
    if(tbl.lock~=nil) then
      tbl["name"]="locked door"
      if (tbl.lock>0) then
        for d in all(data_locks.doors) do if(d.x==tbl.x and d.y==tbl.y)then tbl.lock=d.lock or 1 break end end
        key.set_color_swap(tbl,tbl.lock)
      end
    end
    return entity.new(self,tbl)
  end,

  -- interact action
  interact=function(self)
    self.collision=not self.collision
    self.sprite=(self.collision and 82) or 81
    if (self.lock>0) then
      self.lock=0
      self.color_swap_enable=false
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
    -- TODO: implement this
    msg.add("went on stairs")
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
    change_state(state_read)
    sel.read.text=self.message
    sel.read.fg=self.fg
    sel.read.bg=self.bg
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

  -- interact action
  interact = function(self)
    -- TODO: implement this
    msg.add("opened chest")
    change_state(state_game)
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
    tbl.item_data=tbl.item_data~=nil and tbl_copy(tbl.item_data) or {}
    if (tbl.item_class==key.class) then 
      for d in all(data_locks.keys) do if(d.x==tbl.x and d.y==tbl.y)then tbl.item_data["lock"]=d.lock or 1 break end end 
      if (tbl.item_data.lock>1)key.set_color_swap(tbl,tbl.item_data.lock)
      tbl.name=key.colors[tbl.item_data.lock][1].." key"
    end
    return entity.new(self,tbl)
  end,

  -- interact action
  interact=function(self)
    msg.add("picked up "..self:get_name())
    inventory.add(self)
    self:destroy()
    change_state(state_game)
  end,

})



-------------------------------------------------------------------------------
-- possession (item in inventory)
-------------------------------------------------------------------------------
possession=object:inherit({
  -- static vars
  class="possession",
  parent_class=object.class,
  num=0,

  -- vars
  name=nil,
  sprite=0,
  interactable=true,

  -- constructor
  new=function(self,tbl)
    local itm=self:inherit(tbl)
    possession.num=possession.num+1
    itm["id"]=possession.num
    return itm
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
  set_color_swap=function(tbl,i)
    tbl["color_swap_enable"]=true
    tbl["color_swap"]={[key.colors[1][2]]=key.colors[i][2],[key.colors[1][3]]=key.colors[i][3]}
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