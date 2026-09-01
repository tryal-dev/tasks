# Compiler assets

`symbols/` is the pinned Business Central symbol set (currently **BC 28.2**)
that the offline compile gate — `npm run compile` / the CI `compile` job —
feeds to the AL compiler as its package cache (`/packagecachepath`). It is the
same lean set the platform compiles submissions against: System (platform
symbols), the Application meta package with Base Application / System
Application / Business Foundation, and the standard test libraries (Library
Assert, Any, Library Variable Storage, Application Test Library, Business
Foundation Test Libraries).

Two pins must stay in sync with this folder:

- `scripts/compile.js` — `PLATFORM_VERSION` / `RUNTIME` in the generated
  `app.json` (BC 28 → runtime 17.0);
- `package.json` → `config.alToolVersion` — the
  `Microsoft.Dynamics.BusinessCentral.Development.Tools` dotnet tool version
  CI installs.

## Updating to a new BC version

Replace the `.app` files with the new pinned version's symbol packages and
bump the two pins above. The dependency list for generated test apps is read
from the packages themselves (each `.app`'s embedded manifest), so adding or
swapping packages needs no script change.

**Watch file sizes:** GitHub rejects files over 100 MB, and the Base
Application symbols are ~98 MB today. If a future symbol set crosses the
limit, move this folder to Git LFS or a CI-time download instead of plain
git.
