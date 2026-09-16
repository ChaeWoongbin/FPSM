-- FPS Manager app icon. Run from fps_manager_app with Aseprite --batch --script.
local root = 'assets/app_icon/'
local pc = app.pixelColor

local function rgba(hex, alpha)
  hex = hex:gsub('#', '')
  return pc.rgba(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16), alpha or 255)
end

local C = {
  clear=rgba('000000',0), ink=rgba('06111f'), navy=rgba('091a2f'), panel=rgba('102942'),
  cyan=rgba('39d7df'), cyan2=rgba('1598b3'), white=rgba('f4f1df'),
  orange=rgba('ff9f2f'), orange2=rgba('d96b22'), blue=rgba('1d5c88')
}

local function image(w,h,fill)
  local im=Image(w,h,ColorMode.RGB)
  if fill then im:clear(fill) end
  return im
end

local function px(im,x,y,color)
  if x>=0 and y>=0 and x<im.width and y<im.height then im:putPixel(x,y,color) end
end

local function rect(im,x,y,w,h,color)
  for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,color) end end
end

local function circle(im,cx,cy,r,color)
  for y=-r,r do for x=-r,r do
    if x*x+y*y<=r*r then px(im,cx+x,cy+y,color) end
  end end
end

local function roundedRect(im,x,y,w,h,r,color)
  rect(im,x+r,y,w-r*2,h,color)
  rect(im,x,y+r,w,h-r*2,color)
  circle(im,x+r,y+r,r,color)
  circle(im,x+w-r-1,y+r,r,color)
  circle(im,x+r,y+h-r-1,r,color)
  circle(im,x+w-r-1,y+h-r-1,r,color)
end

local function line(im,x0,y0,x1,y1,color,thick)
  local dx,sx=math.abs(x1-x0),x0<x1 and 1 or -1
  local dy,sy=-math.abs(y1-y0),y0<y1 and 1 or -1
  local err=dx+dy
  while true do
    local r=math.floor((thick or 1)/2)
    rect(im,x0-r,y0-r,thick or 1,thick or 1,color)
    if x0==x1 and y0==y1 then break end
    local e2=2*err
    if e2>=dy then err=err+dy; x0=x0+sx end
    if e2<=dx then err=err+dx; y0=y0+sy end
  end
end

local function fillPoly(im,points,color)
  for y=0,im.height-1 do
    local nodes={}
    local j=#points
    for i=1,#points do
      local pi,pj=points[i],points[j]
      if (pi[2]<y and pj[2]>=y) or (pj[2]<y and pi[2]>=y) then
        table.insert(nodes,math.floor(pi[1]+(y-pi[2])/(pj[2]-pi[2])*(pj[1]-pi[1])))
      end
      j=i
    end
    table.sort(nodes)
    for i=1,#nodes-1,2 do rect(im,nodes[i],y,nodes[i+1]-nodes[i]+1,1,color) end
  end
end

local function resizeNearest(src,w,h)
  local out=image(w,h)
  for y=0,h-1 do for x=0,w-1 do
    out:putPixel(x,y,src:getPixel(math.floor(x*src.width/w),math.floor(y*src.height/h)))
  end end
  return out
end

local background=image(64,64)
roundedRect(background,1,1,62,62,8,C.ink)
roundedRect(background,3,3,58,58,7,C.navy)
rect(background,7,7,50,1,C.blue)
rect(background,7,56,50,1,C.ink)
for y=8,55,8 do for x=8,55,8 do px(background,x,y,C.panel) end end

local shield=image(64,64)
fillPoly(shield,{{9,15},{55,15},{53,38},{47,49},{32,59},{17,49},{11,38}},C.cyan2)
fillPoly(shield,{{12,17},{52,17},{50,37},{44,47},{32,55},{20,47},{14,37}},C.white)
fillPoly(shield,{{15,19},{49,19},{47,36},{41,44},{32,51},{23,44},{17,36}},C.panel)
rect(shield,15,19,34,2,C.cyan)
line(shield,17,37,24,45,C.cyan,2)
line(shield,47,37,40,45,C.cyan,2)
line(shield,24,45,32,51,C.cyan,2)
line(shield,40,45,32,51,C.cyan,2)

local symbols=image(64,64)
-- Crown-like club leadership mark.
rect(symbols,24,10,16,3,C.orange)
rect(symbols,23,7,4,5,C.orange)
rect(symbols,30,5,4,7,C.orange)
rect(symbols,37,7,4,5,C.orange)
rect(symbols,26,12,12,2,C.orange2)
-- Tactical crosshair.
circle(symbols,32,29,10,C.white)
circle(symbols,32,29,7,C.panel)
rect(symbols,31,16,3,7,C.white)
rect(symbols,31,35,3,7,C.white)
rect(symbols,19,28,7,3,C.white)
rect(symbols,38,28,7,3,C.white)
circle(symbols,32,29,3,C.orange)
rect(symbols,31,25,3,9,C.orange)
rect(symbols,28,28,9,3,C.orange)
px(symbols,32,29,C.white)
-- Management performance bars.
rect(symbols,25,42,4,5,C.orange2)
rect(symbols,30,39,4,8,C.orange)
rect(symbols,35,36,4,11,C.orange)
rect(symbols,24,48,16,2,C.white)

local highlight=image(64,64)
rect(highlight,8,9,2,6,C.cyan)
rect(highlight,10,7,6,2,C.cyan)
rect(highlight,54,49,2,6,C.orange2)
rect(highlight,49,55,6,2,C.orange2)

local composite=image(64,64)
composite:drawImage(background,Point(0,0))
composite:drawImage(shield,Point(0,0))
composite:drawImage(symbols,Point(0,0))
composite:drawImage(highlight,Point(0,0))

local sprite=Sprite(64,64,ColorMode.RGB)
sprite.layers[1].name='background'
sprite:newCel(sprite.layers[1],1,background,Point(0,0))
local shieldLayer=sprite:newLayer(); shieldLayer.name='club_shield'; sprite:newCel(shieldLayer,1,shield,Point(0,0))
local symbolLayer=sprite:newLayer(); symbolLayer.name='fps_and_management'; sprite:newCel(symbolLayer,1,symbols,Point(0,0))
local highlightLayer=sprite:newLayer(); highlightLayer.name='pixel_highlights'; sprite:newCel(highlightLayer,1,highlight,Point(0,0))
sprite:saveAs(root..'fps_manager_icon.aseprite')
sprite:close()

for _,size in ipairs({16,32,48,64,72,96,144,192,512,1024}) do
  resizeNearest(composite,size,size):saveAs(root..'fps_manager_icon_'..size..'.png')
end

local palette=assert(io.open(root..'fps-manager-icon.gpl','w'))
palette:write('GIMP Palette\nName: FPS Manager App Icon\nColumns: 4\n#\n')
for _,entry in ipairs({{'06','11','1f','ink'},{'09','1a','2f','navy'},{'10','29','42','panel'},{'39','d7','df','cyan'},{'15','98','b3','cyan-dark'},{'f4','f1','df','ivory'},{'ff','9f','2f','orange'},{'d9','6b','22','orange-dark'},{'1d','5c','88','blue'}}) do
  palette:write(string.format('%d %d %d %s\n',tonumber(entry[1],16),tonumber(entry[2],16),tonumber(entry[3],16),entry[4]))
end
palette:close()

local log=assert(io.open(root..'build-log.txt','w'))
log:write('PASS: layered 64x64 Aseprite source and 10 nearest-neighbor PNG sizes generated.\n')
log:close()
