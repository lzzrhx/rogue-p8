-------------------------------------------------------------------------------
-- utils
-------------------------------------------------------------------------------

-- calculate (chebyshev) distance between two points
function dist(a,b)
  return max(abs(b.x-a.x),abs(b.y-a.y))
end

-- calculate string width
function str_width(s)
  return print(s,0,128)
end

-- calculate string height
function str_height(s)
  return tbl_len(split(s,"\n"))
end

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
function tbl_merge(a,b)
  for k,v in pairs(b) do a[k]=v end return a
end

-- check length of table
function tbl_len(t)
  num=0
  for k,v in pairs(t) do num+=1 end
  return num
end

-- transform position to screen position
function pos_to_screen(pos)
  return {x=8*(pos.x-cam_x),y=8*(pos.y-cam_y)}
end

-- cubic polynomial smoothstep
function smoothstep(x)
  return x*x*(3-2*x)
end

-- linear interpolation
function lerp(val,min,max)
  return (max-min)*val+min
end

-- wavy text
function wavy_print(s,x,y,c,h)
  for i=1,#s do print(sub(s,i,i),x+i*4,y+wavy(i),c) end
end

-- wavy value
function wavy(i,h,s,o)
  return sin(t()*(s or 1.25)+(i or 1)*(o or 0.06))*(h or 3)
end

-- change palette (if not locked)
function pal_set(param,lock)
  if(not pal_lock) then
    pal_lock=lock or false
    pal(param)
  end
end

-- change all colors (except black)
function pal_all(c,lock)
  pal_set({0,c,c,c,c,c,c,c,c,c,c,c,c,c,c},lock or false)
end

-- unlock and reset palette
function pal_unlock()
  pal_lock=false
  pal()
end

-- add two 2d vectors
function vec2_add(a,b)
  return {x=a.x+b.x,y=a.y+b.y}
end

function vec2_scale(a,b)
  return {x=a.x*b,y=a.y*b}
end

-- draw sprite with 2d vector screen coordinate
function vec2_spr(s,pos)
  spr(s,pos.x,pos.y)
end
