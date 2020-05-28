pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- night city scene

local cam,scl,wf,t={},3,false,0
local norms,fcntrs,fnorms={},{},{}
--
local v_up={0,1,0}
local vrtx={}
local max_vrtx,nb_clip
local tris={}

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
  m={},
  --move forward
  mf=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]+cos(a)*v
   p[3]=p[3]-sin(a)*v
   self.pos=p
  end,
  --side back
  sb=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]-cos(a)*v
   p[3]=p[3]+sin(a)*v
   self.pos=p
  end,
  --strafe left
  sl=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]-cos(a-0.25)*v
   p[3]=p[3]+sin(a-0.25)*v
   self.pos=p
  end,
  --strafe right
  sr=function(self,v)
   local p,a=self.pos,self.ang
   p[1]=p[1]-cos(a+0.25)*v
   p[3]=p[3]+sin(a+0.25)*v
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
 nbvrt=#vrtx
 local m=make_bld_sm({0,0,0},{24,32,16})
 vrtx,tris=m.vrtx,m.tris
 max_vrtx=#vrtx
 --init_norm(vrtx)
end
function _update()
 t+=0.01
 if (btn(⬆️,1)) cam:mf(1.25)
 if (btn(⬇️,1)) cam:sb(1.25)
 if (btn(⬅️)) cam.ang+=0.005
 if (btn(➡️)) cam.ang-=0.005
 if (btn(⬆️)) cam.pos[2]+=1
 if (btn(⬇️)) cam.pos[2]-=1
 if (btn(⬅️,1)) cam:sl(1.25)
 if (btn(➡️,1)) cam:sr(1.25)
 if (btnp(❎)) wf=not wf
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
 cam:upd_m()
 local v_view,v_wrld={},{}
	
 for v in all(vrtx) do
  local tmp=m_x_v(m_wrld,v)
  add(v_wrld,tmp)
  add(v_view,m_x_v(cam.m,tmp))
 end
	
 --should be usefull only for
 --rotating objects, so it
 --could be precalculated
 init_norm(v_wrld)
	
 -- testing visibles
 nb_clip=0
 local vistris={}
 for i=1,#tris,4 do
  local idx=(i-1)/4+1
  local norm=norms[idx]
  local vp=v_clone(v_wrld[tris[i]])
  v_add(vp,cam.pos,-1)
  
  if v_dot(norm,vp)<0 then
   -- clipping
   local triidx={
    tris[i],
    tris[i+1],
    tris[i+2],
    tris[i+3],--col
    (i-1)/4+1}--idx normal

   local tclips=t_clip({0,0,1},
    {0,0,1},v_view,triidx)
   for t in all(tclips) do
    -- add clipped triangle
    local z=(v_view[t[1]][3]
     +v_view[t[2]][3]
     +v_view[t[3]][3])/3
    add(vistris,{
     key=z,
     tri=t
    })
   end
  end 
 end
 
 -- proj
 local proj=cam:proj(v_view)
-- local pcntr=cam:proj(fcntrs)
-- local pnorm=cam:proj(fnorms)

 -- sorting visible tris
 shellsort(vistris)
 
 --light
 local lgt={1,-1,1} 
 v_normz(lgt)

 -- drawing visible tris
 for j=#vistris,1,-1 do
  local itri=vistris[j].tri
  local v1,v2,v3,c,idx=
	  proj[itri[1]],
	  proj[itri[2]],
	  proj[itri[3]],
	  itri[4],
	  itri[5]
--local w1,w2,w3=
--v_view[itri[1]],
--v_view[itri[2]],
--v_view[itri[3]]
  --color and dither
  color(c)
  local ptn=v_dot(norms[idx],lgt)
  ptn=flr(ptn*8+8)
  fillp(dith2[flr(ptn)])
  tri(v1[1],v1[2],v2[1],v2[2],v3[1],v3[2],c)
--  
--fillp()
--line(64+w1[1],128-w1[3],64+w2[1],128-w2[3],8)
--line(64+w3[1],128-w3[3])
--line(64+w1[1],128-w1[3])
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
 v_pln,v_nrm,v_view,triidx)
    
 local tri,v_in,v_out={
 v_view[triidx[1]],
 v_view[triidx[2]],
 v_view[triidx[3]]},
 {},{}

 local pdot,d=
  v_dot(v_nrm,v_pln),{}
 for i=1,3 do
  d[i]=v_dot(v_nrm,tri[i])-pdot
  if d[i]>0 then 
   add(v_in,i)
  else
   add(v_out,i)
  end
 end
 if (#v_in==3) return {triidx}
 if #v_in==1 and #v_out==2 then
  --make a new tri with
  --inside point and
  --new points
  local v1,v2=
   v_intsec(v_pln,v_nrm,tri[v_in[1]],tri[v_out[1]]),
   v_intsec(v_pln,v_nrm,tri[v_in[1]],tri[v_out[2]])
  idx1=max_vrtx+nb_clip+1
  idx2=idx1+1
  v_view[idx1],v_view[idx2]=
   v1,v2
  nb_clip+=2
  return {
   {triidx[v_in[1]],
   idx1,
   idx2,
   triidx[4],
   triidx[5]}
  }
 end
 if #v_in==2 and #v_out==1 then
  local v1,v2=
   v_intsec(v_pln,v_nrm,tri[v_in[1]],tri[v_out[1]]),
   v_intsec(v_pln,v_nrm,tri[v_in[2]],tri[v_out[1]])
  idx1=max_vrtx+nb_clip+1
  idx2=idx1+1
  v_view[idx1],v_view[idx2]=
   v1,v2
  nb_clip+=2
  return {
   {triidx[v_in[1]],
   triidx[v_in[2]],
   idx1,
   triidx[4],
   triidx[5]},
   {triidx[v_in[2]],
   idx1,
   idx2,
   triidx[4],
   triidx[5]}
  }
 end
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
-->8
--local max_vrtx,nb_clip=#vrtx
local col1,col2,col3=0x54,0x4f,0x55
local vrtx={
 {-48,4,16},{-16,4,16},{-16,4,0},{-48,4,0}
}

local tris={
 1,2,3,col1, 1,3,4,col1
}

function make_bld_sm(pos,siz)
 local px,py,pz,sx,sy,sz=
  pos[1],pos[2],pos[3],
  siz[1]/2,siz[2],siz[3]/2
 local vrtx={
  {-sx+px,py,-sz+pz},
  {sx+px,py,-sz+pz},
  {sx+px,py,sz+pz},
  {-sx+px,py,sz+pz},
  {-sx+px,sy+py,-sz+pz},
  {sx+px,sy+py,-sz+pz},
  {sx+px,sy+py,sz+pz},
  {-sx+px,sy+py,sz+pz},

  {-sx+px,sy*1.3+py,pz},
  {sx+px,sy*1.3+py,pz}
 }
 local tris={
  1,5,2,col1, 5,6,2,col1,
  2,6,3,col1, 6,7,3,col1,
  3,7,4,col1, 7,8,4,col1,
  4,8,1,col1, 8,5,1,col1,
  8,9,5,col1, 6,10,7,col1,
  5,9,6,col2, 6,9,10,col2,
  7,10,8,col2, 8,10,9,col2
 }

 return {
  vrtx=vrtx,
  tris=tris
 }
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
44444444777454447474744477747544554477747774777457745554777477745554757477755775777577757555777555557775777555555555555555555555
74447444747444447474744474447444444447447474474474444444457475744544757447447544474475747545754545457545757545554555455555555555
47474744747444447774777477747774455447547755475577754555457577754555757547557775575577557555775555557775777555555555555555555555
44744474747444444474747444747474444447447474474444744444447444744454777447544474475474747454745454545474547454545554555455555555
44444444777457445474777477747774554457447574777477545554557455745554575477757755777577757775777555557775557555555555555555555555
44444444444444444444444444444444444444444444444444444444454445444544454445444544454445444545454545454545455545554555455555555555
44444444444444444454445444544454455445544555455545554555455545554555455545554555555555555555555555555555555555555555555555555555
44444444444444444444444444444444444444444444444444444444444444444454445444544454445444544454445454545454545454545554555455555555
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444444444444555455545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444444444444555455545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444444444444555455545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444444444444555455545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444444444444555455545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444444444444555455545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555554444444444445554555455555555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000044544454445444544455555555555555555555554444445444544454445545555555555555555554445444544454445444544400000000000000
00000000000044444444444444444454445555555555555555554444444444444444444444555555555555555554444444444444444444444400000000000000
00000000000054445444544454445455555555555555555555445444544454445444544454445555555555555554544454445444544454445400000000000000
00000000000044444444444444444445454555555555555444444444444444444444444444444445555555555554444444444444444444444400000000000000
00000000000044444444444444444444444444444444445444544454445444544454445444544454445444444444444444444444444444444400000000000000
00000000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000
00000000000444444444444444444444444444445444544454445444544454445444544454445444544454445444444444444444444444444440000000000000
00000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444000000000000
00000000004444444444444444444444445444544454445444544454445444544454445444544454445444544454445444444444444444444444000000000000
00000000044444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444400000000000
00000000044444444444444444444444544454445444544454445444544454445444544454445444544454445444544444444444444444444444400000000000
00000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000
00000000445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454440000000000
00000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000
00000000544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444540000000000
00000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000
00000000445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454440000000000
00000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000
00000000544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444540000000000
00000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000
00000000445444544454445444544454445555555555555555555555555555555555555555555555555555555554445444544454445444544454440000000000
00000000000000544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444540000000000000000
00000000000000008888588888888888888888888888888888888888888888888888888888888588888888888888888888888888888888888000000000000000
0000000000000000888055555555555585555555555555558888f8fffffffffffffffffffff8f555888555555555555585555555550000008000000000000000
0000000000000000800885555555555585555555555555588f48888fff4fff4fff4fff4fff8ff555885885555555555585555555550000008000000000000000
0000000000000000800088855555555585555555555555588ffff8888ffffffffffffffff8fff555858558855555555585555555550000008000000000000000
0000000000000000800055888555555585555555555555858fff4ff888884fff4fff4fff8fff4555858555588555555585555555550000008000000000000000
0000000000000000800055588885555585555555555555858ffffffff88f88fffffffff8fffff555855855555885555585555555550000008000000000000000
0000000000000000800055555858855585555555555558558f4fff4fff888f888f4fff8fff4ff555855855555558855585555555550000008000000000000000
0000000000000000800055555588588585555555555558558ffffffffff8f88ff88ff8fffffff555855585555555588585555555550000008000000000000000
0000000000000000800055555555855885555555555585558fff4fff00008008800888ff4fff4555855585555555555885555555550000008000000000000000
0000000000000000800055555555588588855555555585558fffffff0000080008880088fffff555855558555555555588855555550000008000000000000000
0000000000000000800055555555555885588555555855558f4fff4f000000800088804f888ff555855558555555555585588555550000008000000000000000
0000000000000000800055555555555588555885555855558fffffff000000080800088ffff88555855555855555555585555885550000008000000000000000
00000000000000008888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888000000000000000
0000000000000000800088888855555555588555588555558ffffff8888880000000888888888888888555585555555555555555588000008000000000000000
0000000000000000800055555588888855555855585885558888888f000000000000004fff888888858888888888888555555555550880008000000000000000
0000000000000000800055555555555588888888585888888fffffff00000000000000fffffff885888888858555555888888888888008808000000000000000
00000000000000008888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888000000000000000
00000000000000000000555555555555555555558555888888ffffff00000000000000fffffff555555555558555555555555555550000000000000000000000
000000000000000000005555555555555555555585555555ff888888000000000000004fff4ff555555555558555555555555555550000000000000000000000
000000000000000000005555555555555555555585555555ffffffff88888800000000fffffff555555555558555555555555555550000000000000000000000
0000000000000000000055555555555555555555855555554fff4fff00000088888800ff4fff4555555555558555555555555555550000000000000000000000
000000000000000000005555555555555555555585555555ffffffff000000000000888888fff555555555558555555555555555550000000000000000000000
000000000000000000005555555555555555555585555555ff4fff4f000000000000004fff888888555555558555555555555555550000000000000000000000
000000000000000000005555555555555555555585555555ffffffff00000000000000fffffff555888888558555555555555555550000000000000000000000
00000000000000000000555555555555555555558888888888888888888888888888888888888888888888888555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ff4fff4f000000000000004fff4ff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
0000000000000000000055555555555555555555555555554fff4fff00000000000000ff4fff4555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ff4fff4f000000000000004fff4ff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
0000000000000000000055555555555555555555555555554fff4fff00000000000000ff4fff4555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ff4fff4f000000000000004fff4ff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
0000000000000000000055555555555555555555555555554fff4fff00000000000000ff4fff4555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ff4fff4f000000000000004fff4ff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
0000000000000000000055555555555555555555555555554fff4fff00000000000000ff4fff4555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffff00000000000000fffffff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ff4fff4f000000000000004fff4ff555555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffffffffffffffffffffffffff55555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffffffffffffffffffffffffff55555555555555555555555555550000000000000000000000
000000000000000000005555555555555555555555555555ffffffffffffffffffffffffffffff55555555555555555555555555550000000000000000000000
00000000000000000000445444544454445444544454445f5ffffffffffffffffffffffffffff4f4445444544454445444544454440000000000000000000000
00000000000000000004444444444444444444444444444ffffffffffffffffffffffffffffff444444444444444444444444444444000000000000000000000
00000000000000000044544454445444544454445444544fffffffffffffffffffffffffffffff44544454445444544454445444544400000000000000000000
000000000000000004444444444444444444444444444445ffffffffffffffffffffffffffffff44444444444444444444444444444440000000000000000000
000000000000000044544454445444544454445444544455ffffffffffffffffffffffffffffff54445444544454445444544454445444000000000000000000
0000000000000004444444444444444444444444444444fffffffffffffffffffffffffffffffff4444444444444444444444444444444400000000000000000
00000000000004445444544454445444544454445444545ffffffffffffffffffffffffffffffff4544454445444544454445444544454445000000000000000
00000000000044444444444444444444444444444444444ffffffffffffffffffffffffffffffff4444444444444444444444444444444444400000000000000
00000000000444544454445444544454445444544454455ffffffffffffffffffffffffffffffff4445444544454445444544454445444544450000000000000
0000000000444444444444444444444444444444444444ffffffffffffffffffffffffffffffffff444444444444444444444444444444444444000000000000
0000000004445444544454445444544454445444544455ffffffffffffffffffffffffffffffffff544454445444544454445444544454445444500000000000
0000000044444444444444444444444444444444444445ffffffffffffffffffffffffffffffffff444444444444444444444444444444444444440000000000
0000000044544454445444544454445444544454445445ffffffffffffffffffffffffffffffffff445444544454445444544454445444544454440000000000
000000004444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffff44444444444444444444444444444444444440000000000
000000005444544454445444544454445444544454445ffffffffffffffffffffffffffffffffffff44454445444544454445444544454445444540000000000
000000004444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffff44444444444444444444444444444444444440000000000
000000004454445444544454445444544454445444544ffffffffffffffffffffffffffffffffffff45444544454445444544454445444544454440000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

