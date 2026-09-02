# TryAL Tasks — community task catalog

Practice tasks for **TryAL.dev**, a practice platform for Microsoft
Dynamics 365 Business Central (AL) developers. Every task in `tasks/` is served
to users through the platform's REST API; submissions are compiled with the
AL compiler and graded by test codeunits inside BC containers.

**Solve them at [https://tryal.dev/](https://tryal.dev/).** This repository is the source of truth
for the tasks themselves — the platform imports them from a pinned, approved
ref.

**Anyone can add a task.** Copy a template, fill it in, open a PR.

**1. Copy the template.** The directory name **is** the task id:
`<topic>-<slug>`, where the prefix is the task's topic from
[`topics.yaml`](topics.yaml) and the slug describes what the user
builds. It must match the `id` field in `metadata.yaml`.

Windows (PowerShell):

```powershell
Copy-Item -Recurse templates\full_execution tasks\algorithm-your-idea
```

macOS / Linux (bash):

```bash
cp -r templates/full_execution tasks/algorithm-your-idea
```

**2. Fill in the files** — `metadata.yaml`, `task.md`, `starter/`,
`tests/`, `solution/`. Every template file is annotated with what goes where,
and [`tasks/basics-add-table-field`](tasks/basics-add-table-field)
is a small complete example to crib from.

**3. Lint locally, then open a PR:**

```bash
npm install
npm run lint
```

CI additionally compiles your starter, solution and tests with the real AL
compiler — see [CONTRIBUTING.md](CONTRIBUTING.md) for running that gate
locally with `npm run compile`.

Read **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full walkthrough: grading
semantics, the metadata field reference, and the quality bar your task must
meet. Budget real time for the tests — the bar is that your `solution/` passes
every test and the unchanged `starter/` fails at least one, which is what makes
a task worth solving. Not sure the idea fits the catalog? Open a
[**Propose a new task** issue](https://github.com/Drakonian/tryal-dev-tasks/issues/new/choose)
first and get feedback before writing tests.

## Repository layout

```
tasks/<task-id>/          one directory per task — the directory name IS the task id
├── metadata.yaml         grading config + catalog metadata (JSON-Schema validated)
├── task.md               problem statement served to users
├── starter/*.al          starter code, one file per AL object
├── tests/*.al            the test codeunits that grade submissions
└── solution/*.al         reference solution — never served, proves solvability

templates/                copyable skeleton for new tasks
schema/                   JSON Schema for metadata.yaml (live editor validation)
topics.yaml               the platform's topic set
compiler/symbols/         pinned BC symbols for the offline compile gate
scripts/lint.js           offline format check — run via `npm run lint`
scripts/compile.js        offline AL compile gate — run via `npm run compile`
scripts/smoke.js          grades tasks against the real platform (Grade tasks workflow)
.github/                  CI + manual grading workflows, issue forms, PR template, CODEOWNERS
.claude/skills/           optional AI-agent authoring skill (see CONTRIBUTING)
```

## How grading works

Every task is graded **`full_execution`**: the submission is compiled with
the real AL compiler against the platform's pinned BC version, published into
a real Business Central container together with the task's test codeunits,
and passes when every `[Test]` procedure passes. Users see per-test results.

> The platform format also defines a `compile_only` tier (graded by
> compilation alone). This catalog doesn't accept it for now — compiling
> proves too little to make a task meaningful — so the lint rejects it.

## Quality gates

- **Lint (CI, offline):** format contract — schema-valid metadata, unique
  sortId, required files, submission limits and topics.
- **Compile gate (CI, offline):** each changed task's starter, solution and
  tests are compiled with the real AL compiler against the platform's pinned
  BC symbols ([`compiler/symbols/`](compiler)) — catches invalid AL without
  a BC container. Diagnostics show up as inline PR annotations; analyzer
  findings are surfaced but non-fatal, like on the platform. Pushes to main
  (and PRs touching shared files) compile the full catalog.
- **Grading (CI, manual):** a maintainer runs the **Grade tasks** workflow
  from the Actions tab for selected task ids (or `all`). Each task is uploaded
  to the platform's staging area and graded in a real BC container: the
  `solution/` must compile and pass every test, and the unchanged `starter/`
  must compile but fail at least one. It is never automatic — every run
  occupies real containers on the platform host.
- **Human review (always):** a task's `tests/` are trusted code executed in
  the platform's containers, so every PR needs maintainer approval. The
  platform imports tasks from a pinned, approved ref — never from an open
  branch.

## License

[MIT](LICENSE) — contributions are accepted under the same terms.
