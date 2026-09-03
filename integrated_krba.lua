return function(mod)
  local GameVersion=require("src.core.GameVersion")
  local IS_GEN2=GameVersion.generation()==2
  if not IS_GEN2 then
    local okProbe,BattleStateProbe=pcall(require,"src.battle.BattleState")
    IS_GEN2=okProbe and type(BattleStateProbe)=="table" and rawget(BattleStateProbe,"newWild")==nil
  end
  if IS_GEN2 then
    mod.exports.integratedKrba=false
    return false
  end
  local function loadLocal(path)
    local src,err=mod:read(path)
    assert(src,"unable to read "..path..": "..tostring(err))
    local loader=loadstring or load
    local chunk,compileErr=loader(src,"@"..mod.path.."/"..path)
    assert(chunk,compileErr)
    return chunk()
  end
  local data=loadLocal("data/gen1_anims.lua")
  for id,file in pairs(data.sfx or {}) do
    mod.content.sfx:register(id,{file=mod.assets:path("assets/sfx/"..file)})
  end
  local mobile = type(mod._kantoInMotionNativeMobileHost) == "function"
    and mod._kantoInMotionNativeMobileHost()
  local installer=loadLocal(mobile
    and "lib/krba_essentials_player_mobile.lua"
    or "lib/krba_essentials_player.lua")
  installer(mod,data)
  mod.exports.integratedKrba=true
  mod.exports.integratedKrbaCoverage=165
  mod.log:info("integrated Kanto Rework Essentials move animations (165 Gen 1 moves)")
  return true
end
