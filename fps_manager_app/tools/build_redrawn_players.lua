-- Converts 28 high-resolution redraws into the game's shared 64-color,
-- 64-logical-pixel portrait format and writes editable Aseprite sources.
local root='assets/players_hd/'
local output='assets/players/'
local ids={
  'player_00','player_01','player_02','player_03','player_04','player_05','player_06','player_07',
  'player_08','player_09','player_10','player_11','player_12','player_13','player_14','player_15',
  'open_a_0','open_a_1','open_a_2','open_b_0','open_b_1','open_b_2',
  'world_a_0','world_a_1','world_a_2','world_b_0','world_b_1','world_b_2'
}

local pc=app.pixelColor
local paletteFile=assert(io.open(root..'management-64.gpl','r'))
local colors={}
local palette=Palette(65)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
for line in paletteFile:lines() do
  local r,g,b=line:match('^(%d+) (%d+) (%d+)')
  if r then
    r,g,b=tonumber(r),tonumber(g),tonumber(b)
    table.insert(colors,{r,g,b})
    palette:setColor(#colors,Color{r=r,g=g,b=b,a=255})
  end
end
paletteFile:close()
assert(#colors>0,'Palette is empty')

local cache={}
local function quant(pixel)
  local alpha=pc.rgbaA(pixel)
  if alpha==0 then return 0 end
  local r,g,b=pc.rgbaR(pixel),pc.rgbaG(pixel),pc.rgbaB(pixel)
  local key=r*65536+g*256+b
  local cached=cache[key]
  if not cached then
    local best=1e10
    for _,value in ipairs(colors) do
      local distance=(r-value[1])^2+(g-value[2])^2+(b-value[3])^2
      if distance<best then best=distance;cached=value end
    end
    cache[key]=cached
  end
  return pc.rgba(cached[1],cached[2],cached[3],alpha)
end

local function enlarge(image,factor)
  local result=Image(image.width*factor,image.height*factor,ColorMode.RGB)
  for y=0,result.height-1 do for x=0,result.width-1 do
    result:drawPixel(x,y,image:getPixel(math.floor(x/factor),math.floor(y/factor)))
  end end
  return result
end

local preview=Image(7*128,4*128,ColorMode.RGB)
local log=assert(io.open(root..'build-log.txt','w'))

for index,id in ipairs(ids) do
  local source=app.open(root..id..'.png')
  assert(source.width>=1024 and source.height>=1024,id..' is not a high-resolution source')
  local original=Image(source.width,source.height,ColorMode.RGB)
  original:drawSprite(source,1)
  local logical=Image(64,64,ColorMode.RGB)
  for y=0,63 do for x=0,63 do
    local sx=math.min(original.width-1,math.floor((x+.5)*original.width/64))
    local sy=math.min(original.height-1,math.floor((y+.5)*original.height/64))
    logical:drawPixel(x,y,quant(original:getPixel(sx,sy)))
  end end
  source:close()

  local final=enlarge(logical,4)
  final:saveAs(output..id..'.png')
  local sprite=Sprite(256,256,ColorMode.RGB)
  sprite:setPalette(palette)
  sprite.layers[1].name='portrait_'..id
  sprite:newCel(sprite.layers[1],1,final,Point(0,0))
  sprite:saveAs(root..'aseprite/'..id..'.aseprite')
  sprite:close()

  local check=app.open(root..'aseprite/'..id..'.aseprite')
  assert(check.width==256 and check.height==256 and #check.frames==1,id..' Aseprite roundtrip failed')
  check:close()

  preview:drawImage(enlarge(logical,2),Point(((index-1)%7)*128,math.floor((index-1)/7)*128))
  log:write(id..': OK; HD source -> 64 logical pixels -> 256 PNG/Aseprite\n')
  log:flush()
end

preview:saveAs(root..'players_redrawn_preview.png')
log:write('COMPLETE: 28 portraits\n')
log:close()
