-- Unlocks travel to Nullarbor, mirroring the other inner-planet discovery
-- techs. No recipe unlock (Fulgora's grants lightning-rod; Nullarbor has none).
local util = require("util")

data:extend({
  {
    type = "technology",
    name = "planet-discovery-nullarbor",
    -- Placeholder icon (reuse Fulgora's) until custom art exists.
    icons = util.technology_icon_constant_planet("__space-age__/graphics/technology/fulgora.png"),
    icon_size = 256,
    essential = true,
    effects = {
      {
        type = "unlock-space-location",
        space_location = "nullarbor",
        use_icon_overlay_constant = true,
      },
    },
    prerequisites = { "space-platform-thruster" },
    unit = {
      count = 1000,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
        { "space-science-pack", 1 },
      },
      time = 60,
    },
  },
})
