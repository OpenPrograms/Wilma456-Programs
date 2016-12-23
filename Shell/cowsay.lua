local fs = require("filesystem")
local io = require("io")
local Args = {...}
local eyestr = "oo"
local cowname = "default"
local deadstr = "  "
local argmode = "none"
local saytext = ""
local charlimit = 40
local exit = false
for _,text in ipairs(Args) do
if argmode == "cowsel" then
  cowname = text
  argmode = "none"
elseif argmode == "eyes" then
  eyestr = text:sub(1,-text:len()+1)
  argmode = "none"
elseif argmode == "text" then
  saytext = saytext.." "..text
elseif argmode == "charsel" then
  charlimit = tonumber(text)
  argmode = "none"
  if charlimit == nil then
    print("-w must be a Number")
    return
  end
else
  if text == "-f" then
    argmode = "cowsel"
  elseif text == "-e" then
    argmode = "eyes"
  elseif text == "-d" then
    deadstr = "U "
    eyestr = "xx"
  elseif text == "-p" then
    eyestr = "@@"
  elseif text == "-w"  then
    argmode = "charsel"
  elseif text == "-l" then
    local filelist = fs.list("/usr/share/cowsay")
    while true do
      local filename = filelist()
      if filename == nil then
        break
      else
        io.write(filename.." ")
      end
    end
    exit = true
  else 
    argmode = "text"
    saytext = text
  end
end
end

if exit == true then
  return 0
end

if saytext == "" then
  print("Uasage: cowsay [options] <cowfile>")
  return 1
end

local cowta = {}

local function readFile(name)
local fileha = io.open("/usr/share/cowsay/"..cowname,"r")
local tmpta = {}
while true do
local linecon = fileha:read("*l")
if linecon == nil then
  cowta[name] = tmpta
  break
elseif linecon:find("$the_cow = ") == 1 then
  --nothing
elseif linecon:find("EOC") == 1 then
  --nothing
elseif linecon:find("#") == 1 then
  --nothing
else
  linecon = linecon:gsub("$thoughts","\\")
  linecon = linecon:gsub("$eyes",eyestr)
  linecon = linecon:gsub("\\\\","\\")
  linecon = linecon:gsub("$tongue",deadstr)
  table.insert(tmpta,linecon)
end
end
end

if fs.exists("/usr/share/cowsay/"..cowname) == false then
  print("Could not find "..cowname.." cowfile!")
  return 2
end

readFile(cowname)

if saytext:len() < charlimit then
  io.write(" ")
  for i = saytext:len()+2,1,-1 do
    io.write("_")
  end
  print()
  print("< "..saytext.." >")
  io.write(" ")
  for i = saytext:len()+2,1,-1 do
    io.write("-")
  end
  print()
else
  io.write(" ")
  for i = charlimit,1,-1 do
    io.write("_")
  end
  print()
  local charcou = 1
  local charpos = "start"
  io.write("/ ")

 for i = 1,#saytext do
  local c = saytext:sub(i,i)
  if charcou == charlimit then
    if charpos == "start" then
      print(" \\")
      charpos = nil
    else
      print(" |")
    end
   if saytext:len()-i < charlimit then
      io.write("\\ ")
   else
    io.write("| ")
   end
   charcou = 1
  else
    io.write(c)
    charcou = charcou + 1
 end
 end

  for i=charlimit-charcou,1,-1 do
    io.write(" ")
  end
  print(" /")
  io.write(" ")
  for i=charlimit,1,-1 do
    io.write("-")
  end
  print()
end

--cowname = cowname..".cow"
for _,text in ipairs(cowta[cowname]) do
print(text)
end
