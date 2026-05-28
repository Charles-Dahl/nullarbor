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
    name = "nullarbor-process-exposed-granite",
    icon = "__base__/graphics/icons/uranium-238.png",
    icon_size = 64,
    category = "nullarbor-pyromilling",
    energy_required = 2,
    ingredients = {
      { type = "item", name = "nullarbor-exposed-granite", amount = 1 },
    },
    results = {
      { type = "item", name = "uranium-238", amount = 1 },
      { type = "item", name = "stone", amount = 2 },
    },
    enabled = true,
    allow_productivity = false,
  },
  {
    type = "recipe",
    name = "nullarbor-process-enriched-granite",
    icon = "__base__/graphics/icons/uranium-235.png",
    icon_size = 64,
    category = "nullarbor-pyromilling",
    energy_required = 2,
    ingredients = {
      { type = "item", name = "nullarbor-enriched-granite", amount = 1 },
    },
    results = {
      { type = "item", name = "uranium-235", amount = 1 },
      { type = "item", name = "stone", amount = 2 },
    },
    enabled = true,
    allow_productivity = false,
  },
})
