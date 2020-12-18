pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- 3d model editor
-- @yourykiki

-- rotate selection ?
-- draw grid

-- c_3d on a sphere look at 0,0,0
-- or moving camera
-- token war ----------------
-- ed tools refactor

local c_top,c_side,c_front,c_3d,
 mdl,mrk_mdl,c_current,ivrtx,
 toolb,modal,ctx_mnu,pmb,colpick,
 inearvrtx,inearnormal,selface,
 newelt,selnode
local top,sid,fro,normals,
 normcnt,lastcol,mdlstate,
 istate,rotcapt,poly2node,
 dtw,dth=
 {1,3},{1,2},{3,2},{},
 {},84,{},
 0,false,{},
 64,60
local v_up={0,1,0}

--0 no selection
--1 mouse select begin
--2 mouse select end
--3 move with keyb
--  or drag with mouse
local updstate,
 us_noselect,
 us_select,
 us_edit,
 us_add,
 us_link,
 us_child=0,0,1,2,3,4,5

local mousemode,
 mm_point,
 mm_drag,
 drag_orig=0,0,1

local ed_vrtx,ed_face,ed_capt,ed_node=
 "vrtx","face","capt","node"
local ed_tool={name=ed_vrtx}

local render,
 r_wire,
 r_flat=0,0,1

local addvol_mnu={
 { caption="add cube",
   onclick=function()
    add_prism(4,c_current)
   end
 },
 { caption="add pent prism",
   onclick=function()
    add_prism(5,c_current)
   end
 },
 { caption="add hex prism",
   onclick=function()
    add_prism(6,c_current)
   end
 }
}

local del_mnu={
 { caption="delete selection",
   onclick=function()
    del_vrtx(ivrtx,mdl)
    ivrtx={}
    inearvrtx=nil
    updstate=us_noselect
    pushmodel(mdl)
   end
 },
 { caption="dupl. selection",
   onclick=function()
    duplicate(ivrtx)
    pushmodel(mdl)
   end
 }
}
function getaddmnu(lbl)
 return {
  { caption="add "..lbl,
    onclick=function()
     newelt={}
     updstate=us_add
    end
  }
 }
end
function getendmnu(lbl)
 local add_elt
 if lbl=="link" then
  add_elt=function()end
 elseif lbl=="face" then
  add_elt=add_face
 else
  add_elt=add_node
 end
 return {
  { caption="accept "..lbl,
    onclick=function()
     add_elt()
     updstate=us_noselect
     pushmodel(mdl)
    end
  },
  { caption="cancel",
    onclick=function()
     newelt=nil
     --restore last mdl state
     mdl=pop_model(0)
     updstate=us_noselect
    end
  }
 }
end
local delnodmnu={
 { caption="delete nodes",
   onclick=function()
    del_node()
    --selnode=nil--seems useless
    pushmodel(mdl)
   end
 },
 { caption="link nodes",
   onclick=function()
    updstate=us_link
   end
 },
 { caption="add child",
   onclick=function()
    updstate=us_child
   end
 }
}
function _init()
 -- devkit mode/mouse
 poke(0x5f2d,1)
 -- init cam
 c_top,c_side,c_front,c_3d=
  init_cam("t",64, 8,top),
  init_cam("s",64,68,sid),
  init_cam("f", 0,68,fro),
  init_cam("3d",0, 8)
 c_3d.proj=proj3d
 -- load default model
 mdl=make_cube()
 pushmodel(mdl)
 update_normals(mdl)
 mrk_mdl=make_marker()
 -- toolbar
 toolb=init_toolbar()
 -- default tool
 ed_tool.update=update_vrtx
 -- color picker
 colpick=init_col_picker()
 c_current=c_3d
 --init dith ramp
-- dith=tbl_parse("{0x0000,0x8000,0x8020,0xa020,0xa0a0,0xa4a0,0xa4a1,0xa5a1,0xa5a5,0xe5a5,0xa5b5,0xf5b5,0xf5f5,0xfdf5,0xfdf7,0xffff}")
 dith2=tbl_parse("{0x0000,0x0000,0x8020,0xc020, 0xc060,0xc070,0xe070,0xe470, 0xe472,0xf472,0xf4f2,0xf5f2, 0xf5fa,0xf7fa,0xf7fe,0xffff}")
end

function init_cam(name,vx,vy,ax)
 local camdst=16
 local res=tbl_parse("{roty=0,ang=0.25,vang=0,m={},focus=false,zoom=100,sel={x1=0,y1=0,x2=0,y2=0,a=false},p_vrtx={},p_normcnt={},view={w=64,h=60,x="..vx..",y="..vy..",tw=64,th=60,tx="..vx..",ty="..vy.."},pos={0,4,-"..camdst.."}}")
 res.name=name
 res.camdst=camdst
 res.ax=ax
 res.upd_m=function(self)
  local d=self.camdst
  self.pos[1]=-d*cos(self.ang)
  self.pos[3]= d*sin(self.ang)
  local m_vw=
   make_m_from_v_angle(v_up,self.ang)
  m_vw[13],m_vw[14],m_vw[15]=
   self.pos[1],self.pos[2],self.pos[3]
  m_qinv(m_vw)
  self.m=m_vw
 end
 res.proj=proj2d
 res.setfocus=function(self,mx,my)
  local v=self.view
  self.focus=
   v.x<mx and mx<=(v.x+v.w) and
   v.y<my and my<=(v.y+v.h)
 end
 res.drawsel=function(self)
  local sel=self.sel
  if sel.a then
   fillp(0x5a5a)
   rect(sel.x1,sel.y1,
    sel.x2,sel.y2,0x57)
   fillp()
  end
 end
 res.draworig=function(self)
  local pos,w,h=
   self.pos,self.view.w,self.view.h
  local x,y=
   mid(1,w/2+pos[1],w-2),
   mid(1,h/2+pos[2],h-2)
  line(x,y,x,y,7)
 end
 res.startselect=function(self,mx,my)
  local sel,view=self.sel,self.view
  sel.x1,sel.y1,
  sel.x2,sel.y2, sel.a=
   mx-view.x,my-view.y,
   mx-view.x,my-view.y, true
 end
 res.updselect=function(self,mx,my)
  local sel,view=self.sel,self.view
  sel.x2,sel.y2=mx-view.x,my-view.y
 end
 res.endselect=function(self)
  self.sel.a=false
  self:sortsel()
 end
 res.selectnode=function(self)
  local _selface=self:selectelt(
   inearnormal,self.p_normcnt)
  local _selnode={}
  for iface in all(_selface) do
   local nod=poly2node[iface] 
   if not inarray(_selnode,nod)then
    add(_selnode,nod)
   end
  end
  return _selface,_selnode
 end
 res.selectelt=function(self,inearelt,listelt)
  local _selelt,sel={},self.sel
  if sel.x1==sel.x2 and
     sel.y1==sel.y2 then
   return {inearelt}
  end
  for k,v in pairs(listelt) do
   if self:vinsel(v) then
    add(_selelt,k)
   end
  end
  return _selelt
 end
 res.vinsel=function(self,v)
  local sel,vx,vy=self.sel,
   v[1],v[2]   
  return isinside(vx,vy,
   sel.x1,sel.x2,sel.y1,sel.y2)
 end
 res.sortsel=function(self)
  local sel=self.sel
  if sel.x1>sel.x2 then
   sel.x1,sel.x2=sel.x2,sel.x1
  end
  if sel.y1>sel.y2 then
   sel.y1,sel.y2=sel.y2,sel.y1
  end
 end
 res.moveselvrtx=function(self,bl,br,bu,bd,vrtx)
  local ax=self.ax
  if (not ax) return 
  for i in all(ivrtx) do
   if (bl) vrtx[i][ax[1]]-=1
   if (br) vrtx[i][ax[1]]+=1
   if (bu) vrtx[i][ax[2]]+=1
   if (bd) vrtx[i][ax[2]]-=1
  end
  if bl or br or bu or db then
   pushmodel(mdl)
  end
 end
 res.movedragselvrtx=function(self,dx,dy,vrtx)
  if (not ax) return
  for i in all(ivrtx) do
   vrtx[i][ax[1]]+=dx
   vrtx[i][ax[2]]-=dy
  end
 end
 res.nearselvrtx=function(self,mx,my)
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
 end
 res.near_vrtx=function(self,mx,my)
  inearvrtx=
   isin2dvec(
    self.view,
    mx,my,
    self.p_vrtx)
 end
 res.near_normals=function(self,mx,my)
  inearnormal=
   isin2dvec(
    self.view,
    mx,my,
    self.p_normcnt)
 end
 res.update=function(self)
  local view=self.view
  view.w,view.h,view.x,view.y=
   lerp(view.w,view.tw,0.6),
   lerp(view.h,view.th,0.6),
   lerp(view.x,view.tx,0.6),
   lerp(view.y,view.ty,0.6)
  view.halfw,view.halfh=
   view.w/2,view.h/2
 end
 return res
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
 local noop={icon=6,onclick=function()end}
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
   {icon=9,
    onclick=function()
     if #mdlstate>1 then
      mdl=pop_model()
      refreshpolyinfo()
      reset_tool()
     end
    end,
    tgl=function()
     return #mdlstate>1
    end
   },
   {icon=10,
    onclick=function()
     if istate<#mdlstate then
      mdl=pop_model(1)
      refreshpolyinfo()
      reset_tool()
     end
    end,
    tgl=function()
     return istate<#mdlstate
    end
   },
   noop,
   {icon=3,
    onclick=function()
     selecttool(ed_vrtx,update_vrtx)
    end,
    tgl=function()
     return ed_tool.name==ed_vrtx
    end
   }, 
   {icon=4,
    onclick=function()
     selecttool(ed_face,update_face)
     reset_tool()
    end,
    tgl=function()
     return ed_tool.name==ed_face
    end
   },
   {icon=12,
    onclick=function()
     selecttool(ed_node,update_node)
    end,
    tgl=function()
     return ed_tool.name==ed_node
    end
   },
   {icon=5,
    onclick=function()
     selecttool(ed_capt,update_capt)
    end,
    tgl=function()
     return ed_tool.name==ed_capt
    end
   },
   noop,
   {icon=7,
    onclick=function()
     render=r_wire
    end,
    tgl=function()
     return render==r_wire
    end
   },
   {icon=8,
    onclick=function()
     render=r_flat
    end,
    tgl=function()
     return render==r_flat
    end
   },
   noop,
   {icon=11,
    onclick=function()
     rotcapt=not rotcapt
    end,
    tgl=function()
     return rotcapt
    end
   },
   {icon=13,
    onclick=function()
     if dtw==64 then
      dtw,dth=129,121
     else
      dtw,dth=64,60
     end
    end,
    tgl=function()
     return dtw==129
    end
   }
  },
  update=update_actions,
  draw=function(self,c_current)
   rectfill(0,0,127,7,8)
   draw_icons(self)
   local zm=c_current.zoom
   print((zm\1).."%",108,1,15)
   --print("∧"..stat(1),64,1,15)
  end
 }
end

function selecttool(name,fun)
 ed_tool.name=name
 ed_tool.update=fun
 reset_tool()
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
  colsel={},
  colchange=false,
  actions={
   {icon=32,
    onclick=function()
     del_face(selface,mdl)
     selface=nil
    end,
   },
   {icon=33,
    onclick=function()
     inv_face(selface)
    end,
   }
  },
  isinside=function(self,mx,my)
   return isinside(mx,my,
    0,127,128-self.h,127)
  end,
  update=function(self,mx,my,mb,dw)
   --change color
   self.colchange=false
   local y=128-self.h
   local colsel=self.colsel
   colsel[0],colsel[1]=nil,nil

   if isinside(mx,my,28,124,y+9,y+13) then
    colsel[0]=(mx-28)\6
   elseif isinside(mx,my,28,124,y+16,y+20) then
    colsel[1]=(mx-28)\6
   else
    update_actions(self,mx,my,mb,dw,4,y+22)
   end
   --btn pressed
   if m_pressed(mb,1) then
    if colsel[0] then
     self.col=
      (self.col&0xf0)|colsel[0]
    elseif colsel[1] then
     self.col=
      (self.col&0x0f)|(colsel[1]<<4)
    end
    lastcol=self.col
    self.colchange=true
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
     self.col&0x0f,
    (self.col&0xf0)>>4
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
     if self.colsel[j]==i then
      fillp(▒)
      rect(27+xoff,y+8+yoff,
       33+xoff,y+14+yoff,15)
      fillp()
     end
    end
   end
   --
   draw_icons(self,4,y+22)
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
 -- update cam view port
 c_3d:update()
 c_top:update()
 c_side:update()
 c_front:update()

 -- toolbar
 toolb:update(mx,my,mb,dw)
 -- modal
 if modal then
  modal:update(mx,my,mb)
  return
 end
 
 -- move cam
 if c_current then
  if m_pressed(mb,4) then
   drag_orig={mx,my}
  elseif mb&4==4 then
   local dx,dy=
    mx-drag_orig[1],
    my-drag_orig[2]
   if c_current.name=="3d" then
    move_3dcam(dx/0.05,dy/4)
   else
    move_2dcam(dx,dy)
   end
   drag_orig={mx,my}
   return
  end
 end

 -- 3d cam size
 local view=c_3d.view
 view.tw,view.th=dtw,dth
 -- handle edition tool
 ed_tool.update(mx,my,mb,dw)
 update_normals(mdl)
 
 -- 3d
 if c_current.name=="3d" then
  local ta,dy=0,0
  if (btn(⬅️)) ta=0.02
  if (btn(➡️)) ta=-0.02
  if (btn(⬆️)) dy=1
  if (btn(⬇️)) dy=-1
  c_3d.vang=lerp(c_3d.vang,ta,0.6)
  move_3dcam(c_3d.vang,dy) 
 end

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
 local vert,w,h,zm,ax,pos={},
  self.view.w/2,
  self.view.h/2,
  self.zoom/100,
  self.ax,
  self.pos
 for i=1,#vrtx do 
  local pnt=vrtx[i]
  vert[i]={
   pos[1]+pnt[ax[1]]*zm+w,
   pos[2]-pnt[ax[2]]*zm+h
  }
 end
 return vert
end
function proj3d(self,vrtx)
 local vert,ww,hh=
  {},self.view.halfw,
  self.view.halfh
 
 for i,v in pairs(vrtx) do 
  local w=ww/v[3]
  vert[i]={
   ww+w*v[1],
   hh-w*v[2]
  }
 end
 return vert
end

function update_vrtx(mx,my,mb,dw)
 -- btn state
 local bl,br,bu,bd=
   btn(⬅️),btn(➡️),
   btn(⬆️),btn(⬇️)
 
 -- 
 c_current:near_vrtx(mx,my)
 --
 if updstate==us_noselect then
  update_focus(mx,my)
  if mb&1==1 then
   -- store mx,my start
   c_current:startselect(mx,my)
   updstate=us_select
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,addvol_mnu)
  end

 elseif updstate==us_select then
  c_current:updselect(mx,my)
  if mb&1==0 then
   -- store mx,my end
   c_current:endselect()
   ivrtx=c_current:selectelt(
    inearvrtx,c_current.p_vrtx)
   -- check if vrtx selected
   if #ivrtx>0 then
    updstate=us_edit
   else
    updstate=us_noselect
   end
  end
  
 elseif updstate==us_edit then
  local nearsel=c_current:nearselvrtx(mx,my)
  if mousemode==mm_point then
   update_focus(mx,my)
   if m_pressed(mb,2) and not ctx_mnu then
    ctx_mnu=init_context_mnu(mx,my,del_mnu)
   end
   if (ctx_mnu) return
  elseif mousemode==mm_drag then
   dx,dy=mx-drag_orig[1],
         my-drag_orig[2]
   c_current:movedragselvrtx(
     dx,dy,mdl.vrtx)
   drag_orig={mx,my}
   -- 
   if mb&1==0 then
    mousemode=mm_point
    pushmodel(mdl)
    return
   end
  end
  -- move with keys
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
	 if colpick.colchange then
	  for v in all(selface) do
  	 local poly=mdl.polys[v]
  	 if (poly) poly[#poly]=colpick.col
  	end
  	pushmodel(mdl)
 	end
	 return
	end

 if updstate==us_noselect then
  update_focus(mx,my)

  if mb&1==1 then
   -- store mx,my start
   c_current:startselect(mx,my)
   updstate=us_select
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,getaddmnu"face")
  end

 elseif updstate==us_select then
  c_current:updselect(mx,my)
  if mb&1==0 then
   -- store mx,my end
   c_current:endselect()
   selface=c_current:selectelt(
    inearnormal,c_current.p_normcnt)
   -- check if face selected
	  if selface and #selface>0 then
	   updstate=us_edit
	   update_colpick()
	  else
    updstate=us_noselect
   end
  end
 elseif updstate==us_edit then
  update_focus(mx,my)
  -- color handled by color picker
  if m_pressed(mb,1) then
   updstate=us_noselect
  end
 elseif updstate==us_add then
  -- 
  c_current:near_vrtx(mx,my)
  if m_pressed(mb,1) then
   add(newelt,inearvrtx)
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,
    getendmnu"face")  
  end
 end
end

function update_colpick()
 for v in all(selface) do
  local poly=mdl.polys[v]
  colpick.col=poly[#poly]
 end
end

function update_capt(mx,my,mb,dw)
 update_focus(mx,my)
 if (rotcapt) c_3d.ang+=0.005
end

function update_node(mx,my,mb,dw)

 if updstate==us_noselect then
  update_focus(mx,my)
  c_current:near_normals(mx,my)
 
  if mb&1==1 then
   -- store mx,my start
   c_current:startselect(mx,my)
   updstate=us_select
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,getaddmnu"node")
  end
 elseif updstate==us_select then
  c_current:updselect(mx,my)
  if mb&1==0 then
   -- store mx,my end
   c_current:endselect()
   facenod,selnode=c_current:selectnode()

   -- check if node selected
   if selnode and #selnode>0 then
    updstate=us_edit
   else
    updstate=us_noselect
   end
  end
 elseif updstate==us_edit then
  update_focus(mx,my)
  if m_pressed(mb,1) then
   updstate=us_noselect
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,delnodmnu)
  end
 elseif updstate==us_link then
  c_current:near_normals(mx,my)
  if m_pressed(mb,1) then
   --toggle link
   c_current:startselect(mx,my)
   local f,n=c_current:selectnode()
   if #n>0 then
    link_nodes(selnode[1],facenod[1],
     n[1],f[1])
   end
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,
    getendmnu"link")
  end
 elseif updstate==us_child then
  c_current:near_normals(mx,my)
  if m_pressed(mb,1) then
   --toggle link
   c_current:startselect(mx,my)
   local f,n=c_current:selectnode()
   if #n>0 then
    link_child(selnode[1],n[1])
   end
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,
    getendmnu"link")
  end
 elseif updstate==us_add then
  --near face
  c_current:near_normals(mx,my)
  if m_pressed(mb,1) then
   add(newelt,inearnormal)
  elseif m_pressed(mb,2) and not ctx_mnu then
   ctx_mnu=init_context_mnu(mx,my,
    getendmnu"node") 
  end
 end
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
 if selface and #selface>0 then
  colpick:draw()
 end
 spr(0,stat(32)-1,stat(33)-1)
 --if (curinod) print("curinod "..curinod,0,12,7)
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

 local iscam3d,toolname=
  cam.name=="3d",ed_tool.name
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

  -- determine poly draw order
  local vispolys={}
  curinod=selnode and selnode[1] 
   or getcurinod(c_3d.pos,curinod)
  if curinod then
   prepare_polys(v_wrld,v_view,
    curinod,{},vispolys)--cam.view)
  else
   --no nodes structure, z-sort
   vispolys=shellsort(
    cullnclip(v_wrld,v_view,vispolys)
   )
  end
  
  --proj,including vrtx from clip
  vrtx=c_3d:proj(v_view)
  c_3d.p_vrtx=vrtx
  -- and finally
  draw_polys(vispolys,vrtx)
  
  -- draw normals and stuffs
  pnormals=_normcnt
  cam.p_normcnt=pnormals
  
  if toolname~=ed_capt then
   draw_circ({pnormals[inearnormal]},15)
   if selface then
    for v in all(selface) do
     draw_circ({pnormals[v]},7)
    end
   end
   --
   draw_selected_vrtx(vrtx,v_view)
   draw_visible_vrtx(vrtx,v_view,5)
   draw_visible_vrtx(pnormals,v_vwcnt,8)
   if toolname==ed_face then
    draw_newface(vrtx)
   elseif toolname==ed_node then
    if newelt then
     draw_visible_vrtx(
      pnormals,v_vwcnt,11,
      newelt,inarray)
    end
    draw_visible_vrtx(
     pnormals,v_vwcnt,13,poly2node,inkey)
   end
  end
  --print("#vispolys "..#vispolys)
 else 
  -- 2d wire rendering
  vrtx=cam:proj(vrtx)
  cam.p_vrtx=vrtx
  draw_polys_wire(vrtx,mdl.polys)
  draw_selected_vrtx(vrtx)
  -- draw all vertex
  draw_points(vrtx,5)
  cam:draworig()
  if toolname==ed_face then
   draw_newface(vrtx)
  end
 end
 --
 cam:drawsel()
 if (cam.focus) then
  rect(0,0,vport.w-1,vport.h-1,7)
 end
 print(cam.name,2,2,6)
 clip()
end

function draw_newface(vrtx)
 if (not newelt) return
 local lv=vrtx[newelt[#newelt]]
 for i=1,#newelt do
  local v=vrtx[newelt[i]] 
  line(lv[1],lv[2],v[1],v[2],11)
  lv=v
 end
end

function draw_polys_wire(vrtx,polys,col)
 col=col or 6
 for poly in all(polys) do
  -- convert poly with vrtx idx
  -- to poly with vrtx coord
  local _poly={}
  for i=1,#poly-1 do
   _poly[i]=vrtx[poly[i]]
  end
  draw_wire(_poly,col)
 end
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

function draw_visible_vrtx(vrtx,v_view,col,filter,fun)
 -- draw all vertex
 local visvrtx,filtered=
  {},filter~=nil
 for k,v in pairs(vrtx) do
  if isvrtxvisible(v_view,k) 
   and (not filtered
        or fun(filter,k)) then
   add(visvrtx,v)
  end
 end
 draw_points(visvrtx,col)
end
function isvrtxvisible(v_view,iv)
 return not v_view
  or v_view[iv][3]>0
end
--_poly=polygon with vertx coord
function draw_wire(_poly,col)
 local v1,v2=_poly[#_poly]
 for v in all(_poly) do
  v2,v1=v1,v
  line(v1[1],v1[2],v2[1],v2[2],col)
 end
end

-- check visibility
function cullnclip(v_wrld,v_view,polysorted)
 local vispolys={}
 if #polysorted==0 then
  --z sorted
  for k,poly in pairs(mdl.polys) do
   _cullnclip(v_wrld,v_view,k,poly,vispolys)
  end
 else
  --node sorted
  for k in all(polysorted) do
   local poly=mdl.polys[k]
   _cullnclip(v_wrld,v_view,k,poly,vispolys)
  end
 end
 return vispolys
end
function _cullnclip(v_wrld,v_view,k,poly,vispolys)
 local norm=normals[k]
 local vp=v_clone(v_wrld[poly[1]])
 v_add(vp,c_3d.pos,-1)

 -- backface culling
 local back,wire,nod=
  v_dot(norm,vp)<0,
  render==r_wire,0
   
 if ed_tool.name==ed_node then
  local p2nk,nodes=
   poly2node[k],
   mdl.nodes
  -- new node
  if (inarray(newelt,k)) nod=5
  -- in a node
  if (p2nk~=nil) nod=1
  -- selected node
  if (inarray(selnode,p2nk))nod=4
  if selnode then 
   _nod=nodes[selnode[1]]
   if _nod then
    -- adjacent nodes
    if (inarray(_nod.conn,p2nk)) nod=3
    -- child nodes
    if (inarray(_nod.child,p2nk)) nod=2
   end
  end
 end

 if back or wire or newnod or nod then
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
    z=max(z,v_view[iv][3])
   end
   add(vispolys,{
    poly=tc,
    col=poly[#poly],
    idx=k,
    key=1/z, --maxz
    vis=back,
    nod=nod
   })
  end
 end
end

function draw_polys(vispolys,vrtx)
 
 local wirepolys,nodetool=
  tbl_parse"{{},{},{},{},{}}",
  ed_tool.name==ed_node

 --light
 local lgt={1,-1,0} 
 v_normz(lgt)
 
 for objpoly in all(vispolys) do
-- for j=#vispolys,1,-1 do
--  local objpoly=vispolys[j]
  local poly,idx,col=
   objpoly.poly,
   objpoly.idx,
   objpoly.col
  local _poly,x,y={},0,0
  for i=1,#poly do
   add(_poly,vrtx[poly[i]])
   x+=vrtx[poly[i]][1]
   y+=vrtx[poly[i]][2]
  end
  --color and dither
  if render==r_flat and objpoly.vis then
   local ptn=v_dot(normals[idx],lgt)
   ptn=(ptn*8+8)\1
   fillp(dith2[ptn\1])
   polyfill(_poly,col)
  end
  if render==r_wire then
   draw_wire(_poly,6)
  end

  add(wirepolys[objpoly.nod],_poly)
  -- debug zsort
  --print(objpoly.key,x/#poly,y/#poly,7)
 end
 fillp()
 -- additional node tool infos
-- if (not nodetool) return
 local pcol=split"13,5,4,3,11"
 for i,col in pairs(pcol) do
  for _poly in all(wirepolys[i]) do
   draw_wire(_poly,col)
  end
 end
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

function reset_tool()
 ivrtx,selface=
  nil,nil
 updstate=us_noselect
end

function move_3dcam(dx,dy)
 -- make the cam move based
 -- on ang instead of models
 c_3d.ang-=dx
 c_3d.pos[2]+=dy
end

function move_2dcam(dx,dy)
 c_current.pos[1]+=dx
 c_current.pos[2]+=dy
end

-->8
--3d maths utils
--from @fsouchu
--[[local m4ident=
 {1,0,0,0, 
  0,1,0,0, 
  0,0,1,0, 
  0,0,0,1}
]]--
--[[function m_makerotx(a)
 return {
  1,0,     0,       0,
  0,cos(a),-sin(a), 0,
  0,sin(a),cos(a),  0,
  0,0,     0,       1 
 }
end]]--
function m_makeroty(a)
 return {
  cos(a),0,-sin(a), 0,
  0,     1,0,       0,
  sin(a),0,cos(a),  0,
  0,     0,0,       1 
 }
end
--[[function m_makerotz(a)
 return {
  cos(a),-sin(a),0,0,
  sin(a),cos(a),0,0,
  0,     0,     1,0,
  0,     0,     0,1
 }
end]]--
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

--[[function transform(lvrtx,px,py,pz,roty)
 local m_roty,m_tran=
  m_makeroty(roty),
  m_maketran(px,py,pz)

 m_wrld=m4ident
 m_wrld=m_x_m(m_wrld,m_tran)
 m_wrld=m_x_m(m_wrld,m_roty)
 for i,v in pairs(lvrtx) do
  lvrtx[i]=m_x_v(m_wrld,v)
 end
end]]--
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
local shell_gaps=split"701,301,132,57,23,10,4,1"
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
 --not mandatory,but fluent
 return a
end

-- morgan3d
-- https://www.lexaloffle.com/bbs/?tid=2477
--[[function heap_sort(data)
 local n=#data
if (n==0) return
 for i=flr(n/2)+1,1,-1 do
  local parent,value,m=i,data[i],i+i
  local key=value.key 

  while m<=n do
   if ((m<n) and (data[m+1].key>data[m].key)) m+=1
   local mval=data[m]
   if (key>mval.key) break
   data[parent]=mval
   parent=m
   m+=m
  end
  data[parent]=value
 end 

 for i=n,2,-1 do
  local value = data[i]
  data[i],data[1]=data[1],value

  local parent,terminate,m=1,i-1,2
  local key=value.key 
  while m<=terminate do
   local mval=data[m]
   local mkey=mval.key
   if (m<terminate) and (data[m+1].key>mkey) then
    m+=1
    mval=data[m]
    mkey=mval.key
   end
   if (key>mkey) break
   data[parent]=mval
   parent=m
   m+=m
  end  

  data[parent]=value
 end
end
]]--
-->8
--3d models
local col1=0x54
 
function make_cube()
 return tbl_parse("{polys={{1,2,3,4,84},{5,6,7,8,84},{8,7,2,1,84},{4,3,6,5,84},{7,6,3,2,84},{4,5,8,1,84}},walls={},vrtx={{-8,0,-4},{-6,8,-4},{6,8,-4},{8,0,-4},{8,0,4},{6,8,4},{-6,8,4},{-8,0,4}},nodes={}}")
end

function make_marker()
 return tbl_parse("{vrtx={{0,0,0},{10,0,0},{0,10,0},{0,0,10}},lins={{1,2},{1,3},{1,4}}}")
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
--[[function logarray(arr)
 color(7)
 printh(#arr)
 for k,v in pairs(arr) do
  printh("k="..k..",v="..v)
 end
end]]--

function add_all(a,b)
 for x in all(b) do
  add(a,x)
 end
end

function inarray(array,val)
 for k,v in pairs(array) do
  if (v==val) return true,k
 end
 return false
end

function inkey(array,k)
 return array[k]~=nil 
end

function lerp(v0,v1,prc)
 return (1-prc)*v0+prc*v1
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

function update_actions(self,mx,my,mb,dw,x,y)
 x,y=x or 0,y or 0
 self.sel=0
 --mouse over refactor isinside + div
 for i,act in pairs(self.actions) do
  bx1,bx2,by1,by2=
   i*7-6+x,i*7+1+x,0+y,7+y
  if bx1<mx and mx<=bx2 and
     by1<my and my<=by2 then
   self.sel=i
   if m_pressed(mb,1) then
    -- clicked
    act.onclick()
   end
  end
 end
end

function draw_icons(self,x,y)
 x,y=x or 0,y or 0
 for i,act in pairs(self.actions) do
  d=(i==self.sel) and 16 or 0
  if (act.tgl and act.tgl()) d=32
  spr(act.icon+d,i*7-6+x,y)
 end
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

function add_prism(nface,cam)
 local lvrtx,lpolys,face,
  top,bot,lcol,md,ax=
  {},{},{},{},{},lastcol,
  nface*2,cam.ax or c_front.ax
 for i=1,nface do
  local x,z=
   ( 6*cos(i/nface+1/md)+0.5)\1,
   (-6*sin(i/nface+1/md)+0.5)\1
  addvrtx(lvrtx,ax,x,z)
  add(bot,i*2)
  add(top,(nface+1-i)*2-1)
 end
 for i=1,nface+1 do
  local ev,od=(i*2-1)%md+1,(i*2-2)%md+1
  if #face==0 then
   face={ev,od}
  else
   add(face,od)
   add(face,ev)
  end
  if #face==4 then
   add(face,lcol)
   add(lpolys,face)
   face={ev,od}
  end
 end
 --top
 add(bot,lcol)
 add(lpolys,bot)
 add(top,lcol)
 add(lpolys,top)

 local lwalls={}
 
 _mdl={
  vrtx=lvrtx,
  polys=lpolys,
  walls=lwalls
 }
 
 local st_vrtx=#(mdl.vrtx)
 add_model(_mdl)
 local end_vrtx=#(mdl.vrtx)-1
 select_vrtx(st_vrtx,end_vrtx)
 pushmodel(mdl)
end

function select_vrtx(st_vrtx,end_vrtx)
 local selvrtx={}
 for k=st_vrtx,end_vrtx do
  add(selvrtx,k+1)
 end
 ivrtx=selvrtx
 updstate=us_edit
end

-- adapt to the camera axis
function addvrtx(lvrtx,ax,x,z)
 local nax={1,2,3}
 del(nax,ax[1])
 del(nax,ax[2])
 local axy=nax[1]
 if (axy==3) x,z=z,x
 local v1,v2={},{}
 --
 v1[ax[1]]=x
 v1[axy]=4
 v1[ax[2]]=z
 v2[ax[1]]=x
 v2[axy]=-4
 v2[ax[2]]=z
 --
 add(lvrtx,v1)
 add(lvrtx,v2)
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

function inv_face(selface)
 local polys=mdl.polys
 
 for v in all(selface) do
  local poly,new=polys[v],{}
 
  for i=#poly-1,1,-1 do
   add(new,poly[i])
  end
  polys[v]=new
  new[#poly]=poly[#poly]
 end
end

function del_face(selface,_mdl)
 local polys=_mdl.polys
 for i=#selface,1,-1 do
  local v=selface[i]
 	del(polys,polys[v])
 end
end

function del_vrtx(selvrtx,_mdl)
	local vrtx,polys=
	 _mdl.vrtx,_mdl.polys
	
	for i=#selvrtx,1,-1 do
	 local isv=selvrtx[i]
	 printh("del isv "..isv)
	 --delete vrtx
	 del(vrtx,vrtx[isv])
  for poly in all(polys) do
	  del_poly_vrtx(isv,poly)
	  dec_poly_vrtx(isv,poly)
 	end
 	-- in reverse to avoid testholes
 	for k=#polys,1,-1 do
  	poly=polys[k]
 	 --delete face
 	 if #poly<=3 then
 	  del_face({k},_mdl)
 	 end
  end
	end
	--debug
	--printh(table_to_str(_mdl))
end

function del_poly_vrtx(isv,poly)
 for j=1,#poly-1 do
  local iv=poly[j] 
  if iv==isv then
   del(poly,iv)
   return
  end
 end
end

function dec_poly_vrtx(isv,poly)
 for j=1,#poly-1 do
  local iv=poly[j]
  if iv>isv then
   --decrease >isv in polys
   poly[j]=iv-1
  end
 end
end

function add_face()
 local polys=mdl.polys
 add(polys,newelt)
 add(newelt,lastcol)
 newelt=nil
end

function add_node()
 local nodes,node=mdl.nodes,
  {polys=newelt,
   conn={},
   child={},
   prtl={}
  }
 add(nodes,node)
 newelt=nil
 refreshpolyinfo()
end

function del_node()
 for node in all(selnode) do
  --todo del conn in other nodes
  mdl.nodes[node]=nil
 end
 refreshpolyinfo()
end

function link_nodes(n1,f1,n2,f2)
 if n1!=n2 then
  local node1,node2=
   mdl.nodes[n1],mdl.nodes[n2]
  tgl_link(node1.conn,n2,
           node1.prtl,f1)
  tgl_link(node2.conn,n1,
           node2.prtl,f2)
 end
end

function link_child(parent,child)
 if parent!=child then
  tgl_link(
   mdl.nodes[parent].child,
   child)
 end
end

function tgl_link(conn,n,prtl,f)
 local inarr,offs=inarray(conn,n)
 offs=inarr and offs or #conn+1
 if not inarr then
  conn[offs]=n
 else
  conn[offs]=nil
 end
 if prtl then
  if inarr then
   prtl[offs]=nil
  else
   prtl[offs]=f
  end
 end
end

function getcurinod(pos,pinod)
 for i,n in pairs(nodeinfo) do
  if (n:inbound(pos)) return i 
 end
 return pinod
end

function prepare_polys(v_wrld,
  v_view,curinod,_w,polys)--d_area
 _w[curinod]=true
 local nodes=mdl.nodes
 local node=nodes[curinod]

 -- get farthest node...
 for k,inod in pairs(node.conn) do
  if not _w[inod] then
-- portal cull start --
--   portal=cullnclip(
--    v_wrld,
--    v_view,
--    {node.prtl[k]})
   --potentially visible ?
--   if #portal>0 then
--    local prtlvrtx={}
--    for v in all(portal.poly) do
--     add(prtlvrtx,vrtx[v])
--    end
--    c_3d:proj(prtlvrtx)
    --todo portal inside d_area
-- portal cull end   --
    prepare_polys(v_wrld,
     v_view,inod,_w,polys)
--   end
  end 
 end

 -- and add clipped polys
 -- (without sort)
 local vispoly=cullnclip(
  v_wrld,
  v_view,
  node.polys)
 add_all(polys,vispoly)
 
 -- add child (details in a node)
 for child in all(node.child) do
  --prepare with sort
  vispoly=shellsort(
   cullnclip(
    v_wrld,
    v_view,
    nodes[child].polys
   )
  )
  add_all(polys,vispoly)
 end
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
--export(_mdl)
 mdl=_mdl
 pushmodel(mdl)
 --
 refreshpolyinfo()
end

function refreshpolyinfo()
 poly2node={}
 for k,node in pairs(mdl.nodes) do
  for ipol in all(node.polys) do
   poly2node[ipol]=k
  end
 end
 nodeinfo={}
 for node in all(mdl.nodes) do
  for k in all(node.polys) do
   local poly=mdl.polys[k]
   --for each vrtx,last is color
   for i=1,#poly-1 do 
    local v=mdl.vrtx[poly[i]]
    minx=min(minx,v[1])
    miny=min(miny,v[2])
    minz=min(minz,v[3])
    maxx=max(maxx,v[1])
    maxy=max(maxy,v[2])
    maxz=max(maxz,v[3])
   end
  end
  add(nodeinfo,{
   minx=minx,
   miny=miny,
   minz=minz,
   maxx=maxx,
   maxy=maxy,
   maxz=maxz,
   inbound=function(self,p)
    return self.minx<=p[1]
     and p[1]<=self.maxx 
     and self.miny<=p[2]
     and p[2]<=self.maxy
     and self.minz<=p[3]
     and p[3]<=self.maxz
    end
  })
 end
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


function duplicate(selvrtx)
 local str=table_to_str(mdl)
 local _mdl=tbl_parse(str)
 --invert selection
 local othvrtx={}
 for iv=1,#(mdl.vrtx) do
  add(othvrtx,iv)
 end
 for iv in all(selvrtx) do
  del(othvrtx,iv)
 end
 --delete other vrtx
 del_vrtx(othvrtx,_mdl)
 local st_vrtx=#(mdl.vrtx)
 add_model(_mdl)
 local end_vrtx=#(mdl.vrtx)-1
 select_vrtx(st_vrtx,end_vrtx)
end

function pushmodel(mdl)
 local nbstate=#mdlstate
 while istate<#mdlstate do
  mdlstate[#mdlstate]=nil
 end
 add(mdlstate,table_to_str(mdl))
 istate=#mdlstate
end

function pop_model(z)
 z=z or -1
 istate=max(1,istate+z)
 local str=mdlstate[istate]
 return tbl_parse(str)
end
__gfx__
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110000000006000000060000000d000005dddd500dddddd0000000000000dd500000dd500000dd0000dd00000ddd00000ddd00000dd00dd00000000000000000
161000000006000000666000000000000dd0d0d00d0000d00000000005dd00d005ddddd00d0d00d00d00d0d000dd0d000d5d00000d0000d00000000000000000
1661000006666600066666000d050d000d0d0dd00d0000d0000000000d0000d00dddddd00dd000d00d000dd00d0d00d00dd50000000000000000000000000000
166610000066600000060000000000000dd0d0d00d0000d0000000000d0000d00dddddd00ddd00d00d00ddd00d0000d000005dd0000000000000000000000000
166661000006000000060000000d00000d0d0dd00d0000d0000000000d00dd500ddddd50000000d00d0000000d0000d00000d5d00d0000d00000000000000000
1166100002222200022222000000000005dddd500dddddd00000000005dd000005dd000000dddd0000dddd0000dddd000000ddd00dd00dd00000000000000000
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0000dd0000000000000000
0006600000000000000000000000000005dddd500d0d0d000000000005dd000005dd00000000000000000000000000000000ddd0d000000d0000000000000000
006006000006000000060000000d00000d0d0dd0000000d0000000000d00dd500ddddd500000dd0000dd00000ddd00000000d5d0000000000000000000000000
006006000006000000666000000000000dd0d0d00d000000000000000d0000d00dddddd00d0d00d00d00d0d000dd0d0000005dd0000000000000000000000000
0006600006666600066666000d050d000d0d0dd0000000d0000000000d0000d00dddddd00dd000d00d000dd00d0d00d00dd50000000000000000000000000000
000006000066600000060000000000000dd0d0d00d0000000000000005dd00d005ddddd00ddd00d00d00ddd00d0000d00d5d0000000000000000000000000000
000000600222220002222200000d000005dddd5000d0d0d0000000000000dd500000dd5000dddd0000dddd0000dddd000ddd0000d000000d0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0000dd0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020002000080000000000000000f000005ffff500ffffff0000000000000ff500000ff500000ff0000ff00000fff00000fff00000ff00ff00000000000000000
222022200888880000000000000000000ff0f0f00f0000f00000000005ff00f005fffff00f0f00f00f00f0f000ff0f000f5f00000f0000f00000000000000000
0222220000800080000000000f050f000f0f0ff00f0000f0000000000f0000f00ffffff00ff000f00f000ff00f0f00f00ff50000000000000000000000000000
002220000000000000000000000000000ff0f0f00f0000f0000000000f0000f00ffffff00fff00f00f00fff00f0000f000005ff0000000000000000000000000
022222000200020000000000000f00000f0f0ff00f0000f0000000000f00ff500fffff50000000f00f0000000f0000f00000f5f00f0000f00000000000000000
2220222000222220000000000000000005ffff500ffffff00000000005ff000005ff000000ffff0000ffff0000ffff000000fff00ff00ff00000000000000000
02000200000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000800002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88808880022222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888800002000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888800080008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88808880008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
8888688888868888888888888d88885dddd58ffffff88888888888dd58888ff588888888888888888888888888888888888888888888ff88fff8fff8f8f88888
888868888866688888888888888888dd8d8d8f8888f888888885dd88d85fffff888888888888888888888888888888888888888888888f8888f8f8f888f88888
88666668866666888888888d858d88d8d8dd8f8888f88888888d8888d8ffffff888888888888888888888888888888888888888888888f888ff8f8f88f888888
888666888886888888888888888888dd8d8d8f8888f88888888d8888d8ffffff888888888888888888888888888888888888888888888f8888f8f8f8f8888888
8888688888868888888888888d8888d8d8dd8f8888f88888888d88dd58fffff588888888888888888888888888888888888888888888fff8fff8fff8f8f88888
8822222882222288888888888888885dddd58ffffff888888885dd88885ff8888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11666166111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11116161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11166161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11116161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11666166611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111ffff11111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111f222f222f222f222f222f2221111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111ffffffffffffffffffffffffff111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111f222f222f222f222f222f222f2211111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111fffffffffffffffffffffffffffff1111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111222f222f222f222f222f222f222f222111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111fffffffffffffffffffffffffffffffff11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111f222f662f222f222f222f222f222f222f222111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111fffff6666fffffffffffffffffffffffffffff11111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111122226666662222222222222222222222222222f1111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f266666666f2f2f2f2f2f2f2f2f2f2f2f2f2f21111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112266666666662222222222222222222222222221111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111f6666666666662f2f2f2f2f2f2f2f2f2f2f2f2f1111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111116666666666666622222222222222222222222221111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111116666666666666666f2f2f2f2f2f2f2f2f2f2f2f21111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111116666666666666622222222222222222222662221111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111f6666666666662f2f2f2f2f2f2f2f2f2f66662f1111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112266666666662222222222222222222266666621111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f266666666f2f2f2f2f2f2f2f2f2f2666666661111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112222666666222222222222222222226666666666111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111f2f2f66662f2f2f2f2f2f2f2f2f2f66666666666611111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112222226622222222222222222222666666666666661111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f2f2f2f2f2f2f2f2f2f2f2f2f2f666666666666611111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112222222222222222222222222222266666666666111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111f2f2f2f2f2f2f2f2f2f2f2f2f2f2f26666666661111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112222222222222222222222222222222666666621111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f66666621111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112222222222222222222222222222222226666221111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f266f2f1111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111122222226622222222222266222222222222222211111111111111111111111111111111111111111111
111111111111111111111111111111111111111111112f2f2f26666f2f2f2f2f26666f2f2f2f2f2f2f2f11111111111111111111111111111111111111111111
11111111111111111111111111111111111111111112222222666666222222226666662222222222222111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111f2f2f2f666666662f2f2f666666662f2f2f2f2f2f111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111222222266666666662222666666666622222222221111111111111111111111111111111111111111111111
11111111111111111111111111111111111111112f2f2f2666666666666f2666666666666f2f2f2f2f1111111111111111111111111111111111111111111111
11111111111111111111111111111111111111122222226666666666666666666666666666222222221111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111f2f2f66666666666666666666666666666f2f2f2f11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111112222266666666666666666666666666666222222211111111111161111111111111111111111111111111111
11111111111111111111111111111111111111112f2f2f66666666666666666666666666662f2f2f111111111111166111111111111111111111111111111111
11111111111111111111111111111111111111111222226666666666666626666666666662222222111111111111166611111111111111111111111111111111
111111111111111111111111111111111111111112f2f266666666666662f6666666666662f2f2f1111111111111166661111111111111111111111111111111
11111111111111111111111111111111111111111222222666666666666226666666666662222221111111111111116611111111111111111111111111111111
1111111111111111111111111111111111111111112f2f2666666666666f2f66666666666f2f2f11111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111122222666666666662222666666666622222211111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111f2f2f26666666666f2f2f666666666f2f2f111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111112222266666666662222266666666622222111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111f2f2f666666666f2f2f266666666f2f2f1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111112222226666666622222226666666222221111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111f2f2f666666662f2f2f266666662f2f11111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111222226666666222222226666662222211111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111f2f2f6666662f2f2f2f2666662f2f111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111122222666666222222222666662222111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111112f2f2666662f2f2f2f2f66662f2f1111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111122222666622222222222666222f1111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f2f26666fffffffffff666ffff1111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f222f662f222f222f2266222f21111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111ffffff66fffffffffffff6fffff1111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111122f2226622f222f222f222f222f2111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111ffffffffffffffffffffffffffff111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111112f222f222f222f222f222f222f22111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111fffffffffffffffffffffffffffff111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111222f222f222f222f222f222f222f2111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111fffffffffffffffffffffffffffff111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111122f222f222f222f222f222f222f22211111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111ffffffffffffffffffffffffffffff11111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111222f222f222f222f222f222f222f2211111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111ffffffffffffffffffffffffffffff11111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111122f222f222f222f222f222f222f22211111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111ffffffffffffffffffffffffffffff11111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111222f222f222f222f222f222f222f2221111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111ffffffffffffffffffffffffffffffff1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111222f222f222f222f222f222f222f222f1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111ffffffffffffffffffffffffffffffff1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111f222f222f222f222f222f222f222f2221111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111ffffffffffffffffffffffffffffffff1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111222f222f222f222f222f222f222f222f2111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111fffffffffffffffffffffffffffffffff111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111f222f222f222f222f222f222222222222111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111ffffffffffff222f222f222f222f222f1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111222222222222222222222222222222221111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111ff222f222f222f222f222f222f222f2221111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111f222222222222222222222222222222221111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
000200003c05335053300532c0532905326053220531e0531a0531705313053110530d0530a053070530405300003000030000100001000000000000000000000000000000000000000000000000000000000000
0114000009450184502c450150500c05007050040500305005050046500765007250077500875009750097500a7500975009750097500b7500f750167501975019750167501a75017750167501b750127500e750
000200000a170131701a1701e1701f1601e1601d1601a150171500f14005130001300010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
