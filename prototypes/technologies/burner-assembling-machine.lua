data:extend({
  {
    type = "technology",
    name = "nullarbor-burner-assembling-machine",
    icon = "__base__/graphics/icons/assembling-machine-1.png",
    icon_size = 64,
    research_trigger = {
      type = "craft-item",
      item = "nullarbor-aluminium",
      count = 10,
    },
    prerequisites = { "nullarbor-pyromill" },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-burner-assembling-machine" },
      { type = "unlock-recipe", recipe = "nullarbor-uranium-aluminium-alloy" },
      { type = "unlock-recipe", recipe = "nullarbor-energetic-science-pack" },
    },
  },
})
