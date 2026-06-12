data:extend({
  {
    type = "technology",
    name = "nullarbor-distributor",
    icons = {
      {
        icon = "__base__/graphics/icons/burner-inserter.png",
        icon_size = 64,
        tint = { r = 1.0, g = 0.78, b = 0.5, a = 1.0 },
      },
    },
    prerequisites = { "nullarbor-burner-assembling-machine" },
    unit = {
      count = 100,
      time = 30,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
        { "space-science-pack", 1 },
        { "nullarbor-energetic-science-pack", 1 },
      },
    },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-distributor" },
    },
  },
})
