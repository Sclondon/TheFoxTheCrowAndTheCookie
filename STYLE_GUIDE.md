# Style guide

The rules the new pixel art in this game follows, worked out by measuring the
user's own sprites (each PNG read pixel by pixel; sizes, palettes and frame
grids below are measured values, not estimates).

Sources studied:

| Game | Where | What was measured |
| --- | --- | --- |
| Hemlock's Tower | `HemlocksTower/Ascension/images` | `crow.png`, `crowFlap.png`, `crow_fall.png`, `frog.png`, `trees/tree*.png`, `dirt.png`, `brickwall.png`, the crow's `SpriteFrames` (`animations/*.tres`) |
| 8 Bit Evil Returns | `8BitEvilReturns-godot/assets/sprites` | `idle_alex.png`, `run_alex.png`, `bat.png`, `ghost.png`, `zombie.png`, `werewolf.png`, `scarecrow.png`, `prop_pumpkin_pile.png`, `street_lamp.png`, `candy_bar.png`, `lollipop.png`, `heart.png`, `gamebg.png` |
| Tlaloc's Curse | `tlalocs-curse-pinball/Sprites` (copies in WirtWare `art/temple`) | `t_warrior.png`, `t_kickback_frog.png`, `t_leaves.png`, `t_feathers.png`, `map_palms.png` |
| WirtWare's collected copies | `WirtWare/art/{graveyard,temple,swamp}`, `art/sizes.txt` | the size list, `sludge_toad.png`, `ground_crypt.png` |

## The anchor: Hemlock's Tower

The crow comes from Hemlock's Tower, so its look sets the rules. The other two
games use a different look (see "Where the games differ" below); this game
follows Hemlock's.

### The crow (measured)

- Cells: idle 8 frames of 16x16 (`crow.png`, 128x16); flap 4 frames of 32x32
  (`crowFlap.png`); fall 2 frames of 16x16. In Hemlock's Tower all three play at
  **5 fps**.
- Body about 12x11 px inside the 16x16 cell, feet on row 13, facing left.
- Idle: the body bobs down 1 px on frames 4 and 8 (beak, eye and brow drop with it).
- 8 colours, no others:

| Hex | Use |
| --- | --- |
| `#0c1023` | darkest navy: silhouette edge, under-tail, legs, feather breaks |
| `#1b1f34` | body shade |
| `#272b41` | body mid (the most used) |
| `#414247` `#35363c` `#212430` | beak, light to dark (3 tones in 3 pixels) |
| `#a02727` | the eye: one pixel |
| `#7a1919` | the brow: one pixel above the beak |

### Outline

- **No black outline.** The edge of a shape is the darkest tone of its own
  material (a "hue outline"): the crow uses `#0c1023`, the frog `#172807`, the
  trees `#321e2f`/`#29172d`.
- The outline is broken where light hits: the tops of tree crowns and the
  crow's back have no edge line at all, only the lighter tones running out to
  the edge.
- Weight: 1 px, never doubled.

### Shading

- 3 to 4 tones per material (crow body 3, frog 5 including the outline,
  tree trunk 3, autumn leaves 4, dirt 3).
- Light from the **top left**: lighter tones on top and left-facing edges,
  darker tones underneath and on the right.
- Flat fills. No dithering, no anti-aliasing, no gradients inside a sprite.
- Texture comes from scattered single darker pixels (feathers on the crow,
  flecks in the dirt, bark lines), not patterns.

### Faces and eyes

- Crow: a single red pixel for the eye with a dark-red brow pixel up and to the
  left of it. No white.
- Frog (Hemlock): 2x2 dark-purple eyes (`#674356`) set wide, no highlight; a
  pale belly patch (`#bca98b`, `#b38c50`).
- 8 Bit Evil heroes: eyes are 1x2 dark pixels with a pink blush pixel below.
- So: faces are two to four pixels. No mouths unless the mouth is the point
  (open to sing or talk).

### Hemlock palette (measured)

| Material | Tones |
| --- | --- |
| Tree trunk | `#29172d` `#321e2f` `#452c32` |
| Autumn leaves | `#88361c` `#b8601e` `#ca8c40` `#deb04f` |
| Grass tufts | `#21533f` `#376854` |
| Dirt | `#55303d` `#673f4d` `#7d506c` |
| Frog | `#172807` `#294013` `#3c5722` `#4b692f` `#6c8654`, belly `#bca98b` `#b38c50`, eyes `#674356` |
| Brick | `#1a3a48` `#244c50` `#295553` `#4c705f` `#6b8f68` `#84a17a` `#93b68e` |

### Sizes

| Kind | Hemlock / others | This game |
| --- | --- | --- |
| Small creature | crow, frog 16x16; sparrow-sized bits 8x8 | crow 16x16 (flight 32x32), sparrow 8x8, frog 16x16 |
| Mid creature | 8 Bit Evil heroes 16x24, bat 32x32, toad 24x24 | fox 32x24 |
| Props | 16 to 64 px | 3 to 52 px; cottage 96x80 |
| Trees | 128x128 | Hemlock's own 128x128 |
| Tiles | 64x64 | ground 64x48 |

## Where the games differ

- **8 Bit Evil Returns** characters have a 1 px near-black outline (`#222034`,
  `#000000`) round the whole figure, brighter saturated fills (Alex: hair
  `#e8af3b`, shirt `#e35a1e`, jeans `#3345b3`) and a soft shadow ellipse under
  the feet. Props such as the pumpkin pile use a 5-tone orange ramp
  (`#7a3006` `#b8500c` `#f07a1e` `#ffb046` `#ffe14a`) with green `#4a6a2a`
  `#6a8a3a`. Bats are 4 frames of 32x32 with 5 colours.
- **Tlaloc's Curse** is the brightest: black `#000000` outlines, teal
  `#089890`, gold `#f8d000`, white `#fff8ff`; small figures (warrior 17x23,
  kickback frog 18x15) and 4 px particle strips (leaves, feathers).
- All three share: 1 px = 1 game pixel, no mixed resolutions, flat fills,
  top-left light, sprite sheets as left-to-right strips of equal cells, and
  Halloween-autumn colour (oranges and golds against cool dark blues and greens).

## Rules for this game

1. **One art pixel is one world pixel.** Nothing is scaled except by the camera,
   which zooms by a whole number (`round(window height / 260)`: 2 in phone
   landscape, 3 in phone portrait at 1x, about 10 on a 3x phone). Nearest
   filtering everywhere, transforms snapped to pixels.
2. **Hue outlines, Hemlock style.** Each material's edge is its own darkest tone.
   Warm things (fox, cookie, wood, thatch, leaves) share the tree shadow
   `#321e2f`; cool things use theirs (crow `#0c1023`, brick `#1a3a48`, leaves
   `#19391a`). Exception: marks that float over the sky (music notes, the "!",
   the speech bubble, the arrow) get a 1 px `#321e2f` ring outside, so they
   read on any sky.
3. **4-tone ramps, lit from the top left.** Every shaded shape is painted from
   a ramp `[outline, dark, mid, light]` by one rule
   (`tools/pix.gd` `shade()`): edge pixel = outline; a pixel whose
   down-right neighbour is outside = dark; whose up-left neighbour is outside =
   light; else mid.
4. **Borrow the palette before adding to it.** The fox is the tree's autumn
   ramp (`#88361c` `#b8601e`, plus one new light `#d47a32`), cream
   `#eadcbf`/`#bca98b` (the frog's belly), socks `#452c32` (the trunk). The
   cookie is the autumn leaves with trunk-brown chips. The cottage is
   Hemlock's brick under a thatch in the leaf ramp. The only new colours are
   glows (`#ffe08a`, `#fff4d0`), which are light, not material.
5. **Faces: 1 to 2 pixels.** The fox's eye is one `#0c1023` pixel; pleased, it
   becomes a 2 px line in `#88361c`. Mouths only open to talk, sing or catch.
6. **Animation.** Strips, left to right, equal cells. Idle loops 2 to 8 frames
   at 1 to 5 fps (the crow's 5 fps is the reference); moving loops 6 frames at
   7 to 10 fps; effects 3 to 4 frames. New crow poses keep the Hemlock body rows
   unchanged wherever the pose allows, so they cut between each other cleanly:

| Strip | Cells | fps |
| --- | --- | --- |
| crow idle / flap / fall (Hemlock) | 8 x 16x16 / 4 x 32x32 / 2 x 16x16 | 5 / 10 in flight / 5 |
| `crow_preen` `crow_sing` `crow_startle` `crow_droop` `crow_peck` `crow_sleep` | 4 / 2 / 2 / 2 / 2 / 2, all 16x16 | 5 / 4 / 8 / 1.2 / 4 / 0.8 |
| `fox_trot` `fox_sniff` | 6 x 32x24 | 10 / 7 |
| `fox_sit` `fox_lookup` `fox_talk` `fox_smile` `fox_bow` `fox_yip` `fox_leap` | 4 / 2 / 2 / 2 / 2 / 2 / 3 | 3 / 1.5 / 5 / 1.5 / 1 / 6 / 7 |
| `cookie` (whole, two glints, bitten) | 4 x 6x6 | on demand |

7. **Backgrounds recede, characters don't.** Far layers (hills, treeline,
   clouds) are drawn as white silhouettes and tinted from the sky colour in
   code; the Hemlock bare trees behind the wood are mixed 50% toward a haze
   colour (`shaders/haze.gdshader`) and move at 0.8 of the camera's pace. The
   wood is lit by the time of day (a `CanvasModulate`); the crow and the fox get
   a stage light that cancels most of it, so the two players always read. Glows
   (lit window, lantern, fireflies, sparkles, notes) sit on their own layer,
   untouched by the night.
8. **Sky.** Ten flat bands from the top colour to the horizon colour, no smooth
   gradient, so it matches the sprites' flat fills.

## Where to change things

- The painter: `tools/pix.gd` (grids, masks, `shade()`, `clump()` for foliage).
- Characters: `tools/gen_characters.gd` (crow poses as character grids using the
  Hemlock palette letters; the fox built from shaded parts plus head grids).
- Scenery, effects, UI bits, the icon: `tools/gen_scenery.gd`.
- Regenerate: `godot --headless --path . --script tools/gen_art.gd`, then
  `godot --headless --path . --import`.
