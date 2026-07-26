---
name: pr-review-sweep
description: Sweep one or more sigma PRs' unresolved review comments end-to-end — fetch (paginated), classify, check-if-already-fixed, fix-with-verification, reply-and-resolve. Never contacts reviewers. Use when a PR has open review feedback that needs triaging and landing.
---

# pr-review-sweep

Codifies the process used to clear ydimitrof's review rounds on sigma PRs. Run this
per-PR whenever `/project-status` (or a manual check) surfaces unresolved review threads.
Named skills `pr-triage-feedback`/`pr-address-feedback`/`pr-commit` were referenced in
project memory as covering this flow, but no such files exist anywhere on this
filesystem (checked: no `sigma/.claude/skills/` history, no matching skill in any
plugin) — this file replaces relying on those names.

## Step 1 — Fetch ground truth, fully paginated

Query GitHub's GraphQL API directly. Never trust file names, a prior status report, or a
reply's own claim about what's outstanding.

```graphql
query($n: Int!) {
  repository(owner: "midt-bg", name: "sigma") {
    pullRequest(number: $n) {
      reviewThreads(first: 100) {
        totalCount
        nodes {
          isResolved
          path
          line
          comments(first: 3) { nodes { author { login } body createdAt } }
        }
      }
    }
  }
}
```

Filter to `isResolved: false`. **`first: 100` is load-bearing** — `first: 50` silently
truncates on any PR that has grown past 50 threads (two real PRs hit this: one had 64
threads, another had 55; the truncated queries under-reported unresolved counts and
caused genuinely-missed comments). Always compare `totalCount` to how many nodes you
actually paged through, so truncation is caught immediately rather than discovered later
by a mismatched count on a subsequent sweep.

## Step 2 — Classify each thread

Three buckets, decided per-thread, not per-PR:

- **Accept-as-is** — the reviewer's ask is valid, no repo-policy reason not to do it. The
  default bucket.
- **Policy-override** — the comment conflicts with something the repo's own `AGENTS.md` /
  `CLAUDE.local.md` already decided (a staged-rollout convention, an intentional
  trade-off). Policy wins silently — no need to escalate to the user — but still reply
  explaining why, so the reviewer isn't left wondering. Verify the policy text actually
  says what you think it says before invoking this bucket; don't assume.
- **Needs-my-decision** — a genuine judgment call with no clear answer from repo policy
  alone. Stop, surface the question verbatim to the user, never guess. This is the only
  bucket that blocks anything, and it blocks only that one thread — every other thread on
  the PR keeps moving.

## Step 3 — Check if it's already fixed before writing any code

Read the current file content at the cited location, and check recent git log/commits on
the PR's actual branch. Multiple rounds turned out to need zero new code because other
work — sometimes from a completely separate concurrent session — had already landed the
fix; it just hadn't been marked resolved on GitHub yet. Skipping this step wastes effort
re-solving a solved problem and risks a redundant, conflicting second fix landing on top
of the first.

## Step 4 — Fix directly, with real verification

For anything genuinely unfixed in the accept-as-is/policy-override buckets: write the
actual code change, then run the project's real test and typecheck commands (not a
hand-picked subset) and confirm green before touching git. Commit using this repo's
convention — `type(scope): subject`, lowercase imperative, no trailing period, **no
`Co-Authored-By` trailer** (CI greps for it) — then push to the contributor's fork branch
only. Never push to `origin`, never force-push, never open a new PR to carry a review
fix — land it on the existing PR's own branch. This step happens inline, synchronously,
in the same pass that found the issue; never "queue it for later."

## Step 5 — Reply, then resolve

Post a reply on the GitHub thread naming the specific fixing commit SHA, so the reviewer
can verify without re-reading the whole diff. Then call `resolveReviewThread` via GraphQL
to close it. Order matters: reply first, resolve second, so there's a paper trail
explaining why a thread closed before it drops off the unresolved list. Needs-my-decision
threads, and any policy-override thread where convention says the reviewer should be the
one to close it, are deliberately left unresolved after the reply — that is correct
behavior, not an oversight.

## Hard constant across all five steps

**Never contact a reviewer** — no request, re-request, or nudge, at any point in this
process. Reviewer contact is a separate action, gated behind the user's explicit,
per-PR, freshly-given approval every time. A prior approval never carries forward to the
next PR or the next round.
