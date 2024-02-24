Hex=peripheral.wrap("left")
HexType=peripheral.getType("left")
Gpu=peripheral.wrap("right")
--reset screen
Gpu.refreshSize()
Gpu.fill()
Gpu.sync()
--get screen size
ScreenX,ScreenY=Gpu.getSize()
--set scale
GridScale=8


--direction shorthand
--1=EAST
--2=SOUTH_EAST
--3=SOUTH_WEST
--4=WEST
--5=NORTH_WEST
--6=NORTH_EAST

function drawPattern(pattern)
    local direction=1
    for i=1,#pattern do
        local c=pattern:sub(i,i)
        print(c)
    end

end

if HexType=="slate" then
    local pattern=Hex.readPattern().angles
    drawPattern(pattern)
end