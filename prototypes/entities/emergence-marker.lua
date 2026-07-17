-- Precursor marker for hunter emergences. A collisionless, non-selectable
-- simple-entity spawned at a telegraphed emergence site during the warning
-- window: it renders the ground disturbance AND serves as the anchor for the
-- native custom alert (add_custom_alert needs an entity to point at). control.lua
-- destroys it when the band emerges, which clears the alert automatically.
-- Art: reuses the vanilla big-scorchmark as "churned/scorched ground". The
-- source is a single-variation ground-patch sheet (960x704, drawn at scale 0.5
-- in vanilla for a 9x9 mark); scaled down here to fit the emergence footprint.
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
    -- Lie flat on the ground like a real scorchmark rather than floating as an object.
    render_layer = "ground-patch-higher2",
    -- Script-managed lifetime; never damaged or mined by players/enemies.
    max_health = 1,
    picture = {
      filename = "__base__/graphics/entity/scorchmark/big-scorchmark.png",
      width = 960,
      height = 704,
      scale = 0.35,
      shift = { 0, 0 },
    },
  },
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
