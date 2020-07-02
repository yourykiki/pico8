pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- temple corridor demo
-- @yourykiki
local cpu={}
local cam,scl,wf,t={},3,false,0
--
local v_up={0,1,0}
local vrtx={}
local max_vrtx,nb_clip=0,0
local nodes,curnod={}

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
  pos={0,6,0},
  ang=0.25,
  fvel=0,--forward
  svel=0,--strafe
  avel=0,
  m={},
  --move forward
  fwd=function(self)
   self.fvel=lerp(self.fvel,1.25,.6)
  end,
  bck=function(self)
   self.fvel=lerp(self.fvel,-1.25,.6)
  end,
  fstp=function(self)
   self.fvel=lerp(self.fvel,0,.5)
  end,
  --strafe
  slt=function(self)
   self.svel=lerp(self.svel,1.25,.6)
  end,
  srt=function(self)
   self.svel=lerp(self.svel,-1.25,.6)
  end,
  sstp=function(self)
   self.svel=lerp(self.svel,0,.5)
  end,
  --strafe
  llt=function(self)
   self.avel=lerp(self.avel,0.015,.6)
  end,
  lrt=function(self)
   self.avel=lerp(self.avel,-0.015,.6)
  end,
  lstp=function(self)
   self.avel=lerp(self.avel,0,.5)
  end,
  move=function(self)
   local p,a,fv,sv=
    self.pos,self.ang,
    self.fvel,self.svel
   if (abs(self.avel)<0.0005) self.avel=0
   a=a+self.avel
   p[1]=p[1]+cos(a)*fv
   p[3]=p[3]-sin(a)*fv
   p[1]=p[1]-cos(a-0.25)*sv
   p[3]=p[3]+sin(a-0.25)*sv
   self.ang,self.pos=a,p
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
  upd_m=function(self)
-- local m_camroty=m_makeroty(cam.a)
--	local v_lookdir=m_x_v(m_camroty,{0,0,1})
--	local v_target=v_add(cam.pos,v_lookdir)

    local m_vw=
     make_m_from_v_angle(v_up,self.ang)
    m_vw[13],m_vw[14],m_vw[15]=
     self.pos[1],self.pos[2],self.pos[3]
    --2 m_inv(m_vw)
    m_qinv(m_vw)
    self.m=m_vw
    --2 self.m=m_x_m(m_vw,{
    --2  1,0,0,0,
    --2  0,1,0,0,
    --2  0,0,1,0,
    --2  -self.pos[1],-self.pos[2],-self.pos[3],1
    --2 })
  end,
  proj=function(self,vrtx)
   local vert={}
   for i=1,#vrtx do 
    local v=vrtx[i]
    local w=63.5/v[3]
    vert[i]={
     63.5+flr(w*v[1]),
     63.5-flr(w*v[2])
    }
   end
   return vert
  end
 }
end
function init_norm(_vrtx,_poly)
 local norms={}
 for poly in all(_poly) do
  local v1,v2,v3=
   v_clone(_vrtx[poly[1]]),
   v_clone(_vrtx[poly[2]]),
   v_clone(_vrtx[poly[3]])
  
  -- normal
  v_add(v2,v1,-1)
  v_add(v3,v1,-1)
  local n=v_cross(v2,v3)
  v_normz(n)
  add(norms,n)
 end
 return norms
end
function _init()
 cam=init_cam()
-- nbvrt=#vrtx
-- init_ring()
 init_lvl()
end

function init_lvl()
 local m1=make_xcor({0,0,0},0)
 local _tris1=add_model(m1)
 add(nodes,make_node(1,_tris1))

 local m2=make_corner({0,0,48},0)
 local _tris2=add_model(m2)
 add_all(_tris2,joinmdl(m1,2,m2,1))
 add(nodes,make_node(2,_tris2))

 local m3=make_corner({32,0,64},-0.25)
 local _tris3=add_model(m3)
 add_all(_tris3,joinmdl(m2,2,m3,1))
 add(nodes,make_node(3,_tris3))

 local m4=make_corner({48,0,32},.5)
 local _tris4=add_model(m4)
 add_all(_tris4,joinmdl(m3,2,m4,1))
 add_all(_tris4,joinmdl(m4,2,m1,3))
 add(nodes,make_node(4,_tris4))

 local m5=make_corner({0,0,-8},.5)
 local _tris5=add_model(m5)
 add_all(_tris5,joinmdl(m1,1,m5,1))
 add(nodes,make_node(5,_tris5))

 local m6=make_tcor({-24,0,-24},.25)
 local _tris6=add_model(m6)
 add_all(_tris6,joinmdl(m5,2,m6,1))
 add(nodes,make_node(6,_tris6))

 local m7=make_corner({-64,0,-24},.25)
 local _tris7=add_model(m7)
 add_all(_tris7,joinmdl(m6,2,m7,1))
 add(nodes,make_node(7,_tris7))

 local m8=make_corner({-80,0,0},0)
 local _tris8=add_model(m8)
 add_all(_tris8,joinmdl(m7,2,m8,1))
 add(nodes,make_node(8,_tris8))

 local m9=make_tcor({-56,0,16},-.25)
 local _tris9=add_model(m9)
 -- jonction
 add_all(_tris9,joinmdl(m8,2,m9,1))
 add_all(_tris9,joinmdl(m6,3,m9,3))
 add_all(_tris9,joinmdl(m1,4,m9,2))
 add(nodes,make_node(9,_tris9))

 link_nodes(1,2)
 link_nodes(2,3)
 link_nodes(3,4)
 link_nodes(1,4)
 link_nodes(1,5)
 link_nodes(5,6)
 link_nodes(6,7)
 link_nodes(7,8)
 link_nodes(8,9)
 link_nodes(1,9)
 link_nodes(6,9)
end

-- m1 model1, d1 door1 ...
function joinmdl(m1,d1,m2,d2)
 local da=m1:door_idx(d1)+m1.start_vrtx
 local db=m2:door_idx(d2)+m2.start_vrtx
 local mj=make_door_joint(da,db)
 return mj.poly
end
--
function init_ring()
 local pos={0,0,0}
 local a,nb=0.05,20 --20
 for i=0,nb-1 do
  local m=make_cor(pos,a*i)
  local _polys=add_model(m)
 	
  d={sin(a*i)*24,0,cos(a*i)*24}
  v_add(pos,d)
  if i>0 then
   local mj=make_cor_joint()
   add_all(_polys,mj.polys)
  end
  add(nodes,make_node(i+1,_polys))
 end
 for i=1,nb do
  local j=(i%nb+1)
  link_nodes(i,j)
 end
end

function add_model(mdl)
--print("max_vrtx"..max_vrtx)
 mdl.start_vrtx=max_vrtx
 for k,v in pairs(mdl.vrtx) do
	 vrtx[k+max_vrtx]=v
 end
 local mpolys=mdl.polys
 for poly in all(mpolys) do
  poly[1]=poly[1]+max_vrtx
  poly[2]=poly[2]+max_vrtx
  poly[3]=poly[3]+max_vrtx
  poly[4]=poly[4]+max_vrtx
 end
 max_vrtx=#vrtx
 return mpolys
end

function _update()
resetcpu()
 t+=0.01
 local btu,btd=btn(⬆️,1),btn(⬇️,1)
 local btsl,btsr=btn(⬅️,1),btn(➡️,1)
 local btll,btlr=btn(⬅️),btn(➡️)
 if (btu) cam:fwd()
 if (btd) cam:bck()
 if (btll) cam:llt()
 if (btlr) cam:lrt()
 if (btn(⬆️)) cam.pos[2]+=1
 if (btn(⬇️)) cam.pos[2]-=1
 if (btsl) cam:slt()
 if (btsr) cam:srt()
 
 if (not btu and not btd) cam:fstp()
 if (not btsl and not btsr) cam:sstp()
 if (not btll and not btlr) cam:lstp()
 cam:move()
 cpu["1-b_curnod"]=curcpu()
 -- on which node camera is ?
 curnod=get_curnod(cam.pos,curnod)
 cpu["2-curnod"]=curcpu()
end

function _draw()
 cls""
 -- model transformation
 --ftheta += 1.0f * felapsedtime; // uncomment to spin me right round baby right round
 local m_rotz,m_roty,m_tran=
  m_makerotz(1),
  m_makeroty(0),--t*0.25
  m_maketran(0,0,0)

 m_wrld={1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
 m_wrld=m_x_m(m_rotz,m_roty)
 m_wrld=m_x_m(m_wrld,m_tran)
	
	-- camera
 cpu["3-b_transf"]=curcpu()
 cam:upd_m()
 local v_view,v_wrld={},{}
	
 for v in all(vrtx) do
  local tmp=m_x_v(m_wrld,v)
  add(v_wrld,tmp)
  add(v_view,m_x_v(cam.m,tmp))
 end
 cpu["4-transf"]=curcpu()
	
 --should be usefull only for
 --rotating objects, so it
 --could be precalculated
-- init_norm(v_wrld)
	
 -- testing visibles
 nb_clip=0
 local vispolys,nodpolys=
  {},getnodpolys(curnod) 
 cpu["5-getnodpolys"]=curcpu()
--print(#nodpolys.poly,32,96)
 local _polys,_norms=
  nodpolys.polys,nodpolys.norms
 print("#_polys"..#_polys)
 for i=1,#_polys do --todo pairs
  local norm,poly=_norms[i],_polys[i]
  local vp=v_clone(v_wrld[poly[1]])
  v_add(vp,cam.pos,-1)
  
  if v_dot(norm,vp)<0 then
   -- clipping
   local polyidx={
    poly[1],
    poly[2],
    poly[3],
    poly[4],
    poly[5],--col
    i}--idx normal

   local tc=t_clip({0,0,1},
    {0,0,1},v_view,polyidx)
--   for tc in all(tclips) do
    -- add clipped polygon
   if tc then
    local z,nbv=0,#tc-2
    for itc=1,nbv do
     z+=v_view[tc[itc]][3]
    end
				z/=nbv
    add(vispolys,{
     key=z,
     poly=tc
    })
   end
  end 
 end
 cpu["6-det_visible"]=curcpu()

 -- proj
 local proj=cam:proj(v_view)
 cpu["7-proj"]=curcpu()

 -- sorting visible poly
 shellsort(vispolys)
 cpu["8-sortvispolys"]=curcpu()

 --light
 local lgt={1,-1,0} 
 v_normz(lgt)

 -- drawing visible poly
 -- fixme 
 for j=#vispolys,1,-1 do
  local ipoly=vispolys[j].poly
--p  local v1,v2,v3,v4,c,idx=
--p	  proj[ipoly[1]],
--p	  proj[ipoly[2]],
--p	  proj[ipoly[3]],
--p	  proj[ipoly[4]],
  local v,c,idx={},
   ipoly[#ipoly-1],
	  ipoly[#ipoly]
	 
		for i=1,#ipoly-2 do
		 v[i]=proj[ipoly[i]]
  end
  --color and dither
  color(c)
  local ptn=v_dot(_norms[idx],lgt)
  ptn=flr(ptn*8+8)
  fillp(dith2[flr(ptn)])
  --filling
  polyfill(v,c)
--p  tri(v1[1],v1[2],v2[1],v2[2],v3[1],v3[2],c)
--p  tri(v1[1],v1[2],v3[1],v3[2],v4[1],v4[2],c)
--p  if #ipoly>6 then
--p   local v5=proj[ipoly[5]]
--p   tri(v1[1],v1[2],v4[1],v4[2],v5[1],v5[2],c)
--p  end
--  
--fillp()

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
 
 cpu["9-filltris"]=curcpu()

 -- test dither
 for i=1,#dith2 do
  color(0x54)
  fillp(dith2[i])
  rectfill((i-1)*8,0,i*8,7)
 end
 fillp()

 print("∧"..stat(1)..
   " poly visible "
   ..#vispolys.." "..curnod.id
   .."v"..cam.avel
   ,0,0,7) 
--print("nodes "..#nodes.polys)
-- print""
-- for k,v in pairs(cpu) do
--  print(k.."  "..v)
-- end
end

-->8
-- rasterization @p01
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

 local x0,y0,x1,y1,x2,y2=
  band(x0,0xffff),band(y0,0xffff),
  band(x1,0xffff),band(y1,0xffff),
  band(x2,0xffff),band(y2,0xffff)
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
-- flip()
end

-- @fred72 polyfill
function polyfill(v,c)
 local p0,nodes=v[#v],{}
 local x0,y0=p0[1],p0[2]
 for i=1,#v do
  local p1=v[i]
  local x1,y1=p1[1],p1[2]
  local _x1,_y1=x1,y1
  if(y0>y1) x0,y0,x1,y1=x1,y1,x0,y0
  local dy=y1-y0
  local dx=(x1-x0)/dy
  if(y0<0) x0-=y0*dx y0=0
  local cy0=ceil(y0)
  -- sub-pix shift
  local sy=cy0-y0
  x0+=sy*dx

  for y=cy0,min(ceil(y1)-1,127) do
   local x=nodes[y]
   if x then
    -- rectfill(x[1],y,x0,y,7)
    -- backup current edge values
    local a,b=x,x0
    if(a>b) a,b=b,a

    local x0,x1=
     ceil(a),min(ceil(b)-1,127)
    if x0<=x1 then
     rectfill(x0,y,x1,y,c)
    end
   else
    nodes[y]=x0
   end
   x0+=dx
  end
  x0,y0=_x1,_y1
 end
end
-->8
-- @fred72 3d utils and more
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
function m_qinv(m)
 m[2],m[5]=m[5],m[2]
 m[3],m[9]=m[9],m[3]
 m[7],m[10]=m[10],m[7]
 local px,py,pz=
  m[13],m[14],m[15]
 m[13],m[14],m[15]=
  -(px*m[1]+py*m[5]+pz*m[9]),
  -(px*m[2]+py*m[6]+pz*m[10]),
  -(px*m[3]+py*m[7]+pz*m[11])
end
function m_inv(m)
 m[2],m[5]=m[5],m[2]
 m[3],m[9]=m[9],m[3]
 m[7],m[10]=m[10],m[7]
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

function make_m_from_v_angle(up,ang)
 local fwd={cos(ang),0,-sin(ang)}
 local right=v_cross(up,fwd)
 v_normz(right)
 fwd=v_cross(right,up)
 return {
  right[1],right[2],right[3],0,
  up[1],up[2],up[3],0,
  fwd[1],fwd[2],fwd[3],0,
  0,0,0,1
 }
end

function t_clip(
 v_pln,v_nrm,v_view,polyidx)
    
 local poly,v_in,v_out={
 v_view[polyidx[1]],
 v_view[polyidx[2]],
 v_view[polyidx[3]],
 v_view[polyidx[4]]
 },
 {},{}

 local pdot,res,d,last=
  v_dot(v_nrm,v_pln),{}
 
 for i=1,5 do
  local j,prevj=
   (i-1)%4+1,(i-2)%4+1
  d=v_dot(v_nrm,poly[j])-pdot
  if last==nil then
   last=d>0 and "in" or "out"
  elseif d>0 then 
   if last=="out" then
    --calc intersect
    local v1=
     v_intsec(v_pln,v_nrm,poly[prevj],poly[j])
    --add res
    local idx=max_vrtx+nb_clip+1
    v_view[idx]=v1
    nb_clip+=1
    add(res,idx)
   end
   add(res,polyidx[j])
   last="in"
  else
   if last=="in" then
    --calc intersect
    local v1=
     v_intsec(v_pln,v_nrm,poly[prevj],poly[j])
    --add res
    local idx=max_vrtx+nb_clip+1
    v_view[idx]=v1
    nb_clip+=1
    add(res,idx)
   end
   last="out"
  end
 end
 add(res,polyidx[5])
 add(res,polyidx[6])

 if (#res>=5) return res
 return nil
end

function v_intsec(
  v_pln,v_nrm,v_start,v_end)

--	v_nrm=vector_normalise(v_nrm)
	local plane_d,ad,bd=
	 -v_dot(v_nrm,v_pln),
	 v_dot(v_start,v_nrm),
	 v_dot(v_end,v_nrm)
	local t=(-plane_d-ad)/(bd-ad)
	local v_s_to_end=v_clone(v_end)
	v_add(v_s_to_end,v_start,-1)
	
	v_scale(v_s_to_end,t)
	 
 local res=v_clone(v_start)
 v_add(res,v_s_to_end)
	return res
end

function lerp(v0,v1,prc)
 return (1-prc)*v0+prc*v1
end
-->8
-- triplefox with ciura's sequence
-- https://www.lexaloffle.com/bbs/?tid=2477
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

function add_all(a,b)
 for x in all(b) do
  add(a,x)
 end
end
-->8
-- 3d models

local col0,col1,col2,col3,col4,col5,m4ident=
 0x01,0x54,0x4f,0x55,0x1c,0x53,
 {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}


function make_cor(pos,ry)
 local lvrtx={
  {-8,0,0},{-8,8,0},
  {0,20,0},{8,8,0},{8,0,0},
  {8,0,8},{8,8,8},
  {0,20,8},{-8,8,8},{-8,0,8},
 }
 local lpolys={
  {1,2,9,10,col1},
  {2,3,8,9,col1},
  {3,4,7,8,col1},
  {4,5,6,7,col1},
  {1,10,6,5,col2},
 }

 transform(lvrtx,
  pos[1],pos[2],pos[3],ry)
 
 return {
  vrtx=lvrtx,
  polys=lpolys,
  door_idx=function(self,i)
   if (i==2) return 6
   return 1
  end
 }
end

function make_door_joint(da,db)
	local a1=da
 local a2=a1+1
 local a3=a2+1
 local a4=a3+1
 local a5=a4+1
	local b1=db
 local b2=b1+1
 local b3=b2+1
 local b4=b3+1
 local b5=b4+1
 local lpoly={
  {a5,a4,b2,b1,col0},
  {a4,a3,b3,b2,col0}, 
  {a3,a2,b4,b3,col0}, 
  {a2,a1,b5,b4,col0},
 }
 return {
  vrtx={},
  poly=lpoly
 }
end

function make_cor_joint()
	local a1=#vrtx-14
 local a2=a1+1
 local a3=a2+1
 local a4=a3+1
 local a5=a4+1
	local b1=#vrtx-9
 local b2=b1+1
 local b3=b2+1
 local b4=b3+1
 local b5=b4+1

 local lpolys={
  {a5,a4,b2,b1,col0},
  {a4,a3,b3,b2,col0},
  {a3,a2,b4,b3,col0},
  {a2,a1,b5,b4,col0},
 }
 return {
  vrtx={},
  polys=lpolys
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

function make_xcor(pos,ry)
 local _vrtx={
  {-8,0,0},{-8,8,0},
  {0,20,0},{8,8,0},{8,0,0},
  {-8,0,8},{-8,8,8},
	 {0,20,16},{8,8,8},{8,0,8},
  {8,0,32},{8,8,32},
  {0,20,32},{-8,8,32},{-8,0,32},
  {8,0,24},{8,8,24},
  {-8,8,24},{-8,0,24},--
  {16,0,8},{16,8,8},
  {16,20,16},{16,8,24},{16,0,24},
  {-16,0,24},{-16,8,24},
  {-16,20,16},{-16,8,8},{-16,0,8},
 }
 local _polys={
  {1,2,7,6,col1},
  {3,8,7,2,col1},
  {3,4,9,8,col1},
  {4,5,10,9,col1},
  {1,6,10,5,col2},--end
  {11,12,17,16,col1},
  {12,13,8,17,col1},
  {13,14,18,8,col1},
  {14,15,19,18,col1},
  {11,16,19,15,col2},--end
  {20,21,9,10,col1},
  {21,22,8,9,col1},
  {22,23,17,8,col1},
  {23,24,16,17,col1},
  {10,16,24,20,col2},--end
  {28,29,6,7,col1},
  {27,28,7,8,col1},
  {26,27,8,18,col1},
  {25,26,18,19,col1},
  {29,25,19,6,col2},--end
 }

 transform(_vrtx,
  pos[1],pos[2],pos[3],ry)
 
 return {
  vrtx=_vrtx,
  polys=_polys,
  door_idx=function(self,i)
   if (i==4) return 25
   if (i==3) return 20
   if (i==2) return 11
   return 1
  end
 }
end

function make_corner(pos,ry)
 local _vrtx={
  {-8,0,0},{-8,8,0},
  {0,20,0},{8,8,0},{8,0,0},
  {-8,0,24},{-8,8,24},
	 {0,20,16},{8,8,8},{8,0,8},
  {16,0,8},{16,8,8},
  {16,20,16},{16,8,24},{16,0,24},
 }
 local _polys={
  {1,2,7,6,col1},
  {2,3,8,7,col1},
  {3,4,9,8,col1},
  {4,5,10,9,col1},
  {1,6,10,5,col2},--end
  {11,12,9,10,col1},
  {12,13,8,9,col1},
  {13,14,7,8,col1},
  {14,15,6,7,col1}, 
  {6,15,11,10,col2},--end
 }

 transform(_vrtx,
  pos[1],pos[2],pos[3],ry)
 
 return {
  vrtx=_vrtx,
  polys=_polys,
  door_idx=function(self,i)
   if (i==2) return 11
   return 1
  end
 }
end

function make_tcor(pos,ry)
 local _vrtx={
  {-8,0,0},{-8,8,0},
  {0,20,0},{8,8,0},{8,0,0},
  {0,20,16},{8,8,8},{8,0,8},
  {8,0,32},{8,8,32},
  {0,20,32},{-8,8,32},{-8,0,32},
  {8,0,24},{8,8,24},
  {16,0,8},{16,8,8},
  {16,20,16},{16,8,24},{16,0,24},
  {-8,0,8},{-8,0,24}
 }
 local _polys={
  {1,2,12,13,col1},
  {3,11,12,2,col1},
  {4,7,6,3,col1},
  {5,8,7,4,col1}, 
  {5,1,21,8,col2},--end
  {10,11,6,15,col1},
  {9,10,15,14,col1},
  {14,22,13,9,col2},--end
  {16,17,7,8,col1},
  {17,18,6,7,col1},
  {18,19,15,6,col1},
  {19,20,14,15,col1},
  {16,8,14,20,col2},--end
 }

 transform(_vrtx,
  pos[1],pos[2],pos[3],ry)
 
 return {
  vrtx=_vrtx,
  polys=_polys,
  door_idx=function(self,i)
   if (i==3) return 16
   if (i==2) return 9
   return 1
  end
 }
end
-->8
-- optimization with graph node
lastcpu=0
function resetcpu()
 lastcpu=0
end

function curcpu()
 local cpu=stat(1)
 local res=cpu-lastcpu 
 lastcpu=cpu
 return res
end
function make_node(a,_polys)
 local vstart=vrtx[_polys[1][1]]
 -- init x z with first vrtx
 local minx,minz,maxx,maxz=
   vstart[1],vstart[3],
   vstart[1],vstart[3]
 for poly in all(_polys) do
  --for each vrtx,last is color
  for i=1,#poly-1 do 
   local v=vrtx[poly[i]]
   minx=min(minx,v[1])
   minz=min(minz,v[3])
   maxx=max(maxx,v[1])
   maxz=max(maxz,v[3])
  end
 end

 return {
  id=a,
  conn={},
  polys=_polys,
  norms=init_norm(vrtx,_polys),
  minx=minx,
  minz=minz,
  maxx=maxx,
  maxz=maxz,
  inbound=function(self,p)
   return self.minx<=p[1]
    and p[1]<=self.maxx 
    and self.minz<=p[3]
    and p[3]<=self.maxz
  end
 }
end

--a,b nodes to link
function link_nodes(a,b)
 local nodea,nodeb=
  nodes[a],nodes[b]
 local conn_a,conn_b=
  nodea.conn,nodeb.conn
 add(conn_a,nodeb)
 add(conn_b,nodea)
end

function getnodpolys(nod)
 local _polys,_norms,_w={},{},{}
 add_all(_polys,nod.polys)
 add_all(_norms,nod.norms)
 _w[nod.id]=true
-- print("adding"..nod.id)
-- print("chld.polys"..#nod.polys)
 
 -- take 2 nodes deep
 addchildnodpolys(
  1,nod,_polys,_norms,_w)

--print(#_w,32,96)
--print(#_polys,96)
-- for k,v in pairs(_w) do
--  print(k..""..tostr(v))
-- end
 return {
  polys=_polys,
  norms=_norms
 }
end

function addchildnodpolys(
 lvl,nod,_polys,_norms,_w)
 lvl-=1
 for chld in all(nod.conn) do
  if lvl>=0 then
   addchildnodpolys(lvl,chld,_polys,_norms,_w)
   if not _w[chld.id] then
--    print("adding"..chld.id)
--    print("chld.poly"..#chld.poly)
    _w[chld.id]=true
    add_all(_polys,chld.polys)
    add_all(_norms,chld.norms)
   end
  end
 end
end

-- first time by walking all
-- otherwise by looking to
-- adjacent nodes
function get_curnod(pos,pnod)
 if pnod==nil or pnod.id==1 then
  for i,n in pairs(nodes) do
   if (n:inbound(pos)) return n 
  end
 else
  if (pnod:inbound(pos)) return pnod
  for chld in all(pnod.conn) do  
   if chld:inbound(pos) then
    return chld
   end
  end
 end
 return nodes[1]
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
44444444777454447774777477747544554477747774777457745554757477745774777477757555777555557755777575555555775575757775555555555555
74447444747444447474447474747444444447447474474474444444757447447544474475747544754445444745757575454545475575757575455555555555
47474744747444447774447477747774455447547755475577754555757547557775475577557555775555555755757577755555575575757575555555555555
44744474747444447474447474747474444447447474474444744444777447444474475474747454745444544754747474745454575477747574555455555555
44444444777457447774547477747774554457447574777477545554575477747754777477757775777555557775777577755555777557557775555555555555
44444444444444444444444444444444444444444444444444444444454445444544454445444544454445444545454545454545455545554555455555555555
44444444444444444454445444544454455445544555455545554555455545554555455545554555555555555555555555555555555555555555555555555555
44444444444444444444444444444444444444444444444444444444444444444454445444544454445444544454445454545454545454545554555455555555
55555555555555555555555555555555555555555555555555555555555555545544554455445544554455445544554455445544554455445544554455445544
45554555455545554555455545554555455545554555455545554555455545444444444444444444444444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555555455545554555455545554555455545554555455545554555455545554555
55545554555455545554555455545554555455545554555455545554555444544454444444444444444444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555555554455445544554455445544554455445544554455445544554455445544
45554555455545554555455545554555455545554555455545554555454445554544454444444444444444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555554555555555554555455545554555455545554555455545554555455545554555
55545554555455545554555455545554555455545554555455544454445455544454445444544444444444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555555555555555544554455445544554455445544554455445544554455445544
45554555455545554555455545554555455545554555455545444544454445554444454445444544444444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555554555555555555555455545554555455545554555455545554555455545554555
55545554555455545554555455545554555455545554555444544454445455544444445444544454444444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555544555555555555554455445544554455445544554455445544554455445544
45554555455545554555455545554555455545554554454445444544455545554444454445444544454444444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555554555555555555555555555554555455545554555455545554555455545554555
55545554555455545554555455545554555455544454445444544454455455544444445444544454445444544444444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555544555555555555555555555544554455445544554455445544554455445544
45554555455545554555455545554555455545444544454445444544455545554444444445444544454445444544444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555554555455555555555555555555555455545554555455545554555455545554555
55545554555455545554555455545554545444544454445444544454555455544444445444544454445444544454444444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555544554555555555555555555555555455445544554455445544554455445544
45554555455545554555455545554544454445444544454445444555455545554444444445444544454445444544454444444444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555554555455555555555555555555555555555554555455545554555455545554555
55545554555455545554555455544454445444544454445444544554555455544444444444544454445444544454445444544444444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555544554455555555555555555555555555555544554455445544554455445544
45554555455545554555455545444544454445444544454445444555455545554444444445444544454445444544454445444544444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555554555455545555555555555555555555555555555455545554555455545554555
55545554555455545554445444544454445444544454445444545554555455544444444444544454445444544454445444544454444444444444444444444444
55555555555555555555555555555555555555555555555555555555555555555544554455555555555555555555555555555555555555445544554455445544
45554555455545554544454445444544454445444544454445454555455545504444444444444544454445444544454445444544454444444444444444444444
55555555555555555555555555555555555555555555555555555555555555001555455545555555555555555555555555555555555555554555455545554555
55545554555455544454445444544454445444544454445444545554555455011444444444444454445444544454445444544454445444544444444444444444
55555555555505555555555555555555555555555555555555555555555550000044554455445555555555555555555555555555555555550044554455445544
45554555455110444544454445444544454445444544454445554555455510001114444444444544454445444544454445444544454445441014444444444444
55555555500000555555555555555555555555555555555555555555555500001005455545554555555555555555555555555555555555500000055545554555
55545554110111044454445444544454445444544454445455545554555100011111444444444454445444544454445444544454445444511101110444444444
55555500000000055555555555555555555555555555555555555555550000000011054455445555555555555555555555555555555555000000000055445544
45551011101110144544454445444544454445444544454545554555450010001111144444444444454445444544454445444544454445111011101110444444
55500000000000005555555555555555555555555555555555555555500000051000105545554555555555555555555555555555555555000000000000054555
51011101110111014454445444544454445444544454445455545554000100544111114444444444445444544454445444544454445441011101110111011444
00000000000000000555555555555555555555555555555555555555000005545011001455445545555555555555555555555555555550000000000000000044
10111011101110111544454445444544454445444544455545554550100015544411111144444444454445444544454445444544454410111011101110111044
00000000000000000055555555555555555555555555555555555500000055554550100045554555555555555555555555555555555500000000000000000044
11011101110111011154445444544454445444544454455455545501000455544441111114444444445444544454445444544454445111011101110111011144
00000000000000000055555555555555555555555555555555555000000555555544001100445544555555555555555555555555555000000000000000000044
10111011101110111014454445444544454445444544455545551000105545444544411111444444454445444544454445444544454110111011101110111044
00000000000000000005555555555555555555555555555555550000055555555555400010054555455555555555555555555555550000000000000000000044
11011101110111011101445444544454445444544454555455510001055444544454441111144444445444544454445444544454440111011101110111011144
00000000000000000000555555555555555555555555555555000000555555555555551100115544554555555555555555555555500000000000000000000044
10111011101110111011154445444544454445444555455545001005455445444544444111111444444445444544454445444544401110111011101110111044
00000000000000000000055555555555555555555555555550000005555555555555555510001555454555555555555555555555500000000000000000000044
11111111111111111111144444444444444444444454545400010054555444544454445411111144444444444444444444444444411111111111111111111144
00010001000100010001055455545554555455545555555500000555555555555555555550110044544455545554555455545554500100010001000100010044
10111011101110111011154445444544454445444545454510101555454445444544454441111144444445444544454445444544401110111011101110111044
10001000100010001000155545554555455545554555555500000555555555555555555541111144444445554555455545554555400010001000100010001044
11111111111111111111144444444444444444444454545401010454444444444444444441111144444444444444444444444444411111111111111111111144
00010001000100010001055455545554555455545555555500000555555455545554555451110144544455545554555455545554500100010001000100010044
10111011101110111011154445444544454445444545454510101545454445444544454441111144444445444544454445444544401110111011101110111044
10001000100010001000155545554555455545554555555500000555455545554555455541111144444445554555455545554555400010001000100010001044
11111111111111111111144444444444444444444454545401010454444444444444444441111144444444444444444444444444411111111111111111111144
00010001000100010001055455545554555455545555555500000555555455545554555451110144544455545554555455545554500100010001000100010044
10111011101110111011154445444544454445444545454510101545ffffffffffffffff41111144444445444544454445444544401110111011101110111044
100010001000100010001555455545554555455545555555000005ffffffffffffffffff41111144444445554555455545554555400010001000100010001044
11111111111111111111144444444444444444444454545401010ffffffffffffffffffff1111144444444444444444444444444411111111111111111111144
00010001000100010001055455545554555455545555555500000000000000000000000000010144544455545554555455545554500100010001000100010044
10111011101110111011154445444544454445444545454510000000000000000000000000001144444445444544454445444544401110111011101110111044
10001000100010001000155545554555455545554555555500000000000000000000000000000144444445554555455545554555400010001000100010001044
11111111111111111111144444444444444444444454545ffffffffffffffffffffffffffffffff4444444444444444444444444411111111111111111111144
000100010001000100010554555455545554555455555fff4fff4fff4fff4fff4fff4fff4fff4fff544455545554555455545554500100010001000100010044
10111011101110111011154445444544454445444545ffffffffffffffffffffffffffffffffffffff4445444544454445444544401110111011101110111044
100010001000100010001555455545554555455545fffffffffffffffffffffffffffffffffffffffff445554555455545554555400010001000100010001044
11111111111111111111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111111111111144
00000000000000000fff4fff4fff4fff4fff4fff000000000000000000000000000000000000000000000fff4fff4fff4fff4fff4fff00000000000000000044
00000000000000fffffffffffffffffffffffff00000000000000000000000000000000000000000000000fffffffffffffffffffffffff00000000000000044
000000000000ffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000ffffffffffffffffffffffffff000000000000044
000000000fffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000fffffffffffffffffffffffffff000000000044
000000ff4fff4fff4fff4fff4fff4fff4ff0000000000000000000000000000000000000000000000000000000ff4fff4fff4fff4fff4fff4fff4ff000000044
0000ffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffff0000044
0fffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000fffffffffffffffffffffffffffffff0044
fffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff44
4fff4fff4fff4fff4fff4fff4fff4f00000000000000000000000000000000000000000000000000000000000000000f4fff4fff4fff4fff4fff4fff4fff4f44
ffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffffffffffffff44
fffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffff44
ffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffffffffffff44
4fff4fff4fff4fff4fff4fff00000000000000000000000000000000000000000000000000000000000000000000000000000fff4fff4fff4fff4fff4fff4f44
fffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffff44
ffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffffffff44
fffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffffff44
4fff4fff4fff4fff4ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff4fff4fff4fff4fff4f44
ffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffff44
fffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffff44
fffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff44
4fff4fff4fff4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f4fff4fff4fff4f44
fffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffff44
fffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffff44
ffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffff44
4fff4fff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004fff4fff4f44
fffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff44
ffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff44
fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff44
4ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff4f44
ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff44
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff44
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff4fff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

