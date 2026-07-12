-- Precursor marker for hunter emergences. A collisionless, non-selectable
-- simple-entity spawned at a telegraphed emergence site during the warning
-- window: it renders the ground disturbance AND serves as the anchor for the
-- native custom alert (add_custom_alert needs an entity to point at). control.lua
-- destroys it when the band emerges, which clears the alert automatically.
-- Placeholder art: reuses the surface-rock sprite as "churned ground".
data:extend({
  {
    name = "nullarbor-emergence-tremor",
    type = "simple-entity",
    flags = { "placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable", "not-upgradable" },
    icon = "__base__/graphics/icons/huge-rock.png",
    icon_size = 64,
    collision_mask = { layers = {} }, -- overlaps terrain and units freely
    collision_box = { { -0.8, -0.6 }, { 0.8, 0.6 } },
    selectable_in_game = false,
    render_layer = "object",
    -- Script-managed lifetime; never damaged or mined by players/enemies.
    max_health = 1,
    picture = {
      filename = "__base__/graphics/decorative/huge-rock/huge-rock-05.png",
      width = 201,
      height = 179,
      scale = 0.4,
      shift = { 0.1, 0.05 },
    },
  },
})
