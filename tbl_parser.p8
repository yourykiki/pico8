pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function match(s,tokens)
  for i=1,#tokens do
    if(s==sub(tokens,i,i)) return true
  end
  return false
end

function parse_num_val(str,pos,val)
 val=val or ''
 local c=sub(str,pos,pos)
 if(not match(c,"-xb0123456789abcdef.")) return tonum(val),pos
 return parse_num_val(str,pos+1,val..c)
end

-- parse a string delimited with "
-- or a raw string [a-z0-9_-]
-- or a true false to boolean
function parse_str_val(str,pos,val,delim)
 local c=sub(str,pos,pos)
 if delim=='"' then
  if (c=='"') return val,pos+1
 elseif not match(c,"abcdefghijklmnopqrstuvwxyz0123456789_-") then
  if val=="true" or val=="false" then
   val=val=="true"
  end
  return val,pos
 end
 return parse_str_val(str,pos+1,val..c,delim)
end

function nxt_delim(str,pos)
 local c=sub(str,pos,pos)
 if (c==',' or c=='=' or c=='}') return c,pos
 return nxt_delim(str,pos+1) 
end

function tbl_parse(str,pos)
 pos=pos or 1
 local first=sub(str,pos,pos)
 if first=='{' then
  local obj={}
  pos+=1
  while true do
   res,pos=tbl_parse(str,pos)
   if (res==nil) return obj,pos
   tk,pos=nxt_delim(str,pos)
   -- if = bef ,} parse after =
   if tk=="=" then
    key,val,pos=res,tbl_parse(str,pos+1)
    obj[key]=val
   else
    add(obj,res)
   end
   if (sub(str,pos,pos)==',')  pos+=1
  end
 elseif first=='}' then
  return nil,pos+1
 elseif match(first,"-0123456789") then
  return parse_num_val(str,pos)
 elseif first=='"' then
  return parse_str_val(str,pos+1,'','"')
 else
  return parse_str_val(str,pos,"")
 end
end

-->8
function table_to_str(tbl)
	local str,i="{",1
	for k,val in pairs(tbl) do
	 if k==i then
	  i+=1
	 else
 	 str=str..k.."="
	 end
	 local t=type(val)
	 --type=string,number,boolean
	 if t=="table" then
   str=str..table_to_str(val)..","
-- 	 str=str.."\n"
	 elseif t=="boolean" then
	  str=str..(val and "true" or "false")..","
	 else
   str=str..val..","
	 end
	end
	if sub(str,#str,#str)=="," then 
	 str=sub(str,1,#str-1) 
 end
 return str.."}"
end

function print32(str)
 local pos=1
 while (pos < #str) do
  print(sub(str,pos,pos+32))
  pos+=32  
 end
end
-->8
-- testing

function assert_tbl(exp,val,inp)
 if (inp) print32("inp "..inp)
 if (inp) print32("val "..table_to_str(val))
--print("exp "..type(exp))
--print("val "..type(val))
 assert(type(exp)==type(val))--type
 assert(#exp==#val)--nbelement
 for k,v in pairs(exp) do
--  print("k "..k)
  if type(v)=="table" then
   assert_tbl(v,val[k])
  else
	  assert(val[k]==v) 
  end
 end
 if (inp) print"assert ok"
end

---------------------
local exp={}
local inp="{}"

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp={0}
local inp="{0}"

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp={-10}
local inp="{-10}"

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp={-10,30,40}
local inp="{-10,30,40}"

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp={true,k1=false,40}
local inp="{true,k1=false,40}"

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp={"toto"}
local inp='{"toto"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp={"toto","tutu"}
local inp='{"toto","tutu"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {"toto",3.14,"tutu"}
local inp='{"toto",3.14,"tutu"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {k1="toto"}
local inp='{"k1"="toto"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {k1="toto"}
local inp='{k1="toto"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {k1="toto",k2="tutu"}
local inp='{"k1"="toto","k2"="tutu"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {k1="toto",k2="tutu"}
local inp='{k1="toto",k2="tutu"}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {{1,2,3}}
local inp='{{1,2,3}}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= {{1,2,3},{5,6,9}}
local inp='{{1,2,3},{5,6,9}}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local exp= 
 {vrtx={{1,2,3},{5,6,9}},
  walls={},
  polys={{1,2,3},{5,6,9}}
 }
local inp='{vrtx={{1,2,3},{5,6,9}},'
 inp=inp..'walls={},'
 inp=inp..'polys={{1,2,3},{5,6,9}}'
 inp=inp..'}'

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
---------------------
local col1=0x54
local exp=
 {vrtx={
   {-8,0,0},{-6,8,0},
   {6,8,0},{8,0,0},
   {8,0,8},{6,8,8},
   {-6,8,8},{-8,0,8},
  },
  polys={
   {1,2,3,4,col1},
   {5,6,7,8,col1},
   {1,2,7,8,col1},
   {5,6,3,4,col1},
   {2,3,6,7,col1},
   {1,8,5,4,col1},
  },
  walls={}
 }
 
local inp="{"
 inp=inp.."polys={"
 inp=inp.."{1,2,3,4,0x54},"
 inp=inp.."{5,6,7,8,0x54},"
 inp=inp.."{1,2,7,8,0x54},"
 inp=inp.."{5,6,3,4,0x54},"
 inp=inp.."{2,3,6,7,0x54},"
 inp=inp.."{1,8,5,4,0x54},"
 inp=inp.."},"
 inp=inp.."vrtx={{-8,0,0},{-6,8,0},"
 inp=inp.."{6,8,0},{8,0,0},"
 inp=inp.."{8,0,8},{6,8,8},"
 inp=inp.."{-6,8,8},{-8,0,8},"
 inp=inp.."},"
 inp=inp.."walls={}"
 inp=inp.."}"

local val=tbl_parse(inp)
assert_tbl(exp,val,inp)
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
