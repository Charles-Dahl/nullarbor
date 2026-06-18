-- Nullarbor map generation. Reuses Fulgora's terrain noise by name (the
-- fulgora_* expressions, cliff-fulgora, and the fulgora_islands/fulgora_cliff
-- autoplace-controls are all global Space Age prototypes loaded before this
-- mod). The only deviations: the oil-ocean tiles are omitted (basins fall to
-- nullarbor-sand), and scrap / ruins / fulgurite are omitted. Result: a dry
-- red-desert of rock mesas and sand basins, fully walkable, no water.
local nullarbor_map_gen = {}

nullarbor_map_gen.nullarbor = function()
  return {
    property_expression_names = {
      elevation = "fulgora_elevation",
      temperature = "temperature_basic",
      moisture = "moisture_basic",
      aux = "aux_basic",
      cliffiness = "fulgora_cliffiness",
      cliff_elevation = "cliff_elevation_from_elevation",
    },
    cliff_settings = {
      name = "cliff-fulgora",
      control = "fulgora_cliff",
      cliff_elevation_0 = 80,
      cliff_elevation_interval = 40,
      cliff_smoothing = 0,
      richness = 0.95,
    },
    autoplace_controls = {
      ["fulgora_islands"] = {},
      ["fulgora_cliff"] = {},
    },
    autoplace_settings = {
      ["tile"] = {
        settings = {
          ["nullarbor-sand"] = {},
          ["fulgoran-rock"] = {},
          ["fulgoran-dust"] = {},
          ["fulgoran-dunes"] = {},
        },
      },
      ["decorative"] = {
        settings = {
          ["medium-fulgora-rock"] = {},
          ["small-fulgora-rock"] = {},
          ["tiny-fulgora-rock"] = {},
        },
      },
      ["entity"] = {
        settings = {
          ["nullarbor-surface-rock"] = {},
          ["nullarbor-ferrous-shale"] = {},
          ["nullarbor-cupric-shale"] = {},
          ["nullarbor-bauxite"] = {},
          ["nullarbor-irradiated-oil"] = {},
          ["big-fulgora-rock"] = {},
        },
      },
    },
  }
end

return nullarbor_map_gen
