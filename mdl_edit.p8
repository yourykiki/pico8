pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- 3d model editor
-- @yourykiki

-- resize view(port) cam
-- add/remove face
-- add more volumes
-- copy each mdl state in stack
-- draw grid matching temple rooms size

-- c_3d on a sphere look at 0,0,0

local c_top,c_side,c_front,c_3d,
 mdl,mrk_mdl,c_current,ivrtx,
 toolb,modal,ctx_mnu,pmb,colpick,
 inearvrtx,inearnormal,selface
local top,sid,fro,normals,normcnt=
 {1,3},{1,2},{3,2},{},{}
local v_up={0,1,0}

--0 no selection
--1 mouse select begin
--2 mouse select end
--3 move with keyb
--  or drag with mouse
local updstate,
 us_noselect,
 us_select,
 us_editvrtx,
 us_editface=0,0,1,2,3

local mousemode,
 mm_point,
 mm_drag,
 drag_orig=0,0,1

local ed_vrtx,ed_face=
 "vrtx","face"
local ed_tool={name=ed_vrtx}

local render,
 r_wire,
 r_flat=0,0,1
local dith={
 0x0000,0x8000,0x8020,0xa020,
 0xa0a0,0xa4a0,0xa4a1,0xa5a1,
 0xa5a5,0xe5a5,0xa5b5,0xf5b5,
 0xf5f5,0xfdf5,0xfdf7,0xffff
}
local dith2={
 0x0000,0x0000,0x8020,0xc020,
 0xc060,0xc070,0xe070,0xe470,
 0xe472,0xf472,0xf4f2,0xf5f2,
 0xf5fa,0xf7fa,0xf7fe,0xffff
}

local add_mnu={
 { caption="add cube",
   onclick=function()
    add_cube()
   end
 },
 { caption="item 2",
   onclick=function()
    sfx(2)
   end
 },
 { caption="item 3",
   onclick=function()
    sfx(2)
   end
 }
}

function _init()
 -- devkit mode
 poke(0x5f2d, 1)
 -- init cam
 c_top,c_side,c_front,c_3d=
  init_cam("t",64, 8,top),
  init_cam("s",64,68,sid),
  init_cam("f", 0,68,fro),
  init_cam("3d",0, 8)
 c_3d.proj=proj3d
 -- load default model
 mdl=make_cube({0,0,0},0)
 update_normals(mdl)
 mrk_mdl=make_marker()
 -- toolbar
 toolb=init_toolbar()
 -- default tool
 ed_tool.update=update_vrtx
 -- color picker
 colpick=init_col_picker()
end

function init_cam(name,vx,vy,ax)
 local camdst=16
 return {
  name=name,
  pos={0,4,-camdst},
  roty=0,
  ang=0.25,camdst=camdst,
  view={w=64,h=60,x=vx,y=vy},
  m={},
  focus=false,zoom=100,
  ax=ax,
  sel={x1=0,y1=0,x2=0,y2=0,a=false},
  p_vrtx={},
  p_normcnt={},
  upd_m=function(self)
   local d=self.camdst
   c_current.pos[1]=-d*cos(c_current.ang)
   c_current.pos[3]= d*sin(c_current.ang)

   local m_vw=
    make_m_from_v_angle(v_up,self.ang)
   m_vw[13],m_vw[14],m_vw[15]=
    self.pos[1],self.pos[2],self.pos[3]
   m_qinv(m_vw)
   self.m=m_vw
  end,
  proj=proj2d,
  setfocus=function(self,mx,my)
   local v=self.view
   self.focus=
    v.x<mx and mx<=(v.x+v.w) and
    v.y<my and my<=(v.y+v.h)
  end,
  drawsel=function(self)
   local sel=self.sel
   if sel.a then
    fillp(0x5a5a)
    rect(sel.x1,sel.y1,
     sel.x2,sel.y2,0x57)
    fillp()
   end
  end,
  startselect=function(self,mx,my)
   local sel,view=self.sel,self.view
   sel.x1,sel.y1,
   sel.x2,sel.y2, sel.a=
    mx-view.x,my-view.y,
    mx-view.x,my-view.y, true
  end,
  updselect=function(self,mx,my)
   local sel,view=self.sel,self.view
   sel.x2,sel.y2=mx-view.x,my-view.y
  end,
  endselect=function(self)
   self.sel.a=false
   local selvrtx={}
   self:sortsel()
   for k,v in pairs(self.p_vrtx) do
    if self:vinsel(v) then
     add(selvrtx,k)
    end
   end
   ivrtx=selvrtx
  end,
  vinsel=function(self,v)
   local sel,vx,vy=self.sel,
    v[1],v[2]   
   return isinside(vx,vy,
    sel.x1,sel.x2,sel.y1,sel.y2)
  end,
  sortsel=function(self)
   local sel=self.sel
   if sel.x1>sel.x2 then
    sel.x1,sel.x2=sel.x2,sel.x1
   end
   if sel.y1>sel.y2 then
    sel.y1,sel.y2=sel.y2,sel.y1
   end
  end,
  moveselvrtx=function(self,bl,br,bu,bd,vrtx)
   local ax=self.ax
   if (not ax) return 
   for i in all(ivrtx) do
    if (bl) vrtx[i][ax[1]]-=1
    if (br) vrtx[i][ax[1]]+=1
    if (bu) vrtx[i][ax[2]]+=1
    if (bd) vrtx[i][ax[2]]-=1
   end
  end,
  movedragselvrtx=function(self,dx,dy,vrtx)
   for i in all(ivrtx) do
    vrtx[i][ax[1]]+=dx
    vrtx[i][ax[2]]-=dy
   end
  end,
  nearselvrtx=function(self,mx,my)
   local res,view=false,self.view
   local _mx,_my=
    mx-view.x,my-view.y
  	local mx1,mx2,my1,my2=
	   _mx-3,_mx+3,_my-3,_my+3
   for i in all(ivrtx) do
    local v=self.p_vrtx[i]
    if v then
     res=res or (
      isinside(v[1],v[2],
	      mx1,mx2,my1,my2))
    end
   end
   return res
  end,
  near_vrtx=function(self,mx,my)
   inearvrtx=
    isin2dvec(
     self.view,
     mx,my,
     self.p_vrtx)
  end,
  near_normals=function(self,mx,my)
   inearnormal=
    isin2dvec(
     self.view,
     mx,my,
     self.p_normcnt)
  end
 }
end

function init_modal(msg,fnc,w,h)
 resetkeys()
 return {
  msg=msg,
  fnc=fnc,
  w=w,h=h,
  update=function(self,mx,my,mb)
   if keypaste() then 
    self.fnc()
    modal=nil
   elseif m_pressed(mb,2) then 
    modal=nil
   end
  end,
  draw=function(self)
   local sx,sy=(128-w)/2,(128-h)/2
   rectfill(sx,sy,sx+w,sy+h,8)
   print(self.msg,sx+1,sy+1,6)
  end
 }
end

function init_toolbar()
 return {
  actions={
   {icon=1,
    onclick=function()
     modal=init_modal(
      "paste model or\npress mouse button 2",
      import,96,12
     )
    end
   },
   {icon=2,
    onclick=function()
     export(mdl)
    end
   },
   {icon=5,onclick=noop},
   {icon=3,
    onclick=function()
     ed_tool.name=ed_vrtx
     ed_tool.update=update_vrtx
    end,
    tgl=function()
     return ed_tool.name==ed_vrtx
    end
   }, 
   {icon=4,
    onclick=function()
     ed_tool.name=ed_face
     ed_tool.update=update_face
    end,
    tgl=function()
     return ed_tool.name==ed_face
    end
   },
   {icon=5,onclick=noop},
   {icon=6,
    onclick=function()
     render=r_wire
    end,
    tgl=function()
     return render==r_wire
    end
   },
   {icon=7,
    onclick=function()
     render=r_flat
    end,
    tgl=function()
     return render==r_flat
    end
   }
  },
  update=function(self,mx,my,mb,dw)
   self.sel=0
   --mouse over refactor isinside + div
   for i,act in pairs(self.actions) do
    bx1,bx2,by1,by2=
     i*7-6,i*7+1,0,7
    if bx1<mx and mx<=bx2 and
       by1<my and my<=by2 then
     self.sel=i
     if m_pressed(mb,1) then
      -- clicked
      act.onclick()
     end
    end
   end
  end,
  draw=function(self,c_current)
   rectfill(0,0,127,7,8)
   for i,act in pairs(self.actions) do
    d=(i==self.sel) and 16 or 0
    if (act.tgl and act.tgl()) d=32
    spr(act.icon+d,i*7-6,0)
   end
   local zm=c_current.zoom
   print((zm\1).."%",108,1,15)
   --print("∧"..stat(1),64,1,15)
  end
 }
end

function init_context_mnu(mx,my,mnu_items)
 local max_l,nb_item=0,#mnu_items
 for item in all(mnu_items) do
  local l=#(item.caption)
  if (l>max_l) max_l=l
 end
 -- calc coord
 local stx,sty=
  min(128-max_l*4,mx),
  min(128-nb_item*7,my)

 return {
  stx=stx,sty=sty,
  edx=stx+max_l*4,
  edy=sty+nb_item*7,
  max_l=max_l,
  items=mnu_items,
  sel=0,
  update=function(self,mx,my,mb,dw)
   self.sel=0
   --mouse over
   if self.stx<mx and mx<self.edx and
      self.sty<my and my<self.edy then
    self.sel=(my-self.sty)\7+1
   end
   if m_pressed(mb,1) then
    local item=self.items[self.sel]
    if (item) item.onclick()
    ctx_mnu=nil
   end
  end,
  draw=function(self)
   local stx,sty,edx,edy=
    self.stx,self.sty,
    self.edx,self.edy
   rectfill(stx,sty,edx,edy,8)
   for i,item in pairs(self.items) do
    local c=6
    if self.sel==i then
     c=8
     rectfill(stx,sty+i*7-7,
      edx,sty+i*7-1,6)
    end
    print(item.caption,stx+1,sty+7*i-6,c)
   end
  end
 }
end

function init_col_picker()
 return {
  h=32,
  col=0x84,
  delface=false,
  sel={},
  isinside=function(self,mx,my)
   return isinside(mx,my,
    0,127,128-self.h,127)
  end,
  update=function(self,mx,my,mb,dw)
   --change color
   local y=128-self.h
   local sel=self.sel
   sel[0],sel[1],delface=
    nil,nil,false

   if isinside(mx,my,28,124,y+9,y+13) then
    sel[0]=(mx-28)\6
   elseif isinside(mx,my,28,124,y+16,y+20) then
    sel[1]=(mx-28)\6
   elseif isinside(mx,my,4,12,y+22,y+30) then 
    delface=true
   end
   self.delface=delface
   --btn pressed
   if m_pressed(mb,1) then
    if sel[0] then
     local col=self.col
     self.col=(col&0xf0)|sel[0]
    elseif sel[1] then
     local col=self.col
     self.col=(col&0x0f)|(sel[1]<<4)
    elseif delface then
     del_face(selface)
     selface=nil
    end
   end
  end,
  draw=function(self)
   local h=self.h
   local x,y=0,128-h
   rectfill(x,y,127,127,5)
   print("face color",1,y+2,6)
   print("  1 :",1,y+9)
   print("  2 :",1,y+16)
   local col={
     self.col & 0x0f,
    (self.col & 0xf0) >> 4
   }
   for j=0,1 do
    for i=0,15 do
     local xoff,yoff=i*6,j*7
     rectfill(28+xoff,y+9+yoff,
      32+xoff,y+13+yoff,i)
     if i==col[j+1] then
      rect(27+xoff,y+8+yoff,
       33+xoff,y+14+yoff,7)
     end
     if self.sel[j]==i then
      fillp(▒)
      rect(27+xoff,y+8+yoff,
       33+xoff,y+14+yoff,15)
      fillp()
     end
    end
   end
   --
   local delicon=32
   if (delface) delicon+=16
   spr(delicon,4,y+22)
  end
 }
end

function _update()
 local mx,my,mb,dw=
  stat(32),stat(33),stat(34),stat(36)
 update(mx,my,mb,dw)
 pmb=mb
end

function update(mx,my,mb,dw)
 -- toolbar
 toolb:update(mx,my,mb,dw)
 -- modal
 if modal then
  modal:update(mx,my,mb)
  return
 end
 
 -- 3d specific
 if c_current and c_current.name=="3d" then
  if m_pressed(mb,4) then
   drag_orig={mx,my}
  elseif mb&4==4 then
   dx,dy=mx-drag_orig[1],
         my-drag_orig[2]
   -- make the cam move based
   -- on ang instead of models
   c_current.ang+=(dx/0.05)
   c_current.pos[2]+=dy/4
   drag_orig={mx,my}
   return
  end
 end

 ed_tool.update(mx,my,mb,dw)
 
 -- zoom
 if c_current then
  local dzm=0
  if dw>0 then
   dzm=10
  elseif dw<0 then
   dzm=-10
  end
  c_current.zoom+=dzm
  c_current.camdst-=dzm/10
 end
   
 if ctx_mnu then
  ctx_mnu:update(mx,my,mb)
 end
end

function update_focus(mx,my)
 c_top:setfocus(mx,my)
 c_side:setfocus(mx,my)
 c_front:setfocus(mx,my)
 c_3d:setfocus(mx,my)
 
 if (c_top.focus) c_current=c_top
 if (c_side.focus) c_current=c_side
 if (c_front.focus) c_current=c_front
 if (c_3d.focus) c_current=c_3d
end

function update_normals(mdl)
 normcnt={}
 --center
 for i,p in pairs(mdl.polys) do
  local v,siz={0,0,0},#p-1
  for j=1,siz do
   local vj=mdl.vrtx[p[j]]
   v_add(v,vj)
  end
  v_scale(v,1/siz)
  add(normcnt,v)
 end
 --normals
 normals=init_norm(mdl.vrtx,mdl.polys)
end

function proj2d(self,vrtx)
 local vert,w,h,zm,ax={},
  self.view.w/2,
  self.view.h/2,
  self.zoom/100,
  self.ax
 for i=1,#vrtx do 
  local pnt=vrtx[i]
  vert[i]={
   pnt[ax[1]]*zm+w,
   -pnt[ax[2]]*zm+h
  }
 end
 return vert
end
function proj3d(self,vrtx)
 local vert,ww,hh,zm=
  {},self.view.w/2,
  self.view.h/2,
  1--use camdst instead
 
 for i=1,#vrtx do 
  local v=vrtx[i]
  local w=ww/v[3]
  vert[i]={
   ww+w*v[1]*zm,
   hh-w*v[2]*zm
  }
 end
 return vert
end


function update_vrtx(mx,my,mb,dw)
 -- 
 if (c_current) c_current:near_vrtx(mx,my)
 --
 if updstate==us_noselect then
  update_focus(mx,my)
  if mb&1==1 then
   -- store mx,my start
   c_current:startselect(mx,my)
   updstate=us_select
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,add_mnu)
  end

 elseif updstate==us_select then
  c_current:updselect(mx,my)
  if mb&1==0 then
   -- store mx,my end
   c_current:endselect()
   -- check if vrtx selected
   if #ivrtx>0 then
    updstate=us_editvrtx
   else
    updstate=us_noselect
   end
  end
  
 elseif updstate==us_editvrtx then
  local nearsel=c_current:nearselvrtx(mx,my)
  if mousemode==mm_point then
   update_focus(mx,my)
  elseif mousemode==mm_drag then
   dx,dy=mx-drag_orig[1],
         my-drag_orig[2]
   c_current:movedragselvrtx(
     dx,dy,mdl.vrtx)
   drag_orig={mx,my}
   -- 
   if mb&1==0 then
    mousemode=mm_point
    update_normals(mdl)
    return
   end
  end


  local bl,br,bu,bd=
   btn(⬅️),btn(➡️),
   btn(⬆️),btn(⬇️)
  
  c_current:moveselvrtx(
   bl,br,bu,bd,mdl.vrtx)
    
  if m_pressed(mb,1)
    and mousemode==mm_point then
   if nearsel then
    --dragmove mode on
    mousemode=mm_drag
    drag_orig={mx,my}
   else
    --back to selection
    ivrtx={}
    updstate=us_noselect
   end
  end
  
  if mousemode==mm_drag then
   -- dragmove
   if mb&1==0 then
    mousemode=mm_point
   end
  end
 end
end

function update_face(mx,my,mb,dw)
 --
 if (c_current) c_current:near_normals(mx,my)
	
	-- inside colpick 
 if selface and colpick:isinside(mx,my,mb) then
	 colpick:update(mx,my,mb,dw)
	 local poly=mdl.polys[selface]
	 if (poly) poly[#poly]=colpick.col
	 update_normals(mdl)
	 return
	end

 if updstate==us_noselect then
  update_focus(mx,my)
	 if m_pressed(mb,1) then
	  -- if near a normal, select it
   selface=inearnormal
	  if selface then
	   updstate=us_editface
	   update_colpick()
	  end

--	 elseif m_pressed(mb,2) and not ctx_mnu then
--	  -- context menu
--	  ctx_mnu=init_context_mnu(mx,my,add_mnu)
	 end
	elseif updstate==us_editface then
	 -- apply color of color picker
	 -- or delegate to it
	 if m_pressed(mb,1) then
	  selface=inearnormal
	  if selface then
	   update_colpick()
	  else
 	  updstate=us_noselect
 	 end
	 end
	end
end

function update_colpick()
 local poly=mdl.polys[selface]
 colpick.col=poly[#poly]
end

function _draw()
 cls()
 draw_cam(c_top)
 draw_cam(c_side)
 draw_cam(c_front)
 draw_cam(c_3d)
 camera()
 toolb:draw(c_current)

 if modal then
  modal:draw()
 end
 if ctx_mnu then
  ctx_mnu:draw()
 end
 if selface then
  colpick:draw()
 end
 spr(0,stat(32)-1,stat(33)-1)
end

function draw_cam(cam)
 local vport=cam.view
 camera(-vport.x,-vport.y)
 clip(vport.x,vport.y,vport.w,vport.h)
 rectfill(0,0,vport.w-1,vport.h-1,1)

 -- draw origin marker
 draw_marker(cam,mrk_mdl)
 -- draw model
 local vrtx,_normcnt={},{}
 add_all(vrtx,mdl.vrtx)
 add_all(_normcnt,normcnt)

 local iscam3d=cam.name=="3d"
 -- draw model
 if iscam3d then
  -- world transform
  local m_roty,m_tran=
   m_makeroty(cam.roty),
   m_maketran(0,0,0)
		
  m_wrld={1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
  m_wrld=m_x_m(m_wrld,m_roty)
  m_wrld=m_x_m(m_wrld,m_tran)
  -- cam transform
  cam:upd_m()
  local v_view,v_wrld,v_vwcnt=
   {},{},{}
	
  for v in all(vrtx) do--optim vrtx
   local tmp=m_x_v(m_wrld,v)
   add(v_wrld,tmp)
   add(v_view,m_x_v(cam.m,tmp))
  end

  -- normal center  
  normals=init_norm(v_wrld,mdl.polys)
  --
  for v in all(_normcnt) do
   local tmp=m_x_v(m_wrld,v)
   add(v_vwcnt,m_x_v(cam.m,tmp))
  end

  _normcnt=cam:proj(v_vwcnt)
	
  local	vispolys=
   cullnclip(v_wrld,v_view)
   
  --proj, including vrtx from clip
  vrtx=c_3d:proj(v_view)
  c_3d.p_vrtx=vrtx
  -- and finally
  draw_polys(vispolys,vrtx)
  
  -- draw normals
  pnormals=_normcnt
  cam.p_normcnt=pnormals
  draw_points(pnormals,8)
  draw_circ({pnormals[inearnormal]},15)
  if selface then
   draw_circ({pnormals[selface]},7)
  end
  --  
  draw_selected_vrtx(vrtx,v_view)
  draw_visible_vrtx(vrtx,v_view)

 else 
  -- 2d wire rendering
  vrtx=cam:proj(vrtx)
  cam.p_vrtx=vrtx
	 for poly in all(mdl.polys) do
	  -- convert poly with vrtx idx
	  -- to poly with vrtx coord
	  local _poly={}
	  for i=1,#poly-1 do
	   _poly[i]=vrtx[poly[i]]
	  end
	  draw_wire(_poly)
	 end
  draw_selected_vrtx(vrtx)
  -- draw all vertex
  draw_points(vrtx,5)
 end
 --
 cam:drawsel()
 if (cam.focus) then
  rect(0,0,vport.w-1,vport.h-1,7)
 end
 print(cam.name,2,2,6)
 clip()
end

function draw_selected_vrtx(vrtx,v_view)
 if ivrtx then
  -- draw selected vrtx
  local selvrtx={}
  for iv in all(ivrtx) do
   if isvrtxvisible(v_view,iv) then
    add(selvrtx,vrtx[iv])
   end
  end
  draw_circ(selvrtx,7)
  draw_points(selvrtx,11)
 end
 if inearvrtx and 
  isvrtxvisible(
   v_view,inearvrtx) then
  draw_circ({vrtx[inearvrtx]},15)
 end
end

function draw_visible_vrtx(vrtx,v_view)
 -- draw all vertex
 local visvrtx={}
 for k,v in pairs(vrtx) do
  if isvrtxvisible(v_view,k) then
   add(visvrtx,v)
  end
 end
 draw_points(visvrtx,5)
end
function isvrtxvisible(v_view,iv)
 return not v_view
  or v_view[iv][3]>0
end
--_poly=polygon with vertx coord
function draw_wire(_poly)
 local v1,v2=_poly[#_poly]
 for v in all(_poly) do
  v2,v1=v1,v
  line(v1[1],v1[2],v2[1],v2[2],6)
 end
end

function cullnclip(v_wrld,v_view)
 local vispolys={}
 -- check visibility
 for k,poly in pairs(mdl.polys) do
  local norm=normals[k]
  local vp=v_clone(v_wrld[poly[1]])
  v_add(vp,c_3d.pos,-1)

  -- backface culling
  if v_dot(norm,vp)<0
   or render==r_wire then
   -- clipping
   local polyidx={}
   for i=1,#poly-1 do
    polyidx[i]=poly[i]
   end

   local tc=t_clip({0,0,1},
    {0,0,1},v_view,polyidx)
   -- final polygon to render
   if tc then
	   local z=0
	   for iv in all(tc) do
	    z=max(z,v_view[iv][3]
	     +abs(v_view[iv][2]))
	   end
	   add(vispolys,{
	    poly=tc,
	    col=poly[#poly],
	    idx=k,
	    key=z
	   })
	  end
  end
 end
 return vispolys
end

function draw_polys(vispolys,vrtx)

 -- sorting visible poly
 shellsort(vispolys)

 --light
 local lgt={1,-1,0} 
 v_normz(lgt)
 
-- for objpoly in all(vispolys) do
 for j=#vispolys,1,-1 do
  local objpoly=vispolys[j]
 	local poly,idx,col=
 	 objpoly.poly,
 	 objpoly.idx,
 	 objpoly.col
 	local _poly={}
	 for i=1,#poly do
	  add(_poly,vrtx[poly[i]])
	 end
  --color and dither
	 if render==r_flat then
   local ptn=v_dot(normals[idx],lgt)
   ptn=(ptn*8+8)\1
   fillp(dith2[ptn\1])
   polyfill(_poly,col)
	 else
   draw_wire(_poly)
	 end
 end
 fillp()
end

function draw_points(vrtx,col)
 for v in all(vrtx) do
  line(v[1],v[2],v[1],v[2],col)
 end
end

function draw_circ(vrtx,col)
 for v in all(vrtx) do
  circ(v[1],v[2],2,col)
 end
end

function draw_lin(vrtx,lins)
 fillp(▒)
 for lin in all(lins) do
  local v1,v2=vrtx[lin[1]],
   vrtx[lin[2]]
  line(v1[1],v1[2],v2[1],v2[2],5)
 end
 fillp()
end

function draw_marker(cam,mrk_mdl)
 local vrtx={}
 add_all(vrtx,mrk_mdl.vrtx)
 
 vrtx=cam:proj(vrtx)
 draw_lin(vrtx,mrk_mdl.lins)
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
--
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

-- polyfill from virtua racing
function polyfill(p,col)
	color(col)
	local p0,nodes=p[#p],{}
	local x0,y0=p0[1],p0[2]

	for i=1,#p do
		local p1=p[i]
		local x1,y1=p1[1],p1[2]
		-- backup before any swap
		local _x1,_y1=x1,y1
		if(y0>y1) x1=x0 y1=y0 x0=_x1 y0=_y1
		-- exact slope
		local dx=(x1-x0)/(y1-y0)
		if(y0<0) x0-=y0*dx y0=-1
		-- subpixel shifting (after clipping)
		local cy0=(y0&0xffff)+1
--		local cy0=y0\1+1
		x0+=(cy0-y0)*dx
		for y=cy0,min(y1\1,127) do
			local x=nodes[y]
			if x then
				rectfill(x,y,x0,y)
			else
				nodes[y]=x0
			end
			x0+=dx
		end
		-- next vertex
		x0=_x1
		y0=_y1
	end
end

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
-->8
--3d models
local col1=0x54
 
function make_cube(pos,ry)
 local lvrtx={
  {-8,0,-4},{-6,8,-4},
  {6,8,-4},{8,0,-4},
  {8,0,4},{6,8,4},
  {-6,8,4},{-8,0,4},
 }
 local lpolys={
  {1,2,3,4,col1},
  {5,6,7,8,col1},
  {8,7,2,1,col1},
  {4,3,6,5,col1},
  {7,6,3,2,col1},
  {4,5,8,1,col1},
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

function make_marker()
 return {
  vrtx={
   {0,0,0},{10,0,0},
   {0,10,0},{0,0,10}
  },
  lins={
   {1,2},{1,3},{1,4}
  }
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
-->8
-- utils @yourykiki
function noop()
end
function add_all(a,b)
 for x in all(b) do
  add(a,x)
 end
end

function isin2dvec(view,mx,my,
 arrayv2d)
	local _mx,_my=
	 mx-view.x,my-view.y
	local mx1,mx2,my1,my2=
	 _mx-3,_mx+3,_my-3,_my+3
	for i,v in pairs(arrayv2d) do
	 if isinside(v[1],v[2],
	  mx1,mx2,my1,my2) then
	  return i
	 end
	end
	return nil
end

function isinside(vx,vy,mx1,mx2,my1,my2)
 return
  mx1<=vx and vx<=mx2 and
  my1<=vy and vy<=my2
end
--
function keypaste()
 local c_v,kp=false
 while stat(30) do
  kp=ord(stat(31))
  c_v=c_v or kp==213
 end
 return c_v
end

function resetkeys()
 while (stat(30)) do
  stat(31)
 end
end

function m_pressed(mb,n)
 return mb&n==n and pmb&n==0
end

--
function add_cube()
 cub="{polys={{1,2,3,4,0},"
  .."{5,6,7,8,84},{8,7,2,1,84},"
  .."{4,3,6,5,84},{7,6,3,2,84},"
  .."{4,5,8,1,84}},"
  .."vrtx={{-4,0,-4},{-4,8,-4},"
  .."{4,8,-4},{4,0,-4},{4,0,4},"
  .."{4,8,4},{-4,8,4},{-4,0,4}}}"
 local st_vrtx=#(mdl.vrtx)
 local _mdl=tbl_parse(cub)
printh("add_cube:"..table_to_str(_mdl))
 add_model(_mdl)
 ed_vrtx=#(mdl.vrtx)-1
 local selvrtx={}
 for k=st_vrtx,ed_vrtx do
  add(selvrtx,k+1)
 end
 ivrtx=selvrtx
 updstate=us_editvrtx
end

-- add mdl vrtx to world vrtx
-- update polygone vrtx index
function add_model(_mdl)
 local st_vrtx,st_poly=
  #(mdl.vrtx),#(mdl.polys)
 for k,v in pairs(_mdl.vrtx) do
	 mdl.vrtx[k+st_vrtx]=v
 end
 for poly in all(_mdl.polys) do
  for k,p in pairs(poly) do
	  if k<#poly then
 	  poly[k]=p+st_vrtx
 	 end
  end
  add(mdl.polys,poly)
 end
end

-- test local clipin,clipout=0,1
function t_clip(
 v_pln,v_nrm,v_view,polyidx)
 local max_vrtx,nb_clip=
  #v_view,0
 local poly,v_in,v_out,n=
  {},{},{},#polyidx
  
 for k,pidx in pairs(polyidx) do
   poly[k]=v_view[pidx]
 end
 local pdot,res,d,last=
  v_dot(v_nrm,v_pln),{}
 
 for i=1,n+1 do
  local j,prevj=
   (i-1)%n+1,(i-2)%n+1
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

 if (#res>=3) return res
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

function del_face(selface)
 local polys=mdl.polys
	del(polys,polys[selface])
end
-->8
-- export / import

function export(mdl)
 -- format string
 local str=table_to_str(mdl)
 -- to clipboard
 printh(str,"@clip")
 sfx(0)
end

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
	 else
   str=str..val..","
	 end
	end
	if sub(str,#str,#str)=="," then 
	 str=sub(str,1,#str-1) 
 end
 return str.."}"
end

function import()
 -- from clipboard
 local past_str=stat(4)
 local _mdl=tbl_parse(past_str)
 export(_mdl)
 -- test vrtx/polys...
-- assert(_mdl.vrtx)
-- assert(_mdl)
-- assert(_mdl)
 mdl=_mdl
 update_normals(mdl)
end


-- import 
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

__gfx__
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110000000006000000060000000d000005dddd50000000000000dd500000dd500000000000000000000000000000000000000000000000000000000000000000
161000000006000000666000000000000dd0d0d00000000005dd00d005ddddd00000000000000000000000000000000000000000000000000000000000000000
1661000006666600066666000d050d000d0d0dd0000000000d0000d00dddddd00000000000000000000000000000000000000000000000000000000000000000
166610000066600000060000000000000dd0d0d0000000000d0000d00dddddd00000000000000000000000000000000000000000000000000000000000000000
166661000006000000060000000d00000d0d0dd0000000000d00dd500ddddd500000000000000000000000000000000000000000000000000000000000000000
1166100002222200022222000000000005dddd500000000005dd000005dd00000000000000000000000000000000000000000000000000000000000000000000
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006600000000000000000000000000005dddd500000000005dd000005dd00000000000000000000000000000000000000000000000000000000000000000000
006006000006000000060000000d00000d0d0dd0000000000d00dd500ddddd500000000000000000000000000000000000000000000000000000000000000000
006006000006000000666000000000000dd0d0d0000000000d0000d00dddddd00000000000000000000000000000000000000000000000000000000000000000
0006600006666600066666000d050d000d0d0dd0000000000d0000d00dddddd00000000000000000000000000000000000000000000000000000000000000000
000006000066600000060000000000000dd0d0d00000000005dd00d005ddddd00000000000000000000000000000000000000000000000000000000000000000
000000600222220002222200000d000005dddd50000000000000dd500000dd500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020002000000000000000000000f000005ffff50000000000000ff500000ff500000000000000000000000000000000000000000000000000000000000000000
222022200000000000000000000000000ff0f0f00000000005ff00f005fffff00000000000000000000000000000000000000000000000000000000000000000
0222220000000000000000000f050f000f0f0ff0000000000f0000f00ffffff00000000000000000000000000000000000000000000000000000000000000000
002220000000000000000000000000000ff0f0f0000000000f0000f00ffffff00000000000000000000000000000000000000000000000000000000000000000
022222000000000000000000000f00000f0f0ff0000000000f00ff500fffff500000000000000000000000000000000000000000000000000000000000000000
2220222000000000000000000000000005ffff500000000005ff000005ff00000000000000000000000000000000000000000000000000000000000000000000
02000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88808880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88808880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
70000000777007707000770077707770000000000000000000000000000000011088800000000000000000000000000000000000000000000000000000000001
07000000700070707000707070007070000000000000000000000000000000011008000000000000000000000000000000000000000000000000000000000001
00700000770070707000707077007700000000000000000000000000000000011008000000000000000000000000000000000000000000000000000000000001
07000000700070707000707070007070000000000000000000000000000000011008000000000000000000000000000000000000000000000000000000000001
70000000700077007770777077707070000000000000000000000000000000011008000000000000000000000000000000000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
70000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
07000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
00700000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
07000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
70000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000008686666666666686800000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000086666666666666666666666666666666666666680000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000066600000000000000000000000000000000006660000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000060066000000000000000000000000000000660060000000000011000000000000000000000006060000000000060600000000000000000000001
10000000000600000660000000000000000000000000066000006000000000011000000000000000000000008686666666666686800000000000000000000001
10000000000600000006600000000000000000000006600000006000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000600000000086666666666666666666680000000006000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000600000000060000000000000000000060000000006000000000011000000000000000000000000000000000000000000000000000000000000001
10000000006000000000600000000000000000000006000000000600000000011000000000000000000000000000000000000000000000000000000000000001
10000000006000000000600000000000000000000006000000000600000000011000000000000000000000000000000000000000000000000000000000000001
10000000006000000000600000000000000000000006000000000600000000011000000000000000000000000000000000000000000000000000000000000001
10000000006000000000600000000000000000000006000000000600000000011000000000000000000000000000000000000000000000000000000000000001
10000000060000000006000000000000000000000000600000000060000000011000000000000000000000000000000000000000000000000000000000000001
10000000060000000006000000000000000000000000600000000060000000011000000000000000000000000000000000000000000000000000000000000001
10000000060000000006000000000000000000000000600000000060000000011000000000000000000000000000000000000000000000000000000000000001
10000000060000000006000000000000000000000000600000000060000000011000000000000000000000000000000000000000000000000000000000000001
10000000600000000060000000000000000000000000060000000006000000011000000000000000000000000000000000000000000000000000000000000001
10000000600000000060000000000000000000000000060000000006000000011000000000000000000000000000000000000000000000000000000000000001
10000000600000000060000000000000000000000000060000000006000000011000000000000000000000000000000000000000000000000000000000000001
10000000600000000060000000000000000000000000060000000006000000011000000000000000000000000000000000000000000000000000000000000001
10000006000000000600000000000000000000000000006000000000600000011000000000000000000000000000000000000000000000000000000000000001
10000006000000006866666666666666666666666666668600000000600000011000000000000000000000000000000000000000000000000000000000000001
10000006000000660000000000000000000000000000000066000000600000011000000000000000000000000000000000000000000000000000000000000001
10000006000066000000000000000000000000000000000000660000600000011000000000000000000000000000000000000000000000000000000000000001
10000060006600000000000000000000000000000000000000006600060000011000000000000000000000000000000000000000000000000000000000000001
10000060660000000000000000000000000000000000000000000066060000011000000000000000000000000000000000000000000000000000000000000001
10000086666666666666666666666666666666666666666666666666680000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10888000000000000000000000000000000000000000000000000000000000011008800000000000000000000000000000000000000000000000000000000001
10800000000000000000000000000000000000000000000000000000000000011080000000000000000000000000000000000000000000000000000000000001
10880000000000000000000000000000000000000000000000000000000000011088800000000000000000000000000000000000000000000000000000000001
10800000000000000000000000000000000000000000000000000000000000011000800000000000000000000000000000000000000000000000000000000001
10800000000000000000000000000000000000000000000000000000000000011088000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000086666666800000000000011000000000000000000000000086666666666680000000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000000060000000000060000000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000000060000000000006000000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000000600000000000006000000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000000600000000000006000000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000000600000000000006000000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000000600000000000000600000000000000000000001
10000000000000000000000000000000000000000060000000600000000000011000000000000000000000006000000000000000600000000000000000000001
10000000000000000000000000000000000000000086666666800000000000011000000000000000000000008666666666666666800000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000001
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
000200003c05335053300532c0532905326053220531e0531a0531705313053110530d0530a053070530405300003000030000100001000000000000000000000000000000000000000000000000000000000000
0114000009450184502c450150500c05007050040500305005050046500765007250077500875009750097500a7500975009750097500b7500f750167501975019750167501a75017750167501b750127500e750
000200000a170131701a1701e1701f1601e1601d1601a150171500f14005130001300010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
