local args={...}
local hex=peripheral.wrap("left")
local hexType=peripheral.getType("left")
local gpu=peripheral.wrap("right")
--reset screen
gpu.setSize(64)
gpu.refreshSize()
gpu.fill()
gpu.sync()
--get screen size
local screenX,screenY=gpu.getSize()
--set scale
local gridScale=tonumber(args[1])
if not gridScale then
    gridScale=8
end
print("gridScale: "..gridScale)
--direction shorthand
--1=EAST
--2=SOUTH_EAST
--3=SOUTH_WEST
--4=WEST
--5=NORTH_WEST
--6=NORTH_EAST

--angle shorthand
--d=sharp right
--e=right
--w=forward
--q=left
--a=sharp-left

function drawPattern(pattern,startDir)
    local direction
    --start x1,y1 as middle of screen
    local x1=math.floor(screenX/2)
    local y1=math.floor(screenY/2)
    local x2=x1
    local y2=y1
    local color=0xffffffff
    --init start direction
    if startDir=="EAST" then--EAST
        direction=1
        x2=x1+gridScale
    elseif startDir=="SOUTH_EAST" then--SOUTH_EAST
        direction=2
        x2=x1+(gridScale/2)
        y2=y1+gridScale
    elseif startDir=="SOUTH_WEST" then--SOUTH_WEST
        direction=3
        x2=x1-(gridScale/2)
        y2=y1+gridScale
    elseif startDir=="WEST" then--WEST
        direction=4
        x2=x1-gridScale
    elseif startDir=="NORTH_WEST" then--NORTH_WEST
        direction=5
        x2=x1-(gridScale/2)
        y2=y1-gridScale
    elseif startDir=="NORTH_EAST" then--NORTH_EAST
        direction=6
        x2=x1+(gridScale/2)
        y2=y1-gridScale
    end
    --draw initial line
    gpu.line(x1,y1,x2,y2,color)
    for i=1,#pattern do
        local c=pattern:sub(i,i)
        --print(c)
        --update direction
        if c=="d" then
            direction=direction+2
        elseif c=="e" then
            direction=direction+1
        elseif c=="w" then

        elseif c=="q" then
            direction=direction-1
        elseif c=="a" then
            direction=direction-2
        else
            error("Program encountered unknown angle while reading pattern")
            os.exit()
        end
        --check for over/underflow
        if direction>6 then
            direction=direction-6
        elseif direction<1 then
            direction=direction+6
        end
        --update line coords
        x1=x2
        y1=y2
        if direction==1 then--EAST
            x2=x2+gridScale
        elseif direction==2 then--SOUTH_EAST
            x2=x2+(gridScale/2)
            y2=y2+gridScale
        elseif direction==3 then--SOUTH_WEST
            x2=x2-(gridScale/2)
            y2=y2+gridScale
        elseif direction==4 then--WEST
            x2=x2-gridScale
        elseif direction==5 then--NORTH_WEST
            x2=x2-(gridScale/2)
            y2=y2-gridScale
        elseif direction==6 then--NORTH_EAST
            x2=x2+(gridScale/2)
            y2=y2-gridScale
        end
        --draw line
        color=color-0x00080808
        if color<0xff000000 then
            color=0xff000000
        end
        gpu.line(x1,y1,x2,y2,color)
    end
end

if hexType=="slate" then
    local pattern=hex.readPattern()
    print("startDir: "..pattern.startDir)
    print("angles: "..pattern.angles)
    drawPattern(pattern.angles,pattern.startDir)
    gpu.sync()
end
print("Render Complete")
