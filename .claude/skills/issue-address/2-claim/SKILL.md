---
name: issue-address:claim
description: Step 2 of issue-address — claim a confirmed-open, confirmed-unclaimed sigma issue before reproducing/fixing it, by self-assigning and posting a claim comment via the gh CLI (no dedicated GitHub MCP server is connected in this environment — gh is the actual mechanism). Closes the race condition where two runs could pick the same issue.
---

# issue-address:claim

Runs immediately after `issue-address:confirm-open` returns GO, and before
`issue-address:reproduce` starts any work. Exists because confirming an issue is
open/unclaimed and then *starting work on it* are two different moments in time — without
an explicit claim in between, a second concurrent run of this same skill (or a human
contributor) could pick the same issue, and nothing in `issue-address:select`'s
`reject-claimed` check would have caught it, since that check only looks for assignees and
existing claim-language comments — which don't exist yet for an issue nobody has started.

**No dedicated GitHub/issue-tracking MCP server is connected in this environment** — every
GitHub interaction in this whole skill chain (and everywhere else this session) goes
through the `gh` CLI via Bash. If a GitHub MCP server becomes available later, swap the
commands below for its equivalent calls; until then, `gh` is the actual mechanism, not a
gap to work around.

## Steps

1. **Self-assign**, so the issue shows a claim to anyone else's `select:reject-claimed`
   pass or manual look:
   ```bash
   gh issue edit <N> --repo midt-bg/sigma --add-assignee "@me"
   ```
   If self-assignment fails (e.g. insufficient repo permissions — a common case for
   external contributors on a repo they don't have write access to), don't halt the
   sequence on that alone; fall back to step 2's comment as the claim signal, and note in
   the report that assignment wasn't possible so a human knows to check.

2. **Post a claim comment** — visible even to someone who doesn't check assignees,
   and consistent with the claim-language `select:reject-claimed` already scans for
   ("работя по това", "I'll pick this up"):
   ```bash
   gh issue comment <N> --repo midt-bg/sigma --body "Работя по този issue (issue-address skill chain). Ще линкна PR-а тук след fix + verify."
   ```

3. **Re-confirm the claim actually landed** before proceeding — read the issue back and
   check the assignee list and/or the posted comment are present:
   ```bash
   gh issue view <N> --repo midt-bg/sigma --json assignees,comments
   ```
   If neither the assignment nor the comment is visible, don't silently proceed as if
   claimed — report the failure; a claim that didn't actually post protects nobody.

## Output

Hand off to `issue-address:reproduce` — same issue number, now with a real claim on
record. If this step's own re-confirmation fails (step 3), stop the sequence and report,
same severity as a `confirm-open` NO-GO — proceeding to reproduce/fix on an issue that
isn't actually marked claimed defeats the point of adding this step.
