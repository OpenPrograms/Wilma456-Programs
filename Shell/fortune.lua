local fs = require("filesystem")
local io = require("io")

local textta = {}
local textcou = 0

local function readFile(name)
local fileha = io.open("/usr/share/fortune/"..name,"r")
local tmpta = {}
while true do
local linecon = fileha:read("*l")
if linecon == nil then
  break
elseif linecon == "%" then
  table.insert(textta,tmpta)
  textcou = textcou + 1
  tmpta = {}
else
  table.insert(tmpta,linecon)
end
end
end
local filelist = fs.list("/usr/share/fortune")

while true do
local filename = filelist()
if filename == nil then
  break
else
  readFile(filename)
end
end

local rantext = math.random(1,textcou)

for _,text in ipairs(textta[rantext]) do
print(text)
end
