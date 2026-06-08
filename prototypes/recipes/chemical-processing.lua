data:extend({
  {
    type = "recipe",
    name = "nullarbor-slurry-u238",
    icon = "__space-age__/graphics/icons/fluid/fluorine.png",
    icon_size = 64,
    category = "chemistry",
    energy_required = 5,
    ingredients = {
      { type = "fluid", name = "nullarbor-radioactive-slurry", amount = 100 },
    },
    results = {
      { type = "fluid", name = "nullarbor-radioactive-slurry", amount = 75 },
      { type = "item", name = "uranium-238", amount = 1, probability = 0.3 },
    },
    enabled = false,
    allow_productivity = false,
  },
  {
    type = "recipe",
    name = "nullarbor-solid-fuel-to-coal",
    icon = "__base__/graphics/icons/coal.png",
    icon_size = 64,
    category = "chemistry",
    energy_required = 5,
    ingredients = {
      { type = "item", name = "solid-fuel", amount = 3 },
    },
    results = {
      { type = "item",  name = "coal",         amount = 2  },
      { type = "fluid", name = "petroleum-gas", amount = 20 },
    },
    enabled = false,
    allow_productivity = false,
  },
})
