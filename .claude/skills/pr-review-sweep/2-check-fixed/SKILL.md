---
name: pr-review-sweep:check-fixed
description: Step 2 of pr-review-sweep — before queuing anything, check whether each accept-as-is / policy-override thread is already fixed in the current code or a recent commit on the PR's own branch.
---

# pr-review-sweep:check-fixed

Read the current file content at the cited location, and check recent git log/commits on
the PR's actual branch. Multiple review rounds turned out to need zero new code because
other work — sometimes from a completely separate concurrent session, sometimes a prior
sweep's queued PRD that landed since the last check — had already landed the fix; it just
hadn't been marked resolved on GitHub yet.

Skipping this step wastes a scheduler PRD re-solving a solved problem and risks a
redundant, conflicting second fix landing on top of the first.

## Output

Two lists per PR: **already-fixed** (thread id + the commit/line that fixed it — routes
straight to `pr-review-sweep:land-and-resolve`, skipping the queue entirely) and
**survives** (thread id, disposition, type — goes on to `pr-review-sweep:queue`).
