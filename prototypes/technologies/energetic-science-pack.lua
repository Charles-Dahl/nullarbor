data:extend({
  {
    type = "technology",
    name = "nullarbor-energetic-science-pack",
    icon = "__base__/graphics/icons/automation-science-pack.png",
    icon_size = 64,
    research_trigger = {
      type = "craft-item",
      item = "uranium-238",
      count = 1,
    },
    prerequisites = { "nullarbor-refining", "nullarbor-burner-assembling-machine" },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-energetic-science-pack" },
    },
  },
})
