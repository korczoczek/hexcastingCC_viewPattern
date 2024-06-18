local args={...}
---------------------------------------
--define where the peripherals are HERE
local hex_location="top"
local gpu_location="bottom"
--set background color
local background=0x00007f00
---------------------------------------
local hex=peripheral.wrap(hex_location)
local hexType=peripheral.getType(hex_location)
local gpu=peripheral.wrap(gpu_location)
--reset screen
gpu.sync()
gpu.setSize(64)
gpu.refreshSize()
gpu.fill(background)
gpu.setFont("ascii")
gpu.sync()
--get screen size
local screenX,screenY,screenBlockX,screenBlockY=gpu.getSize()
--set scale
local blockSize=math.min(screenBlockX,screenBlockY)
local gridScale=tonumber(args[1])
if not gridScale then
    gridScale=6*blockSize
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

local function getInitialDirection(startDir)
    if startDir=="EAST" then--EAST
        return 1
    elseif startDir=="SOUTH_EAST" then--SOUTH_EAST
        return 2
    elseif startDir=="SOUTH_WEST" then--SOUTH_WEST
        return 3
    elseif startDir=="WEST" then--WEST
        return 4
    elseif startDir=="NORTH_WEST" then--NORTH_WEST
        return 5
    elseif startDir=="NORTH_EAST" then--NORTH_EAST
        return 6
    end
end

local function updateDirection(c,direction)
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
    return direction
end

local function getLineCoords(x,y,direction)
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
    return x,y
end

local function getBounds(pattern,startDir)
    local x,y,minX,minY,maxX,maxY=0,0,0,0,0,0
    local direction=getInitialDirection(startDir)
    x,y=getLineCoords(x,y,direction)
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
        direction=updateDirection(c,direction)
        --update line coords
        x,y=getLineCoords(x,y,direction)
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
    local direction=getInitialDirection(startDir)
    local x1,y1=getStart(pattern,startDir,startX,startY,sizeX,sizeY)
    local x2,y2=x1,y1
    local startX,startY=x1,y1
    local color=0x00ffffff
    local colorStep=math.floor(0xff/(string.len(pattern)+1))
    local colorDiff=(colorStep*0x10000)+(colorStep*0x100)+colorStep
    --init start direction
    x2,y2=getLineCoords(x2,y2,direction)
    --draw initial line
    gpu.lineS(x1,y1,x2,y2,color)
    for i=1,#pattern do
        local c=pattern:sub(i,i)
        --print(c)
        --update direction
        direction=updateDirection(c,direction)
        --update line coords
        x1=x2
        y1=y2
        x2,y2=getLineCoords(x2,y2,direction)
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

local function diplayGenericIota(iotaType,iota)
    if iotaType=="" or iotaType==nil then
        print("Iota is Empty")
        return
    elseif iotaType=="hexcasting:pattern" then
        print("Single Pattern")
        print("startDir: "..iota.startDir)
        print("angles: "..iota.angles)
        drawPattern(iota.angles,iota.startDir)
        gpu.sync()
        return
    elseif iotaType=="hexcasting:list" then
        print("Pattern List")
        drawList(iota)
        return
    elseif iotaType=="hexcasting:vec3" then
        print("Vector")
        print(iota.x)
        print(iota.y)
        print(iota.z)
        gpu.drawText(2,2,"Vector:",0x00000000)
        gpu.drawText(2,10,string.format("%.3f", iota.x),0x00000000)
        gpu.drawText(2,18,string.format("%.3f", iota.y),0x00000000)
        gpu.drawText(2,26,string.format("%.3f", iota.z),0x00000000)
        gpu.sync()
        return
    elseif iotaType=="hexcasting:double" then
        print("Double")
        print(iota)
        gpu.drawText(2,2,"Double:",0x00000000)
        gpu.drawText(2,10,iota,0x00000000)
        gpu.sync()
        return
    elseif iotaType=="hexcasting:entity" then
        local entityType
        if iota.isPlayer then
            entityType="Player"
        else
            entityType="Non-Player"
        end
        print(entityType.." Entity:")
        print(iota.name)
        print(iota.uuid)
        gpu.drawText(2,2,entityType.." Entity:",0x00000000)
        gpu.drawText(2,10,iota.name,0x00000000)
        gpu.drawText(2,18,iota.uuid,0x00000000)
        gpu.sync()
        return
    else
        print("Unknown iota")
    end
end

--determine storage type
if hexType=="slate" then
    local pattern=hex.readPattern()
    print("Slate")
    print("startDir: "..pattern.startDir)
    print("angles: "..pattern.angles)
    drawPattern(pattern.angles,pattern.startDir)
    gpu.sync()
elseif hexType=="focal_port" then
    if hex.hasFocus() then
        diplayGenericIota(hex.getIotaType(),hex.readIota())
    else
        print("Focal port is empty")
    end
elseif hexType=="akashic_bookshelf" then
    diplayGenericIota(hex.shelfIotaType,hex.shelfIota)
else
    print("Unknown peripheral")
end

