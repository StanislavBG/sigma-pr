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
