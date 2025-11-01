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
