# Magmatic Planet — free demo, 24 pixel-art assets, top-down

A free sample of **Magmatic Planet**, a 441-asset top-down volcanic pack by PixLog: rock
ground, a few lava river pieces, the four corners of a ridge-wall room and ten props.

## Sizes — read this first

**Every cell is 32×32 pixels.** Nothing is scaled and nothing is padded. Every file is a
whole number of cells.

| folder | assets | size of every file | cells |
|---|---|---|---|
| `terrain/lava-path/` | 6 | **32×32** | 1×1 |
| `terrain/rock-bank/` | 4 | **32×32** | 1×1 |
| `props/amber-crystal-formations/` | 2 | **32×32** | 1×1 |
| `props/boulders-rubble-scree/` | 2 | **32×32** | 1×1 |
| `props/crystal-obsidian-sulfur-nodes/` | 1 | **32×32** | 1×1 |
| `props/fossils-titan-remains/` | 1 | **32×32** | 1×1 |
| `props/geysers-vents-spatter-cones/` | 1 | **32×32** | 1×1 |
| `props/heat-plants-fire-flora/` | 2 | **32×32** | 1×1 |
| `props/lava-pools-falls/` | 1 | **32×32** | 1×1 |
| `props/ridge-wall-modules/` | 4 | **64×96** | 2×3 |

- `sheets/` holds the same art packed into one sheet per size. Slice `terrain.png` and
  `props-32x32.png` at **32×32**, `props-64x64.png` at **64×64** and `props-64x96.png` at
  **64×96**. **0 margin, 0 spacing.**
- `atlas.json` lists every asset's sheet and `x, y, w, h` in pixels.
- Props and walls have a transparent background. Place them on a layer above the terrain.

## Placing the pieces

- **Ground** (`rock-bank`): any tile goes next to any other.
- **Lava river** (`lava-path`): `tile_00` is the ground the river runs through. `tile_06`
  runs east–west, `tile_07` north–south, `tile_08` and `tile_09` are bends, and `tile_16`
  is a crossing. Every piece meets its neighbour at the same point on the edge.
- **Wall room** (`ridge-wall-modules`): the four corners close a small room. Put
  `06-corner-es` at cell (0, 0), `07-corner-ws` at (2, 0), `08-corner-en` at (0, 3) and
  `09-corner-wn` at (2, 3). Each piece's top-left corner sits on its cell.

The demo is placed by hand. **In the full pack**, the Godot TileSet and the Tiled tilesets
also paint lava pools and rivers with the terrain brush, and walls come with straight runs
for rooms of any size.

## Import settings

**Unity:** select a sheet PNG. Texture Type **Sprite (2D and UI)** · Sprite Mode
**Multiple** · Pixels Per Unit **32** · Filter Mode **Point (no filter)** · Compression
**None**. In the Sprite Editor choose Slice → **Grid By Cell Size**, using that sheet's
cell size, Offset **0**, Padding **0**.

**Godot 4:** copy the whole folder into your project and open
`godot/magmatic-planet.tres` on a TileMapLayer. Tile size is 32×32. Set Project Settings →
Rendering → Textures → Default Texture Filter to **Nearest**.

**Tiled:** add the `.tsx` files in `tiled/` to a map with 32×32 tiles.

**GameMaker:** a Tile Set with tile width and height **32**, offset **0**, separation
**0**, or the individual PNGs as sprites.

## Licence

Use the assets in any number of your own games and apps, free or commercial, and edit
them however you like. Don't resell or share the assets themselves, and don't use them to
train AI. Full terms are in `LICENSE.txt`.

## Made with AI assistance

The art was generated with the help of AI tools. Every asset was hand-picked and prepared
for this pack.
