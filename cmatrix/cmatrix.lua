--cmatrix made by JakobDev
--Licensed under BSD-2-Clause
local component = require("component")
local event = require("event")
local thread = require("thread")
local term = require("term")
local gpu = component.gpu

local w,h = gpu.getResolution()
local bBreak = false
local nSpeed = 0.01

local tChars = {"1","2","3","4","5","6","7","8","9","0","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","(",")","!","?","[","]","{","}","/","\\","#","=","<",">","*",",",".","@","%"}
local tLines = {}
for i=1,w do
    if math.random(1,2) == 1 then
        tLines[i] = {true,math.random(1,10)}
    else
        tLines[i] = {false,math.random(1,10)}
    end
end

local tText = {}
for i=0,h do
    tText[i] = ""
end

local function scrollDown()
    for i=h-1,1,-1 do
        gpu.copy(1,i,w,1,0,1)
        tText[i] = tText[i-1]
    end
    tText[h] = tText[h-1]
    tText[h+1] = nil
end

local function generateText()
    local sText = ""
    for i=1,w do
        if  tLines[i][1] == true then
            sText = sText..tChars[math.random(1,#tChars)]
        else
            sText = sText.." "
        end
        tLines[i][2] = tLines[i][2] - 1
        if tLines[i][2] == 0 then
            if math.random(1,2) == 1 then
                tLines[i] = {true,math.random(1,10)}
            else
                tLines[i] = {false,math.random(1,10)}
            end
        end
    end
    gpu.set(1,1,sText)
    tText[1] = sText
end

local function redrawLines()
    --For cahnging Colours
    for i=1,h do
        if tText[i] == "" then
            gpu.set(1,i,"Test123")
        end
        gpu.set(1,i,tText[i])
    end
end

gpu.setForeground(0x1ec503)
gpu.setBackground(0x000000)
gpu.fill(1, 1, w, h, " ")

generateText()

thread.create(function()
    while true do
        os.sleep(nSpeed)
        if bBreak == true then
            break
        end
        scrollDown()
        generateText()
    end
end)

while true do
    local tEvent = table.pack(event.pull())
    if tEvent[1] == "key_down" then
        local sKey = string.upper(string.char(tEvent[3]))
        if sKey == "Q" then
            bBreak = true
            break
        elseif sKey == "0" then
            nSpeed = 0.01
        elseif sKey == "1" then
            nSpeed = 0.02
        elseif sKey == "2" then
            nSpeed = 0.03
        elseif sKey == "3" then
            nSpeed = 0.04
        elseif sKey == "4" then
            nSpeed = 0.05
        elseif sKey == "5" then
            nSpeed = 0.06
        elseif sKey == "6" then
            nSpeed = 0.07
        elseif sKey == "7" then
            nSpeed = 0.08
        elseif sKey == "8" then
            nSpeed = 0.09
        elseif sKey == "9" then
            nSpeed = 0.1
        elseif sKey == "@" then
            --Green
            gpu.setForeground(0x1ec503)
            redrawLines()
        elseif sKey == "!" then
            --Red
            gpu.setForeground(0xff0000)
            redrawLines()
        elseif sKey == "%" then
            --Magenta
            gpu.setForeground(0xff00ff)
            redrawLines()
        elseif sKey == "&" then
            --White
            gpu.setForeground(0xFFFFFF)
            redrawLines()
        elseif sKey == "$" then
            --Blue
            gpu.setForeground(0x0000ff)
            redrawLines()
        elseif sKey == "#" then
            --Yellow
            gpu.setForeground(0xffff00)
            redrawLines()
        elseif sKey == "^" then
            --Cyan
            gpu.setForeground(0x00ffff)
            redrawLines()
        end
    elseif tEvent[1] == "interrupted" then
        bBreak = true
        break
    end
end

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
gpu.fill(1, 1, w, h, " ")
term.setCursor(1,1)
