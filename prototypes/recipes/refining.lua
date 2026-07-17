data:extend({
  {
    type = "recipe",
    name = "nullarbor-refine-irradiated-oil",
    icon = "__base__/graphics/icons/fluid/crude-oil.png",
    icon_size = 64,
    subgroup = "nullarbor-processing",
    order = "b[refining]-a[irradiated-oil]",
    category = "oil-processing",
    energy_required = 5,
    ingredients = {
      { type = "fluid", name = "nullarbor-irradiated-oil", amount = 100 },
      { type = "fluid", name = "water", amount = 100 },
    },
    results = {
      { type = "fluid", name = "heavy-oil", amount = 100 },
      { type = "fluid", name = "nullarbor-radioactive-slurry", amount = 25 },
    },
    enabled = false,
    allow_productivity = false,
  },
})
