pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- 2d frustrum

local scl,grid,cam=3


function _init()
 grid=init_grid()
 cam=init_cam()
end

function init_cam()
 return {
  pos={16,16,0},
  ang=0,
  mf=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]+cos(a)*v
   p[2]=p[2]-sin(a)*v
   self.pos=p
  end,
  sb=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]-cos(a)*v
   p[2]=p[2]+sin(a)*v
   self.pos=p
  end
 }
end

function init_grid()
 local wdt,hgt,cells=32,32,{}
 for i=1,wdt*hgt do
  cells[i]=1
 end

 return {
  wdt=wdt,
  hgt=hgt,
  cells=cells,
  frust=function(self,cam)
   local res,i={},1
   local z,dz,af,a,
         lcx,lcy=
         2,1,0.13,cam.ang,
         cam.pos[1],cam.pos[2]
   local ca1,sa1,caaf,saaf=
    cos(a-af),sin(a-af),
    2*cos(a)*cos(af)/8,
   -2*sin(a)*sin(af)/8
  
   while z<6 do
		  -- use cos(a-b)-cos(a+b)=2*sin(a)sin(b)
		  local sx,sy,dx,dy,old=
		   ca1*z+lcx,-sa1*z+lcy,
		   z*saaf,z*caaf,-1
		
		  for rx=0,8 do
		  local x,y=
		   band(sx+rx*dx,0x1f),
     band(sy+rx*dy,0x1f)
		   local idx=bor(x,shl(y,5))
		   if old!=idx then
		    res[i]={x=x,y=y}
      old=idx
      i+=1
     end
		  end
		  z+=dz
		 end
   return res
  end
 }
end

function _update()
 if (btn(⬆️)) cam:mf(0.25)
 if (btn(⬇️)) cam:sb(0.25)
 if (btn(⬅️)) cam.ang-=0.02
 if (btn(➡️)) cam.ang+=0.02
end

function _draw()
 cls""
 
 local fs=grid:frust(cam)
 -- bg
-- drawgrid(grid)
 drawfrust(fs)
 drawcam(cam)
 print(stat(1).." "..#fs,0,0)
end

function drawfrust(fs)
 for i=1,#fs do
  local f=fs[i]
  local x,y=f.x*scl,f.y*scl
  rectfill(x,y,x+scl,y+scl,8)
 end
end

function drawcam(c)
 local x,y,a=c.pos[1],c.pos[2],c.ang
 line(x*scl,y*scl,
      (x+cos(a)*5)*scl,
      (y-sin(a)*5)*scl,9)
 line(x*scl,y*scl,
      x*scl,y*scl,7)
end

function drawgrid(g)
 local len,c=
  g.wdt*g.wdt,g.cells
 for i=0,len-1 do
  local x,y=i%32,flr(i/32)
  x*=scl
  y*=scl
  rect(x,y,x+scl,y+scl,c[i+1])
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
