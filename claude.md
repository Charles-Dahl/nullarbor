# Nullarbor

A Factorio: Space Age mod adding a desert frontier planet. Mid-late game, positioned between the inner planets and Aquilo.

## Design principle

**Familiar materials, novel system.** Most of Nullarbor's outputs are vanilla materials (iron, copper, solid fuel, uranium isotopes, the standard oils) used in distinctive ways. The planet's identity is in its *systems* — fuel logistics, pollution inversion, rail-centric expansion, terrain-based combat — not in exotic substances. The two genuine material additions are aluminium (a new metal category absent from vanilla) and uranium-steel alloy (the planet's signature heavy material).

## Core identity

**Fuel is the substrate.** The Pyromill produces solid fuel in such overwhelming quantity from shale processing that the player's first hour reframes fuel from "consumable to manage" into "surplus to spend." Everything downstream is a fuel sink: burner buildings (fuel-quality-scaled), trains, gantries, refining (fuel + water → oils + uranium), alloy production (fuel as reduction reagent), premium fuel as the science pack, and the planet's infinite research tier (combustion mastery) consuming premium fuel indefinitely. The planet has no fuel scarcity; the design pressure is always "what to spend fuel on next."

**Burner-first, electricity-secondary.** Nullarbor's signature buildings are burner-powered (Pyromill, Burner Assembling Machine, distributor, gantry, armored locomotive, burner inserter mk2). Electricity exists for vanilla buildings that require it (chemistry plant, refinery, centrifuge) but is not the dominant power paradigm. Fuel-quality scaling makes burner buildings competitive with electric/module alternatives — better fuel = faster building, with a curve from coal (slow) to premium fuel (very fast).

**Pollution inverted.** Industrial pollution is a *defensive* substance: hunters cannot initiate combat within polluted territory. Pristine areas are hostile. Pollution disables condensers (water source), creating the tension that water infrastructure must extend into pristine hostile terrain. Hunters pursued into polluted territory keep fighting, then disengage when the engagement ends.

**Terrain split.** Two terrain types govern emergence: *hard rock* (where the starter area lies) cannot spawn enemy emergences ever; *loose sand* (the more common terrain) can. This gives the planet readable geology — players see rock and know it's safe from ambush, see sand and know bands can spawn beneath them. The rail network of mature factories crosses sand to connect rocky industrial islands.

## Resource model

### Surface scatter (hand-mined)
- **Rocks**: stone + iron ore + small amount of solid fuel. Bootstrap material, sparse, exhaustible per starter area.
- **Loose ferrous shale**: hand-mineable, triggers Pyromill research.

### Drillable patches
- **Ferrous shale**: workhorse. Pyromill recipe: shale → iron ore + solid fuel.
- **Cupric shale**: support. Pyromill recipe: shale → copper ore + solid fuel.
- **Bauxite**: specialty. Pyromill recipe: bauxite → aluminium + stone.
- **Irradiated Oil**: pumpjack-extracted, rare, deep desert. Produces irradiated oil that must be processed to separate isotopes.

### Refinery chemistry (Nullarbor-specific recipe)
- Irradiated oil + water → heavy oil + radioactive slurry.
- Heavy oil cracks down to light, then petroleum, exactly as vanilla. Players get the full petrochemical chain by cracking, not by direct refinery output.

### Chemical processing
2 uranium recipes to target the uranium isotopes individually, each one returns a portion of the slurry and has a chance to find some uranium. Also a new coal recipe from solid fuel
- Radioactive slurry = smaller amount of radioactive slurry + chance of U238
- Radioactive slurry = smaller amount of radioactive slurry + chance of U235
- Solid fuel = coal + petroleum (the only way to get coal on this planet)

## Buildings

### Pyromill
Footprint: 2x2
Energy: Fuel
Furnace-like building that processes base materials into 2 outputs
- Ferrous shale → iron ore + solid fuel
- Cupric shale → copper ore + solid fuel
- Bauxite → aluminium + stone
Speed increased with better types of fuel

### Burner Assembling Machine
Footprint: 2x2
Energy: Fuel
The heavy-industrial assembler. Runs custom Nullarbor recipes plus a subset of vanilla `crafting` recipes. No fluidbox — explicitly excludes fluid-involving recipes by virtue of having no fluid I/O. Categories: `nullarbor-burner-crafting` (specialty) + `crafting` (universal vanilla basics).

Signature recipes:
- Uranium-steel alloy: steel + U-238 + aluminium → alloy. Each metal contributes a property: steel structures, U-238 densifies, aluminium chemically stabilizes/passivates the uranium against oxidation.
- Thermite: aluminium + iron ore → thermite. Premium fuel that doubles as the science pack for this planet.

### Burner Inserter MKII
Footprint: 1x1
Energy: Fuel
This is an upgrade to the vanilla burner inserter. It scales speed with the fuel used and can fuel itself from the machine it's taking from as well as belts

### Distributor
Footprint: 1x2
Energy: Fuel
Belt-straddling burner inserter cluster. Sits on a belt tile with a sealed pickup zone. Four drop targets, two per long side, landing one tile out from the footprint (long-inserter reach): feeds 2x2 machines hugging the belt (drop lands in their far column) or machines set one tile back; 1x1 machines must sit one tile back. Fuel priority: self > target buildings > pass-through for ingredient-handling roles. Vanilla filter-inserter logic. Solves the "many burner buildings need fuel" problem in dense layouts.

Fueling: deep fuel buffer (several slots), refuels itself natively from any fuel it handles, and accepts fuel inserted by hand or by inserter — so it stays useful on belts that never carry fuel; belt-borne fuel makes it fully autonomous. Implemented as a composite: one selectable primary inserter (full 1x2 selection box, higher selection priority than belts, custom collision layer so it overlaps belts but blocks other distributors) plus three hidden arm inserters managed by control.lua (lifecycle, filter sync from primary, fuel top-up from primary's buffer).

Placement (train-stop model): must straddle a straight belt run lengthwise — both covered tiles need straight, same-direction belts parallel to the footprint axis; belt ghosts count. Manual placement (real or ghost) elsewhere is rejected with a cursor warning; holding the item highlights valid belt runs nearby. Bot/script builds are never rejected — a distributor whose underlay is missing or invalid (removed later, rotated, or belts not yet built) is disabled with a "Must be over belts" status and re-enables automatically, checked once per second.

### Gantry
Footprint: 6x4, fits over rails
Cargo loader/unloader straddling rails. Belt I/O on long sides, fuel slot on short sides only, toggle: Load / Unload / Off. Fuel-quality scaled. No idle fuel consumption.

### Atmospheric Condenser
Footprint: 3x3
Energy: Electric
Captures gases in the atmosphere to get fluids.
Used on Nullarbor as the source of water.

### Heavy Locomotive
Armored locomotive built from uranium-steel alloy, with personal-style equipment grid. The grid takes vanilla equipment (shields, fuel-burning generators, weapons). Interleaving armored locomotives with cargo wagons distributes equipment grids along a consist, giving players a configurable mobile-fortress design space. The locomotive's alloy plating provides physical and explosion resistance.

## Combat

### Bestiary
Three hunter variants on a uranium-bioaccumulation spectrum:
- **Swarmer**: fast, fragile, numerous. Low uranium accumulation.
- **Armored bruiser**: slow, tanky. External uranium plating.
- **Exploder**: AOE detonation on death, glowing green. High internal accumulation.

**Morphing**: swarmers can morph into bruisers (fast morph, slow movement) or exploders (slow morph, mid-speed). Combat sequence is layered: swarm hits → bruisers arrive (early morph, slow advance) → exploders overtake bruisers near end (late morph, faster speed). Each escalation has a visible windup, giving the player reaction windows.

### Emergence
Bands emerge from telegraphed underground sites in *pristine sand only* — never rock, never pollution. Telegraphed by ground tremors and loosening, giving the player warning. Per-region caps prevent runaway. Bands disperse if unengaged.

Evolution drives frequency and composition, not pollution (preserving the inversion). Driven by time + uranium extracted.

### Defensive infrastructure
- **Uranium-steel walls**: high HP, physical + explosion resistance. Specifically counter exploders. Used at outpost perimeters and condenser sites.
- **Personal armor plating**: alloy-based equipment, typed damage resistance (physical + explosion). Complements shields (capacity vs. efficiency). Diminishing returns on stacking, never 100% resistance.

## Trigger / progression flow

1. Land → mine rocks → bootstrap iron-and-fuel from stone furnaces.
2. Find loose shale → triggers Pyromill + condenser research (bundled).
3. Build Pyromill → process shale → fuel surplus moment (the planet announces itself).
4. Process bauxite in Pyromill → aluminium (the novel material), triggers Burner Assembling Machine research.
5. Build Burner Assembling Machine → produce alloy (steel + U-238 + aluminium), thermite, premium fuel.
6. Set up refinery → irradiated oil + water → heavy oil + U-238 + trace U-235. Crack oils for downstream products.
7. Late game: expand into deep sand for enriched uranium fluid (pumpjack), armored locomotives, defensive infrastructure scaling.

All triggers are **engagement-based** (Space Age milestone pattern), not science-pack-cost. Each new tier of building is unlocked by *encountering the resource it processes* — find shale, get Pyromill; find bauxite, get Burner Assembling Machine. Consistent with the "systems, not materials" identity: tech unlocks come from doing, not from owning.

## Tech tree highlights

- **Premium fuel as science pack**: Nullarbor's science consumable. The planet's signature output also fuels research.
- **Infinite combustion research**: per-planet endgame infinite-research tier (analog to mining productivity for Nauvis). Each level raises the ceiling of fuel-quality scaling. Exponential cost in premium fuel. Self-reinforcing loop — more research → faster premium fuel → cheaper next research level. Permanent endgame sink for the planet's economy.

## Aesthetic / naming register

Pilbara red desert + Wild West / late-1800s industrial-frontier aesthetic. Building names use period-industrial vocabulary (Pyromill, Burner Assembling Machine, gantry, distributor). No shared prefix family — each building stands on its own with a name that reflects its function in the vocabulary of the era. Avoid technical/clinical/modern naming (no "thermal bonder," no "compact furnace mk2"). Aim for words that sound like they'd appear on a hand-painted sign over a frontier industrial facility.

## Implementation principles

- **Single-input recipes for the Pyromill**: keeps the building's "feed it raw planetary stuff" identity consistent. Fuel is consumed at the building level, not as a recipe ingredient.
- **No fluid I/O on Burner Assembling Machine**: thematic constraint (high-heat dry chemistry) and mechanical simplification (no fluidbox on 2x2 footprint). Excludes fluid recipes naturally.
- **Custom crafting categories for specialty recipes**: Nullarbor specialties use `nullarbor-burner-crafting`. Buildings list multiple categories to accept both specialty and vanilla `crafting` recipes.
- **Multi-output recipes require explicit `icon` and `icon_size`**: single-output recipes inherit from the product; multi-output cannot, so the recipe needs its own icon set.
- **Building entities and items are linked by shared name**: the entity's `minable.result` and the item's `place_result` both reference the shared name. Locale entries needed for both `[entity-name]` and `[item-name]`.
- **Fuel-quality scaling**: implemented intrinsically on burner buildings. Better fuel = faster crafting. No separate research required for the baseline mechanic; the infinite combustion research amplifies the curve.

## Known open design questions

- **Specific Pyromill crafting recipe ingredients balance**: currently steel furnace + steel + stone, ratios placeholder.
- **Exact refinery output ratios** (heavy oil vs. uranium fluid): placeholder, needs balancing.
- **Combustion mastery exact cost curve and effect magnitude**: placeholder, needs balancing.
- **Hunter AI behavior in pollution**: pursued into pollution, disengage when threat ends — exact thresholds TBD.
- **Emergence telegraph timing and per-region caps**: placeholders pending playtesting.
- **Bauxite map placement**: small deposits near starter rocky area, larger deposits further out, but exact spawning logic TBD.
