-- Kanto in Motion <-> PotatoVoxel staged-battle compatibility.
--
-- PotatoVoxel owns the world/camera/3D arena. KIM may own its animated
-- battlers, KRBA effects, HP/status HUD and Modern lower panel.
--
-- No PotatoVoxel or HGSS package files are modified on disk.

return function(mod, battleSystemEnabled, battleHudGeometry)
  if not (mod and type(mod.find) == "function") then return false end

  local function handle()
    local ok, h = pcall(mod.find, "potato_voxel")
    return ok and type(h) == "table" and h or nil
  end

  local function modules()
    local h = handle()
    local exports = h and type(h.exports) == "table" and h.exports or nil
    local lib = exports and exports.lib or nil
    if not (type(lib) == "table" and type(lib.require) == "function") then
      return nil
    end
    local okO, OverworldBattle = pcall(lib.require, "OverworldBattle")
    if not (okO and type(OverworldBattle) == "table") then return nil end
    local okP, BattlePics = pcall(lib.require, "BattlePics")
    return OverworldBattle, (okP and BattlePics or nil)
  end

  local ensureKrbaBound

  -- Two stage predicates are required. Potato asks its texture provider while
  -- BattleScene.render is BUILDING the current shot, so OverworldBattle.shot()
  -- is still nil at exactly that point. `stageLive` therefore keys off the live
  -- battle session; `active` additionally requires a finished shot and is used
  -- only by final-screen HUD/UI ownership.
  local function stageLive(battle)
    local OverworldBattle = modules()
    if not OverworldBattle then return false end
    if type(OverworldBattle.enabled) == "function" then
      local ok, value = pcall(OverworldBattle.enabled)
      if not ok or value ~= true then return false end
    end
    local live = type(OverworldBattle.battle) == "function"
      and OverworldBattle.battle() or nil
    if live == nil then return false end
    if battle ~= nil and live ~= battle then return false end
    -- Bind the ACTUAL AnimPlayer instance held by Potato's BattleState. This
    -- happens before normal move selection/queue playback and avoids relying
    -- on class-table inheritance across the two mod sandboxes.
    ensureKrbaBound(live)
    return true
  end

  local function active(battle)
    if not stageLive(battle) then return false end
    local OverworldBattle = modules()
    local shot = OverworldBattle and type(OverworldBattle.shot) == "function"
      and OverworldBattle.shot() or nil
    return type(shot) == "table"
  end

  local function kimBattleOn()
    if type(battleSystemEnabled) ~= "function" then return true end
    local ok, enabled = pcall(battleSystemEnabled)
    return not ok or enabled ~= false
  end

  -- Battle Art pins Gen1Recomp's persistent BATTLE LAYOUT option to OG while
  -- its staged battle is active. If the player later disables Battle Art and
  -- returns to PotatoVoxel, that saved OG value survives and Potato correctly
  -- obeys it -- which removes the boxed WIDE HUD panels and also changes the
  -- intro party-row composition. That leaked save setting affects BOTH of KIM's
  -- Potato paths: the native fallback and KIM's own HUD/UI ownership. Before
  -- Battle Art rewrote the option the user's working Potato setup was WIDE in
  -- both cases, so restore that same predicate for every live Potato stage.
  -- This is runtime-only: the saved battleLayout value is never rewritten.
  local function potatoNativeWide(battle)
    return stageLive(battle)
  end

  mod._kantoInMotionPotatoNativeWideActive = function(battle)
    return potatoNativeWide(battle)
  end

  -- Party-ball ownership is different from Potato's WIDE-layout predicate.
  -- When KIM's battle system owns the snapped HP/status HUD, the native
  -- Potato/Gen1 HUD row must not also remain in the world/source layer. The
  -- integrated Pokeball Colorfix queries this seam and suppresses only that
  -- duplicate source row; KIM's private HUD capture remains untouched.
  mod._kantoInMotionPotatoKimHudActive = function(battle)
    return kimBattleOn() and stageLive(battle)
  end

  local function kimSpritesOn()
    local options=mod.options
    if not (options and type(options.get)=="function") then return true end
    local ok,value=pcall(options.get,options,"battleSprites")
    return not ok or value~=false
  end

  local function kimAnimationsOn()
    local options=mod.options
    if not (options and type(options.get)=="function") then return true end
    local ok,value=pcall(options.get,options,"battleAnimations")
    return not ok or value~=false
  end

  -- Feature-level ownership for Potato's cooperative stage. These are
  -- intentionally independent from KIM BATTLE SYSTEM: the explicit BATTLE
  -- SPRITES and MOVE ANIMATIONS toggles can still supply those two layers
  -- while Potato owns the arena/camera and native/other UI owns the menus.
  mod._kantoInMotionExternalStageUsesKimSprites = function(battle)
    return kimSpritesOn() and stageLive(battle)
  end
  mod._kantoInMotionExternalStageAllowsKimAnimations = function(battle)
    return kimAnimationsOn() and stageLive(battle)
  end
  mod._kantoInMotionExternalStageAllowsKimTrainer = function(battle)
    -- Keep the established desktop Potato trainer handoff unchanged. Mobile is
    -- different: when BATTLE SYSTEM = OFF, KIM no longer has the final-window
    -- trainer compositor that makes the custom trainer safe, so feeding KIM's
    -- true-colour trainer into Potato's native Gen-1 capture produces the tiny
    -- broken fragment seen on Android/iOS. Mobile therefore yields the trainer
    -- back to Potato/native when KIM battle ownership is OFF, while desktop
    -- keeps its already-working cooperative trainer path.
    if type(mod._kantoInMotionNativeMobileHost)=="function" then
      local ok,value=pcall(mod._kantoInMotionNativeMobileHost)
      if ok and value==true then return kimBattleOn() and stageLive(battle) end
    end
    return stageLive(battle)
  end

  -- Potato's BACK SPRITES mode deliberately leaves the player battler in
  -- Gen1Recomp's original 2D back-pic slot. KIM uses this predicate to feed
  -- that exact slot a frame-stable animated back image without turning the
  -- whole KIM battle scene back on.
  mod._kantoInMotionExternalStagePlayerBackPinned = function(battle)
    if not stageLive(battle) then return false end
    local OverworldBattle = modules()
    if not (OverworldBattle and type(OverworldBattle.backPinned)=="function") then
      return false
    end
    local ok, value = pcall(OverworldBattle.backPinned)
    return ok and value==true
  end

  mod._kantoInMotionExternalStageUsesKimHud = function(battle)
    return kimBattleOn() and active(battle)
  end

  -- Potato is a cooperative scene owner only while its staged shot is live.
  -- KIM may still supply sprites/animations instead of treating the installed
  -- mod as a blanket reason to turn those systems off.
  local interop = mod._kantoInMotionInterop
  if interop and type(interop.registerBattle) == "function" then
    interop:registerBattle({
      owner = "potato_voxel",
      priority = 80,
      sceneOwner = true,
      modernUi = "lower",
      allowKIMSprites = true,
      allowKIMAnimations = true,
      textScale = true,
      suppressSurfaces = { "text", "panels" },
      active = function(_, battle)
        return active(battle)
      end,
    })
  end

  ---------------------------------------------------------------------------
  -- True-colour observation.
  --
  -- Potato's paper-repair pass is correct for original Gen-1 keyed-white art,
  -- but it must not fill transparent holes in HGSS/KIM/other true-colour PNGs.
  -- Observe the public pokemon.sprite context after downstream providers have
  -- resolved it; HGSS already marks its selected battle assets trueColor=true.
  ---------------------------------------------------------------------------
  local trueColorBattle = { front = {}, back = {} }

  local function speciesKey(value)
    return tostring(value or ""):upper():gsub("[^A-Z0-9_]", "")
  end

  if mod.hooks and type(mod.hooks.wrap) == "function"
      and not mod._kantoInMotionPotatoTrueColorObserver then
    mod._kantoInMotionPotatoTrueColorObserver = true
    mod.hooks:wrap("pokemon.sprite", function(nextFn, path, ctx)
      local out = nextFn(path, ctx)
      if type(ctx) == "table"
          and (ctx.kind == "battle" or ctx.kind == "battle_anim")
          and ctx.trueColor == true and ctx.species ~= nil then
        local side = ctx.side == "back" and "back" or "front"
        trueColorBattle[side][speciesKey(ctx.species)] = true
      end
      return out
    end, 25000)
  end

  local function trueColorSide(battle, side)
    local battler = battle and (side == "enemy" and battle.enemy or battle.player)
    local mon = battler and battler.mon
    local key = speciesKey(mon and mon.species)
    if key == "" then return false end
    return trueColorBattle[side == "enemy" and "front" or "back"][key] == true
  end

  ---------------------------------------------------------------------------
  -- Direct KIM staged cards.
  --
  -- v47 temporarily replaced battle.player/enemy.sprite and asked Potato's
  -- native Gen-1 pic renderer to capture it. That renderer still carries the
  -- cartridge back/front slot assumptions, which is why Charizard could be
  -- clipped to a small lower fragment. A texture provider is allowed to
  -- return a finished card directly, so use KIM's 48/56px live Canvas as the
  -- card itself. captureW/H are presentation metadata; enlarging those values
  -- applies PLAYER PKMN SIZE without resampling the pixels.
  ---------------------------------------------------------------------------
  ensureKrbaBound = function(battle)
    if not (battle and kimAnimationsOn()) then return false end
    local player=battle.animPlayer
    local binder = mod.exports and mod.exports._kantoInMotionBindKrbaPlayer
    local direct = mod.exports and mod.exports._kantoInMotionStartKrbaDirect
    if type(player) ~= "table" or type(binder) ~= "function"
        or type(direct) ~= "function" then return false end

    -- Bind update/draw/isDone/pollEffects first, then put a Potato-specific
    -- start closure directly on the live instance.  BattleState executes move
    -- rows with `self.animPlayer.start(self.animPlayer, ...)`, so this is the
    -- last possible seam before vanilla AnimPlayer:start.  Calling the direct
    -- KRBA provider here removes load-order ambiguity between Potato and KIM.
    if player._kantoInMotionPotatoDirectStart ~= true then
      local ok,value=pcall(binder,player,battle,"potato_voxel")
      if not ok or value==false then return false end
      local fallback=player.start
      player.start=function(self,moveId,attackerIsPlayer,opts)
        local okStart,handled=pcall(direct,self,battle,moveId,attackerIsPlayer,opts,"potato_voxel")
        if okStart and handled==true then
          if mod.log and type(mod.log.info)=="function" then
            mod.log:info("PotatoVoxel: KIM KRBA direct start %s",tostring(moveId))
          end
          return
        end
        return fallback(self,moveId,attackerIsPlayer,opts)
      end
      player._kantoInMotionPotatoDirectStart=true
      if mod.log and type(mod.log.info)=="function" then
        mod.log:info("PotatoVoxel: bound live AnimPlayer to KIM KRBA provider")
      end
    else
      -- Refresh only the owner mapping; do not overwrite the direct start
      -- closure we installed above.
      player._kantoInMotionBattle=battle
      player._kantoInMotionPotatoKRBA=true
    end
    return true
  end

  local function activeKrba()
    local getter = mod.exports and mod.exports._kantoInMotionKRBAActiveSession
    if type(getter) ~= "function" then return nil end
    local ok, sess = pcall(getter)
    return ok and type(sess) == "table" and not sess.done and sess or nil
  end

  -- Return the live Essentials/KRBA transform for one physical battler.
  -- Session:battlerTransform already understands dedicated opponent variants:
  -- for an enemy Quick Attack it maps the moving USER cell to the enemy, not
  -- to the pinned player target. This is the distinction v56 intentionally
  -- threw away when it froze both sprites to stop the wrong-side lunge.
  local function potatoBattlerTransform(battle, side)
    if not kimAnimationsOn() or type(battle) ~= "table" then return nil end
    local player = battle.animPlayer
    local sess = type(player) == "table" and rawget(player, "_krs") or nil
    if not (sess and not sess.done and type(sess.battlerTransform) == "function") then
      return nil
    end
    local ok, tr = pcall(sess.battlerTransform, sess, side)
    return ok and type(tr) == "table" and tr or nil
  end

  local function potatoBattlerTransforms(battle, side)
    if not kimAnimationsOn() or type(battle) ~= "table" then return nil end
    local player = battle.animPlayer
    local sess = type(player) == "table" and rawget(player, "_krs") or nil
    if not (sess and not sess.done) then return nil end
    if type(sess.battlerTransforms) == "function" then
      local ok, list = pcall(sess.battlerTransforms, sess, side)
      if ok and type(list) == "table" and #list > 0 then return list end
    end
    local one = potatoBattlerTransform(battle, side)
    return one and { one } or nil
  end

  -- Build KIM's mutable 48/56px frame into the SAME 160x144 logical card
  -- contract Potato's native sideTexture uses. v50-v53 returned the tiny proxy
  -- itself and lied about captureW/H to scale it; BattleScene.monMatrix then
  -- interpreted those proxy dimensions as the whole battle surface, which is
  -- why large player backs could collapse into a clipped block. Keep the card
  -- dimensions/anchor fixed and scale only the art inside it.
  local kimCardCanvas = {}
  local function directCard(image, factor, side, meta, battle)
    if not (image and type(image.getDimensions) == "function") then return nil end
    local ok, w, h = pcall(image.getDimensions, image)
    if not ok or not (tonumber(w) and tonumber(h) and w > 0 and h > 0) then
      return nil
    end
    local g=love and love.graphics
    if not (g and type(g.newCanvas)=="function") then return nil end
    factor=tonumber(factor) or 1
    if not (factor>0) or factor~=factor then factor=1 end
    factor=math.max(0.5,math.min(2.0,factor))
    meta=type(meta)=="table" and meta or {}

    local CW,CH=160,144
    local AX,AY=80,96
    local key=side=="enemy" and "enemy" or "player"
    local card=kimCardCanvas[key]
    if not card then
      local okC,c=pcall(g.newCanvas,CW,CH,{dpiscale=1})
      if not okC or not c then
        okC,c=pcall(g.newCanvas,CW,CH)
      end
      if not (okC and c) then return nil end
      if c.setFilter then pcall(c.setFilter,c,"nearest","nearest") end
      card=c; kimCardCanvas[key]=c
    end

    local prev=type(g.getCanvas)=="function" and g.getCanvas() or nil
    local pushed=pcall(g.push,"all")
    if not pushed then pcall(g.push) end
    local okDraw,err=pcall(function()
      g.setCanvas(card)
      if g.origin then g.origin() end
      g.clear(0,0,0,0)
      if g.setShader then g.setShader() end
      if g.setBlendMode then g.setBlendMode("alpha") end
      g.setColor(1,1,1,1)
      local dw,dh=w*factor,h*factor
      -- Mobile KIM-owned lower UI consumes substantially more vertical space
      -- than Potato's native battle strip.  Keep the 3D player billboard on
      -- the same arena cell but lift only the artwork inside its 160x144 card
      -- so large backs (Charizard in particular) clear the Modern dialog.
      -- Desktop and BATTLE SYSTEM = OFF keep Potato's exact authored baseline.
      local playerLift=0
      if side=="player" and kimBattleOn()
          and type(mod._kantoInMotionNativeMobileHost)=="function" then
        local okM,value=pcall(mod._kantoInMotionNativeMobileHost)
        if okM and value==true then playerLift=8 end
      end
      -- Match Potato's texturing seam: every species is centered on TEX_AX
      -- and grounded at TEX_AY before the complete 160x144 card is stood up
      -- in the world. While KRBA is active, apply ONLY this side's semantic
      -- battler transform inside the card. That restores authored lunges such
      -- as enemy Quick Attack without ever moving the opposite target sprite.
      local transforms=potatoBattlerTransforms(battle,side)
      if not transforms or #transforms==0 then transforms={{ visible=true }} end
      -- Draw every semantic battler copy. Quick Attack and a few other moves
      -- author translucent duplicate USER cells to form a swoosh/trail; using
      -- only the first negative cell makes the staged opponent appear static.
      for _,tr in ipairs(transforms) do
        if not tr or tr.visible~=false then
          local dx=tr and (tonumber(tr.dx) or 0) or 0
          local dy=tr and (tonumber(tr.dy) or 0) or 0
          local zx=tr and (tonumber(tr.scaleX) or 1) or 1
          local zy=tr and (tonumber(tr.scaleY) or 1) or 1
          local ang=tr and (tonumber(tr.rotation) or 0) or 0
          local alpha=tr and (tonumber(tr.opacity) or 1) or 1
          if tr and tr.mirror then zx=-zx end
          g.push()
          g.translate(AX+dx,AY+dy)
          if ang~=0 then g.rotate(ang) end
          if zx~=1 or zy~=1 then g.scale(zx,zy) end
          g.translate(-AX,-AY)
          g.setColor(1,1,1,alpha)
          g.draw(image,AX-dw*0.5,AY-dh-playerLift,0,factor,factor)
          g.pop()
        end
      end
    end)
    if prev then pcall(g.setCanvas,prev) else pcall(g.setCanvas) end
    pcall(g.pop)
    if not okDraw then error(err,0) end

    return {
      canvas=card,
      ax=AX, ay=AY,
      trainer=meta.trainer==true,
      captureW=CW, captureH=CH,
    }
  end

  local installedProviderFor = nil
  local originalFilledFor = nil
  local trueColorCapture = false
  local animBridgeClass=nil
  local animBridgeFn=nil
  local animBridgeInner=nil
  local animBridgeErrorLogged=false
  local finalAnimHudInstalled=false
  local animHudHitLogged=false
  local activeBattle=nil

  local function battleIsTop(game,battle)
    if not battle then return false end
    local stack=game and game.stack
    if not (stack and type(stack.top)=="function") then return true end
    local ok,top=pcall(stack.top,stack)
    if not ok or top==nil then return true end
    return top==battle
  end

  -- Install AFTER Potato/KRBA have both had a chance to wrap BattleState.
  -- When a live KRS session exists, this is the authoritative final flat-screen
  -- draw seam: do not call the captured/native animation path at all, because
  -- that either paints vanilla effects or (v53) nothing. Instead ask KRBA to
  -- draw directly with Potato's exact pair midpoint/separation transform.
  local function installAnimDrawBridge(OverworldBattle)
    local okB,BattleState=pcall(require,"src.battle.BattleState")
    if not (okB and type(BattleState)=="table"
        and type(BattleState.drawAnimLayer)=="function") then return false end
    if BattleState.drawAnimLayer==animBridgeFn and animBridgeClass==BattleState then
      return true
    end
    -- A late external wrapper may replace ours between mods.loaded/game.ready.
    -- Wrap the current function again; active KRBA exits before reaching the
    -- older chain, while inactive battles preserve it unchanged.
    animBridgeInner=BattleState.drawAnimLayer
    animBridgeClass=BattleState
    animBridgeFn=function(self,colorized)
      local shot=type(self)=="table" and rawget(self,"dramaticShapeShot") or nil
      local player=type(self)=="table" and self.animPlayer or nil
      local sess=type(player)=="table" and rawget(player,"_krs") or nil
      local live=type(OverworldBattle.battle)=="function" and OverworldBattle.battle() or nil
      if type(shot)=="table" and live==self and sess and not sess.done
          and kimAnimationsOn() then
        local drawer=mod.exports and mod.exports._kantoInMotionDrawKrbaPotato
        if type(drawer)=="function" then
          local a=shot.anchors or OverworldBattle.ANCHOR
          local sp=shot.player
          local se=shot.enemy
          if type(a)=="table" and type(a.player)=="table" and type(a.enemy)=="table"
              and type(sp)=="table" and type(se)=="table" then
            local px,py=sp[1],sp[2]
            if type(OverworldBattle.backPinned)=="function" then
              local okP,pinned=pcall(OverworldBattle.backPinned)
              if okP and pinned then px,py=a.player[1],a.player[2] end
            end
            local cx,cy=(se[1]+px)*0.5,(se[2]+py)*0.5
            local ax,ay=(a.enemy[1]+a.player[1])*0.5,
                        (a.enemy[2]+a.player[2])*0.5
            local k=1
            if type(OverworldBattle.animScale)=="function" then
              local okK,value=pcall(OverworldBattle.animScale,shot,px,py)
              if okK and tonumber(value) then k=tonumber(value) end
            end
            -- When the final render.hud bridge is installed, suppress the
            -- source/UI-canvas animation here. Modern UI may clear that source
            -- later in the frame; the final bridge redraws KRBA after the
            -- composite where neither Potato nor Modern UI can erase it.
            if finalAnimHudInstalled then return end
            local okD,handled=pcall(drawer,self,{
              authoredCenter={ax,ay}, projectedCenter={cx,cy}, scale=k,
            })
            if okD and handled==true then return end
            if not okD and not animBridgeErrorLogged then
              animBridgeErrorLogged=true
              if mod.log and type(mod.log.error)=="function" then
                mod.log:error("PotatoVoxel KRBA source draw failed: %s",tostring(handled))
              end
            end
          end
        end
      end
      return animBridgeInner(self,colorized)
    end
    BattleState.drawAnimLayer=animBridgeFn
    return true
  end

  -- Final-window KRBA pass. The source BattleState animation layer can be
  -- cleared/rebuilt by Modern UI, so the authoritative Potato integration is
  -- emitted from render.hud after the normal composite. Map the logical
  -- 160x144 battle coordinate system through Potato's own viewport transform;
  -- the KRS provider then applies the same pair midpoint/separation projection
  -- Potato uses for native move animations.
  local function installFinalAnimHud(OverworldBattle)
    if finalAnimHudInstalled then return true end
    if not (mod.hooks and type(mod.hooks.wrap)=="function") then return false end
    local g=love and love.graphics
    if not (g and type(g.push)=="function" and type(g.scale)=="function") then
      return false
    end
    local unpackFn=table.unpack or unpack
    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local battle=activeBattle
      local live=type(OverworldBattle.battle)=="function" and OverworldBattle.battle() or nil
      local shot=battle and rawget(battle,"dramaticShapeShot") or nil
      local player=battle and battle.animPlayer or nil
      local sess=type(player)=="table" and rawget(player,"_krs") or nil
      local topBattle=battleIsTop(game,battle)

      -- Full-field KRBA timing planes are screen-space effects, not staged
      -- battler-space particles. Draw them at the real window dimensions before
      -- the source HUD/Modern UI so Thunder/Flash-style BG/FG fills are truly
      -- fullscreen while battle chrome remains readable on top. Particle cels
      -- are still drawn after the source composite below so Modern UI cannot
      -- erase them.
      if topBattle and battle and live==battle and type(shot)=="table"
          and sess and not sess.done and kimAnimationsOn() then
        local backFn=sess.drawBattleArtScreenBack
        local frontFn=sess.drawBattleArtScreenFront
        if type(backFn)=="function" then pcall(backFn,sess) end
        if type(frontFn)=="function" then pcall(frontFn,sess) end
      end

      local result={pcall(nextFn,game,viewport)}
      if not result[1] then error(result[2],0) end

      -- Mobile BACK SPRITES trainer path. Potato deliberately skips the
      -- player-side 3D texture whenever BACK SPRITES is ON, so its trainer is
      -- not a billboard at all -- it remains in Gen1Recomp's flat back-pic
      -- slot.  KIM's main draw wrapper suppresses the malformed mobile source
      -- trainer only while BATTLE SYSTEM is OFF. Rebuild exactly one complete
      -- trainer here at final window resolution, anchored to Potato's pinned
      -- player slot and clipped above the native command/dialog boundary.
      -- This is the path the earlier provider-side fixes could never reach.
      if topBattle and battle and live==battle and type(shot)=="table"
          and not kimBattleOn() and battle.showPlayerBack then
        local pinned=false
        if type(OverworldBattle.backPinned)=="function" then
          local okP,value=pcall(OverworldBattle.backPinned)
          pinned=okP and value==true
        end
        local mobile=false
        if type(mod._kantoInMotionNativeMobileHost)=="function" then
          local okM,value=pcall(mod._kantoInMotionNativeMobileHost)
          mobile=okM and value==true
        end
        if pinned and mobile then
          local custom=false
          local image=nil
          local getter=mod.exports and mod.exports._kantoInMotionBattleTrainerFrame
          if type(getter)=="function" then
            local okI,value=pcall(getter,battle)
            if okI and value then image=value; custom=true end
          end
          image=image or battle.playerBackPic
          local layout=shot.layout
          local a=shot.anchors or OverworldBattle.ANCHOR
          if image and type(image.getDimensions)=="function"
              and type(layout)=="table" and type(a)=="table"
              and type(a.player)=="table" then
            local okD,sw,sh=pcall(image.getDimensions,image)
            if okD and tonumber(sw) and tonumber(sh) and sw>0 and sh>0 then
              local winW,winH=g.getDimensions()
              local sourceW=tonumber(shot.pw) or tonumber(winW) or 1
              local sourceH=tonumber(shot.ph) or tonumber(winH) or 1
              local rx=(tonumber(winW) or sourceW)/math.max(1,sourceW)
              local ry=(tonumber(winH) or sourceH)/math.max(1,sourceH)
              local vx=(tonumber(layout.viewportX) or tonumber(shot.viewportX)
                or tonumber(shot.lx) or 0)*rx
              local vy=(tonumber(layout.viewportY) or tonumber(shot.viewportY)
                or tonumber(shot.ly) or 0)*ry
              local uiScale=tonumber(layout.scale) or tonumber(shot.scale) or 1
              local ax=tonumber(a.player[1]) or 26
              -- WIDE translates the classic player slot down by eight rows.
              -- On touch layouts that lands the flat trainer/Pokemon inside
              -- the command strip. Restore the classic feet row (96) for the
              -- mobile pinned presentation only.
              local ay=(tonumber(a.player[2]) or 96)-8
              local slide=(tonumber(battle.introSlide) or 0)*2
              local shakeX,shakeY=0,0
              local fx=battle.fx
              if type(fx)=="table" then
                shakeX=tonumber(fx.shakeX) or 0
                shakeY=tonumber(fx.shakeY) or 0
                if shakeX==0 and shakeY==0 and (tonumber(fx.shake) or 0)>0 then
                  shakeX=((tonumber(battle.frame) or 0)%4<2) and 2 or -2
                end
              end
              local off=0
              if type(battle.picOffset)=="function" then
                local okO,value=pcall(battle.picOffset,battle,"back")
                if okO then off=tonumber(value) or 0 end
              end
              local artScale=custom and 1 or 2
              local sx=artScale*uiScale*rx
              local sy=artScale*uiScale*ry
              local cx=vx+(ax+slide+shakeX+off)*uiScale*rx
              local feetY=vy+(ay+shakeY)*uiScale*ry
              local pushed=false
              local okDraw,err=pcall(function()
                g.push("all"); pushed=true
                if g.origin then g.origin() end
                if g.setShader then g.setShader() end
                if image.setFilter then pcall(image.setFilter,image,"nearest","nearest") end
                local tint=shot.tint
                local r,gg,b=1,1,1
                if type(tint)=="table" then
                  r=tonumber(tint[1]) or 1
                  gg=tonumber(tint[2]) or 1
                  b=tonumber(tint[3]) or 1
                end
                g.setColor(r,gg,b,1)
                if type(g.setScissor)=="function" then
                  local clipH=math.max(0,math.min(tonumber(winH) or feetY,feetY))
                  g.setScissor(0,0,tonumber(winW) or 1,clipH)
                end
                g.draw(image,cx-sw*sx*0.5,feetY-sh*sy,0,sx,sy)
                g.pop(); pushed=false
              end)
              if pushed then pcall(g.pop) end
              if not okDraw and mod.log and type(mod.log.error)=="function" then
                mod.log:error("PotatoVoxel mobile pinned trainer draw failed: %s",tostring(err))
              end
            end
          end
        end
      end

      -- BACK SPRITES quality path. The 160x144 UI layer is deliberately kept
      -- transparent for KIM's pinned player; redraw the original atlas frame
      -- here at final window resolution. The logical footprint is identical to
      -- v57's fitted 48x48 proxy, but no pixels are discarded before upscale.
      if topBattle and battle and live==battle and type(shot)=="table" and kimSpritesOn() then
        local pinned=false
        if type(OverworldBattle.backPinned)=="function" then
          local okP,value=pcall(OverworldBattle.backPinned)
          pinned=okP and value==true
        end
        local getter=mod.exports and mod.exports._kantoInMotionPotatoPinnedBackNative
        local layout=shot.layout
        local a=shot.anchors or OverworldBattle.ANCHOR
        if pinned and type(getter)=="function" and type(layout)=="table"
            and type(a)=="table" and type(a.player)=="table" then
          local okI,image,fit=pcall(getter,battle)
          if okI and image and type(image.getDimensions)=="function" then
            local okD,sw,sh=pcall(image.getDimensions,image)
            if okD and tonumber(sw) and tonumber(sh) and sw>0 and sh>0 then
              local winW,winH=g.getDimensions()
              local sourceW=tonumber(shot.pw) or tonumber(winW) or 1
              local sourceH=tonumber(shot.ph) or tonumber(winH) or 1
              local rx=(tonumber(winW) or sourceW)/math.max(1,sourceW)
              local ry=(tonumber(winH) or sourceH)/math.max(1,sourceH)
              local vx=(tonumber(layout.viewportX) or tonumber(shot.viewportX)
                or tonumber(shot.lx) or 0)*rx
              local vy=(tonumber(layout.viewportY) or tonumber(shot.viewportY)
                or tonumber(shot.ly) or 0)*ry
              local uiScale=tonumber(layout.scale) or tonumber(shot.scale) or 1
              local ax=tonumber(a.player[1]) or 40
              local ay=tonumber(a.player[2]) or 96
              -- BACK SPRITES bypasses directCard entirely.  The WIDE layout
              -- moves this native slot from row 96 to row 104; on mobile that
              -- is exactly the extra eight rows that leave large backs such as
              -- Charizard standing on KIM's lower panel. Undo only that WIDE
              -- Y translation for mobile KIM-owned battles. Desktop and native
              -- BATTLE SYSTEM = OFF keep Potato's authored placement.
              local mobilePinnedLift=0
              if kimBattleOn() and type(mod._kantoInMotionNativeMobileHost)=="function" then
                local okM,value=pcall(mod._kantoInMotionNativeMobileHost)
                if okM and value==true then mobilePinnedLift=8 end
              end
              fit=tonumber(fit) or 1
              local transforms=potatoBattlerTransforms(battle,"player")
              if not transforms or #transforms==0 then transforms={{ visible=true }} end
              for _,tr in ipairs(transforms) do
                if not tr or tr.visible~=false then
                  local dx=tr and (tonumber(tr.dx) or 0) or 0
                  local dy=tr and (tonumber(tr.dy) or 0) or 0
                  local zx=tr and (tonumber(tr.scaleX) or 1) or 1
                  local zy=tr and (tonumber(tr.scaleY) or 1) or 1
                  local ang=tr and (tonumber(tr.rotation) or 0) or 0
                  local alpha=tr and (tonumber(tr.opacity) or 1) or 1
                  if tr and tr.mirror then zx=-zx end
                  local cx=vx+(ax+dx)*uiScale*rx
                  local feetY=vy+(ay+dy-mobilePinnedLift)*uiScale*ry
                  local sx=fit*uiScale*rx
                  local sy=fit*uiScale*ry
                  local pushed=false
                  local okDraw,err=pcall(function()
                    g.push("all"); pushed=true
                    if g.origin then g.origin() end
                    if g.setShader then g.setShader() end
                    if image.setFilter then pcall(image.setFilter,image,"nearest","nearest") end
                    -- Preserve Potato's daylight/night tint on the pinned sprite.
                    local tint=shot.tint
                    local r,gg,b=1,1,1
                    if type(tint)=="table" then
                      r=tonumber(tint[1]) or 1
                      gg=tonumber(tint[2]) or 1
                      b=tonumber(tint[3]) or 1
                    end
                    g.setColor(r,gg,b,alpha)
                    -- The original back pic is not allowed to spill through the
                    -- text/menu boundary. Keep the same boundary at the fixed
                    -- authored feet row even while the battler lunges.
                    if type(g.setScissor)=="function" then
                      -- Only protect the lower command/menu area. Do not clip
                      -- the high-resolution KIM back sprite to Potato's narrow
                      -- 160x144 viewport sides: large Gen 5 backs (Charizard in
                      -- particular) legitimately extend left of that logical
                      -- card when PLAYER PKMN SIZE is above 100%. v59 clipped
                      -- those pixels even though the sprite anchor was correct.
                      local clipBottom=vy+((ay-mobilePinnedLift)*uiScale*ry)
                      local clipW=tonumber(winW) or 1
                      local clipH=math.max(0,math.min(tonumber(winH) or clipBottom,clipBottom))
                      g.setScissor(0,0,clipW,clipH)
                    end
                    g.translate(cx,feetY)
                    if ang~=0 then g.rotate(ang) end
                    if zx~=1 or zy~=1 then g.scale(zx,zy) end
                    g.draw(image,-sw*sx*0.5,-sh*sy,0,sx,sy)
                    g.pop(); pushed=false
                  end)
                  if pushed then pcall(g.pop) end
                  if not okDraw and mod.log and type(mod.log.error)=="function" then
                    mod.log:error("PotatoVoxel native pinned back draw failed: %s",tostring(err))
                  end
                end
              end
            end
          end
        end
      end

      if topBattle and battle and live==battle and type(shot)=="table" and sess and not sess.done
          and kimAnimationsOn() then
        local drawer=mod.exports and mod.exports._kantoInMotionDrawKrbaPotato
        local layout=shot.layout
        local a=shot.anchors or OverworldBattle.ANCHOR
        local sp=shot.player
        local se=shot.enemy
        if type(drawer)=="function" and type(layout)=="table"
            and type(a)=="table" and type(a.player)=="table" and type(a.enemy)=="table"
            and type(sp)=="table" and type(se)=="table" then
          local px,py=sp[1],sp[2]
          if type(OverworldBattle.backPinned)=="function" then
            local okP,pinned=pcall(OverworldBattle.backPinned)
            if okP and pinned then px,py=a.player[1],a.player[2] end
          end
          local cx,cy=(se[1]+px)*0.5,(se[2]+py)*0.5
          local ax,ay=(a.enemy[1]+a.player[1])*0.5,
                      (a.enemy[2]+a.player[2])*0.5
          local k=1
          if type(OverworldBattle.animScale)=="function" then
            local okK,value=pcall(OverworldBattle.animScale,shot,px,py)
            if okK and tonumber(value) then k=tonumber(value) end
          end

          -- Essentials particles are authored around battler CENTRES, whereas
          -- Potato publishes the projected FEET of each billboard.  v54 used
          -- the feet midpoint as if it were the Essentials midpoint, leaving
          -- target-local attacks visibly below/away from the opponent. Recover
          -- the canonical Gen1 centre offsets and scale them with each live
          -- 3D card's projected cell span. BACK SPRITES keeps the player in
          -- the fixed native slot, so that side retains the canonical offset.
          local pinned=false
          if type(OverworldBattle.backPinned)=="function" then
            local okP,value=pcall(OverworldBattle.backPinned)
            pinned=okP and value==true
          end
          local ps=tonumber(shot.playerSpan)
          local es=tonumber(shot.enemySpan)
          local pScale=(not pinned and ps and ps>0) and math.max(0.5,math.min(2.0,ps/56)) or 1
          local eScale=(es and es>0) and math.max(0.5,math.min(2.0,es/56)) or 1
          local playerCenter={ px + 14*pScale, py - 26*pScale }
          local enemyCenter={ se[1] - 4*eScale, se[2] - 26*eScale }
          local effectScale=math.max(0.5,math.min(2.0,(pScale+eScale)*0.5))

          local winW,winH
          if type(g.getDimensions)=="function" then winW,winH=g.getDimensions() end
          local sourceW=tonumber(shot.pw) or tonumber(winW) or 1
          local sourceH=tonumber(shot.ph) or tonumber(winH) or 1
          local rx=(tonumber(winW) or sourceW)/math.max(1,sourceW)
          local ry=(tonumber(winH) or sourceH)/math.max(1,sourceH)
          local vx=(tonumber(layout.viewportX) or tonumber(shot.viewportX)
            or tonumber(shot.lx) or 0)*rx
          local vy=(tonumber(layout.viewportY) or tonumber(shot.viewportY)
            or tonumber(shot.ly) or 0)*ry
          local uiScale=tonumber(layout.scale) or tonumber(shot.scale) or 1

          local pushed=false
          local okDraw,err=pcall(function()
            g.push("all"); pushed=true
            if g.origin then g.origin() end
            if g.setShader then g.setShader() end
            if g.setColor then g.setColor(1,1,1,1) end
            g.translate(vx,vy)
            g.scale(uiScale*rx,uiScale*ry)
            local handled=drawer(battle,{
              authoredCenter={ax,ay}, projectedCenter={cx,cy}, scale=k,
              playerCenter=playerCenter, enemyCenter=enemyCenter,
              effectScale=effectScale, finalScreen=true, skipPlanes=true,
            })
            g.pop(); pushed=false
            if handled~=true then error("KRBA final provider declined active session",0) end
          end)
          if pushed then pcall(g.pop) end
          if okDraw then
            if not animHudHitLogged and mod.log and type(mod.log.info)=="function" then
              animHudHitLogged=true
              mod.log:info("PotatoVoxel: drawing KIM KRBA on final HUD layer")
            end
          elseif not animBridgeErrorLogged then
            animBridgeErrorLogged=true
            if mod.log and type(mod.log.error)=="function" then
              mod.log:error("PotatoVoxel KRBA final HUD draw failed: %s",tostring(err))
            end
          end
        end
      end
      return unpackFn(result,2,#result)
    end,19000)
    finalAnimHudInstalled=true
    return true
  end

  -- QOL still emits its legacy voxel-coordinate overlays during Potato's
  -- staged battle. Depending on mobile renderer order those primitives may be
  -- on dramaticShapeShot.canvas OR the source/UI canvas. Rebase the caught
  -- marker and, when KIM owns the snapped HUD, the EXP bar onto the final HUD
  -- layer. Drawing the EXP fill
  -- directly into Potato's world canvas leaves it underneath KIM's opaque HUD
  -- and also keeps it at Potato's fixed source Y when HUD SCALE changes.
  -- Quality of Life itself remains unmodified.
  local function installCaughtAlignment()
    local g=love and love.graphics
    if not (g and type(g.rectangle)=="function" and type(g.getCanvas)=="function") then
      return false
    end
    if g._kantoInMotionPotatoCaughtAlignmentV86 then return true end
    -- Earlier builds installed narrower caught/EXP rectangle wrappers. When
    -- this patch is hot-reloaded in the same process, peel off that exact KIM
    -- layer so the v86 mobile final-space QOL router becomes outermost immediately.
    local previousPotatoRouter=g._kantoInMotionPotatoCaughtAlignment
    if previousPotatoRouter and g.rectangle~=previousPotatoRouter then
      g.rectangle=previousPotatoRouter
    end
    local innerRectangle=g.rectangle
    local EPS=0.75
    local caughtPixels={}
    local caughtFrame=nil
    local caughtBattle=nil
    local xpBar=nil
    local xpBurst={}
    local xpFrame=nil
    local xpBattle=nil
    local unpackFn=table.unpack or unpack
    local postBattleDraw=false

    local mobileHost=false
    if type(mod._kantoInMotionNativeMobileHost)=="function" then
      local ok,value=pcall(mod._kantoInMotionNativeMobileHost)
      mobileHost=ok and value==true
    end

    -- Desktop QOL is intercepted on Battle Art/Potato's scaled shot canvas.
    -- Android/iOS can run QOL *after* BattleState:draw has returned, at which
    -- point QOL falls back to its ordinary native/WIDE 1px/2px primitives.
    -- Track that exact post-draw window so those fallback pixels can be decoded
    -- without mistaking ordinary native/KRBA rectangles for QOL overlays.
    if mobileHost then
      local okState,BattleState=pcall(require,"src.battle.BattleState")
      if okState and type(BattleState)=="table" and type(BattleState.draw)=="function"
          and not BattleState._kantoInMotionPotatoQolPostDrawV86 then
        local originalBattleDraw=BattleState.draw
        BattleState._kantoInMotionPotatoQolPostDrawV86=originalBattleDraw
        BattleState.draw=function(self,...)
          activeBattle=self
          postBattleDraw=false
          local result={pcall(originalBattleDraw,self,...)}
          postBattleDraw=true
          local ok=table.remove(result,1)
          if not ok then error(result[1],0) end
          return unpackFn(result)
        end
      end
    end

    local qolHandle=nil
    local function qolOption(game,key)
      if not qolHandle and type(mod.find)=="function" then
        local ok,handle=pcall(mod.find,"quality_of_life")
        if ok then qolHandle=handle end
      end
      local exports=qolHandle and type(qolHandle.exports)=="table"
        and qolHandle.exports or nil
      if exports and type(exports.optionValue)=="function" then
        local ok,value=pcall(exports.optionValue,game,key)
        if ok then return value end
      end
      return nil
    end

    local function battleShake(battle)
      local fx=battle and battle.fx
      local sx=fx and tonumber(fx.shakeX) or 0
      local sy=fx and tonumber(fx.shakeY) or 0
      if sx==0 and sy==0 and fx and (tonumber(fx.shake) or 0)>0 then
        sx=((tonumber(battle.frame) or 0)%4<2) and 2 or -2
      end
      return sx or 0,sy or 0,fx and (tonumber(fx.hudShakeX) or 0) or 0
    end

    local function enemyNameX(battle)
      local name=battle and battle.enemy and battle.enemy.name or ""
      local glyphs=#tostring(name)
      local Font=mod and mod.ui and mod.ui.Font
      if Font and type(Font.split)=="function" then
        local ok,parts=pcall(Font.split,tostring(name))
        if ok and type(parts)=="table" then glyphs=#parts end
      end
      return 8+(glyphs<=2 and 16 or glyphs<=4 and 8 or 0)
    end

    -- Mobile Battle Art already solved this exact high-DPI split: KIM's HUD
    -- geometry is authored in physical playfield pixels, while render.hud is
    -- drawn in LOVE/window units. Reuse the same ScreenPosition lift contract
    -- before mapping the captured QOL pixels into final HUD space.
    local function mobileTouchOrientation(game)
      if not mobileHost then return nil end
      local touch=game and game.touchControls
      local stack=game and game.stack
      if not touch or (stack and type(stack.touchControlsHidden)=="function"
          and stack:touchControlsHidden()) then return nil end
      if type(touch.visible)~="function" then return nil end
      local okVisible,visible=pcall(touch.visible,touch)
      if not okVisible or not visible then return nil end
      local w,h=0,0
      if type(g.getPixelDimensions)=="function" then
        local ok,pw,ph=pcall(g.getPixelDimensions)
        if ok then w,h=tonumber(pw) or 0,tonumber(ph) or 0 end
      end
      if not (w>0 and h>0) and type(g.getDimensions)=="function" then
        local ok,uw,uh=pcall(g.getDimensions)
        if ok then w,h=tonumber(uw) or 0,tonumber(uh) or 0 end
      end
      if not (w>0 and h>0) then return "landscape" end
      return h>w and "portrait" or "landscape"
    end

    local function screenLiftPx(game,pw,ph)
      if not mobileTouchOrientation(game) then return 0 end
      local okSp,ScreenPosition=pcall(require,"src.core.ScreenPosition")
      if not okSp or not ScreenPosition or type(ScreenPosition.lift)~="function" then
        return 0
      end
      if type(ScreenPosition.skinActive)=="function" then
        local okSkin,skin=pcall(ScreenPosition.skinActive)
        if okSkin and skin then return 0 end
      end
      local s=math.max(1,math.floor(math.min((tonumber(pw) or 160)/160,
        (tonumber(ph) or 144)/144)))
      local dpiY=1
      if type(g.getDimensions)=="function" and type(g.getPixelDimensions)=="function" then
        local okU,_,uh=pcall(g.getDimensions)
        local okP,_,pixH=pcall(g.getPixelDimensions)
        if okU and okP and tonumber(uh) and tonumber(pixH) and uh>0 and pixH>0 then
          dpiY=pixH/uh
        end
      end
      local safe=0
      if type(ScreenPosition.safeTop)=="function" then
        local ok,value=pcall(ScreenPosition.safeTop)
        if ok then safe=(tonumber(value) or 0)*dpiY end
      end
      local ok,value=pcall(ScreenPosition.lift,ph,144*s,safe)
      return ok and math.max(0,tonumber(value) or 0) or 0
    end

    local function shotDimensions(shot)
      -- Prefer Potato's published playfield dimensions. They are the coordinate
      -- contract used by QOL's shot.pw/shot.ly formulas and match the physical
      -- playfield that KIM's mobile HUD geometry consumes. Only fall back to the
      -- canvas size for older Potato builds that do not publish pw/ph.
      local pw,ph=tonumber(shot and shot.pw),tonumber(shot and shot.ph)
      local canvas=shot and shot.canvas
      if not (pw and ph) and canvas and type(canvas.getDimensions)=="function" then
        local ok,w,h=pcall(canvas.getDimensions,canvas)
        if ok then pw,ph=tonumber(w),tonumber(h) end
      end
      return pw,ph
    end

    -- Convert Potato's physical shot/playfield coordinates to the exact LOVE
    -- coordinate rectangle used by render.hud. Desktop is intentionally the
    -- identity transform. On mobile, viewport.view* is the same playfield rect
    -- KIM's final HUD uses, so this also accounts for TouchSkin side gutters.
    local function finalSpace(viewport,shot)
      if not mobileHost then return 0,0,1,1 end
      local pw,ph=shotDimensions(shot)
      if not (pw and ph and pw>0 and ph>0) then return 0,0,1,1 end
      local ox=tonumber(viewport and viewport.viewX)
      local oy=tonumber(viewport and viewport.viewY)
      local vw=tonumber(viewport and viewport.viewWidth)
      local vh=tonumber(viewport and viewport.viewHeight)
      if not (ox and oy and vw and vh and vw>0 and vh>0) then
        ox=tonumber(viewport and viewport.x) or 0
        oy=tonumber(viewport and viewport.y) or 0
        vw=tonumber(viewport and viewport.width)
        vh=tonumber(viewport and viewport.height)
      end
      if not (vw and vh and vw>0 and vh>0) and type(g.getDimensions)=="function" then
        local ok,w,h=pcall(g.getDimensions)
        if ok then vw,vh=tonumber(w),tonumber(h) end
        ox,oy=0,0
      end
      if not (vw and vh and vw>0 and vh>0) then return 0,0,1,1 end
      return ox or 0,oy or 0,vw/pw,vh/ph
    end

    local function finalRect(viewport,shot,x,y,w,h)
      local ox,oy,rx,ry=finalSpace(viewport,shot)
      return innerRectangle("fill",ox+x*rx,oy+y*ry,w*rx,h*ry)
    end

    local function overlayCanvasAllowed(shot)
      if g.getCanvas()==(shot and shot.canvas) then return true end
      -- v84 broadens the QOL capture boundary only on the native mobile host.
      -- Desktop Potato keeps the stricter world-canvas contract that was
      -- already stable before this Android/iOS renderer-order regression.
      if type(mod._kantoInMotionNativeMobileHost)=="function" then
        local ok,value=pcall(mod._kantoInMotionNativeMobileHost)
        return ok and value==true
      end
      return false
    end

    local function targetGeometry(battle,shot)
      local pw,ph=shotDimensions(shot)
      if not (pw and ph) then return nil end

      if kimBattleOn() and type(battleHudGeometry)=="function" then
        local lift=mobileHost and screenLiftPx(battle and battle.game,pw,ph) or 0
        local ok,geo=pcall(battleHudGeometry,pw,ph,lift,battle and battle.game)
        local hs=ok and type(geo)=="table" and tonumber(geo.hudScale) or nil
        if hs and hs>0 and tonumber(geo.enemyBandX) and tonumber(geo.enemyBandY) then
          return tonumber(geo.enemyBandX),tonumber(geo.enemyBandY),hs
        end
      end

      local layout=shot and shot.layout
      local hud=layout and layout.hud and layout.hud.enemy
      local hs=layout and tonumber(layout.scale) or tonumber(shot and shot.scale)
      local vx=layout and tonumber(layout.viewportX) or 0
      local vy=layout and tonumber(layout.viewportY) or 0
      if type(hud)=="table" and hs and hs>0 then
        return vx+(tonumber(hud[1]) or 8)*hs,
               vy+(tonumber(hud[2]) or 0)*hs,hs
      end
      return nil
    end

    local function playerGeometry(battle,shot)
      local pw,ph=shotDimensions(shot)
      if not (pw and ph and type(battleHudGeometry)=="function") then return nil end
      local lift=mobileHost and screenLiftPx(battle and battle.game,pw,ph) or 0
      local ok,geo=pcall(battleHudGeometry,pw,ph,lift,battle and battle.game)
      if not (ok and type(geo)=="table") then return nil end
      local hs=tonumber(geo.hudScale)
      local py=tonumber(geo.playerBandY)
      if not (hs and hs>0 and py) then return nil end
      return pw,ph,hs,py
    end

    local function captureXp(battle,progress,sourceKind)
      local frame=tonumber(battle and battle.frame) or 0
      local r,gg,b,a=1,1,1,1
      if type(g.getColor)=="function" then r,gg,b,a=g.getColor() end
      if xpBattle~=battle or xpFrame~=frame then xpBurst={} end
      xpBattle=battle
      xpFrame=frame
      xpBar={ progress=progress, sourceKind=sourceKind, r=r, g=gg, b=b, a=a }
      return true
    end

    local function routeXpMobileFallback(battle,nx,ny,nw,nh)
      if not (mobileHost and postBattleDraw) then return false end
      local progress,kind
      -- This is the same fallback geometry the established mobile Battle Art
      -- bridge uses: QOL emits either its 160x144 row or its WIDE row after the
      -- underlying BattleState draw has completed.
      if math.abs(nh-2)<0.51 and math.abs(ny-89)<=4
          and nx>=75 and nx<=160 and nw>0 and nw<=67 then
        progress=nw
        kind="native"
      elseif math.abs(nh-2)<0.51 and math.abs(ny-91)<=4
          and nx>=180 and nx<=330 and nw>0 and nw<=80 then
        progress=nw*67/80
        kind="wide"
      else
        return false
      end
      return captureXp(battle,math.max(0,math.min(67,progress)),kind)
    end

    local function routeXpBurstMobileFallback(battle,nx,ny,nw,nh)
      if not (mobileHost and postBattleDraw and xpBattle==battle and xpBar
          and xpFrame==(tonumber(battle and battle.frame) or 0)) then return false end
      if math.abs(nw-1)>=0.51 or math.abs(nh-1)>=0.51 then return false end
      local sx0,sy0
      if xpBar.sourceKind=="wide" then sx0,sy0=288,92 else sx0,sy0=80,90 end
      if nx<sx0-32 or nx>sx0+32 or ny<sy0-32 or ny>sy0+32 then return false end
      local r,gg,b,a=1,1,1,1
      if type(g.getColor)=="function" then r,gg,b,a=g.getColor() end
      xpBurst[#xpBurst+1]={x=nx-sx0,y=ny-sy0,r=r,g=gg,b=b,a=a,mobileFallback=true}
      return true
    end

    local function routeCaughtMobileFallback(battle,nx,ny,nw,nh)
      if not (mobileHost and postBattleDraw and battle and battle.kind=="wild") then
        return false
      end
      if math.abs(nw-1)>=0.51 or math.abs(nh-1)>=0.51 then return false end
      local mode=qolOption(battle.game,"qol_caught_indicator")
      if mode~="gen2" and mode~="red" and mode~="grey" then return false end

      local wide=false
      if type(battle.wideLayout)=="function" then
        local ok,value=pcall(battle.wideLayout,battle)
        wide=ok and value==true
      end
      local sx,sy,hudShake=battleShake(battle)
      local anchorX,anchorY
      if wide then
        anchorX,anchorY=112+sx,7+sy
        if mode=="gen2" then
          anchorX,anchorY=anchorX+1,anchorY+2
        else
          anchorX,anchorY=anchorX+1,anchorY+1
        end
      else
        anchorX,anchorY=7+sx+hudShake,7+sy
        if mode=="gen2" then
          anchorX,anchorY=anchorX+2,anchorY+2
        else
          anchorX,anchorY=anchorX+1,anchorY+1
        end
      end

      local side=mode=="gen2" and 6 or 7
      local ux,uy=nx-anchorX,ny-anchorY
      if ux < -0.01 or ux > side-1+0.01
          or uy < -0.01 or uy > side-1+0.01 then return false end

      local frame=tonumber(battle.frame) or 0
      if caughtBattle~=battle or caughtFrame~=frame then
        caughtBattle=battle; caughtFrame=frame; caughtPixels={}
      end
      local r,gg,b,a=1,1,1,1
      if type(g.getColor)=="function" then r,gg,b,a=g.getColor() end
      caughtPixels[#caughtPixels+1]={
        x=ux,y=uy,mode=mode,normalized=true,r=r,g=gg,b=b,a=a,
      }
      return true
    end

    local function routeXp(battle,shot,nx,ny,nw,nh)
      if not overlayCanvasAllowed(shot) then return false end
      -- QOL historically drew this strip into Potato's WORLD canvas. On the
      -- current mobile renderer its post-BattleState pass can instead still be
      -- bound to the UI/source canvas while using Potato's voxel coordinates.
      -- Match the very specific Potato EXP geometry rather than requiring one
      -- exact canvas, then replay it on the final HUD after composition.
      local sc=tonumber(shot.scale)
      local pw=tonumber(shot.pw)
      local ly=tonumber(shot.ly)
      if not (sc and sc>0 and pw and ly) then return false end
      if math.abs(nh-2*sc)>EPS or math.abs(ny-(ly+89*sc))>EPS then
        return false
      end
      local progress=nw/sc
      if not (progress>0 and progress<=67.5) then return false end
      local sourceX=pw-(13+progress)*sc
      if nx<sourceX-EPS or nx>pw-13*sc+EPS then return false end

      -- Suppress the source copy. render.hud replays this after the active
      -- player HUD, so it cannot sit underneath the opaque HUD tiles.
      return captureXp(battle,progress,"scaled")
    end

    local function routeXpBurst(battle,shot,nx,ny,nw,nh)
      if not overlayCanvasAllowed(shot) then return false end
      local sc=tonumber(shot.scale)
      local pw=tonumber(shot.pw)
      local ly=tonumber(shot.ly)
      if not (sc and sc>0 and pw and ly) then return false end
      if math.abs(nw-sc)>EPS or math.abs(nh-sc)>EPS then return false end
      local baseX=pw-(13+67)*sc
      local baseY=ly+90*sc
      if nx<baseX-32*sc or nx>baseX+32*sc
          or ny<baseY-32*sc or ny>baseY+32*sc then return false end
      local frame=tonumber(battle and battle.frame) or 0
      if xpBattle~=battle or xpFrame~=frame or not xpBar then return false end
      local r,gg,b,a=1,1,1,1
      if type(g.getColor)=="function" then r,gg,b,a=g.getColor() end
      xpBurst[#xpBurst+1]={
        x=(nx-baseX)/sc,y=(ny-baseY)/sc,r=r,g=gg,b=b,a=a,
      }
      return true
    end

    local function routeCaught(battle,shot,nx,ny,nw,nh)
      if not overlayCanvasAllowed(shot) then return false end
      if battle and battle.kind and battle.kind~="wild" then return false end
      local sc=tonumber(shot.scale)
      local ly=tonumber(shot.ly)
      if not (sc and sc>0 and ly) then return false end
      if math.abs(nw-sc)>EPS or math.abs(nh-sc)>EPS then return false end

      -- QOL's source caught icon is name-relative on BOTH desktop and mobile.
      -- The previous Potato bridge normalized only Android/iOS, so short names
      -- such as ABRA retained QOL's shifted source X on desktop and the icon
      -- landed beside the level instead of KIM's fixed caught-icon anchor.
      -- Decode the 6x6/7x7 cluster for every platform, matching the already
      -- confirmed Battle Art desktop bridge.
      local normalized=nil
      local mode=qolOption(battle and battle.game,"qol_caught_indicator")
      if mode=="gen2" or mode=="red" or mode=="grey" then
        local anchorX=(enemyNameX(battle)-9)*sc
        local anchorY=ly+7*sc
        if mode=="gen2" then
          anchorX,anchorY=anchorX+2*sc,anchorY+2*sc
        else
          anchorX,anchorY=anchorX+sc,anchorY+sc
        end
        local side=mode=="gen2" and 6 or 7
        local ux,uy=(nx-anchorX)/sc,(ny-anchorY)/sc
        if ux>=-0.01 and ux<=side-1+0.01 and uy>=-0.01 and uy<=side-1+0.01 then
          normalized={x=ux,y=uy,mode=mode,normalized=true}
        end
      end

      local lx=nx/sc
      local lY=(ny-ly)/sc
      if not normalized and (lx < -3 or lx > 36 or lY < 6 or lY > 18) then
        return false
      end

      -- The source pixel is underneath the opaque/final HUD. Capture QOL's
      -- own color and replay it after render.hud, mapped through the same
      -- physical-pixel -> LOVE-unit viewport transform as KIM's mobile HUD.
      local frame=tonumber(battle and battle.frame) or 0
      if caughtBattle~=battle or caughtFrame~=frame then
        caughtBattle=battle; caughtFrame=frame; caughtPixels={}
      end
      local r,gg,b,a=1,1,1,1
      if type(g.getColor)=="function" then r,gg,b,a=g.getColor() end
      if normalized then
        normalized.r,normalized.g,normalized.b,normalized.a=r,gg,b,a
        caughtPixels[#caughtPixels+1]=normalized
      else
        caughtPixels[#caughtPixels+1]={ x=lx+8, y=lY, r=r, g=gg, b=b, a=a }
      end
      return true
    end

    g._kantoInMotionPotatoCaughtAlignment=innerRectangle
    g._kantoInMotionPotatoCaughtAlignmentV86=innerRectangle
    g.rectangle=function(mode,x,y,w,h,...)
      local battle=activeBattle
      local nx,ny,nw,nh=tonumber(x),tonumber(y),tonumber(w),tonumber(h)
      if battle and mode=="fill" and nx and ny and nw and nh then
        local shot=rawget(battle,"dramaticShapeShot")
        local O=modules()
        local live=O and type(O.battle)=="function" and O.battle() or nil
        if type(shot)=="table" and shot.canvas and live==battle then
          -- Android/iOS QOL can emit ordinary native/WIDE primitives after the
          -- BattleState draw. Decode those first; if this is the desktop-style
          -- scaled Potato path, fall through to the established routes below.
          if routeXpMobileFallback(battle,nx,ny,nw,nh) then return end
          if routeXpBurstMobileFallback(battle,nx,ny,nw,nh) then return end
          if routeCaughtMobileFallback(battle,nx,ny,nw,nh) then return end
          if routeXp(battle,shot,nx,ny,nw,nh) then return end
          if routeXpBurst(battle,shot,nx,ny,nw,nh) then return end
          if routeCaught(battle,shot,nx,ny,nw,nh) then return end
        end
      end
      return innerRectangle(mode,x,y,w,h,...)
    end

    if mod.hooks and type(mod.hooks.wrap)=="function" then
      mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
        local result={pcall(nextFn,game,viewport)}
        if not result[1] then error(result[2],0) end
        local battle=activeBattle
        local shot=battle and rawget(battle,"dramaticShapeShot") or nil
        local frame=tonumber(battle and battle.frame) or -1

        if battleIsTop(game,battle) and type(shot)=="table"
            and xpBattle==battle and xpBar and xpFrame==frame then
          local progress=tonumber(xpBar.progress) or 0
          if progress>0 then
            local cr,cg,cb,ca=1,1,1,1
            if type(g.getColor)=="function" then cr,cg,cb,ca=g.getColor() end
            g.setColor(xpBar.r or 1,xpBar.g or 1,xpBar.b or 1,xpBar.a or 1)

            if kimBattleOn() then
              local pw,ph,hs,playerY=playerGeometry(battle,shot)
              if pw and ph and hs and playerY then
                local targetW=progress*hs
                local targetX=pw-(13+progress)*hs
                local targetY=playerY+41*hs
                finalRect(viewport,shot,targetX,targetY,targetW,2*hs)
                if #xpBurst>0 then
                  local burstBaseX=pw-(13+67)*hs
                  local burstBaseY=targetY+hs
                  for _,px in ipairs(xpBurst) do
                    g.setColor(px.r or 1,px.g or 1,px.b or 1,px.a or 1)
                    finalRect(viewport,shot,burstBaseX+(tonumber(px.x) or 0)*hs,
                      burstBaseY+(tonumber(px.y) or 0)*hs,hs,hs)
                  end
                end
              end
            else
              -- Native/WIDE Potato HUD. Keep the EXP strip inside the boxed
              -- player HUD, but place it LOWER than the HP digits so it sits
              -- where the user mock shows it: beneath the HP number row and
              -- and just above the bottom border. Scale the QOL 67px source span to
              -- the 80px native HUD width so a full EXP bar visually matches
              -- the box width.
              local layout=shot.layout
              local hud=layout and layout.hud and layout.hud.player
              local hs=layout and tonumber(layout.scale) or tonumber(shot.scale)
              local vx=layout and tonumber(layout.viewportX) or tonumber(shot.viewportX) or 0
              local vy=layout and tonumber(layout.viewportY) or tonumber(shot.viewportY) or tonumber(shot.ly) or 0
              if type(hud)=="table" and hs and hs>0 then
                local hx=vx+(tonumber(hud[1]) or 184)*hs
                local hy=vy+(tonumber(hud[2]) or 56)*hs
                local maxW=60*hs
                local ratio=math.max(0,math.min(1,progress/67))
                local targetW=maxW*ratio
                local targetX=hx+9*hs
                local targetY=hy+23*hs
                finalRect(viewport,shot,targetX,targetY,targetW,2*hs)
                if #xpBurst>0 then
                  local burstBaseX=targetX
                  local burstBaseY=targetY+hs
                  local burstScale=80/67
                  for _,px in ipairs(xpBurst) do
                    g.setColor(px.r or 1,px.g or 1,px.b or 1,px.a or 1)
                    finalRect(viewport,shot,burstBaseX+(tonumber(px.x) or 0)*hs*burstScale,
                      burstBaseY+(tonumber(px.y) or 0)*hs,hs,hs)
                  end
                end
              end
            end
            g.setColor(cr,cg,cb,ca)
          end
        end

        if battleIsTop(game,battle) and type(shot)=="table" and caughtBattle==battle
            and #caughtPixels>0 and caughtFrame==frame then
          local bx,by,hs=targetGeometry(battle,shot)
          if bx and by and hs then
            local cr,cg,cb,ca=1,1,1,1
            if type(g.getColor)=="function" then cr,cg,cb,ca=g.getColor() end
            if kimBattleOn() then
              -- Match the confirmed desktop QOL bridge: decode the source
              -- name-relative icon, then replay it at one fixed HUD-local
              -- anchor so short/long enemy names cannot move the caught ball.
              for _,px in ipairs(caughtPixels) do
                g.setColor(px.r or 1,px.g or 1,px.b or 1,px.a or 1)
                if px.normalized then
                  local targetAnchor=px.mode=="gen2" and 9 or 8
                  finalRect(viewport,shot,bx+(targetAnchor+(tonumber(px.x) or 0))*hs,
                    by+(targetAnchor+(tonumber(px.y) or 0))*hs,hs,hs)
                else
                  finalRect(viewport,shot,bx+px.x*hs,by+px.y*hs,hs,hs)
                end
              end
            else
              -- Potato/native enemy HUD: put the caught ball AFTER the fixed
              -- right-side level field instead of before the Pokemon name.
              -- Normalize the captured QOL pixels so all GEN2/RED/GREY styles
              -- keep their exact shape, then right-anchor the cluster inside
              -- the enemy HUD's top row (x=71 on the classic 80px band).
              local minX,minY=math.huge,math.huge
              for _,px in ipairs(caughtPixels) do
                minX=math.min(minX,tonumber(px.x) or 0)
                minY=math.min(minY,tonumber(px.y) or 0)
              end
              local layout=shot.layout
              local hud=layout and layout.hud and layout.hud.enemy
              local hudW=type(hud)=="table" and tonumber(hud[3]) or 80
              -- User reference mock: four logical pixels left and one
              -- logical pixel lower than v56, placing the ball immediately
              -- after the level text instead of against the HUD's outer edge.
              local anchorX=math.max(2,(hudW or 80)-15)
              local anchorY=8
              for _,px in ipairs(caughtPixels) do
                g.setColor(px.r or 1,px.g or 1,px.b or 1,px.a or 1)
                local ux=(tonumber(px.x) or minX)-minX
                local uy=(tonumber(px.y) or minY)-minY
                finalRect(viewport,shot,bx+(anchorX+ux)*hs,
                  by+(anchorY+uy)*hs,hs,hs)
              end
            end
            g.setColor(cr,cg,cb,ca)
          end
        end
        return unpackFn(result,2,#result)
      end,30000)
    end
    return true
  end

  local function install()
    local OverworldBattle, BattlePics = modules()
    if not OverworldBattle then return false end

    -- Restore Potato's WIDE battle composition at runtime for every live
    -- Potato stage, including KIM-owned HUD/UI battles. Battle Art's forceOG()
    -- writes the engine option to disk, so merely disabling Battle Art or
    -- restarting the game does not undo it. Wrapping isWideBattleLayout covers
    -- BattleState:uiSize(), wideLayout(), Game.wideBattleInStack(), menu
    -- centering and Potato's own BattleScene.metrics() without mutating saves.
    local okBattleState, BattleState = pcall(require, "src.battle.BattleState")
    if okBattleState and type(BattleState) == "table"
        and type(BattleState.isWideBattleLayout) == "function"
        and not BattleState._kantoInMotionPotatoWideLayoutV67 then
      -- v66's wrapper closed over the old "KIM off only" predicate. If this
      -- update is hot-reloaded in the same Gen1Recomp session, unwrap that
      -- exact layer before installing v67 so the new all-Potato rule takes
      -- effect immediately instead of requiring a process restart.
      local originalIsWide = BattleState._kantoInMotionPotatoWideLayoutV66
        or BattleState.isWideBattleLayout
      BattleState._kantoInMotionPotatoWideLayoutV67 = originalIsWide
      BattleState.isWideBattleLayout = function(self, ...)
        if potatoNativeWide(self) then return true end
        return originalIsWide(self, ...)
      end
    end

    local nativeProvider = OverworldBattle.sideTexture

    if installedProviderFor ~= OverworldBattle
        and type(OverworldBattle.setTextureProvider) == "function"
        and type(nativeProvider) == "function" then
      OverworldBattle.setTextureProvider(function(battle, side)
        -- Mobile BATTLE SYSTEM = OFF still allows the explicit PLAYER TRAINER
        -- identity choice.  Do NOT hand Potato a prebuilt 160x144 trainer card:
        -- its BattleScene expects sideTexture itself to establish `texturing`,
        -- disable the pic scissors, force 1x capture and report the trainer
        -- anchor.  Bypassing that native capture is what left only the clipped
        -- cap/backpack fragment on Android/iOS.
        --
        -- Instead swap only battle.playerBackPic for the duration of Potato's
        -- own sideTexture call, then restore it immediately.  This is the same
        -- native capture contract that works on desktop, but scoped late enough
        -- that it cannot poison construction of the mobile 3D stage.
        local mobileNative=false
        if type(mod._kantoInMotionNativeMobileHost)=="function" then
          local okM,value=pcall(mod._kantoInMotionNativeMobileHost)
          mobileNative=okM and value==true
        end
        if mobileNative and not kimBattleOn() and side=="player"
            and stageLive(battle) and battle and battle.showPlayerBack then
          local trainerGetter=mod.exports and mod.exports._kantoInMotionBattleTrainerFrame
          if type(trainerGetter)=="function" then
            local okT,image=pcall(trainerGetter,battle)
            if okT and image then
              local savedBack=battle.playerBackPic
              battle.playerBackPic=image
              trueColorCapture=true
              local result={pcall(nativeProvider,battle,side)}
              trueColorCapture=false
              battle.playerBackPic=savedBack
              if not result[1] then error(result[2],0) end
              if result[2] then return result[2] end
            end
          end
        end

        -- BATTLE SPRITES is likewise independent for this cooperative scene.
        -- Potato owns world/camera geometry, while the explicit KIM sprite
        -- toggle chooses the battler artwork. This remains available even if
        -- the full KIM Battle System/Modern Battle UI are disabled.
        if kimSpritesOn() and stageLive(battle) then
          local getter = mod.exports and mod.exports._kantoInMotionStagedBattleSprite
          if type(getter) == "function" then
            local ok, image, factor = pcall(getter, battle, side)
            if ok and image then
              local card = directCard(image, factor, side, nil, battle)
              if card then return card end
            end
          end
        end

        -- KIM battle ownership is OFF: keep Potato/native battle timing and
        -- every faint/send-out/damage transformation, but suppress only the
        -- paper-hole repair when the public sprite resolver identified this
        -- side as true-colour (HGSS and other compatible providers).
        if trueColorSide(battle, side) then
          trueColorCapture = true
          local result = { pcall(nativeProvider, battle, side) }
          trueColorCapture = false
          if not result[1] then error(result[2], 0) end
          return result[2]
        end

        return nativeProvider(battle, side)
      end)
      installedProviderFor = OverworldBattle
    end

    if BattlePics and originalFilledFor ~= BattlePics
        and type(BattlePics.filled) == "function"
        and not BattlePics._kantoInMotionTrueAlphaBridgeV48 then
      local original = BattlePics.filled
      BattlePics._kantoInMotionTrueAlphaBridgeV48 = original
      BattlePics.filled = function(img, sealBottom)
        -- KIM's Potato-pinned back proxy is true-alpha art. Potato's paper
        -- repair is intentionally useful for original Gen1 keyed-white pics,
        -- but on KIM art it fills legitimate holes (for example the space
        -- between Charizard's tail and wing). The draw-layer flag is active
        -- only during KIM's temporary pinned substitution, so bypass the fill
        -- for that exact draw without changing Potato's native sprites.
        if trueColorCapture or mod._kantoInMotionPotatoPinnedBackScaleActive then
          return img
        end
        return original(img, sealBottom)
      end
      originalFilledFor = BattlePics
    end

    -- Install the last-stage KRBA renderer after Potato's own class wrappers,
    -- and keep QOL's caught marker attached to whichever HUD currently owns
    -- the battle.
    pcall(installFinalAnimHud,OverworldBattle)
    pcall(installAnimDrawBridge,OverworldBattle)
    pcall(installCaughtAlignment)

    return true
  end

  install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() pcall(install) end)
    mod.events:on("game.ready", function() pcall(install) end)

    -- Bind as early as possible. battle.started occurs before the first move
    -- can be queued, while battle.move_used is a second guaranteed seam just
    -- before that move's animation row reaches AnimPlayer:start.  This makes
    -- the bridge reliable even if Potato has not built its first shot yet.
    mod.events:on("battle.started", function(payload)
      local battle = type(payload) == "table" and payload.battle or nil
      activeBattle=battle
      local O = modules()
      if not (battle and O) then return end
      local enabled = true
      if type(O.enabled) == "function" then
        local ok, value = pcall(O.enabled)
        enabled = ok and value == true
      end
      if enabled then pcall(ensureKrbaBound, battle) end
    end)
    mod.events:on("battle.ended", function(payload)
      local battle=type(payload)=="table" and payload.battle or nil
      if battle==nil or battle==activeBattle then activeBattle=nil end
    end)
    mod.events:on("battle.move_used", function(payload)
      local battle = type(payload) == "table" and payload.battle or nil
      if battle and stageLive(battle) then pcall(ensureKrbaBound, battle) end
    end)
  end

  return {
    active = active,
    install = install,
  }
end
