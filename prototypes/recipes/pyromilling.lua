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
  {
    type = "recipe",
    name = "nullarbor-process-cupric-shale",
    icon = "__base__/graphics/icons/copper-ore.png",
    icon_size = 64,
    category = "nullarbor-pyromilling",
    energy_required = 2,
    ingredients = {
      { type = "item", name = "nullarbor-cupric-shale", amount = 1 },
    },
    results = {
      { type = "item", name = "copper-ore", amount = 1 },
      { type = "item", name = "solid-fuel", amount = 2 },
    },
    enabled = true,
    allow_productivity = false,
  },
  {
    type = "recipe",
    name = "nullarbor-process-bauxite",
    icon = "__base__/graphics/icons/steel-plate.png",
    icon_size = 64,
    category = "nullarbor-pyromilling",
    energy_required = 2,
    ingredients = {
      { type = "item", name = "nullarbor-bauxite", amount = 1 },
    },
    results = {
      { type = "item", name = "nullarbor-aluminium", amount = 1 },
      { type = "item", name = "stone", amount = 2 },
    },
    enabled = true,
    allow_productivity = false,
  },
})
