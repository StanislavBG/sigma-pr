# Supersession triage — #144 and #206 (2026-09-20)

Read-only evidence. No PR was closed, commented on, or re-requested; nothing was pushed to any fork.
Measured against `origin/main` @ `157f5ede`; PR heads fetched as `pr/144`, `pr/157`, `pr/206`.
Merge base of #144 and #206 is `20d2ed92`; #157's is `2d93cd52` (older).

---

## 1. #144 — force-directed network graph (`feat/…`, StanislavBG, opened 2026-06-27)

### 1.1 What main's V2 graph already is

`origin/main:apps/web/app/components/NetworkGraph.tsx` (156 lines; arrived via `4c038168` #356, touched by `6797c931`, `6ddb0c3a`). Header comment, verbatim:

> Static server-rendered radial ego graph (no chart JS, like SankeyDiagram). Centre in the middle, direct counterparties on an inner ring, their top other counterparty on an outer ring. […]
> Every node is a link to its profile. […] Consequently the <svg> must NOT carry role="img": that role collapses the whole graphic into one image for assistive technology and hides the interactive descendants. It is a group of links, and the connections table beside it is the same set of links in a linear form.

Main's component: pure SSR, `Link` per node, `aria-label` per node, no hooks, no client state, no d3, no `useFetcher`. Its tests pin the a11y contract (`does not present itself as a single image, which would hide the links`, `links every node to its own profile`).

### 1.2 File-by-file (20 files in the PR)

| #144 item | Status vs main | Notes |
|---|---|---|
| `NetworkGraph.tsx` (+522) | **conflicts-with-main's-design-intent** | Rewrites the file main independently rewrote (content conflict). Adds `useFetcher` re-centre-on-click, hover card, fullscreen, and its own header states the SVG is `role="img"` — the exact thing main's comment forbids. Its node click re-centres instead of navigating; the link becomes a no-JS fallback only. |
| `NetworkGraph.test.tsx` (+208) | **conflicts** (add/add) | Main has its own test file pinning the opposite a11y contract. |
| `lib/useForceGraph.ts` (+301, + test) | **conflicts-with-main's-design-intent** | d3-force/drag/zoom simulation on hydration. This is precisely "chart JS" that main's header rules out. |
| `lib/network-layout.ts` (+155, + test) | **still-unique, but only meaningful with the sim** | Extracts geometry (W/H/R1/R2), seed, label collision. Main inlines W=760/H=540/R1=150/R2=250 in the component. Without the force sim it is a refactor of a 156-line file; it also changes the canvas size (820×600 vs 760×540). |
| `lib/network-center.ts` (+77, + test) | **partly still-unique** | Shares the `?center` grammar between graph and loader (`centerToken`/`parseCenter`). Main's `routes/network.tsx` still has a private `parseCenter`, so dedupe is valid — but `centerToken` exists only to serve client re-centring. `parseCenter`/`isAdoptableNetwork`/`countDirectEdges` are the reusable part. |
| `components/Pagination.tsx` (+8) | **still-unique** | Renders `Страница N` without `от M` when `pageCount === null`. Main has no null-count path (`Pagination.tsx:18` unconditional). Only needed if counterparty pagination lands. |
| `api-contract` (+29) | **still-unique** | `NetworkData.counterpartyTotal`, `NetworkCounterparty`, `NetworkCounterpartyPage`. Main has none (grep: no hits). Serves the exhaustive relations table, independent of the sim. |
| `db/queries/network.ts` (+105, + test +223), `identity.ts` (+6) | **still-unique** | Counterparty keyset pagination + total; EIK-shape validation for authority slugs. Not in main. Main's network.ts also changed in V2, so it needs a real rebase. |
| `routes/network.tsx` (+151/-), `entity-tables.tsx`, `filters.ts/.test.ts` | **conflicts / needs rework** | 7 conflicts total (measured 2026-09-19: ahead 25, behind 44). Rewires the page around the re-centre model. |
| `styles/pages.css` (+244) | **mostly conflicts** | Styles for the hover card/fullscreen/controls of the client graph. |
| `apps/web/package.json`, `pnpm-lock.yaml` | **conflicts-with-design-intent** | Adds d3-drag/force/selection/zoom (+ 4 `@types`). |

### 1.3 Verdict on "does client-side force layout contradict main's no-chart-JS rationale?"

**Yes — directly, on two independent counts.**

1. *Stack:* main's header says "no chart JS, like SankeyDiagram"; #144 adds four d3 packages and a hydration-time physics sim.
2. *Accessibility:* main's comment says the `<svg>` **must NOT** carry `role="img"` because nodes are links. #144 declares its SVG `role="img"` and routes the accessible path to the table. That re-introduces the defect main just fixed.

This is a product-direction conflict, not a merge conflict. The 44 commits of drift are the smaller cost.

### 1.4 Recommendation for #144

**Rescope to the unique parts; close the graph rewrite.** Keep (as one new, small PR off main): `counterpartyTotal` + `NetworkCounterpartyPage` contract, keyset counterparty query + tests, the `Pagination` null-count tweak, the authority-slug EIK validation, and the shared `parseCenter` — all independent of the sim. Drop `useForceGraph`, `network-layout` (unless the geometry extraction is wanted on its own), d3 deps, the `NetworkGraph.tsx` rewrite and matching CSS. If the maintainers *do* want force layout, that is a product decision to raise explicitly against main's header, not something to merge-conflict into existence. Merge-as-is is not viable.

---

## 2. #206 vs #157 (feat/productivity-tools — copy-citation)

| | #157 | #206 |
|---|---|---|
| Author | Hard-system (external contributor) | StanislavBG |
| Created | 2026-06-27T20:51Z | 2026-07-03T22:33Z (6 days later) |
| Branch / title | `feat/productivity-tools` / identical | identical |
| State | open, CONFLICTING, last updated 2026-08-11; 5 commits | open, CONFLICTING, last updated 2026-09-01; 24 commits |
| Reviews | nedda76 COMMENTED, **ydimitrof CHANGES_REQUESTED**, lyubomir-bozhinov COMMENTED | 3 unresolved ydimitrof threads, all marked non-blocking |
| Diff vs its base | 9 files, +382/-47 | 13 files, +721/-44 |

Neither exists on main (`git ls-tree origin/main`: no `citation.ts`/`CopyCitationButton.tsx`).

### 2.1 Three-way file comparison

| File | #157 | #206 | main | Category |
|---|---|---|---|---|
| `components/CopyCitationButton.tsx` | ✔ (75) | ✔ (128) | ✘ | overlap — #206 adds `execCommand` fallback, `failed` state, unmount guard, `copy-btn` class, single aria-live |
| `lib/citation.ts` | ✔ | ✔ | ✘ | overlap — #206 handles `bidder: null`, documents encoded-slug contract |
| `lib/citation.test.ts` | ✔ | ✔ | ✘ | overlap |
| `routes/authority.tsx` | ✔ | ✔ | exists | overlap |
| `routes/company.tsx` | ✔ | ✔ | exists | overlap |
| `routes/contract.tsx` | ✔ | ✔ | exists | overlap |
| **`lib/meta.ts`** | ✘ | ✔ (+4 `FALLBACK_ORIGIN`) | exists, no such const | **absent from #157** |
| **`components/CopyCitationButton.test.tsx`** | ✘ | ✔ (124) | ✘ | **absent from #157** |
| **`styles/chrome.css`** | ✘ | ✔ (`.header-actions`, `.copy-btn`, 44px touch target) | exists | **absent from #157** |
| `styles/base.css` | ✘ (#157 edits `app.css`, 71 lines) | ✔ (+49 print styles) | both exist | different file, same intent |
| `packages/db/.../details.test.ts` | ✘ | ✔ (+9, pins `contractSlug` encoding) | exists | **absent from #157** |
| `apps/web/package.json`, `pnpm-lock.yaml` | ✘ | ✔ (`@testing-library/react`) | exists | **absent from #157** (needed by the new component test) |
| `components/RiskIndicators.tsx`, `lib/riskLogic.test.ts` | ✔ | ✘ | exist | **only in #157** (#206 dropped them) |

So of #206's 13 files, 6 overlap #157, 1 (`base.css`) overlaps in purpose only, and **6 are genuinely absent from #157**: `meta.ts`, `CopyCitationButton.test.tsx`, `chrome.css`, `details.test.ts`, `package.json`, `pnpm-lock.yaml`.

### 2.2 Judgement against repo convention

`CLAUDE.local.md`: never open a duplicate PR of someone else's work without a stated reason; if a contributor already has a PR open, help *that* PR; superseded PRs get closed immediately; this is not a PR competition. #206 is a same-branch-name, same-title re-implementation of Hard-system's earlier PR, opened while #157 had unresolved reviewer feedback. No stated reason exists on either PR. Being "technically further along" is explicitly not the test.

Constraints on the alternatives: we have **pull-only** on Hard-system's fork, so we cannot push into #157's branch, and we must not force-push or recreate it. #157 has been quiet since 2026-08-11 with CHANGES_REQUESTED outstanding.

### 2.3 Recommendation for #206

**Keep-and-help-#157-adopt-the-extras**, not a blind close. Concretely: (a) approve/decide on the user side first; (b) if approved, offer #157 the six extras as a suggestion/patch (they are additive and separable — `FALLBACK_ORIGIN`, the component test, `chrome.css` touch target, the `details.test.ts` slug guard) and ask Hard-system whether they want to adopt them; (c) leave #206 open, marked as a fallback, only until #157 either adopts or goes stale, then close #206 with a pointer. Rationale: a straight close-in-favour-of-#157 discards the reviewer-driven fixes (clipboard fallback, null bidder, tests) that #157 lacks; keep-both is what the convention forbids.

If the user instead chooses **close**: the 3 unresolved ydimitrof threads on #206 (`meta.ts:12` production-domain confirmation, `CopyCitationButton.tsx:38` clipboard polyfill TypeError, `base.css:175` `break-inside` on tall tables) die with it. All three are marked non-blocking; do not queue separate work for them.

---

## 3. One-line recommendations (approve / reject)

- **#144:** Close the force-graph rewrite (contradicts main's no-chart-JS + no-`role="img"` design); rescope to one small PR with the sim-independent parts (counterparty pagination/contract/query, `Pagination` null-count, EIK slug check, shared `parseCenter`).
- **#206:** Do not close blindly — offer #157's author the six extras (`meta.ts`, component test, `chrome.css`, `details.test.ts`, deps) and close #206 once #157 adopts or goes stale; if you choose close now, its 3 non-blocking threads die with it.
