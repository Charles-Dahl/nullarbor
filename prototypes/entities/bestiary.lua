-- Bestiary: the three hunter variants on a uranium-bioaccumulation spectrum
-- (CLAUDE.md "Bestiary"). This file defines the creatures -- stats, a uranium
-- tint, and the exploder's death AOE. Engagement-triggered morphing
-- (swarmer -> bruiser/exploder) lives in control.lua. Emergence/spawning,
-- evolution, and pollution-gating are deferred to later passes.
--
-- Each clones a vanilla enemy and recolours it: swarmer = small-spitter,
-- bruiser = big-biter (the stomper proved impractical to scale to 2x2 -- its
-- spider leg rig is parameterised on scale), exploder = the stable wriggler.

-- Absolute uranium palette (distinct from the multiplicative material-tints).
local SWARM_TINT = { r = 0.55, g = 0.85, b = 0.20, a = 1 } -- bright bio-green
local BRUISER_TINT = { r = 0.45, g = 0.55, b = 0.42, a = 1 } -- grey-green armor
local EXPLODE_TINT = { r = 0.30, g = 1.00, b = 0.25, a = 1 } -- glowing radioactive green

-- The run/attack animations are nested { layers = { base, mask{tint}, ... } }
-- where the mask layers are greyscale. Overwriting every existing .tint with
-- an absolute colour recolours the whole creature; shadow/untinted layers
-- (no .tint field) are left alone.
local function retint(node, tint)
  if type(node) ~= "table" then
    return
  end
  if node.tint ~= nil then
    node.tint = tint
  end
  for _, v in pairs(node) do
    retint(v, tint)
  end
end

-- ===================== swarmer (small-spitter) =====================
-- Fast, fragile, numerous. Low uranium accumulation -> no resistances. Keeps
-- the spitter's acid ranged attack so it's functional standalone.
local swarmer = util.table.deepcopy(data.raw["unit"]["small-spitter"])
swarmer.name = "nullarbor-swarmer"
swarmer.icon = "__base__/graphics/icons/small-spitter.png"
swarmer.icon_size = 64
swarmer.factoriopedia_simulation = nil
swarmer.max_health = 50
swarmer.movement_speed = 0.24
swarmer.distance_per_frame = 0.06
swarmer.resistances = {}
swarmer.corpse = "small-spitter-corpse"
retint(swarmer.run_animation, SWARM_TINT)
retint(swarmer.attack_parameters, SWARM_TINT)

-- ===================== bruiser (big-biter) =====================
-- Slow, tanky, external uranium plating -> high physical + explosion
-- resistance. (Stomper rejected: spider-unit leg rig won't scale to 2x2.)
local bruiser = util.table.deepcopy(data.raw["unit"]["big-biter"])
bruiser.name = "nullarbor-bruiser"
bruiser.icon = "__base__/graphics/icons/big-biter.png"
bruiser.icon_size = 64
bruiser.factoriopedia_simulation = nil
bruiser.max_health = 900
bruiser.movement_speed = 0.09
bruiser.healing_per_tick = 0.05
bruiser.resistances = {
  { type = "physical", decrease = 14, percent = 60 },
  { type = "explosion", decrease = 14, percent = 60 },
}
bruiser.corpse = "big-biter-corpse"
retint(bruiser.run_animation, BRUISER_TINT)
retint(bruiser.attack_parameters, BRUISER_TINT)

-- ===================== exploder (wriggler) =====================
-- AOE detonation on death, glowing green, high internal accumulation. The
-- wriggler has no death area damage, so attach one via the demolisher's
-- nested-result -> area -> damage pattern. High explosion resistance lets it
-- survive nearby blasts (and chain detonations later).
local exploder = util.table.deepcopy(data.raw["unit"]["small-wriggler-pentapod"])
exploder.name = "nullarbor-exploder"
exploder.icon = "__space-age__/graphics/icons/small-wriggler.png"
exploder.icon_size = 64
exploder.factoriopedia_simulation = nil
exploder.factoriopedia_simulation_premature = nil
exploder.max_health = 110
exploder.movement_speed = 0.18
exploder.healing_per_tick = 0.01
exploder.resistances = { { type = "explosion", percent = 80 } }
exploder.corpse = "small-wriggler-pentapod-corpse"
retint(exploder.run_animation, EXPLODE_TINT)
retint(exploder.attack_parameters, EXPLODE_TINT)
exploder.dying_explosion = "massive-explosion"
exploder.dying_trigger_effect = {
  { type = "create-entity", entity_name = "massive-explosion" },
  {
    type = "nested-result",
    action = {
      type = "area",
      radius = 4,
      -- Hits player/buildings but spares the swarm; "all" would chain.
      force = "not-same",
      action_delivery = {
        type = "instant",
        target_effects = {
          { type = "damage", damage = { amount = 120, type = "explosion" } },
        },
      },
    },
  },
}

-- ===== morphing intermediates (stationary egg-raft cocoons) =====
-- The swarmer commits by becoming a stationary "egg raft" (Gleba spawner,
-- placeholder art) that, after a windup, control.lua completes into the final
-- form. It is a fully neutered unit-spawner -- never spawns units, emits
-- nothing, no map autoplace, and on death just dies (no premature wrigglers)
-- -- so killing it mid-windup cleanly cancels the morph. Distinct tints flag
-- which final form is incubating.
local MORPH_BRUISER_TINT = { r = 0.65, g = 0.75, b = 0.45, a = 1 } -- pale plating green
local MORPH_EXPLODER_TINT = { r = 0.45, g = 1.00, b = 0.30, a = 1 } -- toxic green

-- The egg-raft sprites carry no tint masks (unlike biters/spitters), so force
-- a multiplicative tint onto every non-shadow image layer. Placeholder-grade
-- recolour, distinct from retint() which only overwrites existing tints.
local function tint_layers(node, tint)
  if type(node) ~= "table" then
    return
  end
  if node.filename and not node.draw_as_shadow then
    node.tint = tint
  end
  for _, v in pairs(node) do
    tint_layers(v, tint)
  end
end

-- Shrink every image layer (sprite scale and its shift) so the egg renders
-- smaller; collision/selection boxes are halved separately.
local function scale_layers(node, factor)
  if type(node) ~= "table" then
    return
  end
  if node.filename then
    node.scale = (node.scale or 1) * factor
    local shift = node.shift
    if shift then
      if shift.x then
        node.shift = { x = shift.x * factor, y = shift.y * factor }
      else
        node.shift = { shift[1] * factor, shift[2] * factor }
      end
    end
  end
  for _, v in pairs(node) do
    scale_layers(v, factor)
  end
end

local function make_egg(name, tint, health)
  local egg = util.table.deepcopy(data.raw["unit-spawner"]["gleba-spawner-small"])
  egg.name = name
  egg.icon = "__space-age__/graphics/icons/gleba-spawner-small.png"
  egg.icon_size = 64
  egg.factoriopedia_simulation = nil
  egg.max_health = health
  egg.healing_per_tick = 0 -- damage sticks through the short window
  egg.resistances = {} -- vulnerable -> catchable to cancel the morph
  egg.max_count_of_owned_units = 0 -- never spawn units
  egg.absorptions_per_second = nil -- emits nothing
  egg.autoplace = nil -- never appears in map generation
  egg.dying_trigger_effect = nil -- no premature wrigglers spat out on death
  egg.dying_explosion = nil
  egg.loot = nil -- no pentapod-egg drops when killed
  egg.corpse = "gleba-spawner-corpse-small"
  -- About half size: shrink the sprites and halve the footprint/selection.
  egg.collision_box = { { -0.65, -0.65 }, { 0.65, 0.65 } }
  egg.selection_box = { { -0.75, -0.75 }, { 0.75, 0.75 } }
  tint_layers(egg.graphics_set, tint)
  scale_layers(egg.graphics_set, 0.5)
  return egg
end

local morphing_bruiser = make_egg("nullarbor-morphing-bruiser", MORPH_BRUISER_TINT, 140)
local morphing_exploder = make_egg("nullarbor-morphing-exploder", MORPH_EXPLODER_TINT, 100)

data:extend({ swarmer, bruiser, exploder, morphing_bruiser, morphing_exploder })
