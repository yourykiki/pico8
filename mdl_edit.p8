pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- 3d model editor
-- @yourykiki

local c_top,c_side,c_front,c_3d,
 mdl

function _init()
 -- init cam
 c_top,c_side,c_front,c_3d=
  init_cam("t",64, 0),
  init_cam("s",64,64),
  init_cam("f", 0,64),
  init_cam("3d",0, 0)
 -- load default model
 mdl=make_cube({0,0,0},0)
end

function _update()

end

function _draw()
 cls''
 draw_mdl(c_top)
 draw_mdl(c_side)
 draw_mdl(c_front)
 draw_mdl(c_3d)
end

function init_cam(name,vx,vy)
 return {
  name=name,
  pos={0,6,-10},
  ang=0.25,
  view={w=64,h=64,x=vx,y=vy},
  m={},
  projtop=function(self,vrtx)
   local vert,w,h={},
    self.view.w/2,
    self.view.h/2
   for i=1,#vrtx do 
    local pnt=vrtx[i]
    vert[i]={
     pnt[1]+w,
     -pnt[3]+h
    }
   end
   return vert
  end,
  projsid=function(self,vrtx)
   local vert,w,h={},
    self.view.w/2,
    self.view.h/2
   for i=1,#vrtx do 
    local pnt=vrtx[i]
    vert[i]={
     pnt[1]+w,
     -pnt[2]+h
    }
   end
   return vert
  end,
  projfro=function(self,vrtx)
   local vert,w,h={},
    self.view.w/2,
    self.view.h/2
   for i=1,#vrtx do 
    local pnt=vrtx[i]
    vert[i]={
     pnt[3]+w,
     -pnt[2]+h
    }
   end
   return vert
  end,
  upd_m=function(self)
    local m_vw=
     make_m_from_v_angle(v_up,self.ang)
    m_vw[13],m_vw[14],m_vw[15]=
     self.pos[1],self.pos[2],self.pos[3]
    m_qinv(m_vw)
    self.m=m_vw
  end,
  proj=function(self,vrtx)
   if (name=="t") return self:projtop(vrtx)
   if (name=="s") return self:projsid(vrtx)
   if (name=="f") return self:projfro(vrtx)
   return self:proj3d(vrtx)
  end,
  proj3d=function(self,vrtx)
   local vert,ww,hh=
    {},self.view.w/2,
    self.view.h/2
   
   for i=1,#vrtx do 
    local v=vrtx[i]
    local w=ww/v[3]
    vert[i]={
     ww+w*v[1],
     hh-w*v[2]
    }
   end
   return vert
  end
 }
end

function draw_mdl(cam)
 local vport=cam.view
 camera(-vport.x,-vport.y)
 clip(vport.w,vport.h)
 rect(0,0,vport.w-1,vport.h-1,1)

 local vrtx={}
 add_all(vrtx,mdl.vrtx)
 transform(vrtx,
  0,-4,10,0)

 -- draw model
 --proj
 vrtx=cam:proj(vrtx)
 for poly in all(mdl.polys) do
  draw_wire(vrtx,poly)
 end
 for poly in all(mdl.polys) do
  draw_point(vrtx)
 end
 --

 print(cam.name,2,2)
end

function draw_wire(vrtx,poly)

 local nb=#poly-1
 local v1,v2=vrtx[poly[nb]]

 for i=1,nb do
  v2,v1=v1,vrtx[poly[i]]
  line(v1[1],v1[2],v2[1],v2[2],6)
 end
end

function draw_point(vrtx)
 for v in all(vrtx) do
  line(v[1],v[2],v[1],v[2],8)
 end
end

-->8
--3d maths utils
--from @fsouchu
local m4ident=
 {1,0,0,0, 
  0,1,0,0, 
  0,0,1,0, 
  0,0,0,1}

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
-- matrix x vector
function m_x_v(m,v)
 local x,y,z=v[1],v[2],v[3]
 return {m[1]*x+m[5]*y+m[9]*z+m[13],
  m[2]*x+m[6]*y+m[10]*z+m[14],
  m[3]*x+m[7]*y+m[11]*z+m[15]}
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

function transform(lvrtx,px,py,pz,roty)
 local m_roty,m_tran=
  m_makeroty(roty),
  m_maketran(px,py,pz)

 m_wrld=m4ident
 m_wrld=m_x_m(m_wrld,m_tran)
 m_wrld=m_x_m(m_wrld,m_roty)
 for i,v in pairs(lvrtx) do
  lvrtx[i]=m_x_v(m_wrld,v)
 end
end
-->8
--3d models
local col1=0x54
 
function make_cube(pos,ry)
 local lvrtx={
  {-8,0,0},{-6,8,0},
  {6,8,0},{8,0,0},
  {8,0,8},{6,8,8},
  {-6,8,8},{-8,0,8},
 }
 local lpolys={
  {1,2,3,4,col1},
  {5,6,7,8,col1},
  {1,2,7,8,col1},
  {5,6,3,4,col1},
  {2,3,6,7,col1},
  {1,8,5,4,col1},
 }

 transform(lvrtx,
  pos[1],pos[2],pos[3],ry)

 local lwalls={}
 
 return {
  vrtx=lvrtx,
  polys=lpolys,
  walls=lwalls
 }
end

-->8
-- utils @yourykiki
function add_all(a,b)
 for x in all(b) do
  add(a,x)
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
