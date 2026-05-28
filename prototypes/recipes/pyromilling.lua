data:extend({
  {
    type = "recipe",
    name = "nullarbor-process-ferrous-shale",
    icon = "__base__/graphics/icons/iron-ore.png",
    icon_size = 64,
    category = "nullarbor-pyromilling",
    energy_required = 2,
    ingredients = {
      { type = "item", name = "nullarbor-ferrous-shale", amount = 1 },
    },
    results = {
      { type = "item", name = "iron-ore", amount = 1 },
      { type = "item", name = "solid-fuel", amount = 2 },
    },
    enabled = true,
    allow_productivity = false,
  },
})
