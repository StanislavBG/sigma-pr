# Spine merge на #169 / #170 / #171 (2026-09)

> Запис на резолюциите, с които `origin/main` беше влят в трите dashboard PR-а. Следващите PR-и
> (#172/#193, #188) копират тези решения, вместо да измислят втори вариант на същите hunk-ове.

## Състояние (измерено на 2026-09-19)

`origin/main` = `157f5ede90650b2edbdd498ae44ff7f47e36ae61` — предшественик на и трите клона.

| Клон | PR | Head (= `fork/<клон>`) | Merge commit | CONFLICT в merge-tree | Отворени нишки (outdated) |
| --- | --- | --- | --- | --- | --- |
| `pr/dash-base` | #169 | `68618575` | `68618575` | 0 | 2 (0) |
| `pr/trends` | #170 | `ed0c5061` | `d9e6f81e` | 0 | 4 (0) |
| `pr/overruns` | #171 | `d6e1b91a` | `739c074a` | 0 | 5 (1) |

`ed0c5061` и `d6e1b91a` са post-merge поправки върху съответните merge commit-и. Локалните
глави са идентични с `fork/<клон>` и с head OID на GitHub PR-ите.

## Номериране на миграциите (за целия fleet)

- `main` държи `0000`–`0022`. **`0011` и `0012` вече не са свободни.**
- `0023_contracts_overrun_index.sql` — на #169, #170, #171, #172 и #193; байт-идентичен файл,
  sha256 `6519fc60064c18f39de75035a3caff32a5c093a4d237e4be6c789e9489998e9d` (потвърдено на трите
  клона). Старият `0011_contracts_overrun_index.sql` не съществува в нито един от тях.
- `0024_contract_health.sql` — резервиран за #188.

## Политика за `coverage-baseline.json`

Всеки dashboard клон взема `coverage-baseline.json` от `origin/main` **изцяло** (байт-идентичен на
трите клона). Старите ~74–91% числа на PR-ите се изхвърлят. Покриването на реалния праг е задача
на PRD 808; **сваляне на прага никога не е опция.**

Към момента на измерването CI на #170 и #171 пада само на стъпката `Coverage ratchet` (job
`check`); `test`, `cacbg` и `semgrep` са зелени. #169 е изцяло зелен. Това е очаквано и е извън
обхвата на този merge (PRD 808).

## Споделени резолюции на hunk-ове (копират се, не се извеждат наново)

- `query-params.ts` и `pages.css` — запазват се и двете страни.
- `TrendChart.tsx` — взима се `cached(1800)` и `compact` от main; granularity на `TrendBlock` е
  разширена до `TrendGranularity`.
- #170 реекспортира `INTENTIONALLY_UNKEYED` и взима `--font-mono` на main за `.source`.
- Изтриването на `owner-card` CSS от main остава.
- Непрочетеният `g` query param остава извън #171.
- `pnpm-lock.yaml` никога не се решава на ръка: `git checkout` на копието от main, после
  `pnpm install --lockfile-only`.
- #169 приема catalog/Node 24 тулчейна на main; `apps/web/package.json` се различава от main само
  с добавения `@testing-library/react`.

## Твърди ограничения за останалите PR-и

- **Никакъв force-push и никакъв `git rebase`** — 36 живи ревю нишки на `ydimitrof` биха се
  пре-анкерирали и осиротели. Винаги `git merge origin/main`.

## Единствено отворено предаване

Нишката на #171 върху `coverage-baseline.json` (ред 9; оплакване, че PR-ът сваля `apps/web`
lines 91 → 85.3 / branches 82.4 → 73.3) е вече `isOutdated=true`. Осиротяла е, защото baseline-ът
на main е взет изцяло; оплакването е удовлетворено по конструкция. Изисква отговор + resolve от
PRD `810-d1-threads-dashboard-spine`. Тази нишка не е пипана; общо остават 11 неразрешени
(2/4/5).

## Бележка за scheduler-а

PRD-и с deliverable върху head клон на PR (а не върху job клона) трябва да произвеждат и артефакт
върху собствения job клон, иначе commit guard-ът ги паркира в `needs_review`, колкото и зелена да е
работата.

## Пренастройка на средата и повторна проверка (2026-09-19)

Причина за `worktree_integration_failed`: споделеният клон `/home/bilko/Projects/sigma` беше на
`chore/gh-review-reply-helper`, а не на `main`. Поправено без загуба на данни:

- `sigma-main-edit` (чист, `3dddfb3a`) — `git switch --detach`, за да освободи `main`; worktree-ът е запазен.
- Основният клон — `git switch main` (двата chore комита са вече във `fork`), после локален
  `git merge origin/main` (без rebase, без push). Чуждите `.claude/settings.json` и `<path>` са недокоснати.
- Job клонът е нулиран върху `main`, за да не носи chore комитите; `813a1f2f` е cherry-pick-нат.

Измерено отново (само четене): и трите клона — 0 конфликта срещу `origin/main`; локален head == `fork/<клон>`
(`68618575` / `ed0c5061` / `d6e1b91a`); миграцията `0023_contracts_overrun_index.sql` е с еднакъв sha256
`6519fc60…998e9d`; `coverage-baseline.json` == main на трите; неразрешени нишки 2 / 4 / 5, единствената
`isOutdated` е на #171 (`coverage-baseline.json`). CI на #170/#171 пада само на `Coverage ratchet` —
собственост на PRD `808`, не е пипано.

## Spine merge на #172 / #193 (2026-09-20)

`origin/main` (`157f5ede`) влят с `git merge` (без rebase, без force-push) в двата клона; push към `fork`
беше fast-forward.

| Клон | PR | Стар head | Нов head (merge) | CONFLICT в merge-tree | Неразрешени нишки (outdated) |
| --- | --- | --- | --- | --- | --- |
| `pr/analyze` | #172 | `49a4f1ea` | `ffbca457` | 0 | 6 (0) |
| `docs/methodology-dashboards` | #193 | `f39ab996` | `c600b67d` | 0 | 6 (0) |

Забележка: локалният `docs/methodology-dashboards` (`00272bdc`) е разклонен от `fork/…` (head на PR-а,
`f39ab996`); merge-ът е върху `fork/…`, локалният клон не е пипан.

- Миграцията е `0023_contracts_overrun_index.sql`, sha256 `6519fc60…998e9d` — идентична с #169/#170/#171.
  `migrations.test.ts` сочи към новото име. `coverage-baseline.json` == `origin/main` на двата клона.
- Приложени са същите резолюции: `query-params.ts`/`pages.css` — и двете страни; `cached(1800)` от main
  (в `trends.tsx` и `analytics.tsx`); `TrendChart` с `compact` от main + `TrendGranularity`; `TrendBlock`
  е байт-идентичен с #170. Четирите `packages/db` теста: harness-ът `fakeD1` остава, добавени са и
  main-овите нови тестове (без ръчно писани fake-D1).
- Намерено при merge-а: `git merge` на `pages.css` оставя непълен `@media` блок; правилният резултат е
  3-way (`git merge-file --diff3`) с обединение на двата добавени блока. Ако #172/#193 се мърджат отново —
  проверявай `prettier --check`.
- Умишлени разлики между петте клона: `query-params.ts`, `trends.tsx`, `cache-key.test.ts`, `pages.css` носят
  различно PR-специфично съдържание (#172/#193 са независими от #170: имат `RESERVED_CACHE_PARAMS`, не
  `PLANNED_QUERY_PARAMS`). `TrendChart.tsx` на #172 е идентичен с #170 (`yearAxisTicks`); на #193 е със
  същата логика inline (без `trendAxis.ts`).
- Проверки и на двата клона: `typecheck` и `lint` минават; `packages/db` тестове 824 / 826 минават,
  `apps/web` тестове 935 / 992 минават. Coverage ratchet не е пускан — PRD 808.
