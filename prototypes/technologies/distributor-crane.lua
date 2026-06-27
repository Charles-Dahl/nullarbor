data:extend({
  {
    type = "technology",
    name = "nullarbor-distributor-crane",
    icons = {
      {
        icon = "__space-age__/graphics/icons/agricultural-tower.png",
        icon_size = 64,
        tint = { r = 0.35, g = 0.36, b = 0.38, a = 1.0 },
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
      { type = "unlock-recipe", recipe = "nullarbor-distributor-crane" },
    },
  },
})
