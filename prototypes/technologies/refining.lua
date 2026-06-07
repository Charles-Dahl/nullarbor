data:extend({
  {
    type = "technology",
    name = "nullarbor-refining",
    icon = "__space-age__/graphics/icons/fluid/fluorine.png",
    icon_size = 64,
    research_trigger = {
      type = "mine-entity",
      entity = "nullarbor-irradiated-oil",
    },
    prerequisites = { "nullarbor-burner-assembling-machine" },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-refine-irradiated-oil" },
      { type = "unlock-recipe", recipe = "nullarbor-slurry-u238" },
    },
  },
})
