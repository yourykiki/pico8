pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- model nabateen

local cam,scl,wf,t={},3,false,0
local norms,fcntrs,fnorms={},{},{}
local vrtx={
 {-48,4,16},{-16,4,16},{-16,4,0},{-48,4,0},
 {-16,0,16},{-16,0,0},{-48,0,0},
 {16,4,16},{48,4,16},{48,4,0},{16,4,0},
 {16,0,16},{48,0,0},{16,0,0},
 {-16,8,16},{16,8,16},
 {-48,56,16},{-16,56,16},{16,56,16},{48,56,16},
 {-8,48,16},{8,48,16},{8,8,16},{-8,8,16},
 {-48,56,0},{-24,56,0},{24,56,0},{48,56,0},--28
 {-24,56,-8},{24,56,-8},--30
 {-32,72,16},{-12,72,16},{12,72,16},{32,72,16}, --34
 {-48,72,4},{0,72,4},{48,72,4}, --37
 {-48,64,0},{-24,64,0},{0,72,-8},{24,64,0},{48,64,0},--42
 {-24,64,-8},{24,64,-8},--44
 {-48,112,16},{-32,112,16},{-48,112,4},{-32,120,4},{-32,72,4},--49
 {32,112,16},{48,112,16},{32,120,4},{48,112,4},{32,72,4},--54
 {-12,112,16},{12,112,16},{0,112,4},{0,120,16}
}
local col1,col2,col3=0x54,0x4f,0x55
local tris={
 1,2,3,col1, 1,3,4,col1,
 2,5,6,col1, 2,6,3,col1,
 3,6,7,col1, 3,7,4,col1,
 8,9,10,col1, 8,10,11,col1, 
 8,11,14,col1, 8,14,12,col1,
 10,13,14,col1, 10,14,11,col1,
 15,16,14,col2, 15,14,6,col2, 
 15,6,5,col1, 16,12,14,col1,
 17,18,2,col3, 17,2,1,col3,
 19,20,9,col3, 19,9,8,col3,
 18,19,22,col2, 18,22,21,col2, 
 19,16,22,col2, 22,16,23,col2,
 18,21,15,col2, 21,24,15,col2,
 26,18,17,col1, 25,26,17,col1, 
 28,20,19,col1, 27,28,19,col1,
 27,19,18,col1, 18,26,27,col1, 
 26,29,30,col1, 26,30,27,col1,
 31,32,49,col2, 32,36,49,col2, 
 33,34,54,col2, 33,54,36,col2,
 35,36,39,col1, 35,39,38,col1, 
 36,37,42,col1, 36,42,41,col1,
 38,39,26,col1, 38,26,25,col1, 
 41,42,28,col1, 41,28,27,col1,
 39,43,26,col1, 29,26,43,col1, 
 43,44,30,col1, 43,30,29,col1,
 44,41,27,col1, 44,27,30,col1,
 39,36,40,col2, 39,40,43,col2, 
 40,36,41,col2, 40,41,44,col2,
 40,44,43,col1,
 45,46,48,col2, 45,48,47,col2,
 48,46,31,col1, 48,31,49,col1, 
 47,48,49,col1, 47,49,35,col1,
 50,51,52,col2, 51,53,52,col2,
 52,53,54,col1, 53,37,54,col1,
 50,52,34,col1, 34,52,54,col1,
 56,33,57,col1, 57,33,36,col1,
 55,57,32,col1, 32,57,36,col1,
 56,57,58,col2, 57,55,58,col2,
 46,55,32,col3, 46,32,31,col3, 
 56,50,34,col3, 56,34,33,col3
}

local dith={
 0x0000,0x8000,0x8020,0xa020,
 0xa0a0,0xa4a0,0xa4a1,0xa5a1,
 0xa5a5,0xe5a5,0xa5b5,0xf5b5,
 0xf5f5,0xfdf5,0xfdf7,0xffff
}
local dith2={
 0x0000,0x8000,0x8020,0xc020,
 0xc060,0xc070,0xe070,0xe470,
 0xe472,0xf472,0xf4f2,0xf5f2,
 0xf5fa,0xf7fa,0xf7fe,0xffff
}

function init_cam()
 return {
  pos={0,48,-56},
  ang=0.25,
  mf=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]+cos(a)*v
   p[3]=p[3]-sin(a)*v
   self.pos=p
  end,
  sb=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]-cos(a)*v
   p[3]=p[3]+sin(a)*v
   self.pos=p
  end,
  projiso=function(self,vrtx)
   local vert={}
   for i=1,#vrtx do 
    local pnt=vrtx[i]
    vert[i]={
     pnt[1]+pnt[3]*0.5+64,
     -pnt[2]-pnt[3]*0.5+127
    }
   end
   return vert
  end,
  proj=function(self,vrtx)
   local vert={}
   for i=1,#vrtx do 
    local v=vrtx[i]
    local x,y,z=v[1]-self.pos[1],
     v[2]-self.pos[2],
     v[3]-self.pos[3]
    local w=63.5/z
    vert[i]={
     63.5+flr(w*x),
     63.5-flr(w*y)
    }
   end
   return vert
  end
 }
end
function init_norm(vrtx)
 fcntrs,norms,fnorms={},{},{}
 for i=1,#tris,4 do
  local v1,v2,v3=
   v_clone(vrtx[tris[i]]),
   v_clone(vrtx[tris[i+1]]),
   v_clone(vrtx[tris[i+2]])
  
  local f=
   {(v1[1]+v2[1]+v3[1])/3,
    (v1[2]+v2[2]+v3[2])/3,
    (v1[3]+v2[3]+v3[3])/3}
  add(fcntrs,f)
  -- normal
  v_add(v2,v1,-1)
  v_add(v3,v1,-1)
  local n=v_cross(v2,v3)
  v_normz(n)
  add(norms,n)
  -- normal for rendering
  local f2,n2=v_clone(f),v_clone(n)
  v_scale(n2,5)
  v_add(f2,n2)
  add(fnorms,f2)
 end
end
function _init()
 cam=init_cam()
 --init_norm(vrtx)
end
function _update()
 t+=0.01
 if (btn(⬆️)) cam:mf(0.5)
 if (btn(⬇️)) cam:sb(0.5)
 if (btn(⬅️)) cam.ang-=0.01
 if (btn(➡️)) cam.ang+=0.01
 if (btn(⬆️,1)) cam.pos[2]+=1
 if (btn(⬇️,1)) cam.pos[2]-=1
 if (btnp(❎)) wf=not wf
end

function _draw()
 cls""
 -- transformation
	//ftheta += 1.0f * felapsedtime; // uncomment to spin me right round baby right round
	local m_rotz,m_roty,m_tran=
	 m_makerotz(1),
	 m_makeroty(t*0.25),
  m_maketran(0,0,0)

 m_wrld={1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
	m_wrld=m_x_m(m_rotz,m_roty)
	m_wrld=m_x_m(m_wrld,m_tran)
	
	local v_wrld={}
	for v in all(vrtx) do
	 add(v_wrld,m_x_v(m_wrld,v))
	end
	
	--should be usefull only for
	--rotating objects
	init_norm(v_wrld)
	
 -- proj
 local proj=cam:proj(v_wrld)
 local pcntr=cam:proj(fcntrs)
 local pnorm=cam:proj(fnorms)


 -- testing visibles
 local vistris={}
 for i=1,#tris,4 do
  local idx=(i-1)/4+1
  local norm=norms[idx]
  local vp=v_clone(v_wrld[tris[i]])
  local vcam=cam.pos
  v_add(vp,vcam,-1)
  
  if v_dot(norm,vp)<0 then
   add(vistris,{
    key=fcntrs[idx][3],itris=i
   })
  end 
 end
 
 -- sorting visible tris
 shellsort(vistris)
 
 --local lgt={0,0,1}
 local a=cam.ang
 local lgt={1,-1,1} 
 v_normz(lgt)

 -- drawing visible tris
 for j=#vistris,1,-1 do
  local i=vistris[j].itris
  local v1,v2,v3,c,idx=
	  proj[tris[i]],
	  proj[tris[i+1]],
	  proj[tris[i+2]],
	  tris[i+3],
	  (i-1)/4+1
  
  color(c)
  local ptn=v_dot(norms[idx],lgt)
  ptn=flr(ptn*8+8)
  fillp(dith2[flr(ptn)])
  tri(v1[1],v1[2],v2[1],v2[2],v3[1],v3[2],c)
  -- wireframe
  fillp()
  if wf then
   line(v1[1],v1[2],v2[1],v2[2],6)
   line(v3[1],v3[2])
   line(v1[1],v1[2])  
   -- normals
   local n1=pcntr[idx]
   local n2=pnorm[idx]
   line(n1[1],n1[2],n2[1],n2[2],8)
  end
  
 end
 -- test dither
 for i=1,#dith2 do
  color(0x54)
  fillp(dith2[i])
  rectfill((i-1)*8,0,i*8,7)
 end
 fillp()

 print("∧"..stat(1).." tris "
   ..(#tris/4).." visible "
   ..#vistris.." ",0,0,7)
end


-- not sure it will survive
function tri_vis(vcam,n,v)
 return (n[1]*(v[1]-vcam[1])+
         n[2]*(v[2]-vcam[2])+
         n[3]*(v[3]-vcam[3]))<0
end
-->8
-- @p01
function p01_trapeze_h(l,r,lt,rt,y0,y1)
 lt,rt=(lt-l)/(y1-y0),(rt-r)/(y1-y0)
 if(y0<0)l,r,y0=l-y0*lt,r-y0*rt,0
 y1=min(y1,128)
 for y0=y0,y1 do
  rectfill(l,y0,r,y0)
  l+=lt
  r+=rt
 end
end
function p01_trapeze_w(t,b,tt,bt,x0,x1)
 tt,bt=(tt-t)/(x1-x0),(bt-b)/(x1-x0)
 if(x0<0)t,b,x0=t-x0*tt,b-x0*bt,0
 x1=min(x1,128)
 for x0=x0,x1 do
  rectfill(x0,t,x0,b)
  t+=tt
  b+=bt
 end
end
function tri(x0,y0,x1,y1,x2,y2,col)
-- color(col)
 if(y1<y0)x0,x1,y0,y1=x1,x0,y1,y0
 if(y2<y0)x0,x2,y0,y2=x2,x0,y2,y0
 if(y2<y1)x1,x2,y1,y2=x2,x1,y2,y1
 if max(x2,max(x1,x0))-min(x2,min(x1,x0)) > y2-y0 then
  col=x0+(x2-x0)/(y2-y0)*(y1-y0)
  p01_trapeze_h(x0,x0,x1,col,y0,y1)
  p01_trapeze_h(x1,col,x2,x2,y1,y2)
 else
  if(x1<x0)x0,x1,y0,y1=x1,x0,y1,y0
  if(x2<x0)x0,x2,y0,y2=x2,x0,y2,y0
  if(x2<x1)x1,x2,y1,y2=x2,x1,y2,y1
  col=y0+(y2-y0)/(x2-x0)*(x1-x0)
  p01_trapeze_w(y0,y0,y1,col,x0,x1)
  p01_trapeze_w(y1,col,y2,y2,x1,x2)
 end
end
-->8
-- @fred72 3d utils
function v_cross(a,b)
 local ax,ay,az=a[1],a[2],a[3]
 local bx,by,bz=b[1],b[2],b[3]
 return {ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx}
end
function v_clone(v)
 return {v[1],v[2],v[3]}
end
function v_scale(v,scale)
 v[1]*=scale
 v[2]*=scale
 v[3]*=scale
end
function v_add(v,dv,scale)
 local s=scale or 1
 v[1]+=s*dv[1]
 v[2]+=s*dv[2]
 v[3]+=s*dv[3]
end
function v_len(v)
 local x,y,z=v[1],v[2],v[3]
 local d=max(max(abs(x),abs(y)),abs(z))
 x/=d
 y/=d
 z/=d
 return d*(x*x+y*y+z*z)^0.5
end
function v_normz(v)
 local d=v_len(v)
 v[1]/=d
 v[2]/=d
 v[3]/=d
end
function v_dot(a,b)
 return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end


--
local v_up={0,1,0}
-- matrix x vector
function m_x_v(m,v)
 local x,y,z=v[1],v[2],v[3]
 return {m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]}
end
-- matrix x matrix
function m_x_m(a,b)
 local a11,a12,a13,a14=a[1],a[5],a[9],a[13]
 local a21,a22,a23,a24=a[2],a[6],a[10],a[14]
 local a31,a32,a33,a34=a[3],a[7],a[11],a[15]
 local b11,b12,b13,b14=b[1],b[5],b[9],b[13]
 local b21,b22,b23,b24=b[2],b[6],b[10],b[14]
 local b31,b32,b33,b34=b[3],b[7],b[11],b[15]
return {
 a11*b11+a12*b21+a13*b31,a21*b11+a22*b21+a23*b31,a31*b11+a32*b21+a33*b31,0,
 a11*b12+a12*b22+a13*b32,a21*b12+a22*b22+a23*b32,a31*b12+a32*b22+a33*b32,0,
 a11*b13+a12*b23+a13*b33,a21*b13+a22*b23+a23*b33,a31*b13+a32*b23+a33*b33,0,
 a11*b14+a12*b24+a13*b34+a14,a21*b14+a22*b24+a23*b34+a24,a31*b14+a32*b24+a33*b34+a34,1
}
end


function m_makerotx(a)
 return {
  1,0,     0,       0,
  0,cos(a),-sin(a), 0,
  0,sin(a),cos(a),  0,
  0,0,     0,       1 
 }
end
function m_makeroty(a)
 return {
  cos(a),0,-sin(a), 0,
  0,     1,0,       0,
  sin(a),0,cos(a),  0,
  0,     0,0,       1 
 }
end
function m_makerotz(a)
 return {
  cos(a),-sin(a),0,0,
  sin(a),cos(a),0,0,
  0,     0,     1,0,
  0,     0,     0,1
 }
end
function m_maketran(x,y,z)
 return {
  1,0,0,0,
  0,1,0,0,
  0,0,1,0,
  x,y,z,1
 }
end
-->8
--triplefox with ciura's sequence
--https://www.lexaloffle.com/bbs/?tid=2477
local shell_gaps={701,301,132,57,23,10,4,1} 
function shellsort(a)
 for gap in all(shell_gaps) do
  if gap<=#a then
   for i=gap,#a do
    local t=a[i]
    local j=i
    while j>gap and
       a[j-gap].key>t.key do 
     a[j]=a[j-gap]
     j-=gap
    end
    a[j]=t
   end
  end
 end
end
__gfx__
60006000606060606060606060606060666066606666666666666666666666666000600066006600660066606660666066666666666666666666666666666666
00000000000000000600060006060606060606060606060666066606666666660000000000000000000000000600060006000600060606060666066666666666
00000060006060606060606060606060606060666066666666666666666666660000006000600660066606660666066606666666666666666666666666666666
00000000000000000000000600060606060606060606060606060666066666660000000000000000000000000000006000600060006060606060666066606666
60606060606060606660666066666666666666666666666660006000606060606666555566665555666655556666555566665555666655556666555566665555
06000600060606060606060606060606660666066666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060606060606060606660666666666666666666666600000060006060600000000000000000000000000000000000000000000000000000000000000000
00000006000606060606060606060606060606660666666600000000f94510000000000000000000000000000000000000000000000000000000000000000000
66606660666666666666666666666666600060006060606060606060606060600000000000000000000000000000000000000000000000000000000000000000
06060606060606066606660666666666000000000000000006000600060606060000000000000000000000000000000000000000000000000000000000000000
60606066606666666666666666666666000000600060606060606060606060600000000000000000000000000000000000000000000000000000000000000000
06060606060606060606066606666666000000000000000000000006000606060000000000000000000000000000000000000000000000000000000000000000
66666666666666666000600060606060606060606060606066606660666666660000000000000000000000000000000000000000000000000000000000000000
66066606666666660000000000000000060006000606060606060606060606060000000000000000000000000000000000000000000000000000000000000000
66666666666666660000006000606060606060606060606060606066606666660000000000000000000000000000000000000000000000000000000000000000
06060666066666660000000000000000000000060006060606060606060606060000000000000000000000000000000000000000000000000000000000000000
__label__
44444444777454447774777475745544777477747774577455547774777455547574777457757775777575557775555577557775555555555555555555555555
74447444747444444474447474744444474474744744744444444474757445447574474475444744757475447545454547457545455545554555455555555555
47474744747444447774447477744454475477544755777545554575777545557575475577754755775575557755555557557775555555555555555555555555
44744474747444447444447444744444474474744744447444444474447444447774475444744754747474547454445457545474545454545554555455555555
44444444777457447774547455745544574475747774774455545574557455545754777477557775777577757775555577757775555555555555555555555555
44444444444444444444444444444444444444444444444444444444454445444544454445444544454445444545454545454545455545554555455555555555
44444444444444444454445444544454455445544555455545554555455545554555455545554555555555555555555555555555555555555555555555555555
44444444444444444444444444444444444444444444444444444444444444444454445444544454445444544454445454545454545454545554555455555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000040000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000550000000000000000000000000000000000000444ffff0000000000000000000000000000000000000000
0000000000000000000000000000000000000000005400000000000000000000000000000000000004444fffffffff0000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000054000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000054000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000054000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000054000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000054000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000045000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000054000000000000000000000000000000000000044440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000005000000000000000000000000000000000000044450000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000044000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000445444544400000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000444444444444444444440000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000400000000000000000454445444544454445444000000000000000000000000000000000000
000000000000000000000000000000000000000000044444444444000000000000000004f44f4444444444444444400000000000000000000000000000000000
000000000000000000000000000000000454445444544454445444000000004ff000000044544454445444544454440000000000000000000000000000000000
00000000000000000000000000000000044444444444444444444400000000000000000044444444444440000000000000000000000000000000000000000000
00000000000000000000000000000000544454445444544454445400000000000000000004440000000000000000000000000000000000000000000000000000
00000000000000000000000000000000444444444444444444444400000000000000000000440000000000000000000000000000000000000000000000000000
00000000000000000000000000000004445444544454445444544400000000000000000000440000000000000000000000000000000000000000000000000000
00000000000000000000000000000004444444444444440000000000000000000000000000040000000000000000000000000000000000000000000000000000
00000000000000000000000000000044544454400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

