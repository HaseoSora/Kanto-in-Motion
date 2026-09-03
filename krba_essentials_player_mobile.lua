-- Pokémon Essentials PBAnimation -> Gen1Recomp bridge.
-- This intentionally patches the engine AnimPlayer: Gen1Recomp 0.1.80 has a public
-- battle_anims registry for its native 8x8 format, but PBAnimation needs 192x192 cels,
-- true-colour blending, per-frame transforms, BG/FG planes and per-timing SFX.
return function(mod, DATA)
  local AnimPlayer = require("src.battle.AnimPlayer")
  local BattleState = require("src.battle.BattleState")
  local Sound = require("src.core.Sound")

  local SCALE = 160 / 512 -- source 512x384 -> 160x120; battle text begins at y=96
  local FIELD_H = 96
  local SRC_USER_X, SRC_USER_Y = 128, 224
  local SRC_TARGET_X, SRC_TARGET_Y = 384, 96
  local DST_USER_X, DST_USER_Y = SRC_USER_X * SCALE, SRC_USER_Y * SCALE
  local DST_TARGET_X, DST_TARGET_Y = SRC_TARGET_X * SCALE, SRC_TARGET_Y * SCALE

  -- KRS Wide battle composition. Canonical BattleBackGround assets are authored at
  -- 1920x950. The native bridge still renders into Gen1Recomp's battle canvas for
  -- vanilla/fallback layouts; when Kanto Rework UI owns the Wide battle presenter,
  -- a render.hud seam re-composites the Essentials layers around that presenter.
  local KRS_BG_W, KRS_BG_H = 1920, 950
  local WIDE_POS_X = KRS_BG_W / 512
  -- The 0.1.0 native bridge clips the 512x384 Essentials design to the 160x96
  -- Gen1 battle field. Preserve the same vertical framing in Wide instead of
  -- suddenly exposing the source's lower 77 pixels over KRS's footer area.
  local WIDE_SOURCE_FIELD_H = FIELD_H / SCALE
  local WIDE_POS_Y = KRS_BG_H / WIDE_SOURCE_FIELD_H
  -- UI 0.8.29+ fits battle art into a 190x190 box. The original bridge maps an
  -- Essentials 128px battler to 40 native pixels; 190/128 keeps effect size in
  -- the same visual relationship to the KRS battler art at the 1920x1080 base.
  local WIDE_EFFECT_SCALE = 190 / 128
  local activeSession = nil

  -- Resolve the BattleState that owns a given AnimPlayer. KRBA replaces the
  -- engine subanimation player, so GROWL/ROAR would otherwise bypass
  -- BattleState:playAnimSound, which is where Gen1Recomp normally substitutes
  -- the attacking Pokemon's cry for these two move sounds.
  local function battleForAnimPlayer(animPlayer)
    local game = mod and mod.game
    local stack = game and game.stack
    local states = stack and stack.states
    if type(states) == "table" then
      for i = #states, 1, -1 do
        local state = states[i]
        if type(state) == "table" and state.animPlayer == animPlayer
            and state.player and state.enemy then
          return state
        end
      end
    end
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) == "table" and top.animPlayer == animPlayer then return top end
    return nil
  end

  -- Battle Art Voxel 1.9.x publishes a read-only stage contract for mods
  -- that need to compose 2D effects with its projected 3D battlers.  Kanto
  -- Rework's Essentials bridge predates that contract and normally relies on
  -- BattleState:drawPicsLayer for its background/back-priority effects.
  -- Battle Art deliberately suppresses that layer while its voxel shot owns
  -- the battlers, so use the published projection when it is available.
  local BATTLE_ART_ID = "BATTLE_ART_VOXEL_FORK"
  local function battleArtStageApi()
    if not (mod and type(mod.find) == "function") then return nil end
    local ok, handle = pcall(mod.find, mod, BATTLE_ART_ID)
    if not (ok and handle and handle.exports) then return nil end
    local stage = handle.exports.battleStage
    return type(stage) == "table" and stage or nil
  end

  local function battleArtStageState(battle)
    local stage = battleArtStageApi()
    if not (stage and type(stage.state) == "function") then return nil end
    local okState, state = pcall(stage.state, battle)
    if not (okState and type(state) == "table" and state.staged == true
            and state.ready == true) then return nil end
    return state
  end

  -- API v2 is supplied by the Battle Art plane-compat build.  When present,
  -- full-field Essentials timing planes are rendered inside Battle Art's own
  -- window-resolution scene at the correct depth instead of into 160x96.
  local battleArtPlaneApi = nil
  local battleArtBattlerTransformApi = nil

  local function norm(id)
    return tostring(id or ""):upper():gsub("[^A-Z0-9]", "")
  end

  -- Some Essentials self-target animations contain both USER (-1) and TARGET
  -- (-2) battler-picture cells because USER and TARGET resolve to the same
  -- battler in the source engine. Battle Art has two independent world cards,
  -- so forwarding both roles would incorrectly animate the opponent too.
  -- Keep this list deliberately narrow and extend it only for verified moves.
  local USER_ONLY_BATTLER_TRANSFORMS = {
    DEFENSECURL = true,
  }

  -- Battle Art uses staged anchors that can sit a little high on short or
  -- grounded Pokemon compared with Essentials' authored battler footing.
  -- Keep the source coordinates untouched on the native/KRS path, but apply a
  -- small Battle-Art-only vertical correction for verified moves whose effect
  -- should land lower on the target.
  local function battleArtParticlePoint(moveId, attackerIsPlayer, x, y)
    local move = norm(moveId)
    if move ~= "BUBBLE" and move ~= "DIG" then return x, y end
    local ux, uy, tx, ty
    if attackerIsPlayer == false then
      ux, uy, tx, ty = SRC_TARGET_X, SRC_TARGET_Y, SRC_USER_X, SRC_USER_Y
    else
      ux, uy, tx, ty = SRC_USER_X, SRC_USER_Y, SRC_TARGET_X, SRC_TARGET_Y
    end
    local vx, vy = tx - ux, ty - uy
    local denom = vx*vx + vy*vy
    local t = denom > 0 and (((x-ux)*vx + (y-uy)*vy) / denom) or 0
    t = math.max(0, math.min(1, t))
    if move == "BUBBLE" then
      return x, y + 8*t
    end
    -- Dig's dirt burst is authored around the ground under the target. The
    -- staged target anchor can place it around the body/head instead, so ease
    -- the effect down more aggressively as it reaches the target.
    return x, y + 28*t
  end

  -- Many imported Essentials moves only provide a player-side sequence.  A
  -- single 180-degree reflection fixes true user-to-target travel, but it is
  -- wrong for effects authored locally around one battler: it inverts their
  -- local vertical offset (the Wrap-above-the-head bug).  Classify the missing
  -- opponent fallback from the source effect geometry once per session:
  --   target: every visible effect cel is closer to the target anchor -> move
  --           target space to the player target and preserve local offsets;
  --   user:   every visible effect cel is closer to the user anchor -> move
  --           user space to the enemy user and preserve local offsets;
  --   reflect: mixed/travelling effects -> swap sides with a 180-degree point
  --            reflection across the canonical battler midpoint.
  -- Dedicated opponent variants never use this fallback.  Cel rotation/mirror
  -- flags are left untouched in every mode.
  local function classifyEnemyFallback(anim)
    if not (anim and type(anim.frames) == "table") then return "reflect" end
    local visible, targetLocal, userLocal = 0, 0, 0
    for _, frame in ipairs(anim.frames) do
      for _, c in ipairs(frame) do
        local pattern = c[9]
        if pattern and pattern >= 0 and c[8] == 1 and (c[10] or 0) > 0 then
          visible = visible + 1
          local x, y = c[1] or 0, c[2] or 0
          local dt = (x-SRC_TARGET_X)^2 + (y-SRC_TARGET_Y)^2
          local du = (x-SRC_USER_X)^2 + (y-SRC_USER_Y)^2
          if dt < du then targetLocal = targetLocal + 1
          elseif du < dt then userLocal = userLocal + 1 end
        end
      end
    end
    if visible > 0 and targetLocal == visible then return "target" end
    if visible > 0 and userLocal == visible then return "user" end
    return "reflect"
  end

  local function enemyFallbackPoint(mode, x, y)
    x, y = x or 0, y or 0
    if mode == "target" then
      return x + (SRC_USER_X - SRC_TARGET_X),
             y + (SRC_USER_Y - SRC_TARGET_Y)
    elseif mode == "user" then
      return x + (SRC_TARGET_X - SRC_USER_X),
             y + (SRC_TARGET_Y - SRC_USER_Y)
    end
    return 512 - x, 320 - y
  end

  local function needsWideStageCelScale(anim)
    if not (anim and anim.position == 4 and type(anim.frames) == "table") then return false end
    for _, frame in ipairs(anim.frames) do
      local count, left, right = 0, nil, nil
      for _, c in ipairs(frame) do
        local pattern = c[9]
        if pattern and pattern >= 0 and c[8] == 1 and (c[10] or 0) > 0 then
          local scale = (c[3] or 100) / 100
          local l = (c[1] or 0) - 96 * scale
          local r = (c[1] or 0) + 96 * scale
          count = count + 1
          if not left or l < left then left = l end
          if not right or r > right then right = r end
        end
      end
      if count >= 2 and left and right and left < 0 and right > 512 and (right - left) > 600 then
        return true
      end
    end
    return false
  end

  local original = {
    start = AnimPlayer.start, update = AnimPlayer.update, isDone = AnimPlayer.isDone,
    pollEffects = AnimPlayer.pollEffects, draw = AnimPlayer.draw,
    release = AnimPlayer.release, finalSprites = AnimPlayer.finalSprites,
  }
  local originalDrawPicsLayer = BattleState.drawPicsLayer
  local originalDrawAnimLayer = BattleState.drawAnimLayer

  local shader
  local function getShader()
    if shader ~= nil then return shader or nil end
    local g = love and love.graphics
    if not (g and g.newShader) then shader = false; return nil end
    local code = [[
      extern vec4 krs_overlay;
      extern vec4 krs_tone;
      extern float krs_hue;
      vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 px = Texel(tex, tc) * color;
        float c = cos(krs_hue), s = sin(krs_hue);
        mat3 toYIQ = mat3(0.299,0.587,0.114, 0.596,-0.274,-0.322, 0.211,-0.523,0.312);
        mat3 toRGB = mat3(1.0,0.956,0.621, 1.0,-0.272,-0.647, 1.0,-1.106,1.703);
        vec3 yiq = toYIQ * px.rgb;
        float I = yiq.y * c - yiq.z * s;
        float Q = yiq.y * s + yiq.z * c;
        px.rgb = clamp(toRGB * vec3(yiq.x, I, Q), 0.0, 1.0);
        px.rgb = clamp(px.rgb + krs_tone.rgb, 0.0, 1.0);
        float gray = dot(px.rgb, vec3(0.299,0.587,0.114));
        px.rgb = mix(px.rgb, vec3(gray), clamp(krs_tone.a,0.0,1.0));
        px.rgb = mix(px.rgb, krs_overlay.rgb, clamp(krs_overlay.a,0.0,1.0));
        return px;
      }
    ]]
    local ok, sh = pcall(g.newShader, code)
    shader = ok and sh or false
    return shader or nil
  end

  local function withFieldScissor(fn, stage)
    local g = love.graphics
    if not (g and g.getScissor and g.intersectScissor and g.setScissor) then return fn() end
    local x,y,w,h = g.getScissor()

    if stage and stage.layerTransform then
      -- Battle Art applies its animation transform with love.graphics.translate/
      -- scale, but scissors live in the target canvas' fixed coordinates.
      -- Project the authored 160x96 battle field into the same coordinates so
      -- effects such as Scratch/Ember are not clipped at the old GB rectangle.
      local tr = stage.layerTransform
      local ac = tr.authoredCenter or { 75, 76 }
      local pc = tr.projectedCenter or ac
      local k = tonumber(tr.scale) or 1
      if not (k > 0) or k ~= k then k = 1 end
      local left = pc[1] + k * (0 - ac[1])
      local top = pc[2] + k * (0 - ac[2])
      local right = pc[1] + k * (160 - ac[1])
      local bottom = pc[2] + k * (FIELD_H - ac[2])
      if right < left then left,right = right,left end
      if bottom < top then top,bottom = bottom,top end
      g.intersectScissor(math.floor(left), math.floor(top),
                         math.max(1, math.ceil(right) - math.floor(left)),
                         math.max(1, math.ceil(bottom) - math.floor(top)))
    else
      g.intersectScissor(0,0,160,FIELD_H)
    end

    local ok, err = pcall(fn)
    if x then g.setScissor(x,y,w,h) else g.setScissor() end
    if not ok then error(err,0) end
  end

  local function newSession(owner, anim, moveId, attackerIsPlayer, enemyFallbackMode, opponentVariant)
    local s = {
      owner=owner, anim=anim, moveId=moveId, attackerIsPlayer=attackerIsPlayer,
      enemyFallbackMode=enemyFallbackMode, opponentVariant=opponentVariant == true,
      wideStageCelScale=needsWideStageCelScale(anim),
      tick=0, frame=0, done=false, images={}, quads={}, sources={},
      cryMove=(norm(moveId)=="GROWL" or norm(moveId)=="ROAR"),
      cryPlayed=false, crySpecies=nil,
      bg={ file=nil, x=0,y=0,opacity=0,r=0,g=0,b=0,a=0 },
      fg={ file=nil, x=0,y=0,opacity=0,r=0,g=0,b=0,a=0 },
      bgTweens={}, fgTweens={},
    }

    if s.cryMove then
      local battle = battleForAnimPlayer(owner)
      local battler = battle and (attackerIsPlayer and battle.player or battle.enemy)
      s.crySpecies = battler and battler.mon and battler.mon.species or nil
    end

    function s:image(file)
      if not file then return nil end
      local cached=self.images[file]
      if cached ~= nil then return cached or nil end
      local ok,img=pcall(love.graphics.newImage, mod.assets:path("assets/animations/"..file))
      if ok and img then
        if img.setFilter then img:setFilter("nearest","nearest") end
        self.images[file]=img
      else
        self.images[file]=false
        mod.log:warn("animation image unavailable: %s", tostring(file))
      end
      return self.images[file] or nil
    end

    function s:quad(file, pattern)
      local img=self:image(file); if not img then return nil end
      local by=self.quads[file]; if not by then by={}; self.quads[file]=by end
      local q=by[pattern]
      if q==nil then
        local iw,ih=img:getWidth(),img:getHeight()
        local x=(pattern % 5)*192; local y=math.floor(pattern/5)*192
        if x+192<=iw and y+192<=ih then q=love.graphics.newQuad(x,y,192,192,iw,ih) else q=false end
        by[pattern]=q
      end
      return q or nil
    end

    function s:playSound(t)
      local game=mod.game; local d=game and game.data
      if not d then return end

      -- Gen 1 special case: GROWL and ROAR do not play their normal move SFX.
      -- They play the ATTACKER'S species cry, with the move's tempo modifier
      -- layered on top. The stock BattleState already does this; reproduce it
      -- here because the integrated Essentials player owns these animations.
      if self.cryMove and not self.cryPlayed and self.crySpecies then
        self.cryPlayed = true
        local moveDef = d.moves and d.moves[self.moveId]
        local tempo = moveDef and moveDef.anim and moveDef.anim.tempo or nil
        local src
        if type(Sound.playMoveCry) == "function" then
          src = Sound.playMoveCry(d, self.crySpecies, tempo)
        elseif type(Sound.playCry) == "function" then
          src = Sound.playCry(d, self.crySpecies)
        end
        if src then self.sources[#self.sources+1]=src end
        return
      end

      if not t.sfxId then return end
      local src=Sound.playStereo(d,t.sfxId)
      if not src then return end
      if src.setPitch then pcall(src.setPitch,src,(t.pitch or 100)/100) end
      if src.getVolume and src.setVolume then
        local ok,v=pcall(src.getVolume,src)
        if ok then pcall(src.setVolume,src,v*((t.volume or 100)/100)) end
      end
      self.sources[#self.sources+1]=src
    end

    local function setPlane(p,t)
      p.file=t.file or nil
      p.x=t.bgX or 0; p.y=t.bgY or 0; p.opacity=t.opacity or 0
      p.r=t.colorRed or 0; p.g=t.colorGreen or 0; p.b=t.colorBlue or 0; p.a=t.colorAlpha or 0
    end

    -- Essentials can schedule multiple BG/FG tweens on the SAME frame (e.g.
    -- fade opacity while scrolling X).  The old bridge kept one tween per plane,
    -- so the last timing silently cancelled the others.  Track tweens by property
    -- instead; a newer tween replaces only the properties it actually controls.
    local function startTween(self, which, t)
      local p=self[which]
      local targets={}
      if t.bgX~=nil then targets.x=t.bgX end
      if t.bgY~=nil then targets.y=t.bgY end
      if t.opacity~=nil then targets.opacity=t.opacity end
      if t.colorRed~=nil then targets.r=t.colorRed end
      if t.colorGreen~=nil then targets.g=t.colorGreen end
      if t.colorBlue~=nil then targets.b=t.colorBlue end
      if t.colorAlpha~=nil then targets.a=t.colorAlpha end
      if next(targets)==nil then return end

      local key=which.."Tweens"
      local list=self[key] or {}
      -- Remove only overlapping properties from older tweens.
      for i=#list,1,-1 do
        local old=list[i]
        for prop in pairs(targets) do
          if old.to[prop]~=nil then old.to[prop]=nil; old.from[prop]=nil end
        end
        if next(old.to)==nil then table.remove(list,i) end
      end
      local tw={from={},to={},start=t.frame or self.frame,
                duration=math.max(1,t.duration or 5)}
      for prop,target in pairs(targets) do
        tw.from[prop]=p[prop] or 0
        tw.to[prop]=target
      end
      list[#list+1]=tw
      self[key]=list
    end

    local function advanceTweens(self,which)
      local key=which.."Tweens"
      local list=self[key] or {}
      local p=self[which]
      local keep={}
      for _,tw in ipairs(list) do
        local f=math.max(0,math.min(1,(self.frame-tw.start)/tw.duration))
        for prop,target in pairs(tw.to) do
          p[prop]=tw.from[prop]+(target-tw.from[prop])*f
        end
        if f<1 then keep[#keep+1]=tw end
      end
      self[key]=keep
    end

    -- Kanto in Motion integrated KRS arena transform. The public native
    -- transform uses 160x96 bridge units; convert its translation into the
    -- canonical 1920x950 KRS stage while preserving rotation/scale/opacity.
    function s:battlerTransformWide(side)
      local t=self:battlerTransform(side)
      if not t then return nil end
      return {
        visible=t.visible,
        dx=(t.dx or 0)/SCALE*WIDE_POS_X,
        dy=(t.dy or 0)/SCALE*WIDE_POS_Y,
        scaleX=t.scaleX or 1, scaleY=t.scaleY or 1,
        rotation=t.rotation or 0, mirror=t.mirror==true,
        opacity=t.opacity or 1,
      }
    end

    function s:applyTimings(frame)
      for _,t in ipairs(self.anim.timings or {}) do
        if (t.frame or 0)==frame then
          local typ=t.timingType or 0
          if typ==0 then self:playSound(t)
          elseif typ==1 then self.bgTweens={}; setPlane(self.bg,t)
          elseif typ==2 then startTween(self,"bg",t)
          elseif typ==3 then self.fgTweens={}; setPlane(self.fg,t)
          elseif typ==4 then startTween(self,"fg",t) end
        end
      end
      advanceTweens(self,"bg"); advanceTweens(self,"fg")
    end

    function s:update()
      if self.done then return end
      self.tick=self.tick+1
      local nf=math.floor(self.tick/3)
      if nf~=self.frame then
        self.frame=nf
        if self.frame>=#self.anim.frames then self.done=true; return end
        self:applyTimings(self.frame)
      end
    end

    function s:currentCells()
      return self.anim.frames[self.frame+1] or {}
    end
    function s:roleCell(pattern)
      for _,c in ipairs(self:currentCells()) do if c[9]==pattern then return c end end
      return nil
    end

    function s:battlerTransform(side)
      if side ~= "player" and side ~= "enemy" then return nil end
      -- Map the actual battle side back to the Essentials semantic role. The
      -- same player-authored sequence is reused when no dedicated opponent
      -- animation exists, but -1 always means USER and -2 always means TARGET.
      local roleUser = ((side == "player") == (self.attackerIsPlayer == true))
      if USER_ONLY_BATTLER_TRANSFORMS[norm(self.moveId)] and not roleUser then
        return nil
      end

      -- Essentials' hand-authored opponent variants keep the battlefield
      -- picture slots fixed rather than the semantic roles fixed: -1 is the
      -- lower-left/player-side battler and -2 is the upper-right/enemy-side
      -- battler. Therefore, when an enemy-specific `opp` sequence is active,
      -- the USER lives in -2 and the TARGET lives in -1. Player-authored
      -- sequences (including generated enemy fallbacks when opp=nil) retain
      -- the usual -1 USER / -2 TARGET convention.
      local pattern, srcx, srcy
      if self.opponentVariant then
        if roleUser then
          pattern, srcx, srcy = -2, SRC_TARGET_X, SRC_TARGET_Y
        else
          pattern, srcx, srcy = -1, SRC_USER_X, SRC_USER_Y
        end
      else
        if roleUser then
          pattern, srcx, srcy = -1, SRC_USER_X, SRC_USER_Y
        else
          pattern, srcx, srcy = -2, SRC_TARGET_X, SRC_TARGET_Y
        end
      end
      local c = self:roleCell(pattern)
      if not c then return nil end
      local visible = c[8] == 1 and (c[10] or 255) > 0
      return {
        visible = visible,
        dx = ((c[1] or srcx) - srcx) * SCALE,
        dy = ((c[2] or srcy) - srcy) * SCALE,
        scaleX = (c[3] or 100) / 100,
        scaleY = (c[4] or 100) / 100,
        rotation = math.rad(c[5] or 0),
        mirror = (c[6] or 0) ~= 0,
        opacity = math.max(0, math.min(1, (c[10] or 255) / 255)),
      }
    end

    local function blendMode(v)
      if v==1 then return "add" end
      if v==2 then return "subtract" end
      return "alpha"
    end

    function s:drawCell(c, stage)
      local pattern=c[9]; if pattern<0 or c[8]~=1 or (c[10] or 0)<=0 then return end
      local img=self:image(self.anim.graphic); local q=img and self:quad(self.anim.graphic,pattern)
      if not (img and q) then return end
      local g=love.graphics
      local oldMode,oldAlpha=g.getBlendMode()
      local celBlend=blendMode(c[7])
      -- Battle Art exposes the 3D arena through the world canvas and clears the
      -- normal 160x144 battle/UI canvas to transparent. Essentials additive and
      -- subtractive cels cannot survive that transparent intermediate surface
      -- reliably: their RGB contribution is later alpha-composited over the 3D
      -- shot and can disappear completely (Ember is entirely additive). Preserve
      -- the authored blend everywhere else, but use a straight-alpha carrier while
      -- Battle Art owns the staged surface so the particle remains visible when the
      -- UI layer is composited over the voxel arena.
      if stage and celBlend~="alpha" then celBlend="alpha" end
      pcall(g.setBlendMode,celBlend,"alphamultiply")
      local sh=getShader(); if sh then
        g.setShader(sh)
        pcall(sh.send,sh,"krs_overlay",{(c[11] or 0)/255,(c[12] or 0)/255,(c[13] or 0)/255,(c[14] or 0)/255})
        pcall(sh.send,sh,"krs_tone",{(c[15] or 0)/255,(c[16] or 0)/255,(c[17] or 0)/255,(c[18] or 0)/255})
        pcall(sh.send,sh,"krs_hue",math.rad(self.anim.hue or 0))
      end
      g.setColor(1,1,1,(c[10] or 255)/255)
      local sx=(c[3] or 100)/100*SCALE; local sy=(c[4] or 100)/100*SCALE
      if (c[6] or 0)~=0 then sx=-sx end
      local cx,cy=(c[1] or 0),(c[2] or 0)
      if self.enemyFallbackMode then cx,cy=enemyFallbackPoint(self.enemyFallbackMode,cx,cy) end
      if stage then cx,cy=battleArtParticlePoint(self.moveId,self.attackerIsPlayer,cx,cy) end
      g.draw(img,q,cx*SCALE,cy*SCALE,math.rad(c[5] or 0),sx,sy,96,96)
      if sh then g.setShader() end
      g.setColor(1,1,1,1)
      pcall(g.setBlendMode,oldMode,oldAlpha)
    end

    function s:drawParticles(pass, stage)
      withFieldScissor(function()
        for _,c in ipairs(self:currentCells()) do
          local pr=c[20] or 1
          local back=(pr==0 or pr==2)
          if (pass=="back" and back) or (pass=="front" and not back) then self:drawCell(c,stage) end
        end
      end, stage)
    end

    -- Apply exactly the layer projection described by Battle Art's public
    -- battleStage contract.  This is used for back-priority Essentials cels,
    -- because Battle Art's normal drawAnimLayer projection only reaches the
    -- front animation pass.
    function s:drawParticlesBattleArt(pass, stage)
      if not (stage and stage.layerTransform) then
        return self:drawParticles(pass)
      end
      local tr=stage.layerTransform
      local ac=tr.authoredCenter or {75,76}
      local pc=tr.projectedCenter or ac
      local k=tonumber(tr.scale) or 1
      if not (k>0) or k~=k then k=1 end
      local g=love.graphics
      local pushed=pcall(g.push)
      if not pushed then return false end
      local ok,err=pcall(function()
        g.translate((pc[1] or ac[1])-ac[1],(pc[2] or ac[2])-ac[2])
        if k~=1 then
          g.translate(ac[1],ac[2]); g.scale(k,k); g.translate(-ac[1],-ac[2])
        end
        self:drawParticles(pass,stage)
      end)
      pcall(g.pop)
      if not ok then error(err,0) end
      return true
    end

    function s:drawPlane(p)
      if (p.opacity or 0)<=0 then return end
      withFieldScissor(function()
        local g=love.graphics
        if p.file then
          local img=self:image(p.file); if not img then return end
          local iw,ih=img:getWidth()*SCALE,img:getHeight()*SCALE
          if iw<1 or ih<1 then return end
          g.setColor(1,1,1,(p.opacity or 0)/255)
          local ox=(p.x or 0)*SCALE; local oy=(p.y or 0)*SCALE
          local startX=ox-math.ceil((ox+160)/iw)*iw
          local startY=oy-math.ceil((oy+FIELD_H)/ih)*ih
          for y=startY,FIELD_H,ih do for x=startX,160,iw do g.draw(img,x,y,0,SCALE,SCALE) end end
        else
          g.setColor((p.r or 0)/255,(p.g or 0)/255,(p.b or 0)/255,(p.opacity or 0)/255)
          g.rectangle("fill",0,0,160,FIELD_H)
        end
        g.setColor(1,1,1,1)
      end)
    end

    function s:drawBackground() self:drawPlane(self.bg) end
    function s:drawForeground() self:drawPlane(self.fg) end

    -- Data-only descriptor consumed by Battle Art battleStage API v2.  The
    -- source field is the same 512-wide Essentials design cropped to the
    -- bridge's 160x96 visible battle field (307.2 source pixels high).
    function s:planeDescriptor(p)
      if not p or (p.opacity or 0) <= 0 then return nil end
      local img = nil
      if p.file then
        img = self:image(p.file)
        if not img then return nil end
      end
      return {
        image = img, x = p.x or 0, y = p.y or 0,
        opacity = p.opacity or 0,
        r = p.r or 0, g = p.g or 0, b = p.b or 0,
        sourceWidth = 512, sourceHeight = FIELD_H / SCALE,
      }
    end

    -- Draw one Essentials cel in KRS's canonical 1920x950 battle-background
    -- coordinate space. Positions are remapped to the Wide battle anchors, while
    -- sprite scale stays uniform so circles/beams are not stretched horizontally.
    local KIM_KRS_ANCHORED_TRAVEL = { EMBER=true }
    local function remapAxis(v,srcUser,srcTarget,dstUser,dstTarget)
      local span=srcTarget-srcUser
      if span==0 then return dstUser end
      return dstUser+(v-srcUser)*(dstTarget-dstUser)/span
    end

    function s:drawCellWide(c, kimAnchors)
      local pattern=c[9]; if pattern<0 or c[8]~=1 or (c[10] or 0)<=0 then return end
      local img=self:image(self.anim.graphic); local q=img and self:quad(self.anim.graphic,pattern)
      if not (img and q) then return end
      local g=love.graphics
      local oldMode,oldAlpha=g.getBlendMode()
      local kimAnchored = kimAnchors and KIM_KRS_ANCHORED_TRAVEL[norm(self.moveId)] == true
      local celBlend=blendMode(c[7])
      -- Battle Art's staged-surface fix carries Ember's additive particles as
      -- straight alpha so they survive composition without blowing the whole
      -- surface toward white. KIM's fullscreen KRS world is also a staged
      -- compositor, so use that carrier only when KIM supplied its anchors.
      if kimAnchored and norm(self.moveId)=="EMBER" and celBlend~="alpha" then
        celBlend="alpha"
      end
      pcall(g.setBlendMode,celBlend,"alphamultiply")
      local sh=getShader(); if sh then
        g.setShader(sh)
        pcall(sh.send,sh,"krs_overlay",{(c[11] or 0)/255,(c[12] or 0)/255,(c[13] or 0)/255,(c[14] or 0)/255})
        pcall(sh.send,sh,"krs_tone",{(c[15] or 0)/255,(c[16] or 0)/255,(c[17] or 0)/255,(c[18] or 0)/255})
        pcall(sh.send,sh,"krs_hue",math.rad(self.anim.hue or 0))
      end
      g.setColor(1,1,1,(c[10] or 255)/255)
      -- Most move cels should stay visually relative to the battler art in Wide.
      -- A small subset of Essentials animations instead lays out multiple cels
      -- across the entire 512px battle stage (for example Surf, Earthquake and
      -- Fissure). Those source cels must use the stage scale in Wide or they no
      -- longer cover the full screen area they were authored to span.
      local wideScale = self.wideStageCelScale and WIDE_POS_X or WIDE_EFFECT_SCALE
      local sx=(c[3] or 100)/100*wideScale
      local sy=(c[4] or 100)/100*wideScale
      if (c[6] or 0)~=0 then sx=-sx end
      local cx,cy=(c[1] or 0),(c[2] or 0)
      if kimAnchored then
        -- Map the player-authored USER->TARGET path directly between KIM's
        -- actual battler centers. This replaces the old full-stage Y scaling
        -- that mapped Ember's target Y=96 to ~297px local even when the KRS
        -- enemy stands around Y=500. Semantic anchors also handle enemy-used
        -- Ember without applying the old reflected fallback a second time.
        local user = self.attackerIsPlayer and kimAnchors.player or kimAnchors.enemy
        local target = self.attackerIsPlayer and kimAnchors.enemy or kimAnchors.player
        cx=remapAxis(cx,SRC_USER_X,SRC_TARGET_X,user.x,target.x)
        cy=remapAxis(cy,SRC_USER_Y,SRC_TARGET_Y,user.y,target.y)
      else
        if self.enemyFallbackMode then cx,cy=enemyFallbackPoint(self.enemyFallbackMode,cx,cy) end
        cx=cx*WIDE_POS_X
        cy=cy*WIDE_POS_Y
      end
      g.draw(img,q,cx,cy,
             math.rad(c[5] or 0),sx,sy,96,96)
      if sh then g.setShader() end
      g.setColor(1,1,1,1)
      pcall(g.setBlendMode,oldMode,oldAlpha)
    end

    function s:drawParticlesWide(pass, kimAnchors)
      for _,c in ipairs(self:currentCells()) do
        local pr=c[20] or 1
        local back=(pr==0 or pr==2)
        if (pass=="back" and back) or (pass=="front" and not back) then
          self:drawCellWide(c,kimAnchors)
        end
      end
    end

    -- KIM renders its fullscreen battle world into a final-resolution canvas.
    -- Essentials color-only BG/FG planes are screen flashes/tints, not 1920x950
    -- artwork.  Draw those against the actual active canvas so moves such as
    -- ThunderShock do not expose the canonical KRS rectangle on 16:9/mobile.
    local function drawCurrentCanvasColorPlane(p)
      if not p or p.file or (p.opacity or 0)<=0 then return false end
      local g=love and love.graphics
      if not (g and type(g.getCanvas)=="function" and type(g.rectangle)=="function") then
        return false
      end
      local canvas=g.getCanvas()
      if not canvas or type(canvas.getDimensions)~="function" then return false end
      local ok,w,h=pcall(canvas.getDimensions,canvas)
      if not (ok and tonumber(w) and tonumber(h) and w>0 and h>0) then return false end
      g.push("all")
      if g.origin then g.origin() end
      if g.setScissor then g.setScissor() end
      if g.setShader then g.setShader() end
      pcall(g.setBlendMode,"alpha","alphamultiply")
      g.setColor((p.r or 0)/255,(p.g or 0)/255,(p.b or 0)/255,(p.opacity or 0)/255)
      g.rectangle("fill",0,0,w,h)
      g.pop()
      return true
    end

    -- Battle Art 1.10 exposes only the projected stage contract (API v1), not
    -- a full-resolution BG/FG plane provider. Sending an Essentials timing
    -- plane through the native 160x96 battle surface therefore produces the
    -- obvious centered rectangle seen on ThunderShock/Thunder/Flash. Render
    -- *all* timing planes directly in the final HUD/window coordinate space
    -- while Battle Art owns the voxel stage. Image planes preserve Essentials'
    -- authored 512 x 307.2 field mapping and scrolling/tiling behavior; color
    -- planes simply fill the full active viewport.
    function s:drawPlaneScreen(p)
      if not p or (p.opacity or 0)<=0 then return false end
      local g=love and love.graphics
      if not (g and type(g.getDimensions)=="function") then return false end
      local ok,w,h=pcall(g.getDimensions)
      w,h=tonumber(w),tonumber(h)
      if not (ok and w and h and w>0 and h>0) then return false end

      local pushed=pcall(g.push,"all")
      if not pushed then return false end
      local okDraw,drew=pcall(function()
        if g.origin then g.origin() end
        if g.setScissor then g.setScissor(0,0,w,h) end
        if g.setShader then g.setShader() end
        pcall(g.setBlendMode,"alpha","alphamultiply")

        if p.file then
          local img=self:image(p.file)
          if not img then return false end
          local sourceW=512
          local sourceH=FIELD_H/SCALE
          local sx=w/sourceW
          local sy=h/sourceH
          local iw,ih=img:getWidth()*sx,img:getHeight()*sy
          if iw<1 or ih<1 then return false end
          g.setColor(1,1,1,(p.opacity or 0)/255)
          local ox=(p.x or 0)*sx
          local oy=(p.y or 0)*sy
          local startX=ox-math.ceil((ox+w)/iw)*iw
          local startY=oy-math.ceil((oy+h)/ih)*ih
          for y=startY,h,ih do
            for x=startX,w,iw do
              g.draw(img,x,y,0,sx,sy)
            end
          end
        else
          g.setColor((p.r or 0)/255,(p.g or 0)/255,(p.b or 0)/255,(p.opacity or 0)/255)
          g.rectangle("fill",0,0,w,h)
        end
        return true
      end)
      pcall(g.pop)
      if not okDraw then return false end
      return drew==true
    end

    function s:drawBattleArtScreenBack()
      return self:drawPlaneScreen(self.bg)
    end
    function s:drawBattleArtScreenFront()
      return self:drawPlaneScreen(self.fg)
    end

    -- Mobile Battle Art timing-plane compositor. Unlike the desktop helper it
    -- never pushes LOVE graphics state; Android/iOS draw TouchControls after
    -- the completed frame, so every state touched here is restored explicitly.
    function s:drawPlaneScreenMobile(p)
      if not p or (p.opacity or 0)<=0 then return false end
      local g=love and love.graphics
      if not (g and type(g.getDimensions)=="function") then return false end
      local ok,w,h=pcall(g.getDimensions)
      w,h=tonumber(w),tonumber(h)
      if not (ok and w and h and w>0 and h>0) then return false end

      local oldShader=type(g.getShader)=="function" and g.getShader() or nil
      local cr,cg,cb,ca=1,1,1,1
      if type(g.getColor)=="function" then cr,cg,cb,ca=g.getColor() end
      local oldBlend,oldAlpha
      if type(g.getBlendMode)=="function" then oldBlend,oldAlpha=g.getBlendMode() end
      local scx,scy,scw,sch
      if type(g.getScissor)=="function" then scx,scy,scw,sch=g.getScissor() end
      local oldTransform=nil
      if type(g.getTransform)=="function" then
        local okT,t=pcall(g.getTransform)
        if okT then oldTransform=t end
      end

      local okDraw,drew=pcall(function()
        if oldTransform and type(g.origin)=="function" then g.origin() end
        if g.setScissor then g.setScissor(0,0,w,h) end
        if g.setShader then g.setShader() end
        pcall(g.setBlendMode,"alpha","alphamultiply")
        if p.file then
          local img=self:image(p.file)
          if not img then return false end
          local sourceW=512
          local sourceH=FIELD_H/SCALE
          local sx=w/sourceW
          local sy=h/sourceH
          local iw,ih=img:getWidth()*sx,img:getHeight()*sy
          if iw<1 or ih<1 then return false end
          g.setColor(1,1,1,(p.opacity or 0)/255)
          local ox=(p.x or 0)*sx
          local oy=(p.y or 0)*sy
          local startX=ox-math.ceil((ox+w)/iw)*iw
          local startY=oy-math.ceil((oy+h)/ih)*ih
          for yy=startY,h,ih do
            for xx=startX,w,iw do g.draw(img,xx,yy,0,sx,sy) end
          end
        else
          g.setColor((p.r or 0)/255,(p.g or 0)/255,(p.b or 0)/255,(p.opacity or 0)/255)
          g.rectangle("fill",0,0,w,h)
        end
        return true
      end)

      if oldTransform and type(g.replaceTransform)=="function" then
        pcall(g.replaceTransform,oldTransform)
      end
      if g.setScissor then
        if scx~=nil then pcall(g.setScissor,scx,scy,scw,sch) else pcall(g.setScissor) end
      end
      if g.setShader then pcall(g.setShader,oldShader) end
      if oldBlend and g.setBlendMode then pcall(g.setBlendMode,oldBlend,oldAlpha) end
      pcall(g.setColor,cr or 1,cg or 1,cb or 1,ca or 1)
      if not okDraw then return false end
      return drew==true
    end
    function s:drawBattleArtScreenBackMobile()
      return self:drawPlaneScreenMobile(self.bg)
    end
    function s:drawBattleArtScreenFrontMobile()
      return self:drawPlaneScreenMobile(self.fg)
    end

    function s:drawPlaneWide(p)
      if (p.opacity or 0)<=0 then return end
      local g=love.graphics
      if p.file then
        local img=self:image(p.file); if not img then return end
        local iw,ih=img:getWidth()*WIDE_POS_X,img:getHeight()*WIDE_POS_Y
        if iw<1 or ih<1 then return end
        g.setColor(1,1,1,(p.opacity or 0)/255)
        local ox=(p.x or 0)*WIDE_POS_X; local oy=(p.y or 0)*WIDE_POS_Y
        local startX=ox-math.ceil((ox+KRS_BG_W)/iw)*iw
        local startY=oy-math.ceil((oy+KRS_BG_H)/ih)*ih
        for y=startY,KRS_BG_H,ih do
          for x=startX,KRS_BG_W,iw do
            g.draw(img,x,y,0,WIDE_POS_X,WIDE_POS_Y)
          end
        end
      else
        g.setColor((p.r or 0)/255,(p.g or 0)/255,(p.b or 0)/255,(p.opacity or 0)/255)
        g.rectangle("fill",0,0,KRS_BG_W,KRS_BG_H)
      end
      g.setColor(1,1,1,1)
    end

    local function withWideStage(drawTransform, fn)
      local g=love.graphics
      if not (g and g.push and g.pop) then return fn() end
      local t=drawTransform or {}
      local x,y=t.x or 0,t.y or 0
      local r,sx,sy=t.r or 0,t.sx or 1,t.sy or t.sx or 1
      local ox,oy=t.ox or 0,t.oy or 0
      local kx,ky=t.kx or 0,t.ky or 0
      g.push("all")
      -- KRS backgrounds are unrotated today. Preserve clipping for that normal
      -- path; if another presenter rotates/shears the battle, its own clip stays
      -- authoritative rather than applying a wrong axis-aligned rectangle.
      if r==0 and kx==0 and ky==0 and g.intersectScissor then
        local left=x-ox*sx; local top=y-oy*sy
        local right=left+KRS_BG_W*sx; local bottom=top+KRS_BG_H*sy
        if right<left then left,right=right,left end
        if bottom<top then top,bottom=bottom,top end
        g.intersectScissor(left,top,right-left,bottom-top)
      end
      if g.translate then g.translate(x,y) end
      if r~=0 and g.rotate then g.rotate(r) end
      if g.scale then g.scale(sx,sy) end
      if (kx~=0 or ky~=0) and g.shear then g.shear(kx,ky) end
      if (ox~=0 or oy~=0) and g.translate then g.translate(-ox,-oy) end
      local ok,err=pcall(fn)
      g.pop()
      if not ok then error(err,0) end
    end

    function s:drawWideBack(drawTransform, kimAnchors)
      local fullCanvasColor=drawCurrentCanvasColorPlane(self.bg)
      withWideStage(drawTransform,function()
        if not fullCanvasColor then self:drawPlaneWide(self.bg) end
        self:drawParticlesWide("back",kimAnchors)
      end)
    end

    function s:drawWideFront(drawTransform, kimAnchors)
      local fullCanvasColor=self.fg and not self.fg.file
        and (self.fg.opacity or 0)>0
      withWideStage(drawTransform,function()
        self:drawParticlesWide("front",kimAnchors)
        if not fullCanvasColor then self:drawPlaneWide(self.fg) end
      end)
      if fullCanvasColor then drawCurrentCanvasColorPlane(self.fg) end
    end

    function s:release()
      for _,img in pairs(self.images) do if img and img.release then pcall(img.release,img) end end
      for _,by in pairs(self.quads) do for _,q in pairs(by) do if q and q.release then pcall(q.release,q) end end end
      self.images={}; self.quads={}
      self.sources={}
    end

    s:applyTimings(0)
    return s
  end


  local function kantoInMotionKrsWideActive(battle)
    local fn=mod and mod.exports and mod.exports._kantoInMotionKrsWideActive
    if type(fn)~="function" then return false end
    local ok,value=pcall(fn,battle)
    return ok and value==true
  end

  local function kantoReworkEnabled()
    -- Cooperative external battle scene owners receive a clean animation lane
    -- by default. A source mod may explicitly opt back into KIM/KRBA effects
    -- with allowKIMAnimations=true in its battle compatibility registration.
    local interop = mod and mod._kantoInMotionInterop
    if interop and type(interop.blocksBattleFeature) == "function"
        and interop:blocksBattleFeature("animations") then
      return false
    end
    if not (mod and mod.options and type(mod.options.get) == "function") then return true end
    local ok, value = pcall(mod.options.get, mod.options, "battleAnimations")
    return not ok or value ~= false
  end

  function AnimPlayer:start(moveId, attackerIsPlayer, opts)
    if not kantoReworkEnabled() then
      self._krs=nil
      return original.start(self,moveId,attackerIsPlayer,opts)
    end
    local rec=DATA.moves[norm(moveId)]
    if rec then
      local anim=(not attackerIsPlayer and rec.opp) or rec.player
      if anim then
        local enemyFallbackMode=nil
        if attackerIsPlayer==false and rec.opp==nil and rec.player~=nil then
          enemyFallbackMode=classifyEnemyFallback(rec.player)
        end
        local opponentVariant = attackerIsPlayer == false and rec.opp ~= nil
        self._krs=newSession(self,anim,moveId,attackerIsPlayer,enemyFallbackMode,opponentVariant)
        activeSession=self._krs
        self.steps,self.events={},{}
        self.stepIndex,self.stepLeft,self.elapsed,self.eventCursor=1,0,0,1
        return
      end
    end
    self._krs=nil
    return original.start(self,moveId,attackerIsPlayer,opts)
  end

  function AnimPlayer:update()
    if self._krs then return self._krs:update() end
    return original.update(self)
  end
  function AnimPlayer:isDone()
    if self._krs then return self._krs.done end
    return original.isDone(self)
  end
  function AnimPlayer:pollEffects()
    if self._krs then return {} end
    return original.pollEffects(self)
  end
  function AnimPlayer:draw(colorFn)
    if self._krs then
      -- Under Battle Art, its drawAnimLayer wrapper already projects this
      -- call onto the 3D battlers.  Only project particle cels here; full-field
      -- foreground planes (black/flash/weather layers) must remain in fixed
      -- battle-screen space or they become obvious transformed rectangles.
      self._krs:drawParticles("front", self._krs._battleArtStage)
      if not self._krs._battleArtStage then self._krs:drawForeground() end
      return
    end
    return original.draw(self,colorFn)
  end
  function AnimPlayer:finalSprites()
    if self._krs then return nil end
    return original.finalSprites(self)
  end
  function AnimPlayer:release()
    if self._krs then
      if activeSession==self._krs then activeSession=nil end
      self._krs:release(); self._krs=nil
    end
    return original.release(self)
  end

  local function drawSideTransformed(state, side, c, slide, sx, sy, skipMenuClip)
    if c and (c[8]~=1 or (c[10] or 255)<=0) then return end
    local g=love.graphics
    if not (g.newCanvas and g.getCanvas and g.setCanvas) then
      return originalDrawPicsLayer(state,slide,sx,sy,side,skipMenuClip)
    end
    state._krsSideCanvases=state._krsSideCanvases or {}
    local cv=state._krsSideCanvases[side]
    if not cv then
      cv=g.newCanvas(160,144); if cv.setFilter then cv:setFilter("nearest","nearest") end
      state._krsSideCanvases[side]=cv
    end
    local prev=g.getCanvas(); local sr,sg,sb,sa=g.getColor()
    g.setCanvas(cv); g.clear(0,0,0,0); g.setColor(1,1,1,1)
    originalDrawPicsLayer(state,slide,sx,sy,side,skipMenuClip)
    g.setCanvas(prev)
    local roleUser = (side=="player") == (state.animAttackerIsPlayer==true)
    local px,py=roleUser and DST_USER_X or DST_TARGET_X, roleUser and DST_USER_Y or DST_TARGET_Y
    local srcx,srcy=roleUser and SRC_USER_X or SRC_TARGET_X, roleUser and SRC_USER_Y or SRC_TARGET_Y
    local dx,dy=0,0; local zx,zy=1,1; local ang=0; local mir=false; local alpha=1
    if c then
      dx=((c[1] or srcx)-srcx)*SCALE; dy=((c[2] or srcy)-srcy)*SCALE
      zx=(c[3] or 100)/100; zy=(c[4] or 100)/100; ang=math.rad(c[5] or 0); mir=(c[6] or 0)~=0; alpha=(c[10] or 255)/255
    end
    if mir then zx=-zx end
    g.push(); g.translate(px+dx,py+dy); g.rotate(ang); g.scale(zx,zy); g.translate(-px,-py)
    g.setColor(1,1,1,alpha); g.draw(cv,0,0); g.pop(); g.setColor(sr,sg,sb,sa)
  end

  function BattleState:drawPicsLayer(slide,sx,sy,onlySide,skipMenuClip)
    local sess=self.animPlayer and self.animPlayer._krs
    if not sess then return originalDrawPicsLayer(self,slide,sx,sy,onlySide,skipMenuClip) end
    -- KIM's KRS arena draws the Essentials BG/back/front/FG layers directly
    -- around its final-resolution battlers. Preserve KIM's underlying pic path
    -- here (it hides only the direct battler proxies) so the 160x96 KRBA copy
    -- is not composited a second time over the wide arena.
    if kantoInMotionKrsWideActive(self) then
      return originalDrawPicsLayer(self,slide,sx,sy,onlySide,skipMenuClip)
    end
    -- During the SGB wavy pre-pass, preserve the engine's native path; drawing
    -- true-colour Essentials planes into the grayscale source canvas would corrupt them.
    if self.grayPics then return originalDrawPicsLayer(self,slide,sx,sy,onlySide,skipMenuClip) end
    if not onlySide then
      local baStage=battleArtStageState(self)
      -- Full-field BG planes stay fixed to the battle viewport.  Back-priority
      -- particle cels, however, belong to the same projected coordinate system
      -- as the front effects and therefore follow Battle Art's stage transform.
      -- Never put a full-field timing plane back into Gen1Recomp's 160x96
      -- surface while Battle Art owns the voxel stage. KIM draws it later at
      -- final window resolution via drawBattleArtScreenBack/Front.
      if not baStage then sess:drawBackground() end
      if baStage then sess:drawParticlesBattleArt("back",baStage)
      else sess:drawParticles("back") end
    end
    local u=sess:roleCell(-1); local t=sess:roleCell(-2)
    local playerCell = self.animAttackerIsPlayer and u or t
    local enemyCell  = self.animAttackerIsPlayer and t or u
    if onlySide=="player" then
      drawSideTransformed(self,"player",playerCell,slide,sx,sy,skipMenuClip)
    elseif onlySide=="enemy" then
      drawSideTransformed(self,"enemy",enemyCell,slide,sx,sy,skipMenuClip)
    else
      drawSideTransformed(self,"enemy",enemyCell,slide,sx,sy,skipMenuClip)
      drawSideTransformed(self,"player",playerCell,slide,sx,sy,skipMenuClip)
      -- In SGB colour mode the HUD was composited before the pic pass; a source
      -- BG is inserted here to stay behind battlers, so redraw HUD chrome above it.
      if self.colorMode and self:colorMode() and self.drawHUDs then self:drawHUDs(slide) end
    end
  end

  -- Battle Art compositor compatibility ----------------------------------------------
  -- Kanto Rework normally draws its foreground plane from AnimPlayer:draw.
  -- Battle Art projects that function so normal attack cels follow its 3D battlers;
  -- projecting a full-field plane produces the black boxes seen on Thunder and
  -- similar moves.  Suppress the plane during the projected call and draw it once
  -- afterward in fixed battle-screen space.
  function BattleState:drawAnimLayer(colorized)
    local sess=self.animPlayer and self.animPlayer._krs
    if sess and kantoInMotionKrsWideActive(self) then return end
    local baStage=sess and battleArtStageState(self) or nil
    if not baStage then return originalDrawAnimLayer(self,colorized) end

    sess._battleArtStage=baStage
    local result={pcall(originalDrawAnimLayer,self,colorized)}
    sess._battleArtStage=nil
    if not result[1] then error(result[2],0) end

    -- KIM owns the final-resolution Battle Art timing-plane fallback. Do not
    -- put FG back into the 160x96 UI surface here; render.hud will composite
    -- it across the full viewport after projected particles and before Modern
    -- UI. This applies to both image and color planes.
    return result[2]
  end

  local function installBattleArtPlaneProvider()
    local stage = battleArtStageApi()
    battleArtPlaneApi = nil
    battleArtBattlerTransformApi = nil
    if not stage then return false end

    local installed = false
    if (tonumber(stage.apiVersion) or 0) >= 2
       and type(stage.registerPlaneProvider) == "function" then
      local provider = {
        background = function()
          local sess = activeSession
          if not (sess and not sess.done) then return nil end
          return sess:planeDescriptor(sess.bg)
        end,
        foreground = function()
          local sess = activeSession
          if not (sess and not sess.done) then return nil end
          return sess:planeDescriptor(sess.fg)
        end,
      }
      local ok, accepted = pcall(stage.registerPlaneProvider,
                                 "kanto_rework_battle_anims", provider)
      if ok and accepted ~= false then
        battleArtPlaneApi = stage
        installed = true
      end
    end

    -- API v3 carries Essentials role-cell transforms onto Battle Art's staged
    -- Pokemon cards. This is what makes BIND and other battler-picture moves
    -- visible instead of being lost when Battle Art captures the untransformed
    -- engine pic layer for its world billboards.
    if (tonumber(stage.apiVersion) or 0) >= 3
       and type(stage.registerBattlerTransformProvider) == "function" then
      local provider = {
        transform = function(side)
          local sess = activeSession
          if not (sess and not sess.done) then return nil end
          return sess:battlerTransform(side)
        end,
      }
      local ok, accepted = pcall(stage.registerBattlerTransformProvider,
                                 "kanto_rework_battle_anims", provider)
      if ok and accepted ~= false then
        battleArtBattlerTransformApi = stage
        installed = true
      end
    end
    return installed
  end

  installBattleArtPlaneProvider()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() installBattleArtPlaneProvider() end)
  end

  -- KRS Wide compositor compatibility -------------------------------------------------
  -- Kanto Rework UI draws its high-resolution battle presenter in render.hud, after
  -- BattleState's native canvas. A native-only animation therefore ends up below the
  -- canonical BattleBackGround. Install an OUTER hook so we can:
  --   1. observe the exact 1920x950 background draw;
  --   2. inject Essentials BG/back-priority particles immediately after that draw;
  --   3. let KRS continue with its Pokémon/HUD;
  --   4. inject front-priority particles/FG after KRS returns.
  -- The draw monkey-patch exists only for the duration of one active KRS battle HUD
  -- call and is restored even if the downstream presenter raises.
  local unpackFn=table.unpack or unpack
  local function pack(...) return {n=select("#",...),...} end

  local function drawableSize(drawable)
    if not drawable then return nil,nil end
    local gw=drawable.getWidth; local gh=drawable.getHeight
    if type(gw)~="function" or type(gh)~="function" then return nil,nil end
    local okW,w=pcall(gw,drawable); local okH,h=pcall(gh,drawable)
    if not (okW and okH) then return nil,nil end
    return w,h
  end

  local function quadViewportSize(q)
    if not q then return nil,nil end
    local gv=q.getViewport
    if type(gv)~="function" then return nil,nil end
    local ok,x,y,w,h=pcall(gv,q)
    if not ok then return nil,nil end
    return w,h
  end

  local function parseDrawTransform(...)
    local a={...}; local i=1
    -- love.graphics.draw(drawable, quad, x, y, ...) overload: after removing
    -- drawable in our wrapper, a[1] is Quad instead of x.
    if type(a[1])~="number" and a[1]~=nil then i=2 end
    return {
      x=tonumber(a[i]) or 0, y=tonumber(a[i+1]) or 0,
      r=tonumber(a[i+2]) or 0, sx=tonumber(a[i+3]) or 1,
      sy=tonumber(a[i+4]) or tonumber(a[i+3]) or 1,
      ox=tonumber(a[i+5]) or 0, oy=tonumber(a[i+6]) or 0,
      kx=tonumber(a[i+7]) or 0, ky=tonumber(a[i+8]) or 0,
    }
  end

  local function canonicalWideBackgroundTransform(drawable,...)
    local args={...}
    local baseW,baseH=nil,nil
    if args[1]~=nil and type(args[1])~="number" then
      baseW,baseH=quadViewportSize(args[1])
    end
    if not (baseW and baseH) then
      baseW,baseH=drawableSize(drawable)
    end
    if not (baseW and baseH) then return nil end
    local t=parseDrawTransform(...)
    if t.r~=0 or t.kx~=0 or t.ky~=0 then return nil end
    local outW=math.abs(baseW*(t.sx or 1))
    local outH=math.abs(baseH*(t.sy or 1))
    local tol=4
    if math.abs(outW-KRS_BG_W)<=tol and math.abs(outH-KRS_BG_H)<=tol then
      return t
    end
    return nil
  end

  local function krsUiActive()
    local ok,handle=pcall(mod.find,"kanto_rework_ui")
    return ok and handle~=nil
  end

  mod.hooks:wrap("render.hud",function(next,game,viewport)
    local sess=activeSession
    if not (sess and not sess.done and krsUiActive()) then
      return next(game,viewport)
    end
    local g=love and love.graphics
    if not (g and type(g.draw)=="function") then return next(game,viewport) end

    local oldDraw=g.draw
    local bgTransform=nil
    local injecting=false
    local patched
    patched=function(drawable,...)
      local result=pack(oldDraw(drawable,...))
      if not injecting and not bgTransform then
        local detected=canonicalWideBackgroundTransform(drawable,...)
        if detected then
          bgTransform=detected
          injecting=true
          -- Never let our own sprites re-enter this detector.
          g.draw=oldDraw
          local ok,err=pcall(sess.drawWideBack,sess,bgTransform)
          g.draw=patched
          injecting=false
          if not ok then error(err,0) end
        end
      end
      return unpackFn(result,1,result.n)
    end

    g.draw=patched
    local downstream=pack(pcall(next,game,viewport))
    g.draw=oldDraw
    if not downstream[1] then error(downstream[2],0) end

    -- Only overlay when the canonical background was actually observed. This
    -- keeps third-party battle renderers and unsupported layouts on the native
    -- fallback instead of guessing their geometry.
    if bgTransform and activeSession==sess and not sess.done then
      sess:drawWideFront(bgTransform)
    end
    return unpackFn(downstream,2,downstream.n)
  end,10000)

  mod.exports._kantoInMotionKRBAActiveSession=function() return activeSession end
  mod.exports.playerInstalled=true
  mod.exports.battleArtPlaneCompat=true
  mod.exports.battleArtPlaneCompatVersion=2
  mod.exports.battleArtBattlerTransformCompat=true
  mod.exports.battleArtBattlerTransformCompatVersion=3
  mod.exports.wideLayeringFix=true
  mod.exports.wideLayeringContract=1
end
