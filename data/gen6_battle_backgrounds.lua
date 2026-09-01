-- Location routing for ARENA FILL: GEN6.
--
-- Values name an image set below, never a live Map object. Keeping this pure
-- data makes coverage auditable and lets imported ROMs fail open when they add
-- a map id this Kanto table does not know.

local sets = {
  city = {
    dawn = "citydawn.jpg", day = "cityday.jpg",
    dusk = "citydusk.jpg", night = "citynight.jpg",
  },
  grassy = {
    dawn = "grassydawn.jpg", day = "grassyday.jpg",
    dusk = "grassydusk.jpg", night = "grassynight.jpg",
  },
  bridges = {
    dawn = "bridgesdawn.jpg", day = "bridgesday.jpg",
    dusk = "bridgesdusk.jpg", night = "bridgesnight.jpg",
  },
  rockypath = {
    dawn = "rockypathdawn.jpg", day = "rockypathday.jpg",
    dusk = "rockypathdusk.jpg", night = "rockypathnight.jpg",
  },
  vermilion = {
    dawn = "vermiliondawn.jpg", day = "vermilionday.jpg",
    dusk = "vermiliondusk.jpg", night = "vermilionnight.jpg",
  },
  route2 = {
    dawn = "route2dawn.jpg", day = "route2day.jpg",
    dusk = "route2dusk.jpg", night = "route2night.jpg",
  },
  route5 = {
    dawn = "route5dawn.png", day = "route5day.png",
    dusk = "route5dusk.png", night = "route5night.png",
  },
  fences = {
    dawn = "fencesdawn.png", day = "fencesday.png",
    dusk = "fencesdusk.png", night = "fencesnight.png",
  },

  viridianforest = "viridianforest.jpg",
  victoryroad = "victoryroad.png",
  tunnel = "tunnel.jpg",
  mtmoon = "mtmoon.jpg",
  seafoam = "seafoamislands.jpg",
  ceruleancave = "ceruleancave.jpg",
  pokemonmansion = "pokemonmansion.jpg",
  powerplant = "powerplant.jpg",
  pokemontower = "pokemontower.jpg",
  silphco = "silphco.jpg",
  rockethideout = "rockethideout.jpg",
  ssanne = "ssanne.jpg",
  inssanne = "inssanne.jpg",
  safarizone = "safarizone.png",
  safariwater = "safariwater.jpg",
  cinnabarisland = "cinnabarisland.jpg",
  pewtergym = "pewtergym.jpg",
  ceruleangym = "ceruleangym.jpg",
  vermiliongym = "vermiliongym.jpg",
  celadongym = "celadongym.jpg",
  fuchsiagym = "fuchsiagym.jpg",
  saffrongym = "saffrongym.jpg",
  cinnabargym = "cinnabargym.jpg",
  viridiangym = "viridiangym.png",
  shore = "shore.jpg",
  ocean = "ocean.jpg",
  route10 = "route10.jpg",
  route1213 = "route1213.jpg",
  route17 = "route17.jpg",
  route18 = "route18.jpg",
  route19 = "route19.jpg",
  route21 = "route21.jpg",
  route23 = "route23.jpg",
  oakslab = "oakslab.jpg",

  fightingdojo = "fightingdojo.jpg",
}

local maps = {}
local function assign(set, ids)
  for _, id in ipairs(ids) do maps[id] = set end
end

-- Cities and the League approach exterior.
assign("city", {
  "PALLET_TOWN", "VIRIDIAN_CITY", "PEWTER_CITY", "CERULEAN_CITY",
  "LAVENDER_TOWN", "CELADON_CITY", "FUCHSIA_CITY",
  "SAFFRON_CITY",
})
-- Cinnabar's exterior is a single strong visual identity: wild, trainer,
-- fishing, and surfing battles all use the island plate. Mansion and Gym map
-- ids remain independent below and therefore keep their own routing.
maps.CINNABAR_ISLAND = "cinnabarisland"
maps.VERMILION_CITY = "vermilion"
maps.INDIGO_PLATEAU = "victoryroad"

-- Every numbered Kanto route. Location-specific paintings replace the
-- generic grassy/rocky set where the supplied collection has one.
assign("grassy", {
  "ROUTE_1", "ROUTE_6", "ROUTE_22",
})
assign("fences", {
  "ROUTE_7", "ROUTE_8", "ROUTE_11", "ROUTE_14", "ROUTE_15", "ROUTE_16",
})
maps.ROUTE_2 = "route2"
maps.ROUTE_5 = "route5"
assign("rockypath", { "ROUTE_3", "ROUTE_4", "ROUTE_9" })
maps.ROUTE_10 = "route10"
assign("route1213", { "ROUTE_12", "ROUTE_13" })
maps.ROUTE_17 = "route17"
maps.ROUTE_18 = "route18"
maps.ROUTE_19 = "route19"
maps.ROUTE_20 = "ocean"
maps.ROUTE_21 = "route21"
maps.ROUTE_23 = "route23"
maps.ROUTE_24 = "bridges"
maps.ROUTE_25 = "fences"

-- Forest and caves, including entrance maps whose battles may be supplied by
-- encounter/content mods rather than the original ROM.
maps.VIRIDIAN_FOREST = "viridianforest"
assign("tunnel", {
  "DIGLETTS_CAVE", "DIGLETTS_CAVE_ROUTE_2", "DIGLETTS_CAVE_ROUTE_11",
  "UNDERGROUND_PATH_NORTH_SOUTH", "UNDERGROUND_PATH_WEST_EAST",
  "UNDERGROUND_PATH_ROUTE_5", "UNDERGROUND_PATH_ROUTE_6",
  "UNDERGROUND_PATH_ROUTE_6_COPY", "UNDERGROUND_PATH_ROUTE_7",
  "UNDERGROUND_PATH_ROUTE_7_COPY", "UNDERGROUND_PATH_ROUTE_8",
  "ROCK_TUNNEL_1F", "ROCK_TUNNEL_B1F",
})
assign("mtmoon", { "MT_MOON_1F", "MT_MOON_B1F", "MT_MOON_B2F" })
assign("seafoam", {
  "SEAFOAM_ISLANDS_1F", "SEAFOAM_ISLANDS_B1F", "SEAFOAM_ISLANDS_B2F",
  "SEAFOAM_ISLANDS_B3F", "SEAFOAM_ISLANDS_B4F",
})
assign("ceruleancave", {
  "CERULEAN_CAVE_1F", "CERULEAN_CAVE_2F", "CERULEAN_CAVE_B1F",
})
assign("victoryroad", {
  "VICTORY_ROAD_1F", "VICTORY_ROAD_2F", "VICTORY_ROAD_3F",
})

-- Most Gyms have a common room for ordinary trainers and as the leader's
-- fallback when BOSS BG is disabled. Saffron is deliberate exception:
-- ordinary trainers and boss-off Sabrina retain the voxel Gym, while the
-- independent boss layer reserves saffrongym.jpg for Sabrina herself.
maps.PEWTER_GYM = "pewtergym"
maps.CERULEAN_GYM = "ceruleangym"
maps.VERMILION_GYM = "vermiliongym"
maps.CELADON_GYM = "celadongym"
maps.FUCHSIA_GYM = "fuchsiagym"
maps.CINNABAR_GYM = "cinnabargym"
maps.VIRIDIAN_GYM = "viridiangym"
maps.FIGHTING_DOJO = "fightingdojo"

-- Story/enemy facilities and Oak's opening rival battle.
maps.OAKS_LAB = "oakslab"
maps.POWER_PLANT = "powerplant"
assign("pokemonmansion", {
  "POKEMON_MANSION_1F", "POKEMON_MANSION_2F",
  "POKEMON_MANSION_3F", "POKEMON_MANSION_B1F",
})
assign("pokemontower", {
  "POKEMON_TOWER_1F", "POKEMON_TOWER_2F", "POKEMON_TOWER_3F",
  "POKEMON_TOWER_4F", "POKEMON_TOWER_5F", "POKEMON_TOWER_6F",
  "POKEMON_TOWER_7F",
})
assign("rockethideout", {
  "ROCKET_HIDEOUT_B1F", "ROCKET_HIDEOUT_B2F", "ROCKET_HIDEOUT_B3F",
  "ROCKET_HIDEOUT_B4F", "ROCKET_HIDEOUT_ELEVATOR",
})
assign("silphco", {
  "SILPH_CO_1F", "SILPH_CO_2F", "SILPH_CO_3F", "SILPH_CO_4F",
  "SILPH_CO_5F", "SILPH_CO_6F", "SILPH_CO_7F", "SILPH_CO_8F",
  "SILPH_CO_9F", "SILPH_CO_10F", "SILPH_CO_11F", "SILPH_CO_ELEVATOR",
})

-- Ship exterior and every interior deck/room.
assign("ssanne", { "VERMILION_DOCK", "SS_ANNE_BOW" })
assign("inssanne", {
  "SS_ANNE_1F", "SS_ANNE_2F", "SS_ANNE_3F", "SS_ANNE_B1F",
  "SS_ANNE_KITCHEN", "SS_ANNE_CAPTAINS_ROOM", "SS_ANNE_1F_ROOMS",
  "SS_ANNE_2F_ROOMS", "SS_ANNE_B1F_ROOMS",
})

-- Safari regions. Elite Four/Champion paintings are selected by the
-- independent boss layer; with it off, those rooms retain their voxel arenas.
assign("safarizone", {
  "SAFARI_ZONE_CENTER", "SAFARI_ZONE_EAST", "SAFARI_ZONE_NORTH",
  "SAFARI_ZONE_WEST",
})
-- League boss rooms are supplied by BOSS BG. With that switch disabled they
-- likewise fail open to the normal voxel room; there is no generic indoor art.

-- Story encounters whose battle location is represented by a nearby landmark
-- rather than the map id reported by the engine.  The third rival fight is
-- scripted on CERULEAN_CITY with the RIVAL1 trainer class, but visually takes
-- place at the Route 24 bridge.  Match both fields so ordinary city trainers
-- keep the Cerulean city plate and OPP_RIVAL3 (the Champion class) is untouched.
local encounters = {
  CERULEAN_CITY = { OPP_RIVAL1 = "bridges" },
}

local safariWaterMaps = {
  SAFARI_ZONE_CENTER = true, SAFARI_ZONE_EAST = true,
  SAFARI_ZONE_NORTH = true, SAFARI_ZONE_WEST = true,
}

local fishingMapDefaults = {
  ROUTE_19 = true, ROUTE_20 = true, ROUTE_21 = true,
}

-- Indoor water encounters that deliberately use a different water-facing
-- composition while the rest of each cave retains its normal room plate.
local surfingSets = {
  CERULEAN_CAVE_1F = "seafoam",
  CERULEAN_CAVE_2F = "seafoam",
  CERULEAN_CAVE_B1F = "seafoam",
}

local fishingSets = {
  CERULEAN_CAVE_1F = "seafoam",
  CERULEAN_CAVE_2F = "seafoam",
  CERULEAN_CAVE_B1F = "seafoam",
  SEAFOAM_ISLANDS_1F = "seafoam",
  SEAFOAM_ISLANDS_B1F = "seafoam",
  SEAFOAM_ISLANDS_B2F = "seafoam",
  SEAFOAM_ISLANDS_B3F = "seafoam",
  SEAFOAM_ISLANDS_B4F = "seafoam",
}

return {
  sets = sets,
  maps = maps,
  encounters = encounters,
  safariWaterMaps = safariWaterMaps,
  fishingMapDefaults = fishingMapDefaults,
  surfingSets = surfingSets,
  fishingSets = fishingSets,
}
