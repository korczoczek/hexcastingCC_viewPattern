local args={...}
local hex=peripheral.wrap("left")
local hexType=peripheral.getType("left")
local gpu=peripheral.wrap("right")
--reset screen
gpu.setSize(64)
gpu.refreshSize()
local background=0xffaaaaaa
gpu.fill(background)
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

local function getBounds(pattern,startDir)
    local x,y,minX,minY,maxX,maxY=0,0,0,0,0,0
    local direction
    if startDir=="EAST" then--EAST
        direction=1
        x=x+gridScale
    elseif startDir=="SOUTH_EAST" then--SOUTH_EAST
        direction=2
        x=x+(gridScale/2)
        y=y+gridScale
    elseif startDir=="SOUTH_WEST" then--SOUTH_WEST
        direction=3
        x=x-(gridScale/2)
        y=y+gridScale
    elseif startDir=="WEST" then--WEST
        direction=4
        x=x-gridScale
    elseif startDir=="NORTH_WEST" then--NORTH_WEST
        direction=5
        x=x-(gridScale/2)
        y=y-gridScale
    elseif startDir=="NORTH_EAST" then--NORTH_EAST
        direction=6
        x=x+(gridScale/2)
        y=y-gridScale
    end
    if x>maxX then
        maxX=x
    elseif x<minX then
        minX=x
    end
    if y>maxY then
        maxY=y
    elseif y<minY then
        minY=y
    end
    for i=1,#pattern do
        local c=pattern:sub(i,i)
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
        if direction==1 then--EAST
            x=x+gridScale
        elseif direction==2 then--SOUTH_EAST
            x=x+(gridScale/2)
            y=y+gridScale
        elseif direction==3 then--SOUTH_WEST
            x=x-(gridScale/2)
            y=y+gridScale
        elseif direction==4 then--WEST
            x=x-gridScale
        elseif direction==5 then--NORTH_WEST
            x=x-(gridScale/2)
            y=y-gridScale
        elseif direction==6 then--NORTH_EAST
            x=x+(gridScale/2)
            y=y-gridScale
        end
        if x>maxX then
            maxX=x
        elseif x<minX then
            minX=x
        end
        if y>maxY then
            maxY=y
        elseif y<minY then
            minY=y
        end
    end
    return minX,minY,maxX,maxY
end

local function getStart(pattern,startDir)
    local minX,minY,maxX,maxY=getBounds(pattern,startDir)
    --calc size
    local sizeX=maxX-minX
    local sizeY=maxY-minY
    local offsetX=(screenX-sizeX)/2
    local offsetY=(screenY-sizeY)/2
    return math.floor(offsetX-minX),math.floor(offsetY-minY)
end


local function drawPattern(pattern,startDir)
    local direction
    --start x1,y1 as middle of screen
    --local x1=math.floor(screenX/2)
    --local y1=math.floor(screenY/2)
    local x1,y1=getStart(pattern,startDir)
    local x2,y2=x1,y1
    local startX,startY=x1,y1
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
        if color<0xff0f0f0f then
            color=0xff0f0f0f
        end
        gpu.line(x1,y1,x2,y2,color)
    end
    --denote start
    gpu.filledRectangle(startX,startY,1,1,0xffff0000)
end

if hexType=="slate" then
    local pattern=hex.readPattern()
    print("Slate")
    print("startDir: "..pattern.startDir)
    print("angles: "..pattern.angles)
    drawPattern(pattern.angles,pattern.startDir)
    gpu.sync()
elseif hexType=="focal_port" then
    if hex.hasFocus() then
        local focus=hex.getIotaType()
        if focus=="hexcasting:pattern" then
            local pattern=hex.readIota()
            print("Focus - Single Pattern")
            print("startDir: "..pattern.startDir)
            print("angles: "..pattern.angles)
            drawPattern(pattern.angles,pattern.startDir)
            gpu.sync()
        elseif focus=="hexcasting:list" then
            local iota=hex.readIota()
            print("Focus - Pattern List")
            while true do
                for i=1,#iota do
                    local pattern=iota[i]
                    print("Pattern: "..i.."/"..#iota)
                    print("startDir: "..pattern.startDir)
                    print("angles: "..pattern.angles)
                    gpu.fill(background)
                    drawPattern(pattern.angles,pattern.startDir)
                    gpu.sync()
                    sleep(2)
                end
            end
        else
            print("Focus is empty, or contains no patterns")
        end
    else
        print("Focal port is empty")
    end
else
    print("Unknown peripheral")
end

