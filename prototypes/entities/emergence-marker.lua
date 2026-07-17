-- Precursor marker for hunter emergences. A collisionless, non-selectable
-- simple-entity spawned at a telegraphed emergence site during the warning
-- window: it renders the ground disturbance AND serves as the anchor for the
-- native custom alert (add_custom_alert needs an entity to point at). control.lua
-- destroys it when the band emerges, which clears the alert automatically.
-- Art: the Vulcanus cold-crack decals as a fractured emergence site. Listed as
-- `pictures` variations (256x256 huge set); control.lua assigns a random
-- graphics_variation per spawn so no two nearby sites look alike.
local CRACK_VARIATION_COUNT = 20
local CRACK_SCALE = 1.2 -- 256px source -> ~9.6 tiles across at 1.2
local crack_variations = {}
for i = 1, CRACK_VARIATION_COUNT do
  crack_variations[i] = {
    filename = string.format(
      "__space-age__/graphics/decorative/vulcanus-cracks-cold/vulcanus-cracks-cold-huge-%02d.png",
      i
    ),
    width = 256,
    height = 256,
    scale = CRACK_SCALE,
  }
end

data:extend({
  {
    name = "nullarbor-emergence-tremor",
    type = "simple-entity",
    flags = { "placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable", "not-upgradable" },
    icon = "__base__/graphics/icons/small-scorchmark.png",
    icon_size = 64,
    collision_mask = { layers = {} }, -- overlaps terrain and units freely
    collision_box = { { -0.8, -0.6 }, { 0.8, 0.6 } },
    selectable_in_game = false,
    -- Lie flat on the ground like a decal rather than floating as an object.
    render_layer = "ground-patch-higher2",
    -- Script-managed lifetime; never damaged or mined by players/enemies.
    max_health = 1,
    pictures = crack_variations,
  },
})

-- Dust cloud thrown up over a churning emergence site. The vanilla dust puffs
-- top out around scale 0.4 (too small for the big crack), so we roll our own on
-- the soft smoke.png cloud with a red-desert tan tint and much larger scales.
-- Emitted periodically by control.lua while a site is telegraphed.
local smoke_animations = require("__base__/prototypes/entity/smoke-animations")
data:extend({
  smoke_animations.trivial_smoke({
    name = "nullarbor-emergence-dust",
    color = { r = 0.62, g = 0.46, b = 0.33, a = 0.45 }, -- Pilbara-red tan dust
    affected_by_wind = true,
    render_layer = "smoke",
    movement_slow_down_factor = 0.96,
    duration = 120,
    fade_away_duration = 80,
    spread_duration = 60,
    start_scale = 0.5,
    end_scale = 2.2,
  }),
})

-- Virtual signal used purely as the icon for the emergence custom alert.
-- add_custom_alert takes a SignalID, not an arbitrary image path, and the
-- speaker-alert graphic isn't a vanilla signal, so we wrap it in our own hidden
-- signal. Hidden from the signal-selector GUI; it exists only to carry the icon.
data:extend({
  {
    type = "virtual-signal",
    name = "nullarbor-emergence-alert",
    icon = "__base__/graphics/icons/signal/signal-speaker-alert.png",
    icon_size = 64,
    hidden = true,
    subgroup = "virtual-signal",
    order = "z[nullarbor]-a[emergence-alert]",
  },
})
