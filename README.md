# The Fox, The Crow, and The Cookie

An interactive music video for mewithoutYou's "The Fox, The Crow and The Cookie"
(track 2 of *It's All Crazy! It's All False! It's All a Dream! It's Alright*,
2009, 3:31). The song retells a Sufi teaching story from Bawa Muhaiyaddeen's
*My Love You My Children: 101 Stories for Children*, his version of Aesop's
fable of the fox who flatters the crow into singing so that she drops her food.

A wide pixel-art wood plays the story out on the song's timeline: dawn at a
baker's cottage, a crow who takes a cookie from the sill, a fox who looks up
and pays three compliments, a song, a fall, a bow, dusk, crumbs and night. You
pan around and tap things while it happens. Nothing is scored.

Godot 4.7, GL Compatibility, web export, phone first (portrait and landscape).

**The song is not in the game.** It plays through the official Spotify embed
(default) or the official YouTube upload, shown in a small framed player in
the bottom-left corner. There are no lyrics anywhere in the game or this repo;
the captions are scene titles written for it.

## Playing

- Tap **Tap to play** on the title card. Under it, **Spotify** / **YouTube**
  picks where the song comes from.
- Drag to look around (or arrow keys / A-D, the mouse, the wheel). When the
  action is off screen an arrow at the edge points to it; tap the arrow to go
  there. Leave the view alone for a few seconds and it drifts back to the action.
- Tap anything. The crow preens or startles, the fox yips or grins, cookies
  glint, bushes rustle (one hides sparrows), the bell rings, mushrooms bounce,
  leaf piles fly, the chimney puffs, the lantern switches on and off, the frog
  hops, the pond ripples, the reeds shiver, the owl blinks, eyes shine in the
  den, an acorn drops from the crow's tree. Empty sky sends a bird across;
  empty ground puffs; at night the dark sparkles.
- The story runs on the song's clock whatever you do. Pause the player and the
  story waits; seek and it follows.
- At the end: a card with the credits and **Watch again**.

## The song sources

All configuration is in `data/timeline.json` under `"sources"`:

| Source | ID | Notes |
| --- | --- | --- |
| Spotify (default) | track `4SenxwCmSCIXfklUvmXyNc` | confirmed: the album track, 211 s |
| YouTube | video `kwGgQAMj5DI` | the official "mewithoutYou - Topic" art track (provided by Universal Music Group), 211 s, same audio as the album |

Switch with the buttons on the title card, or a link:
`index.html?source=spotify` or `index.html?source=youtube`. To change the
default, set `"default"` in the file.

**Spotify** (`scripts/song/spotify_source.gd`) loads the Spotify Embed iFrame
API, makes the compact 80 px player (the tab on its corner shrinks it from 300 to
160 px wide), and calls `controller.play()` on Tap to play. The clock follows
the controller's `playback_update` events: it keeps the last position and when
it arrived, and moves on from there between updates (buffering counts as
paused). Listeners who aren't signed in to Spotify in that browser only get a
30-second preview. The game spots that (a duration of about 30 s), and when the
preview ends it carries on silently with the note "Sign in to Spotify in this
browser to hear the whole song".

**YouTube** (`scripts/song/youtube_source.gd`) loads the IFrame Player API with
`playsinline=1, controls=0, rel=0, modestbranding=1` in a 200x200 framed
window (YouTube's minimum player size, so it doesn't shrink), calls
`playVideo()` on Tap to play, and polls `getCurrentTime()` every frame.
There is also the official VEVO music video (`-fRFMkFbH8I`, 3:47, directed by
Amy Carrigan and David Bell). Its intro length isn't measured, so if you switch
`video_id` to it, set the YouTube `"offset"` to the number of seconds of video
before the song's first note.

If a source can't load or play (blocked, offline, region, embedding refused),
or in the editor and desktop builds, the game falls back to a plain clock and
says so in a small note. If the music hasn't started 4 s after Tap to play
(some browsers won't let a game start an embedded player), it asks you to press
play on the player, with a **Watch without the song** button.

`offset` (per source): seconds of the source before the timeline's 0.

## Retiming the story

Every beat is one line in `data/timeline.json`:

```json
{ "t": 88, "id": "flatter_feathers", "caption": "The first compliment", "focus": "tree" }
```

- `t`: seconds into the song. Nudge it to land the beat on the music.
- `id`: which handler in `scripts/director.gd` acts it out (`_beat_<id>`).
- `caption`: a scene title shown for a few seconds ("" for none).
- `focus`: where the camera drifts and the arrow points: `crow`, `fox`,
  `cookie`, `cottage`, `tree`, `den`, or a world x number.
- `"length"`: when the ending card shows (211, the song's length).
- `"sky"`: the time of day, keyed by time (`dawn`, `morning`, `day`,
  `afternoon`, `golden`, `dusk`, `night`, colours in `scripts/backdrop.gd`).

Each handler scales its actions to the gap before the next beat, and any
action still running when the next beat starts is finished at once, so beats
can be moved closer together safely. The current times pace the story evenly
across the 3:31. They are not yet matched to the recording's quiet and loud
sections; the easiest way is to play the song beside
`godot --path . -- --silent --autostart` and note the times.

The beats: dawn, the tray set out, the crow wakes, she spies the cookies, swoops,
takes one, home with her prize; the fox wakes, trots over, looks up; the first,
second and third compliments; a request; she sings and the cookie falls into
his jaws; it's gone; the fox's bow; off he trots; dusk; crumbs (she comes down
for what's left); night.

## Code

```
scenes/main.tscn            one node; everything is built in code
scripts/main.gd             builds the scene, camera, all input, states (title, waiting, show, end)
scripts/director.gd         the story: one handler per beat, tween tracking, camera focus
scripts/world.gd            the wood: scenery, props, every tap target and its reaction
scripts/crow.gd, fox.gd     the two actors (animations, flights, trots, cookie in beak/mouth, tap reactions)
scripts/backdrop.gd         sky bands, sun, moon, stars, clouds, parallax hills/treeline/hazed trees
scripts/fx.gd               sparkles, notes, feathers, leaves, puffs, ripples, "!", picture speech bubbles
scripts/hud.gd              title card, captions, notes, arrows, wait prompt, ending card
scripts/sfx.gd              all sounds, synthesised at start-up (no audio files)
scripts/art.gd              sprite-strip helpers
scripts/song/               SongSource (interface), SilentSource, WebEmbedSource, SpotifySource, YouTubeSource
shaders/haze.gdshader       pushes background trees into the distance
data/timeline.json          beats, sky, song sources
art/                        generated sprite strips (PNG, committed)
art/hemlock/                copies of the Hemlock's Tower originals: the crow, frog, trees, dirt
tools/                      art generator, pixel painter, screenshot tool
tests/                      smoke test (headless) and touch test (windowed)
```

Input is read in `main.gd` `_input` from `InputEventScreenTouch` /
`InputEventScreenDrag` (mouse emulation is off). A drag from a finger whose
press never arrived counts as the press, and a release with no press counts as
a tap. Every interaction works from a tap alone. HUD buttons are hit-tested by
the same code. The game never posts PLAYER_DIED (there is no score).

## Art

All new art is drawn by scripts, to `STYLE_GUIDE.md` (written from measuring
the user's own sprites in Hemlock's Tower, 8 Bit Evil Returns and Tlaloc's
Curse). The crow's idle, flap and fall strips are the Hemlock's Tower
originals (`HemlocksTower/Ascension/images/crow.png`, `crowFlap.png`,
`crow_fall.png`); her extra poses (preen, sing, startle, droop, peck, sleep)
are drawn in the same palette on the same body. The frog and the trees are
Hemlock's too.

```sh
godot --headless --path . --script tools/gen_art.gd   # rewrite art/*.png and icon.png
godot --headless --path . --import                    # let Godot pick them up
```

`godot` is `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.
A new `class_name` script also needs the `--import` run before other scripts can use it.

## Tests

```sh
godot --headless --path . --script tests/smoke_test.gd
godot --path . --resolution 390x844 --script tests/touch_test.gd   # needs a real window
godot --path . --resolution 844x390 --script tests/touch_test.gd
```

The smoke test checks `timeline.json` (order, handlers, focus, sky phases,
length 211, both source IDs), plays the whole show at 25x on the silent clock,
taps every tap target, seeks back from 120 s to 55 s and checks the story
rebuilt itself, checks the ending (crow asleep on her perch, fox home, cookie
gone, crumbs eaten), presses Watch again and tests the silent fallback. It fails
on any engine or script error. The touch test sends real touch events at
window positions (`root.get_final_transform() * node.get_global_transform_with_canvas()`)
for Tap to play, panning, a drag with no press, a release with no press, the
bell, crow, fox, a mouse click, the off-screen arrow, the ending card and
Watch again. Both print PASSED or FAILED and exit 0 or 1.

## Screenshots

```sh
godot --path . --resolution 390x844 -- --silent --shots=title,20,90,150 --shotdir=shots --tag=portrait --speed=4
```

`--shots` takes `title` and show times in seconds; files go to
`shots/<tag>_<time>.png` (git-ignored). Other options: `--autostart`,
`--at=SECONDS`, `--speed=N`, `--silent`. A few are kept in `docs/screenshots/`.

## Export

```sh
godot --headless --path . --export-release "Web" build/index.html
```

The preset (copied from WirtWare) is single-threaded (works on iOS Safari and
GitHub Pages), excludes `tests/*`, sets `touch-action: none` in the page head,
and turns off the experimental virtual keyboard. `build/` is committed.

## Credits

- Song: "The Fox, The Crow and The Cookie" by mewithoutYou. Not included;
  played from the official Spotify and YouTube releases.
- The crow, the frog and the trees: Hemlock's Tower.
- Fonts: Cinzel and Alegreya Sans (SIL Open Font License, `fonts/OFL.txt`).
