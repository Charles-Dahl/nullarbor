data:extend({
  {
    type = "recipe",
    name = "nullarbor-uranium-aluminium-alloy",
    icon = "__base__/graphics/icons/uranium-238.png",
    icon_size = 64,
    category = "nullarbor-crafting",
    energy_required = 10,
    ingredients = {
      { type = "item", name = "uranium-238",          amount = 2 },
      { type = "item", name = "nullarbor-aluminium",  amount = 4 },
    },
    results = {
      { type = "item", name = "nullarbor-uranium-aluminium-alloy", amount = 1 },
    },
    enabled = false,
    allow_productivity = false,
  },
})
