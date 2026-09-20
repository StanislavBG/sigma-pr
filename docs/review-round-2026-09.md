# Review round 2026-09 — готовност за merge на целия fleet

> Измерено на 2026-09-20 (PDT) срещу `origin/main` = `157f5ede`. Числата са от живи измервания
> (`git merge-tree --write-tree origin/main <глава>`, GraphQL `reviewThreads`, `gh pr checks <n>`),
> не са преписани от PRD-та или доклади. Нищо не е merge-нато; никой рецензент не е пингван.

## Резюме по PR

| PR | Клон | Конфликт срещу `main` | Неразрешени нишки | CI | Merge-ready |
| --- | --- | --- | --- | --- | --- |
| #169 | `pr/dash-base` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — първи |
| #170 | `pr/trends` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — след #169 (виж „Поредност") |
| #171 | `pr/overruns` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — след #170 |
| #172 | `pr/analyze` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — след #171 |
| #193 | `docs/methodology-dashboards` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — след #172 (описва таблата) |
| #188 | `feat/contract-health-index` | няма | 0 (6 → 0 в този кръг) | зелен на `09f08c22` (4 pass, 1 skipping) | **да**, технически — след spine-а (GitHub: `BLOCKED` = чака одобрение) |
| #338 | `chore/gh-review-reply-helper` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — независим |
| #269 | `fix/search-ranking-exact-vs-blob-25` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — независим |
| #141 | `feat/map-info-card` | няма | 0 | зелен (4 pass, 1 skipping) | **да** — независим, но виж „Поредност" (`pages.css`) |
| #206 | `feat/productivity-tools` | **6 файла**: `authority.tsx`, `company.tsx`, `contract.tsx`, `apps/web/package.json`, `details.test.ts`, `pnpm-lock.yaml` | 3 (всички non-blocking) | зелен (4 pass, 1 skipping) | **не** |
| #144 | `feat/network-force-layout` | **7 файла**: `NetworkGraph.tsx`, `NetworkGraph.test.tsx`, `entity-tables.tsx`, `network.tsx`, `apps/web/package.json`, `network.test.ts`, `pnpm-lock.yaml` | 1 | зелен (4 pass, 1 skipping) | **не** |

„Merge-ready" е само техническо (без конфликт, нишките резолвнати, CI зелен). Одобрение от
рецензент не е искано и не е отчетено тук; `reviewDecision` е празно на всички.

## Препоръчана поредност

Никой dashboard клон не съдържа друг като предшественик; всички са чисти спрямо `main` поотделно,
но **не и натрупани**: симулирано последователно вливане (`merge-tree` върху вече влетите) дава
конфликти във `MetricInfo.tsx`, `query-params.ts`, `components.css`, `pages.css`,
`cache-key*.ts` и `migrations.test.ts`, щом #169 е влян, защото всеки клон носи собствено копие
на същата основа. Затова след всеки merge следващият клон има нужда от пресен `main` в себе си
(нов merge, не rebase — виж `docs/review-spine-merge-2026-09.md` за резолюциите).

1. **#169** (design-system основа) — от нея зависят останалите.
2. **#170**, 3. **#171**, 4. **#172** — по ред; всеки след merge на предишния + влят `main`.
5. **#193** — методологията описва таблата, влива се след тях.
6. **#188** — индексът на качеството; засяга същите файлове (`MetricInfo`, `query-params`, CSS),
   затова след spine-а и с пресен `main`. Мигрaция `0024` е резервирана за него, `0023` — за spine-а.
7. **#338**, **#269** — независими, чисти и натрупани; могат по всяко време.
8. **#141** — конфликтува в `pages.css` с натрупания spine, така че след него (или преди — тогава
   spine клоновете го поемат в следващия си merge на `main`).
9. **#206**, **#144** — не се вливат (виж по-долу).

## #206 и #144 (вердикт от PRD 804, `docs/review-supersession-2026-09.md`)

- **#144** — затваря се пренаписването на графа (противоречи на „без chart JS" и „без
  `role="img"`" на `main`); rescope към един малък PR с частите, независими от симулацията.
  Още и конфликт в 7 файла.
- **#206** — да не се затваря сляпо: да се предложат допълненията на #157 и #206 да се затвори,
  когато #157 ги приеме или остарее. Конфликт в 6 файла; 3-те нишки са non-blocking.

## Нишки по #188 (6 → 0)

| Нишка | Резултат |
| --- | --- |
| `etl.ts` — `/no such table/i` поглъща грешно изписана таблица | Вече поправено от B3: `isMissingDerivedTableError` хваща името на таблицата и я сравнява с `contract_features`. Тестове в `etl.test.ts` (очакваната таблица и друга/грешно изписана) и `quality.loader.test.ts` (поглъща се само липсващата `contract_features`, `contract_featurez` се хвърля). Без промяна на кода. |
| `query-params.ts` — изгубен `g` | Вече поправено (`c2ba8e78`, `trendStep` във `trends.tsx`): при липсващ `step` се пада към `g`; `step` печели; генерираните линкове се канонизират. Същият механизъм като на #170 — не е втори вариант. |
| `quality.tsx:171` — непроверени `sel`/`contract`/`band` | Поправено в този кръг: `qualityScopeControls` във `lib/filters.ts` — `band` срещу фиксирания набор (`weak`/`mid`/`good`/`0`–`19`), `sel`/`contract` срещу форма на непрозрачен ключ (≤ 80 знака, без кавички, разделители и `..`); иначе `null`. Тестове за враждебна стойност във `filters.test.ts` и `quality.loader.test.ts`. |
| `coverage-baseline.json` — спад | Вече поправено: базата е байт-идентична с `main` (99.4 / 96), а C2 (`61f129fb`) добавя тестове за `/quality` loader-а, render вариантите и заявките. Локално (`vitest --coverage`, `apps/web`): линии 99.17 %, клонове 96.28 % — в допуска 0.5. |
| `0024_contract_health.sql` — ALTER-ите не стигат до production | Виж по-долу. |
| `docs/security-advisories.md` — обхват на игнорирането | Игнорирането вече не съществува: #339 (`75268c7`) изтри записа за GHSA-qwww-vcr4-c8h2, защото react-router 7.18.2 вече не съвпада с advisory-то. `osv-scanner.toml` съдържа само заглавен коментар; документът е поправен да го казва. |

## 0024 на served D1

**Твърдението „served D1 не чете тези колони" е невярно.** Прочетено в кода:

- `scripts/ship-domain.mjs` копира *всяка* колона на изходната работна база в `contracts`,
  `tenders`, `amendments`, `flow_pairs` на served D1; работната база получава цялата верига
  миграции (`scripts/import.mjs`), т.е. включва деветте колони.
- `scripts/precompute.sql` (пуска се на served D1) прави `UPDATE tenders SET estimated_value_eur`.
- `scripts/derive-contract-features.sql` (пуска се на served D1 през `ship-domain.mjs`) чете
  `c.exemption_legal_basis`, `c.outside_zop`, `c.dps_contract` и `t.estimated_value_eur`.
- `flow_pairs.first_date`/`last_date` се създават наново от `precompute.sql` (DROP + CREATE), така
  че те не зависят от ALTER-а.
- Уеб заявките не четат колоните директно (`corrections_count` е от `contract_features`).

Следователно без ALTER-ите първият ship/derive след merge би се провалил с „no such column".
Ledger-ът на миграциите на production е празен (базата е създадена извън wrangler), затова
`migrations apply` не е път за тези колони. **Решение:** нова стъпка „Ensure contract-health
columns exist" в `.github/workflows/deploy.yml` — за всяка от деветте колони проверява
`pragma_table_info` и прави `ALTER TABLE … ADD COLUMN` само ако липсва (идемпотентно, същата
идея като `ensure_column` за registry колоните). Коментарът в миграцията е обновен да сочи тук.

Ограничение: стъпката не е изпълнявана срещу production D1 в този кръг — първото ѝ реално
изпълнение е при deploy след merge на #188; YAML-ът е валиден и логиката е проверена само чрез
четене.
