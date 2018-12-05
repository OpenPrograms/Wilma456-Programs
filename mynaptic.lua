--Mynaptic Version 1.0 made by Wilma456
local component = require("component")
local event = require("event")
local io = require("io")
local term = require("term")
local shell =require("shell")
local os = require("os")
local filesystem = require("filesystem")
local gpu = component.gpu
local w, h = gpu.getResolution()
local tPackages = {}
local tPackagesFull = {}
local nScrollpos = 0
local sSearch = ""
local sOppmPath = "/usr/share/mynaptic/oppm-mynaptic.lua"

if not filesystem.exists(sOppmPath) then
    print("oppm not found")
    return
end

print("Starting Mynaptic. Please wait...")
os.sleep(0.01)

--Packges install type
--0 not installed
--1 installed
--2 marked to install

local tInstalled = {}
local installedHandle = io.popen(sOppmPath.." list -i")
for linecon in installedHandle:lines() do
    tInstalled[linecon] = true
end
installedHandle:close()

local packageHandle = io.popen(sOppmPath.." list")
for linecon in packageHandle:lines() do
    local tTemp = {}
    tTemp.name = linecon
    if tInstalled[linecon] == true then
        tTemp.type = 1
    else
        tTemp.type = 0
    end
    table.insert(tPackages,tTemp)
    table.insert(tPackagesFull,tTemp)
    tTemp = nil
end
packageHandle:close()

local function redrawMenuBar()
    gpu.setForeground(0x000000)
    gpu.setBackground(0x0000ff)
    gpu.fill(1,1,w,1," ")
    gpu.set(1,1,"Apply")
    gpu.setBackground(0xff0000)
    gpu.set(w,1,"X")
end

local function redrawList()
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(1,2,w,h-2," ")
    for i=2,h-1 do
        local tHandle = tPackages[i-1+nScrollpos]
        if type(tHandle) == "table" then
            if tHandle.type == 1 then
                gpu.setBackground(0x00ff00)
            elseif tHandle.type == 2 then
                gpu.setBackground(0xffff00)
            elseif tHandle.type == 3 then
                gpu.setBackground(0xff0000)
            else
                gpu.setBackground(0xFFFFFF)
            end
            gpu.fill(1,i,w,1," ")
            gpu.set(1,i,tHandle["name"])
        end
    end
end

local function redrawSearchBar()
    gpu.setForeground(0x000000)
    gpu.setBackground(0x0000ff)
    gpu.fill(1,h,w,1," ")
    gpu.set(1,h,"Search:"..sSearch)
end

local function redrawAll()
    redrawMenuBar()
    redrawList()
    redrawSearchBar()
end

local function createSearch()
    tPackages = {}
    for k,v in ipairs(tPackagesFull) do
        if v.name:find(sSearch) ~= nil then
            table.insert(tPackages,v)
        end
    end
    nScrollpos = 0
    redrawList()
end

local function apply()
    local tInstall = {}
    local tRemove = {}
    for k,v in ipairs(tPackagesFull) do
        if v.type == 2 then
            table.insert(tInstall,v)
        elseif v.type == 3 then
            table.insert(tRemove,v)
        end
    end
    local nApplyPos = 0
    local tText = {}
    table.insert(tText,"This Packges will be installed:")
    for k,v in ipairs(tInstall) do
        table.insert(tText,v.name)
    end
    table.insert(tText,"This Packges will be removed:")
    for k,v in ipairs(tRemove) do
        table.insert(tText,v.name)
    end
    while true do
        gpu.setForeground(0x000000)
        gpu.setBackground(0xFFFFFF)
        gpu.fill(1,1,w,h," ")
        for i=1,h-1 do
            if type(tText[i+nApplyPos]) == "string" then
                gpu.set(1,i,tText[i+nApplyPos])
            end
        end
        gpu.setBackground(0x0000ff)
        gpu.fill(1,h,w,1," ")
        gpu.set(1,h,"Cancel")
        gpu.set(w-1,h,"OK")
        local tEvent = table.pack(event.pull())
        if tEvent[1] == "scroll" then
            if tEvent[5] == 1 and nApplyPos ~= 0 then
                nApplyPos = nApplyPos - 1
            elseif tEvent[5] == -1 and (nApplyPos ~= #tText-h+1) and (#tText > h-1) then
                nApplyPos = nApplyPos + 1
            end 
        elseif tEvent[1] == "touch" and tEvent[4] == h then
            if tEvent[3] < 7 then
                return
            elseif (tEvent[3] == w) or (tEvent[3] == w-1) then
                break
            end
        elseif tEvent[1] == "interrupted" then
            return false  
        end
    end
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(1,1,w,h," ")
    term.setCursor(1,1)
    filesystem.makeDirectory("/var/mynaptic")
    local hisfile = io.open("/var/mynaptic/history.txt","a")
    for k,v in ipairs(tInstall) do
        print("Install "..v.name)
        os.sleep(0.01)
        shell.execute(sOppmPath.." install "..v.name)
        v.type = 1
        hisfile:write("Installed "..v.name.."\n")
    end
    for k,v in ipairs(tRemove) do
        print("Remove "..v.name)
        os.sleep(0.01)
        shell.execute(sOppmPath.." uninstall "..v.name)
        v.type = 0
        hisfile:write("Removed "..v.name.."\n")
    end
    hisfile:close()
end

gpu.fill(1, 1, w, h, " ")
gpu.setForeground(0x000000)
gpu.setBackground(0xFFFFFF)
redrawAll()

while true do
    local tEvent = table.pack(event.pull())
    if tEvent[1] == "scroll" then
        if tEvent[5] == 1 and nScrollpos ~= 0 then
            nScrollpos = nScrollpos - 1
        elseif tEvent[5] == -1 and (nScrollpos ~= #tPackages-h+2) and (#tPackages > h-2) then
            nScrollpos = nScrollpos + 1
        end    
        redrawList() 
    elseif tEvent[1] == "touch" and tEvent[5] == 0 then
        if tEvent[4] == 1 then
            if tEvent[3] < 6 then
                if apply() == false then
                    break
                else
                    redrawAll()
                end
            elseif tEvent[3] == w then
                break
            end
        elseif tEvent[4] == h then
            sSearch = ""
            createSearch()
            redrawSearchBar()
        elseif type(tPackages[tEvent[4]+nScrollpos-1]) == "table" then
            local tTemp = tPackages[tEvent[4]+nScrollpos-1]
            if tTemp["type"] == 0 then
                tTemp["type"] = 2
            elseif tTemp["type"] == 1 then
                tTemp["type"] = 3
            elseif tTemp["type"] == 2 then
                tTemp["type"] = 0
            elseif tTemp["type"] == 3 then
                tTemp["type"] = 1
            end
            redrawList()
        end
    elseif tEvent[1] == "touch" and tEvent[5] == 1 then
        if type(tPackages[tEvent[4]+nScrollpos-1]) == "table" then
            gpu.setForeground(0x000000)
            gpu.setBackground(0xFFFFFF)
            gpu.fill(1, 1, w, h, " ")
            print("Getting Information about the Package. Please wait...")
            term.setCursor(1,1)
            os.sleep(0.01)
            shell.execute(sOppmPath.." info "..tPackages[tEvent[4]+nScrollpos-1]["name"])
            gpu.setForeground(0x000000)
            gpu.setBackground(0x0000ff)
            gpu.fill(1,h,w,1," ")
            gpu.set(1,h,"OK")
            local bInteruptet = false
            while true do
                local tEvent = table.pack(event.pull())
                if tEvent[1] == "touch" and tEvent[4] == h then
                    redrawAll()
                    break
                elseif tEvent[1] == "interrupted" then
                    bInteruptet = true
                    break
                end
            end
            if bInteruptet == true then
                break
            end
        end
    elseif tEvent[1] == "key_down" then
        if tEvent[3] == 8 then
            sSearch = sSearch:sub(1,-2)
        else
            sSearch = sSearch..string.char(tEvent[3])
        end
        createSearch()
        redrawSearchBar()
    elseif tEvent[1] == "interrupted" then
        break
    end
end

gpu.setBackground(0x000000)
term.clear()
