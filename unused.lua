-- glitch effect
function glitch1()
    o1 = flr(rnd(0x1F00)) + 0x6040
    o2 = o1 + flr(rnd(0x4)-0x2)
    len = flr(rnd(0x40))
    memcpy(o1,o2,len)
end

-- glitch effect
function glitch2(lines)
    local lines=lines or 64
    for i=1,lines do
        row=flr(rnd(128))
        row2=flr(rnd(127))
        if (row2>=row) row2+=1
        memcpy(0x4300, 0x6000+64*row, 64)
        memcpy(0x6000+64*row, 0x6000+64*row2, 64)
        memcpy(0x6000+64*row2, 0x4300,64)
    end
end

-- calculate distance between two points
function dist(a,b)
  return sqrt((b.x-a.x)^2 + (b.y-a.y)^2)
end

-- quartic polynomial smoothstep
function smoothstep(x) return x*x*(2-x*x) end

-- quadratic rational smoothstep
function smoothstep(x) return x*x/(2*x*x-2*x+1) end

--[[
    -- spinning rainbow waves
    num_stars=96
    cols={8,9,10,11,12,13,14,15}
    for i=1,num_stars do
      x=cos(t()/8+i/num_stars)*54
      y=sin(t()/8+i/num_stars)*10+sin(t()+i*(1/num_stars)*5)*4
      c=cols[i%(#cols)+1]
      pset(64+x,30+y+9,c)
      pset(64+x+1,30+y+9+1,c)
      pset(64+x+2,30+y+9+2,c)
    end
        ]]--