local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "recipe",
    name = "nullarbor-slurry-u238",
    -- Slurry base (matching the fluid) with a uranium-238 badge in the corner to
    -- signal what the recipe extracts.
    icons = {
      { icon = "__base__/graphics/icons/fluid/lubricant.png", icon_size = 64, tint = tints.slurry },
      { icon = "__base__/graphics/icons/uranium-238.png", icon_size = 64, scale = 0.5, shift = { 8, 8 } },
    },
    subgroup = "nullarbor-processing",
    order = "c[chemistry]-a[slurry-u238]",
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
    subgroup = "nullarbor-processing",
    order = "c[chemistry]-b[solid-fuel-to-coal]",
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
