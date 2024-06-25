local args={...}
---------------------------------------
--define where the peripherals are HERE
local hex_location="top"
local gpu_location="bottom"
--set background color
local background=0x00007f00
--location of pattern name list
local patternListLoc="patternList"
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
--load pattern list
local isList=false
local patternList={}
if fs.exists(patternListLoc..".lua") then
    patternList = require(patternListLoc)
    isList=true
    print("Pattern name list file found, program will attempt to identify hex patterns")
else
    print("Pattern name list file NOT found")
end
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

local function mysplit(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
  end

local function getColor(isActive)
    if isActive then
        return 0x00a0a0a0
    end
    return 0x00000000
end

local function between(number,lower,upper)
    if number>upper or number<lower then
        return false
    end
    return true
end

local function starts_with(str, start)
    return str:sub(1, #start) == start
 end

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

local function isBookkeeperGambit(pattern)
    local first=pattern:sub(1,1)
    if first=="w" or first=="e" or first=="a" then
        local prev=first
        local curr=""
        for i=2,#pattern do
            curr=pattern:sub(i,i)
            if curr=="q" then
                return false
            elseif prev=="w" and (curr=="a" or curr=="d") then
                return false
            elseif prev=="a" and (curr=="w" or curr=="a") then
                return false
            elseif prev=="e" and curr=="d" then
                return false
            elseif prev=="d" and not curr=="a" then
                return false
            end
            prev=curr
        end
        return true
    end
    return false
end

local function getPatternName(pattern)
    local name=patternList[pattern]
    if name==nil then
        if starts_with(pattern,"dedd") or starts_with(pattern,"aqaa") then
            local number=0
            for i=4,#pattern do
                local op=pattern:sub(i,i)
                if op=="a" then
                    number=number*2
                elseif op=="q" then
                    number=number+5
                elseif op=="w" then
                    number=number+1
                elseif op=="e" then
                    number=number+10
                elseif op=="d" then
                    number=number/2
                end
            end
            if starts_with(pattern,"dedd") then
                number=0-number
            end
            name=tostring(number)
        elseif isBookkeeperGambit(pattern) then
            name="Bookkeeper's Gambit"
        else
            name="?????"
        end
    end
    return name
end

local function drawPattern(pattern,startDir,startX,startY,sizeX,sizeY,patternName)
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
    startX,startY=x1,y1
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
    if patternName then
        gpu.drawText(2,2,patternName,0x00000000)
    end
end

local function drawList(iota)
    local isAuto=true
    local index=1
    local t0=os.clock()
    local prevIndex=0
    local patternName=""
    while true do
        local pattern=iota[index]
        if pattern.angles==nil and pattern.startDir==nil then
            print("List contains non-pattern elements, quitting program")
            return
        end
        if prevIndex~=index then
            print("Pattern: "..index.."/"..#iota)
            print("startDir: "..pattern.startDir)
            print("angles: "..pattern.angles)
            if isList then
                patternName=getPatternName(pattern.angles)
            end
            print("Name: "..patternName)
        end
        gpu.fill(background)
        drawPattern(pattern.angles,pattern.startDir,nil,nil,nil,nil,patternName)
        gpu.drawText(2,screenY-8,index.."/"..#iota,0x00000000)
        gpu.drawText(screenX-(14*6),screenY-8,"PREV      NEXT",getColor(isAuto))
        gpu.drawText(screenX-(9*6),screenY-8,"AUTO     ",getColor(not isAuto))
        gpu.sync()
        prevIndex=index
        local timer=os.startTimer(0.1)
        local event,loc,x,y=os.pullEvent()
        os.cancelTimer(timer)
        if event=="tm_monitor_touch" and loc==gpu_location then
            if between(x,screenX-(9*6),screenX-(5*6)) and between(y,screenY-24,screenY) then
                isAuto=not isAuto
                t0=os.clock()
            elseif between(x,screenX-(14*6),screenX-(10*6)) and between(y,screenY-24,screenY) then
                if not isAuto then
                    index=index-1
                end
            elseif between(x,screenX-(4*6),screenX-(0*6)) and between(y,screenY-24,screenY) then
                if not isAuto then
                    index=index+1
                end
            end
        end
        if isAuto and os.clock()-t0>2 then
            index=index+1
            t0=os.clock()
        end
        if index>#iota then
            index=1
        elseif index<1 then
            index=#iota
        end
    end
end

local function diplayGenericIota(iotaType,iota)
    if iotaType=="hexcasting:null" then
        print("Iota is Empty")
        return
    elseif iotaType=="hexcasting:list" then
        print("Pattern List")
        drawList(iota)
        return
    elseif iotaType=="hexcasting:pattern" then
        print("Single Pattern")
        print("startDir: "..iota.startDir)
        print("angles: "..iota.angles)
        local patternName
        if isList then
            patternName=getPatternName(iota.angles)
            print("Name: "..patternName)
            drawPattern(iota.angles,iota.startDir,nil,nil,nil,nil,patternName)
        else
            drawPattern(iota.angles,iota.startDir)
        end
        gpu.sync()
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
        gpu.drawText(2,18,"UUID:",0x00000000)
        local uuid=mysplit(iota.uuid,"-")
        for i=1,#uuid do
            gpu.drawText(2,18+(i*8),uuid[i],0x00000000) 
        end
        gpu.sync()
        return
    elseif iotaType=="moreiotas:matrix" then
        print("moreiotas Matrix")
        gpu.drawText(2,2,"moreiotas Matrix",0x00000000)
        local maxLen=0
        local str
        for i=1,#iota.matrix do
            str=string.format("%.3f",iota.matrix[i])
            local strLen=string.len(str)
            if strLen>maxLen then
                maxLen=strLen
            end
        end
        local offsetY=0
        local index=1
        for i=1,iota.row do
            local offsetX=0
            if offsetY+18<screenY then
                for j=1,iota.col do
                    if offsetX+(maxLen*6)<screenX then
                        gpu.drawText(2+offsetX,10+offsetY,string.format("%.3f", iota.matrix[index]),0x00000000)
                        print(iota.matrix[index])
                    end
                    offsetX=offsetX+(maxLen*6)
                    index=index+1
                end
            end
            offsetY=offsetY+8
        end
        gpu.sync()
        return
    else
        print("Unknown iota, attempting to print")
        print(iotaType)
        print(tostring(iota))
        gpu.drawText(2,2,iotaType,0x00000000)
        gpu.drawText(2,10,tostring(iota),0x00000000)
        gpu.sync()
    end
end

--determine storage type
if hexType=="slate" then
    local pattern=hex.readPattern()
    local patternName=""
    print("Slate")
    print("startDir: "..pattern.startDir)
    print("angles: "..pattern.angles)
    if isList then
        patternName=getPatternName(pattern.angles)
        print("Name: "..patternName)
        drawPattern(pattern.angles,pattern.startDir,nil,nil,nil,nil,patternName)
    else
        drawPattern(pattern.angles,pattern.startDir)
    end
    gpu.sync()
elseif hexType=="focal_port" then
    if hex.hasFocus() then
        diplayGenericIota(hex.getIotaType(),hex.readIota())
    else
        print("Focal port is empty")
    end
elseif hexType=="akashic_bookshelf" then
    local shelf=hex.readShelf()
    diplayGenericIota(shelf.shelfIotaType,shelf.shelfIota)
else
    print("Unknown peripheral")
end

