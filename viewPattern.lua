local args={...}
local hex=peripheral.wrap("top")
local hexType=peripheral.getType("top")
local gpu=peripheral.wrap("bottom")
--reset screen
gpu.sync()
gpu.setSize(64)
gpu.refreshSize()
local background=0x00007f00
gpu.fill(background)
gpu.setFont("ascii")
gpu.sync()
--get screen size
local screenX,screenY,screenBlockX,screenBlockY=gpu.getSize()
--set scale
local blockSize=math.min(screenBlockX,screenBlockY)
local gridScale=tonumber(args[1])
if not gridScale then
    gridScale=8*blockSize
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

local function getStart(pattern,startDir,startX,startY,sizeX,sizeY)
    local minX,minY,maxX,maxY=getBounds(pattern,startDir)
    --calc size
    local patternSizeX=maxX-minX
    local patternSizeY=maxY-minY
    local offsetX=((sizeX-patternSizeX)/2)+(startX-1)
    local offsetY=((sizeY-patternSizeY)/2)+(startY-1)
    return math.floor(offsetX-minX),math.floor(offsetY-minY)
end


local function drawPattern(pattern,startDir,startX,startY,sizeX,sizeY)
    if startX==nil then
        startX=1
    end
    if startY==nil then
        startY=1
    end
    if sizeX==nil then
        sizeX=screenX
    end
    if sizeY==nil then
        sizeY=screenY
    end
    local direction
    --start x1,y1 as middle of screen
    --local x1=math.floor(screenX/2)
    --local y1=math.floor(screenY/2)
    local x1,y1=getStart(pattern,startDir,startX,startY,sizeX,sizeY)
    local x2,y2=x1,y1
    local startX,startY=x1,y1
    local color=0x00ffffff
    local colorStep=math.floor(0xff/(string.len(pattern)+1))
    local colorDiff=(colorStep*0x10000)+(colorStep*0x100)+colorStep
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
    gpu.lineS(x1,y1,x2,y2,color)
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
        color=color-colorDiff
        if color<0x00080808 then
            color=0x00080808
        end
        gpu.lineS(x1,y1,x2,y2,color)
    end
    --denote start
    gpu.filledRectangle(startX-1,startY-1,3,3,0xffff0000)
end

local function drawList(iota)
    while true do
        for i=1,#iota do
            local pattern=iota[i]
            print("Pattern: "..i.."/"..#iota)
            print("startDir: "..pattern.startDir)
            print("angles: "..pattern.angles)
            gpu.fill(background)
            drawPattern(pattern.angles,pattern.startDir)
            gpu.drawText(2,2,i.."/"..#iota,0x00000000)
            gpu.sync()
            sleep(2)
        end
    end
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
            drawList(iota)
        elseif focus=="hexcasting:vec3" then
            local vector=hex.readIota()
            print("Vector")
            print(vector.x)
            print(vector.y)
            print(vector.z)
            gpu.drawText(2,2,"Vector:",0x00000000)
            gpu.drawText(2,10,string.format("%.3f", vector.x),0x00000000)
            gpu.drawText(2,18,string.format("%.3f", vector.y),0x00000000)
            gpu.drawText(2,26,string.format("%.3f", vector.z),0x00000000)
            gpu.sync()
        elseif focus=="hexcasting:double" then
            local number=hex.readIota()
            print("Double")
            print(number)
            gpu.drawText(2,2,"Double:",0x00000000)
            gpu.drawText(2,10,number,0x00000000)
            gpu.sync()
        elseif focus=="hexcasting:entity" then
            local entity=hex.readIota()
            local entityType
            if entity.isPlayer then
                entityType="Player"
            else
                entityType="Non-Player"
            end
            print(entityType.." Entity:")
            print(entity.name)
            print(entity.uuid)
            gpu.drawText(2,2,entityType.." Entity:",0x00000000)
            gpu.drawText(2,10,entity.name,0x00000000)
            gpu.drawText(2,18,entity.uuid,0x00000000)
            gpu.sync()
        else
            print("Focus is empty, or unknown iota")
        end
    else
        print("Focal port is empty")
    end
elseif hexType=="akashic_bookshelf" then
    local pattern=hex.readShelf().patternKey
    print("Reading Stored Iota")
    print("startDir: "..pattern.startDir)
    print("angles: "..pattern.angles)
    drawPattern(pattern.angles,pattern.startDir)
    gpu.sync()
else
    print("Unknown peripheral")
end

