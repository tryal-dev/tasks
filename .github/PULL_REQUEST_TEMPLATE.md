## What does this PR add or change?

<!-- One or two sentences. For a new task: what does it teach, and why this difficulty? -->

## Checklist

- [ ] `npm run lint` passes locally (CI runs it too)
- [ ] The task compiles — CI runs `npm run compile` with the real AL compiler; run it locally to check before pushing (see CONTRIBUTING)
- [ ] The task directory name equals `metadata.yaml` → `id`
- [ ] Everything `task.md` promises is enforced by a test; good-practice extras are labelled "not graded"
- [ ] Objects are referenced **by name**, never by literal ID
- [ ] Hints are ordered gentle → explicit and don't paste the full solution

<!-- Every task PR requires human maintainer review before merge — tests/ is
     trusted code executed in the platform's containers. -->
