<p align="center">
  <a href="https://tryal.dev/">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset=".github/assets/wordmark-dark.svg">
      <img src=".github/assets/wordmark-light.svg" alt="tryal.dev" height="64">
    </picture>
  </a>
</p>

<p align="center"><strong>Learn AL by writing AL.</strong></p>

<p align="center">
  <a href="https://tryal.dev/"><img src="https://img.shields.io/badge/solve_on-tryal.dev-008d94" alt="Solve on tryal.dev"></a>
  <a href="tasks"><img src="https://img.shields.io/github/directory-file-count/tryal-dev/tasks/tasks?type=dir&label=free%20tasks&color=008d94" alt="Free tasks"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/contributions-welcome-008d94" alt="Contributions welcome"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-008d94" alt="MIT license"></a>
</p>

Practice tasks for **[TryAL.dev](https://tryal.dev/)**, a free website for
learning AL, the programming language of Microsoft Dynamics 365 Business
Central.

Each task is a small coding problem. You write the code in your browser, and
automated tests running on a real Business Central server check whether it
works. Nothing to install.

- **Want to solve tasks?** Head to [tryal.dev](https://tryal.dev/).
- **Found a mistake in a task?** [Report it](https://github.com/tryal-dev/tasks/issues/new?template=task-bug.yml).
- **Want to write a task?** Anyone can — read on.

This repository holds all of the site's free tasks (Pro tasks are kept
separately), and everything in it is [MIT-licensed](LICENSE).

## Add a task

A task is a folder with a problem statement, starter code, and the tests that
check solutions. One rule matters most: **your own solution must pass every
test, and the untouched starter code must fail at least one.** Otherwise
there's nothing to solve.

Have an idea but not sure it fits? [Propose it first](https://github.com/tryal-dev/tasks/issues/new?template=propose-task.yml)
and get feedback before you spend time on tests.

**1. Copy the template.** The folder name is the task id, in the form
`<topic>-<slug>`: the topic comes from [`topics.yaml`](topics.yaml), and the
slug briefly describes what the solver builds — for example
`algorithm-vat-rounding`. It must match the `id` in `metadata.yaml`.

Windows (PowerShell):

```powershell
Copy-Item -Recurse templates\full_execution tasks\algorithm-your-idea
```

macOS / Linux (bash):

```bash
cp -r templates/full_execution tasks/algorithm-your-idea
```

**2. Fill in the files.** Each template file has comments explaining what goes
where, and [`tasks/basics-add-table-field`](tasks/basics-add-table-field) is a
small finished example.

| File | What it is |
|---|---|
| `metadata.yaml` | Title, topic, difficulty, hints, and grading settings |
| `task.md` | The problem statement solvers read |
| `starter/*.al` | The code solvers start from, one file per AL object |
| `tests/*.al` | The test codeunits that grade solutions |
| `solution/*.al` | Your reference solution. **Keep it local** — this repository is public, so `solution/` is gitignored. A maintainer will ask you for it during review. |

**3. Check it locally.** You need [Node.js](https://nodejs.org/) 20 or later:

```bash
npm install
npm run lint
```

CI also compiles your starter and tests with the real AL compiler. To run
that check yourself with `npm run compile`, see
[CONTRIBUTING.md → Quickstart](CONTRIBUTING.md#quickstart).

**4. Open a pull request.**

[CONTRIBUTING.md](CONTRIBUTING.md) is the full guide: grading details, every
`metadata.yaml` field, submission limits, and an optional AI-agent skill that
helps you write a task.

## What happens after you open a PR

1. **Automatic checks.** CI lints your task and compiles the starter and tests
   with the real AL compiler. Any problems are flagged right on the changed
   lines.
2. **Grading.** A maintainer runs your task in a real Business Central
   container: the starter must compile but fail at least one test, and your
   reference solution must pass them all. This step is manual because every
   run uses a real container.
3. **Review.** Tests run as trusted code on the site's servers, so every PR
   needs a maintainer's approval. Only reviewed, merged tasks ever reach the
   site.

## How grading works

A solver's code is compiled with the real AL compiler for the site's Business
Central version, installed into a real Business Central container together
with the task's test codeunits, and passes when every `[Test]` procedure
passes. Solvers see the result of each test.

## Repository layout

```
tasks/<task-id>/          one folder per task — the folder name is the task id
├── metadata.yaml         task settings (validated against schema/)
├── task.md               problem statement
├── starter/*.al          starter code, one file per AL object
└── tests/*.al            test codeunits that grade solutions

templates/                copyable skeleton for new tasks
schema/                   JSON Schema for metadata.yaml (live validation in your editor)
topics.yaml               the site's topics
compiler/symbols/         pinned Business Central symbols for the offline compile check
scripts/                  lint, compile, and grading scripts behind the npm commands
.github/                  CI and grading workflows, issue forms, PR template, README logo
.claude/skills/           optional AI-agent skill for writing tasks
```

## License

[MIT](LICENSE) — contributions are accepted under the same terms.
