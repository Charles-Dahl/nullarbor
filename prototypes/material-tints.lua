-- Shared tints for Nullarbor's placeholder materials, so item icons, resource
-- patch graphics, and minimap colours can be tuned in one place. The icon/graphic
-- tints are MULTIPLICATIVE (they darken/shift the borrowed vanilla art); the
-- _map colours are absolute minimap colours.
return {
  -- Shale family + bauxite: grey rock.
  grey = { r = 0.58, g = 0.6, b = 0.64 },
  grey_map = { r = 0.5, g = 0.5, b = 0.52 },
  -- Irradiated oil: vibrant green. The crude-oil art is near-black, so the
  -- green channel is pushed ABOVE 1.0 to brighten (not just darken) the oil
  -- and make it pop; red/blue are suppressed. Lower g toward 1.0 if too neon.
  green = { r = 0, g = 1, b = 0 },
  green_map = { r = 0.1, g = 0.7, b = 0.15 },
  -- Aluminium: cool near-white (multiply can't brighten past the source art).
  white = { r = 0.88, g = 0.93, b = 1.0 },
}
