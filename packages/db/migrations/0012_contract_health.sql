-- Health-index foundation: add the nine columns required by the Contract Quality / Health Index
-- spec (§7.1). Columns added after a table's creating migration live ONLY here — they are
-- intentionally NOT folded into 0000_init.sql, because SQLite has no ADD COLUMN IF NOT EXISTS and
-- `wrangler d1 migrations apply` on a fresh D1 runs the whole chain (0000 then 0012 would hit
-- "duplicate column"). The work-DB backfill (scripts/import.mjs) applies the full migration chain
-- for the same reason. The health rollup tables need no ALTERs here: they ship in 0000_init.sql
-- for fresh DBs and are (re)created idempotently by the ETL derives (scripts/derive-health.sql,
-- scripts/derive-contract-features.sql) on already-migrated DBs.
-- Numbered 0012 to leave 0011 to `0011_contracts_overrun_index` (PRs #169/#170/#171/#172/#193).
-- Ordering assumption: `wrangler d1 migrations apply` runs migrations in filename order, so if
-- 0011_contracts_overrun_index lands after this file is already applied, it will run AFTER 0012 on
-- any DB that already has 0012. These nine ALTERs are purely additive (new nullable columns on
-- existing tables) and read no state introduced by 0011, so applying out of numeric order is safe
-- here — but any FUTURE 0011 migration that these columns/tables depend on would break that
-- assumption and must be re-numbered above 0012 instead.

ALTER TABLE contracts  ADD COLUMN exemption_legal_basis TEXT;
ALTER TABLE contracts  ADD COLUMN outside_zop           INTEGER;
ALTER TABLE contracts  ADD COLUMN dps_contract          INTEGER;
ALTER TABLE amendments ADD COLUMN reason                TEXT;
ALTER TABLE amendments ADD COLUMN circumstances         TEXT;
ALTER TABLE tenders    ADD COLUMN corrections_count     INTEGER;
ALTER TABLE tenders    ADD COLUMN estimated_value_eur   REAL;
ALTER TABLE flow_pairs ADD COLUMN first_date            TEXT;
ALTER TABLE flow_pairs ADD COLUMN last_date             TEXT;
