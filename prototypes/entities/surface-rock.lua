data:extend({
  {
    type = "simple-entity",
    name = "nullarbor-surface-rock",
    icon = "__base__/graphics/icons/rock-huge.png",
    icon_size = 64,
    flags = { "placeable-neutral", "placeable-off-grid" },
    minable = {
      mining_time = 1.5,
      results = {
        { type = "item", name = "stone",     amount_min = 10, amount_max = 20 },
        { type = "item", name = "iron-ore",  amount_min = 5,  amount_max = 10 },
        { type = "item", name = "solid-fuel", amount_min = 1,  amount_max = 3  },
      },
    },
    collision_box = { { -1.35, -1.35 }, { 1.35, 1.35 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    render_layer = "object",
    pictures = {
      {
        filename = "__base__/graphics/entity/rocks/rock-huge.png",
        priority = "extra-high",
        width = 288,
        height = 216,
        shift = { 0.5, 0 },
      },
    },
    map_color = { r = 0.5, g = 0.4, b = 0.3 },
    subgroup = "grass",
    order = "b[decorative]-b[rock-huge]",
  },
})
