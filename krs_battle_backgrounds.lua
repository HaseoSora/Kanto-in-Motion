-- Canonical Figma battle-background router.
-- Location and world time are read from public Gen1Recomp state. Selection is
-- cached per battle so a random interior never changes while a turn is drawn,
-- and no gameplay RNG value is consumed by presentation.
local M={}
local internalMod=nil
function M.bindMod(mod) internalMod=mod end
local cache=setmetatable({},{__mode="k"})

-- Ground-contact anchors for the authored 1920x950 canonical backgrounds.
-- Coordinates are LOCAL TO THE BACKGROUND image (the KRS battle presenter
-- draws it at logical y=86).  The bottom-centre of a Pokémon sprite is placed
-- on these points, so sprite size/provider/upscale no longer changes where its
-- feet/body contact the arena.  Day/night/sunrise/sunset variants share the
-- same geometry profile; only the four Power Plant interiors have individual
-- profiles.
local GROUND_ANCHORS={
  cave_cerulean={player={644,616},enemy={1496,500}},
  cave_dark={player={616,680},enemy={1460,512}},
  cave_seafoam={player={600,684},enemy={1480,512}},
  cave_victory_road={player={604,664},enemy={1468,496}},
  cerulean_bridge={player={508,688},enemy={1404,524}},
  grass={player={604,672},enemy={1460,520}},
  gym_celadon={player={628,712},enemy={1444,508}},
  gym_cerulean={player={620,712},enemy={1468,504}},
  gym_cinnabar={player={604,724},enemy={1460,512}},
  gym_fuchsia={player={624,732},enemy={1464,500}},
  gym_pewter={player={632,712},enemy={1464,504}},
  gym_saffron_fighting={player={632,732},enemy={1464,504}},
  gym_saffron_psychic={player={628,724},enemy={1460,508}},
  gym_vermilion={player={616,724},enemy={1460,516}},
  gym_viridian={player={636,720},enemy={1464,508}},
  league_agatha={player={632,732},enemy={1468,496}},
  league_bruno={player={628,716},enemy={1460,508}},
  league_champion={player={608,720},enemy={1460,504}},
  league_lance={player={600,724},enemy={1464,500}},
  league_lorelei={player={616,720},enemy={1464,504}},
  mt_moon={player={620,676},enemy={1460,504}},
  oak_lab={player={620,696},enemy={1452,500}},
  pokemon_mansion={player={608,696},enemy={1460,504}},
  pokemon_tower={player={592,640},enemy={1292,460}},
  power_plant_1={player={624,748},enemy={1448,512}},
  power_plant_2={player={644,732},enemy={1464,512}},
  power_plant_3={player={636,736},enemy={1452,512}},
  power_plant_4={player={640,736},enemy={1460,512}},
  power_plant_exterior={player={612,676},enemy={1448,520}},
  road={player={600,672},enemy={1440,520}},
  rocket_hideout={player={520,720},enemy={1470,495}},
  safari={player={608,672},enemy={1448,512}},
  sea={player={604,724},enemy={1456,504}},
  silph_co={player={632,720},enemy={1456,508}},
  ss_anne={player={640,724},enemy={1460,508}},
  viridian_forest={player={640,680},enemy={1456,512}},
}

local PERIOD_SUFFIX={day=true,night=true,sunrise=true,sunset=true}
local function anchorKey(backdrop)
  if type(backdrop)~="table" then return nil end
  local file=tostring(backdrop.file or "")
  if GROUND_ANCHORS[file] then return file end
  local base,suffix=file:match("^(.-)_([^_]+)$")
  if base and PERIOD_SUFFIX[suffix] and GROUND_ANCHORS[base] then return base end
  local kind=tostring(backdrop.kind or "")
  if GROUND_ANCHORS[kind] then return kind end
  return nil
end

function M.groundAnchors(backdrop)
  local key=anchorKey(backdrop)
  local a=key and GROUND_ANCHORS[key] or nil
  -- Legacy global anchors are the terminal fallback for unknown/mod-authored
  -- backgrounds and for Voxel-owned arenas. They are converted to local
  -- 1920x950 background coordinates (presenter y offset is +86).
  a=a or {player={630,704},enemy={1400,484}}
  return {
    player={x=a.player[1],y=a.player[2]},
    enemy={x=a.enemy[1],y=a.enemy[2]},
    profile=key or "fallback",
  }
end

function M.anchorProfileCount()
  local n=0;for _ in pairs(GROUND_ANCHORS) do n=n+1 end;return n
end

local TIMED={
  OAKS_LAB="oak_lab",
  VIRIDIAN_FOREST="viridian_forest",
  ROUTE_24="cerulean_bridge",
  ROUTE_10="power_plant_exterior",
}
local FIXED={
  PEWTER_GYM="gym_pewter",CERULEAN_GYM="gym_cerulean",
  VERMILION_GYM="gym_vermilion",CELADON_GYM="gym_celadon",
  FUCHSIA_GYM="gym_fuchsia",SAFFRON_GYM="gym_saffron_psychic",
  FIGHTING_DOJO="gym_saffron_fighting",CINNABAR_GYM="gym_cinnabar",
  VIRIDIAN_GYM="gym_viridian",
  LORELEIS_ROOM="league_lorelei",BRUNOS_ROOM="league_bruno",
  AGATHAS_ROOM="league_agatha",LANCES_ROOM="league_lance",
  CHAMPIONS_ROOM="league_champion",
  CERULEAN_CAVE_1F="cave_cerulean",CERULEAN_CAVE_2F="cave_cerulean",
  CERULEAN_CAVE_B1F="cave_cerulean",
  VICTORY_ROAD_1F="cave_victory_road",VICTORY_ROAD_2F="cave_victory_road",
  VICTORY_ROAD_3F="cave_victory_road",
  SEAFOAM_ISLANDS_1F="cave_seafoam",SEAFOAM_ISLANDS_B1F="cave_seafoam",
  SEAFOAM_ISLANDS_B2F="cave_seafoam",SEAFOAM_ISLANDS_B3F="cave_seafoam",
  SEAFOAM_ISLANDS_B4F="cave_seafoam",
  GAME_CORNER="rocket_hideout",
}

-- When a map has no authored location-specific scene, reuse the closest
-- canonical Figma family instead of falling back to the old generated colour
-- bands. These are presentation-only choices based on Gen1Recomp's public
-- tileset semantics; exact map and terrain routes above always win.
local TIMED_TILESET={
  OVERWORLD="road",PLATEAU="road",FOREST="viridian_forest",
  FOREST_GATE="viridian_forest",SHIP="ss_anne",SHIP_PORT="ss_anne",
  CEMETERY="pokemon_tower",MANSION="pokemon_mansion",LAB="oak_lab",
}
local FIXED_TILESET={
  CAVERN="cave_dark",UNDERGROUND="cave_dark",
  DOJO="gym_saffron_fighting",GYM="gym_saffron_fighting",
  INTERIOR="silph_co",LOBBY="silph_co",CLUB="silph_co",
  MART="silph_co",POKECENTER="silph_co",MUSEUM="silph_co",
  GATE="silph_co",HOUSE="silph_co",REDS_HOUSE_1="silph_co",
  REDS_HOUSE_2="silph_co",
}

local function starts(value,prefix) return value:sub(1,#prefix)==prefix end

local function periodValue(value)
  local key=tostring(value or "DAY"):upper():gsub("[^A-Z0-9]+","_")
  if key:find("SUNRISE",1,true) or key:find("DAWN",1,true)
      or key=="MORN" or key:find("MORNING",1,true) then return "sunrise" end
  if key:find("SUNSET",1,true) or key:find("DUSK",1,true)
      or key=="EVE" or key:find("EVENING",1,true) then return "sunset" end
  if key=="NITE" or key:find("NIGHT",1,true) or key=="DARK" or key=="NITE_F" then return "night" end
  return "day"
end

function M.period(game)
  -- Graphics owns the live KRS clock. Read it directly so a battle entered
  -- while the player was idle does not wait for the next overworld step to
  -- refresh Game.overworld.tod. The engine field remains the fallback.
  local handle=internalMod and internalMod.find and internalMod.find("graphics")
  local gx=handle and handle.exports or nil
  if type(gx)=="table" and type(gx.timeOfDayPeriod)=="function" then
    local ok,period=pcall(gx.timeOfDayPeriod)
    if ok and period then return periodValue(period) end
  end
  local ow=game and game.overworld
  local value=ow and (ow.tod or ow.daytime) or nil
  if ow and type(ow.timeOfDay)=="function" then
    local ok,resolved=pcall(ow.timeOfDay,ow)
    if ok and resolved~=nil then value=resolved end
  end
  return periodValue(value)
end

local function timed(prefix,period)
  return {file=prefix.."_"..period,kind=prefix,period=period}
end
local function fixed(file,kind)
  return {file=file,kind=kind or file,period=nil}
end

local function stableIndex(battle,mapId,count)
  local key=tostring(mapId or "")..":"..tostring(battle)
  local hash=0
  for i=1,#key do hash=(hash*33+key:byte(i))%2147483647 end
  return hash%count+1
end

local function waterOrGrass(ow)
  local map,p=ow and ow.map,ow and ow.player
  if not (map and p) then return false,false end
  local water=false;local grass=false
  local ok,value=pcall(function() return p.surfing or map:isWaterCell(p.cellX,p.cellY) end)
  if ok then water=value==true end
  ok,value=pcall(function() return map:isGrassCell(p.cellX,p.cellY) end)
  if ok then grass=value==true end
  return water,grass
end

local function uncached(game,battle)
  local ow=game and game.overworld;local map=ow and ow.map
  local mapId=tostring(map and map.id or ""):upper()
  local period=M.period(game)
  local result

  if FIXED[mapId] then result=fixed(FIXED[mapId])
  elseif TIMED[mapId] then result=timed(TIMED[mapId],period)
  elseif starts(mapId,"MT_MOON_") then result=timed("mt_moon",period)
  elseif starts(mapId,"SS_ANNE_") then result=timed("ss_anne",period)
  elseif starts(mapId,"POKEMON_TOWER_") then result=timed("pokemon_tower",period)
  elseif starts(mapId,"SAFARI_ZONE_") then result=timed("safari",period)
  elseif starts(mapId,"POKEMON_MANSION_") then result=timed("pokemon_mansion",period)
  elseif starts(mapId,"SILPH_CO_") then result=fixed("silph_co")
  elseif starts(mapId,"ROCKET_HIDEOUT_") then result=fixed("rocket_hideout")
  elseif starts(mapId,"CERULEAN_CAVE_") then result=fixed("cave_cerulean")
  elseif starts(mapId,"VICTORY_ROAD_") then result=fixed("cave_victory_road")
  elseif starts(mapId,"SEAFOAM_ISLANDS_") then result=fixed("cave_seafoam")
  elseif mapId=="POWER_PLANT" then
    result=fixed("power_plant_"..stableIndex(battle,mapId,4),"power_plant")
  else
    local water,grass=waterOrGrass(ow)
    local tileset=tostring(map and map.def and map.def.tileset or ""):upper()
    if water then result=timed("sea",period)
    elseif grass then result=timed("grass",period)
    elseif tileset:find("CAV",1,true)
        or starts(mapId,"ROCK_TUNNEL_") or starts(mapId,"DIGLETTS_CAVE") then result=fixed("cave_dark","cave")
    elseif starts(mapId,"ROUTE_") or mapId:find("_CITY$",1) or mapId:find("_TOWN$",1)
        or tileset=="OVERWORLD" or tileset=="PLATEAU" then result=timed("road",period)
    elseif TIMED_TILESET[tileset] then result=timed(TIMED_TILESET[tileset],period)
    elseif tileset=="FACILITY" then
      result=fixed("power_plant_"..stableIndex(battle,mapId,4),"power_plant")
    elseif FIXED_TILESET[tileset] then result=fixed(FIXED_TILESET[tileset])
    else
      -- Unknown/mod-authored maps do not expose enough semantics for a more
      -- specific claim. Road is the least specialized authored Kanto scene.
      result=timed("road",period);result.fallback="unknown_map"
    end
  end
  result.mapId=mapId
  return result
end

function M.resolve(game,battle)
  if battle and cache[battle] then return cache[battle] end
  local result=uncached(game,battle)
  if battle then cache[battle]=result end
  return result
end

function M.clear(battle) if battle then cache[battle]=nil end end

local PREVIEW_TIMED={
  grass=true,road=true,sea=true,viridian_forest=true,mt_moon=true,oak_lab=true,
  pokemon_mansion=true,pokemon_tower=true,power_plant_exterior=true,cerulean_bridge=true,safari=true,ss_anne=true,
}
local PREVIEW_FIXED={
  'cave_cerulean','cave_dark','cave_seafoam','cave_victory_road',
  'gym_celadon','gym_cerulean','gym_cinnabar','gym_fuchsia','gym_pewter','gym_saffron_fighting','gym_saffron_psychic','gym_vermilion','gym_viridian',
  'league_agatha','league_bruno','league_champion','league_lance','league_lorelei',
  'power_plant_1','power_plant_2','power_plant_3','power_plant_4','rocket_hideout','silph_co',
}
local PREVIEW_ORDER={
  'grass','road','sea','viridian_forest','mt_moon','cerulean_bridge','safari','ss_anne','oak_lab','pokemon_mansion','pokemon_tower','power_plant_exterior',
}
for _,id in ipairs(PREVIEW_FIXED) do PREVIEW_ORDER[#PREVIEW_ORDER+1]=id end
function M.previewCatalog()
  local out={}
  for _,id in ipairs(PREVIEW_ORDER) do
    out[#out+1]={id=id,label=id:gsub('_',' '):upper(),periods=PREVIEW_TIMED[id] and {'sunrise','day','sunset','night'} or {'default'}}
  end
  return out
end
function M.availablePeriods(id) return PREVIEW_TIMED[tostring(id or '')] and {'sunrise','day','sunset','night'} or {'default'} end
function M.previewBackdrop(id,period)
  id=tostring(id or 'grass');period=tostring(period or 'day')
  if PREVIEW_TIMED[id] then
    if not PERIOD_SUFFIX[period] then period='day' end
    return {file=id..'_'..period,kind=id,period=period,preview=true}
  end
  return {file=id,kind=id,period=nil,preview=true}
end
return M
