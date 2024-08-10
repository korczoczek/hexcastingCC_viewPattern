local args={...}
---------------------------------------
--define where the peripherals are HERE
local hex_location="top"
local gpu_location="bottom"
--set background color
local background=0x00007f00
--location of pattern name list
local patternListLoc="patternList.lua"
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
local greatList={}
if fs.exists(patternListLoc) then
    local f=assert(loadfile(patternListLoc))
    patternList,greatList = f()
    isList=true
    print("Pattern name list found, program will attempt to identify hex patterns")
else
    print("Pattern name list not found")
end
--direction shorthand
--0=EAST
--1=SOUTH_EAST
--2=SOUTH_WEST
--3=WEST
--4=NORTH_WEST
--5=NORTH_EAST

--angle shorthand
--d=sharp right
--e=right
--w=forward
--q=left
--a=sharp-left

local directionMap={
    ["EAST"]=0,
    ["SOUTH_EAST"]=1,
    ["SOUTH_WEST"]=2,
    ["WEST"]=3,
    ["NORTH_WEST"]=4,
    ["NORTH_EAST"]=5
}

local angleMap={
    ["d"]=2,
    ["e"]=1,
    ["w"]=0,
    ["q"]=-1,
    ["a"]=-2
}

local function tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end

local function equalSplit(str,len)
    if len==nil then
        error("No Length Provided")
    end
    local t={}
    local pointerA,pointerB=1,1
    while pointerB<=#str do
        pointerB=pointerB+len
        table.insert(t,str:sub(pointerA,pointerB))
        pointerB=pointerB+1
        pointerA=pointerB
    end
    return t
end

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
    return directionMap[startDir]
end

local function updateDirection(c,direction)
    if direction==nil then
        error("direction is empty",2)
    end
    if angleMap[c]==nil then
        error("Program encountered unknown angle while reading pattern")
        os.exit()
    end
    return (direction+angleMap[c])%6
end

local function getLineCoords(x,y,direction,scale)
    if scale==nil then
        scale=gridScale
    end
    if direction==0 then--EAST
        x=x+scale
    elseif direction==1 then--SOUTH_EAST
        x=x+(scale/2)
        y=y+scale
    elseif direction==2 then--SOUTH_WEST
        x=x-(scale/2)
        y=y+scale
    elseif direction==3 then--WEST
        x=x-scale
    elseif direction==4 then--NORTH_WEST
        x=x-(scale/2)
        y=y-scale
    elseif direction==5 then--NORTH_EAST
        x=x+(scale/2)
        y=y-scale
    end
    return x,y
end

local function getBounds(pattern,startDir,scale)
    local x,y,minX,minY,maxX,maxY=0,0,0,0,0,0
    local direction=getInitialDirection(startDir)
    x,y=getLineCoords(x,y,direction,scale)
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
        x,y=getLineCoords(x,y,direction,scale)
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

local function getStart(pattern,startDir,startX,startY,sizeX,sizeY,scale)
    local minX,minY,maxX,maxY=getBounds(pattern,startDir,scale)
    --calc size
    local patternSizeX=maxX-minX
    local patternSizeY=maxY-minY
    local offsetX=((sizeX-patternSizeX)/2)+(startX-1)
    local offsetY=((sizeY-patternSizeY)/2)+(startY-1)
    return math.floor(offsetX-minX),math.floor(offsetY-minY)
end

local function getPointCloud(startDir,pattern,scale)
    local pointCloud={}
    local direction=getInitialDirection(startDir)
    local x1,y1=getStart(pattern,startDir,0,0,0,0,scale)
    table.insert(pointCloud,x1)
    table.insert(pointCloud,y1)
    local x2,y2=getLineCoords(x1,y1,direction,scale)
    table.insert(pointCloud,x2)
    table.insert(pointCloud,y2)
    for i=1,#pattern do
        local c=pattern:sub(i,i)
        direction=updateDirection(c,direction)
        x1=x2
        y1=y2
        x2,y2=getLineCoords(x1,y1,direction,scale)
        table.insert(pointCloud,x2)
        table.insert(pointCloud,y2)
    end
    return pointCloud
end

local function isPointCloudEqual(cloudA,cloudB,verb)
    if #cloudA%2~=0 or #cloudB%2~=0 then
        error("One of the passed clouds has an odd number of elements",2)
        os.exit()
    end
    if #cloudA~=#cloudB then
        if verb then
            print("Number of elements does not match")
            print("A="..#cloudA)
            print("B="..#cloudB)
        end
        return false
    end
    if cloudB[1]==cloudB[#cloudB-1] and cloudB[2]==cloudB[#cloudB] then
        table.remove(cloudB)
        table.remove(cloudB)
    end
    for i=math.floor(#cloudA/2),1,-1 do
        local j=math.floor(#cloudB/2)
        while j>=1 and (cloudA[(2*i)-1]~=cloudB[(2*j)-1] or cloudA[2*i]~=cloudB[2*j]) do
            j=j-1
        end
        if j>0 then
            --print(i..","..j)
            table.remove(cloudB,(2*j))
            table.remove(cloudB,(2*j)-1)
        end
    end
    if #cloudB==0 then
        return true
    end
    return false
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

local function getGreatSpellName(pattern)
        for great,greatName in pairs(greatList) do
            for directionGreat in pairs(directionMap) do
                local greatPointCloud=getPointCloud(directionGreat,great,2)
                for direction in pairs(directionMap) do
                    local patternPointCloud=getPointCloud(direction,pattern,2)
                    if isPointCloudEqual(patternPointCloud,greatPointCloud) then
                        return greatName
                    end
                end
            end
        end
    return "?????"
end

local function getPatternName(pattern)
    --check pattern list
    local name=patternList[pattern]
    if name==nil then
        --check if number literal
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
            return tostring(number)
        elseif isBookkeeperGambit(pattern) then
            return "Bookkeeper's Gambit"
        else
            return getGreatSpellName(pattern)
        end
    end
    return assert(name)
end

local function drawPattern(pattern,startDir,patternName)
    local startX,startY,sizeX,sizeY=1,1,screenX,screenY
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
        drawPattern(pattern.angles,pattern.startDir,patternName)
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
            drawPattern(iota.angles,iota.startDir,patternName)
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
    elseif iotaType=="moreiotas:string" then
        gpu.drawText(2,2,iotaType,0x00000000)
        print(iotaType)
        print(iota)
        local table=equalSplit(iota,math.floor((screenX-2)/6))
        for i=1,math.floor((screenY-10)/9)-1 do
            if table[i]~=nil then
                gpu.drawText(2,2+(i*9),table[i],0x00000000)
            end
        end
        gpu.sync()
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
        drawPattern(pattern.angles,pattern.startDir,patternName)
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

