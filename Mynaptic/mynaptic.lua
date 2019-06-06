--Mynaptic Version 2.1 made by JakobDev
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
local tMenu = {}
local nScrollpos = 0
local sSearch = ""
local sOppmPath ="/usr/share/mynaptic/oppm-mynaptic.lua"
local sHistoryPath = "/var/mynaptic/history.txt"
local sVersion = "2.1"

if not filesystem.exists(sOppmPath) then
    print("oppm not found")
    return
end

print("Starting Mynaptic. Please wait...")
os.sleep(0.01)

local tHelp = {}

tTemp = {}
tTemp["title"] = "What is OPPM and Mynaptic"
tTemp["content"] = "OPPM is a Package Manager made by Vexatos which allows you simperl to install, remove and update Programs. \n\nMynaptic is a GUI for OPPM"
table.insert(tHelp,tTemp)

tTemp = {}
tTemp["title"] = "Basic Usage"
tTemp["content"] = [[You can mark a Package by clicking it:
White: Package is not installed
Yellow: Package will be installed
Green: Package is already installed
Red: Package will be removed
After you marked the Packages just click "Apply".

You can scroll with the mouse whell in all Menus]]
table.insert(tHelp,tTemp)

tTemp = {}
tTemp["title"] = "Get Information about a Package"
tTemp["content"] = "To get more Information about a Package just rightclick it. It may take a few seconds to fetch the Information"
table.insert(tHelp,tTemp)

tTemp = {}
tTemp["title"] = "Add your own Program"
tTemp["content"] = "To add your own Program to OPPM/Mynaptic please read https://ocdoc.cil.li/tutorial:program:oppm"
table.insert(tHelp,tTemp)

tTemp = {}
tTemp["title"] = "License"
tTemp["content"] = [[Copyright (c) 2018-2019, JakobDev
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]
table.insert(tHelp,tTemp)

tTemp = {}
tTemp["title"] = "About"
tTemp["content"] = "Mynaptic for OPPM Version "..sVersion.." made by JakobDev"
table.insert(tHelp,tTemp)

--Packges install type
--0 not installed
--1 installed
--2 marked to install
--3 mark to remove

local tInstalled = {}
local installedHandle = io.popen(sOppmPath.." list -im")
for linecon in installedHandle:lines() do
    tInstalled[linecon] = true
end
installedHandle:close()

local packageHandle = io.popen(sOppmPath.." list -m")
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
    local sMenu = ""
    for k,v in ipairs(tMenu) do
        sMenu = sMenu..v.text.." "
    end
    gpu.set(1,1,sMenu)
    gpu.setBackground(0xff0000)
    gpu.set(w,1,"X")
end

local function drawEntry(tEntry,nPos)
    if type(tEntry) == "table" then
        if tEntry.type == 1 then
            gpu.setBackground(0x00ff00)
        elseif tEntry.type == 2 then
            gpu.setBackground(0xffff00)
        elseif tEntry.type == 3 then
            gpu.setBackground(0xff0000)
        else
            gpu.setBackground(0xFFFFFF)
        end
        gpu.fill(1,nPos,w,1," ")
        gpu.set(1,nPos,tEntry["name"])
    end
end

local function redrawList()
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(1,2,w,h-2," ")
    for i=2,h-1 do
        drawEntry(tPackages[i-1+nScrollpos],i)
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

local function scrollUp()
    gpu.copy(1,2,w,h-3,0,1)
    drawEntry(tPackages[nScrollpos+1],2)
end

local function scrollDown()
    gpu.copy(1,3,w,h-3,0,-1)
    drawEntry(tPackages[h-2+nScrollpos],h-1)
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
    filesystem.makeDirectory(filesystem.path(sHistoryPath))
    local hisfile = io.open(sHistoryPath,"a")
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

local function drawHistoryEntry(sText,nPos)
    if sText:find("Installed") == 1 then
        gpu.setForeground(0x00ff00)
    elseif sText:find("Removed") == 1 then
        gpu.setForeground(0xff0000)
    else
        gpu.setForeground(0x000000)
    end
    gpu.set(1,nPos,sText)
end

local function history()
    local tHistory = {}
    local nHispos = 0
    if filesystem.exists(sHistoryPath) then
        local hisfile = io.open(sHistoryPath,"r")
        for sLine in hisfile:lines() do
            table.insert(tHistory,sLine)
        end
        hisfile:close()
    else
        tHistory[1] = "History is empty"
    end
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(1,1,w,h," ")
    for i=1,h-1 do
        if tHistory[i] then
           drawHistoryEntry(tHistory[i],i)
        end
    end
    gpu.setBackground(0x0000ff)
    gpu.setForeground(0x000000)
    gpu.fill(1,h,w,1," ")
    gpu.set(1,h,"OK")
    gpu.set(w-4,h,"Clear")
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    while true do
        local tEvent = table.pack(event.pull())
        if tEvent[1] == "scroll" then
            if tEvent[5] == 1 and nHispos ~= 0 then
                nHispos = nHispos - 1
                gpu.copy(1,1,w,h-2,0,1)
                drawHistoryEntry(tHistory[nHispos+1],1)
            elseif tEvent[5] == -1 and (nHispos ~= #tHistory-h+1) and (#tHistory > h-1) then
                nHispos = nHispos + 1
                gpu.copy(1,2,w,h-2,0,-1)
                if tHistory[nHispos+h-1] then
                    drawHistoryEntry(tHistory[nHispos+h-1],h-1)
                end
            end    
        elseif tEvent[1] == "touch" and tEvent[4] == h then
            if tEvent[3] < 3 then
                return
            elseif tEvent[3] > w-5 then
                tHistory = {}
                gpu.setForeground(0x000000)
                gpu.setBackground(0xFFFFFF)
                gpu.fill(1,1,w,h-1," ")
                gpu.set(1,1,"History cleared")
                filesystem.remove(sHistoryPath)
            end
        elseif tEvent[1] == "interrupted" then
            return false
        end
    end
end

local function showHelp(sText)
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(1,1,w,h-1," ")
    term.setCursor(1,1)
    term.write(sText)
    gpu.setBackground(0x0000ff)
    gpu.fill(1,h,w,1," ")
    gpu.set(1,h,"OK")
    while true do
        local tEvent = table.pack(event.pull())
        if tEvent[1] == "touch" and tEvent[4] == h then
            return
        elseif tEvent[1] == "interrupted" then
            return false
        end
    end
end

local function showHelpList()
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(1,1,w,h-1," ")
    for i=1,h-1 do
        if tHelp[i] then
            gpu.set(1,i,tHelp[i]["title"])
        end
    end
    gpu.setBackground(0x0000ff)
    gpu.fill(1,h,w,1," ")
    gpu.set(1,h,"OK")
end

local function helpList()
    showHelpList()
    while true do
        local tEvent = table.pack(event.pull())
        if tEvent[1] == "touch" then
            if tEvent[4] == h then
                return
            elseif tHelp[tEvent[4]] then
                if showHelp(tHelp[tEvent[4]]["content"]) == false then
                    return false
                else
                    showHelpList()
                end
            end
        elseif tEvent[1] == "interrupted" then
            return false
        end
    end
end

tMenu[1] = {text="Apply",func=apply}
tMenu[2] = {text="History",func=history}
tMenu[3] = {text="Help",func=helpList}

gpu.fill(1, 1, w, h, " ")
gpu.setForeground(0x000000)
gpu.setBackground(0xFFFFFF)
redrawAll()

local function main()
while true do
    local tEvent = table.pack(event.pull())
    if tEvent[1] == "scroll" then
        if tEvent[5] == 1 and nScrollpos ~= 0 then
            nScrollpos = nScrollpos - 1
            scrollUp()
        elseif tEvent[5] == -1 and (nScrollpos ~= #tPackages-h+2) and (#tPackages > h-2) then
            nScrollpos = nScrollpos + 1
            --redrawList()
            scrollDown()
        end    
        --redrawList() 
    elseif tEvent[1] == "touch" and tEvent[5] == 0 then
        if tEvent[4] == 1 then
            if tEvent[3] == w then
                break
            else
                local nMenuPos = 0
                for k,v in ipairs(tMenu) do
                    if tEvent[3] > nMenuPos and tEvent[3] < nMenuPos+#v.text+1 then
                        if v.func() == false then
                            return
                        else
                            redrawAll()
                        end
                        break
                    else
                        nMenuPos = nMenuPos+#v.text+1
                    end
                end
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
            --redrawList()
            drawEntry(tTemp,tEvent[4])
        end
    elseif tEvent[1] == "touch" and tEvent[5] == 1 then
        if type(tPackages[tEvent[4]+nScrollpos-1]) == "table" then
            gpu.setForeground(0x000000)
            gpu.setBackground(0xFFFFFF)
            gpu.fill(1, 1, w, h, " ")
            term.setCursor(1,1)
            term.write("Getting Information about the Package. Please wait...")
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
        return
    end
end
end

main()

gpu.setBackground(0x000000)
term.clear()
