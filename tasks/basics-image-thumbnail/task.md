# Make a Proportional Thumbnail

Product pictures reach your extension as Base64 text — an API payload here, an imported catalog there — and the web shop wants a small preview for its item list. Squeezing a 4000-pixel photo into a 64-pixel tile is the browser's problem; producing a proportionally shrunk thumbnail, and refusing payloads that only pretend to be images, is yours. The good news: the System Application ships an `Image` codeunit that loads Base64, reads pixel sizes, resizes, and encodes back — your job is wiring it up and getting the proportional math and its boundaries exactly right.

## Requirements

Create a **codeunit** named `"Thumbnail Generator"` with two public procedures:

```al
procedure GetDimensions(ImageBase64: Text; var Width: Integer; var Height: Integer)
procedure CreateThumbnail(ImageBase64: Text; MaxDimension: Integer): Text
```

Rules:

1. `GetDimensions` loads the image encoded in `ImageBase64` and returns its pixel width and height through the two `var` parameters — width is the horizontal side, height the vertical one — don't swap them.
2. `CreateThumbnail` returns the picture as Base64 again, scaled down so that neither side exceeds `MaxDimension` pixels:
   - if width and height both already fit within `MaxDimension`, the picture keeps its size — never scale up;
   - otherwise the longer side becomes exactly `MaxDimension` and the other side is multiplied by the same factor (`MaxDimension` divided by the longer side), rounded to the nearest whole pixel — an exact half rounds up, so 25.6 becomes 26 and 7.5 becomes 8;
   - a side that would round down to 0 becomes 1 pixel instead — no side of the thumbnail is ever smaller than 1;
   - a square picture larger than the limit becomes exactly `MaxDimension` × `MaxDimension`.
3. Input that cannot be loaded as an image — text that isn't Base64 at all, or perfectly valid Base64 hiding bytes that aren't a picture — must make the call fail with an error, in both procedures. Any error text is fine: the tests only check that an error is raised, not what it says.
4. The tests always feed PNG images and a `MaxDimension` of at least 1, and the thumbnail they get back must still be a PNG. The returned Base64 does not have to be byte-identical to the input — the tests judge the thumbnail only by its decoded width, height, and format.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The grading tests decode the Base64 you return and measure it: a 100×40 PNG with a limit of 50 must come back as 50×20 and a 40×100 PNG as 20×50, an 80×80 PNG with a limit of 32 must become 32×32, and one test picks a random limit and recomputes the expected shorter side itself — hardcoding the examples won't survive it. Rounding is pinned at three spots: 100×40 with a limit of 64 must give 64×26, 20×10 with a limit of 15 must give 15×8, and 100×40 with a limit of 41 must give 41×16 — a fraction below one half (16.4) rounds down, so always rounding up fails here. A 20×10 PNG is returned unchanged in size both for a limit of 64 and for a limit of exactly 20, and a 100×2 PNG with a limit of 10 must become 10×1 — not fail, and not 10×0. `GetDimensions` is checked on a landscape and a portrait fixture, every thumbnail the tests get back is reloaded and must still decode as a PNG, and both procedures are fed plain prose and Base64-encoded prose and must raise an error each time.

## Learn More

- [Image codeunit (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.image) — the full toolbox this task runs on: `FromBase64`, `GetWidth`, `GetHeight`, `Resize`, `GetFormat`, `ToBase64`.
- [Image Format enum (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/enum/system.utilities.image-format) — the format values `GetFormat` can report, `Png` among them.
- [System.Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — precision and direction arguments; the default `'='` direction rounds halves up, exactly what the shorter side needs.
- [Base64 Convert codeunit (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.text.base64-convert) — what Base64 encoding is in BC terms, useful background even though `Image` handles it for you here.
