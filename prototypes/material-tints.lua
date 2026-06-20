-- Shared tints for Nullarbor's placeholder materials, so item icons, resource
-- patch graphics, and minimap colours can be tuned in one place. The icon/graphic
-- tints are MULTIPLICATIVE (they darken/shift the borrowed vanilla art); the
-- _map colours are absolute minimap colours.
return {
  -- Shale family + bauxite: grey rock.
  grey = { r = 0.58, g = 0.6, b = 0.64 },
  grey_map = { r = 0.5, g = 0.5, b = 0.52 },
  -- Irradiated oil: dark green.
  green = { r = 0.3, g = 0.65, b = 0.3 },
  green_map = { r = 0.15, g = 0.4, b = 0.18 },
  -- Aluminium: cool near-white (multiply can't brighten past the source art).
  white = { r = 0.88, g = 0.93, b = 1.0 },
}
