-- Shared tints for Nullarbor's placeholder materials, so item icons, resource
-- patch graphics, and minimap colours can be tuned in one place. The icon/graphic
-- tints are MULTIPLICATIVE (they darken/shift the borrowed vanilla art); the
-- _map colours are absolute minimap colours.
return {
  -- Shale family + bauxite: grey rock IN WORLD (shared graphic tint), but each
  -- reads by yield ON THE MAP so patches are distinguishable at a glance --
  -- rust-red iron, orange copper, blue bauxite/aluminium. (grey_map kept for
  -- reference / any fallback use.)
  grey = { r = 0.58, g = 0.6, b = 0.64 },
  grey_map = { r = 0.5, g = 0.5, b = 0.52 },
  ferrous_map = { r = 0.42, g = 0.58, b = 0.85 },
  cupric_map = { r = 0.82, g = 0.47, b = 0.2 },
  bauxite_map = { r = 0.72, g = 0.6, b = 0.24 },
  -- Irradiated oil: vibrant green. The crude-oil art is near-black, so the
  -- green channel is pushed ABOVE 1.0 to brighten (not just darken) the oil
  -- and make it pop; red/blue are suppressed. Lower g toward 1.0 if too neon.
  green = { r = 0, g = 1, b = 0 },
  green_map = { r = 0.1, g = 0.7, b = 0.15 },
  -- Aluminium: light blue. Multiplicative over the silvery steel-plate art, so
  -- red/green are pulled down while blue stays at 1.0 to tint (not just darken)
  -- the plate a cool sky-blue and separate it visually from steel. Raise r/g
  -- back toward 1.0 if it reads too saturated.
  aluminium = { r = 0.8, g = 0.85, b = 1 },
  -- Uranium-aluminium alloy: green over the tungsten-plate art. Red/blue are
  -- pulled down while green stays high, giving the dark plate a uranium-green
  -- cast distinct from aluminium's sky-blue.
  alloy = { r = 0.42, g = 0.85, b = 0.4 },
  -- Atmospheric Condenser: purple over the assembling-machine-3 art. Green is
  -- suppressed while red/blue stay high for a violet cast.
  purple = { r = 0.82, g = 0.56, b = 0.97 },
  -- Radioactive slurry: a dark tint over the (green) lubricant art, so the fluid
  -- icon reads as dense dark-green sludge. Keeps a little green to match the
  -- fluid's in-pipe colour; lower all channels together for a darker sludge.
  slurry = { r = 0.3, g = 0.36, b = 0.28 },
}
