# Scenario import format

Use **Scenario / Import** to enter a relative UTF-8 JSON path inside `MQL5/Files`. The default is `LevelsZones/scenario.json`. Click Import, confirm replacement, review the draft, then Apply. Import validates the entire file before changing the draft. It must match the exact chart symbol, including any broker suffix.

Start from [wait-sell.json](examples/wait-sell.json) or [open-position.json](examples/open-position.json). These contain fictional example scenarios, not recommendations or current market data. Change the symbol and provenance to match your actual input.

Every import is a **complete replacement**. Missing rows are removed, and omitted/null prices stay undefined. The importer does not merge old Entry or SL values into a new snapshot. The file can be at most 128 KiB and contain up to 128 fields. Duplicate keys, duplicate IDs, unknown keys, invalid types and unsupported schema versions are rejected.

## Scenario

| Key | Meaning |
| --- | --- |
| `schema_version` | `1` (optional; defaults to 1) |
| `symbol` | Required exact chart symbol |
| `snapshot_id` | Required string identifying the source snapshot; empty is allowed for unassigned manual data |
| `source` | Description such as `Codex`, `Manual` or `Imported` |
| `generated_at` | Source timestamp as supplied, preferably ISO 8601 with timezone; never invented by the plugin |
| `mode` | `SETUP` or `OPEN_POSITION` |
| `direction` | SETUP: `BUY`, `SELL`, `WAIT`, `WAIT -> BUY`, `WAIT -> SELL`; OPEN_POSITION: `LONG`, `SHORT` |
| `decision` | `LASCIA`, `CHIUDI`, `DATI_INSUFFICIENTI`; descriptive only |
| `trigger_tf` | A timeframe or combination such as `M5/M15` |
| `overall_status` | One of the manual states below |
| `activation_condition` | Multiline description, at most 8192 characters; JSON uses `\n` for line breaks |
| `fields` | Required complete array of field objects; an empty array is allowed |

## Field

Required keys: `name`, `semantic_type`, `value_type`. Set a unique positive integer `id` to preserve an explicit identity; otherwise IDs start at 10 in file order.

- `semantic_type`: `ENTRY`, `BREAKOUT`, `RETEST`, `REJECTION`, `SUPPORT`, `RESISTANCE`, `SL`, `TP`, `CUSTOM`. Position mode also supports `OPEN_PRICE`, `CURRENT_BID`, `CURRENT_ASK`, `SL_CURRENT`, `SL_MANAGEMENT`, `TP_CURRENT`, `TP1_MANAGEMENT`, `TP2_MANAGEMENT`, `INVALIDATION`.
- `value_type`: `LEVEL` or `ZONE`. A LEVEL must have no To price. A ZONE requires both endpoints or both empty, with From ≤ To.
- `from_price`, `to_price`: decimal strings (recommended), JSON numbers without exponent notation, or `null`. Values must be positive and fit the chart symbol's decimal precision.
- `target_index`: required for `TP` fields. `1` and `2` identify the primary targets for BUY/SELL validation, regardless of name, row order or ID. Other targets use unique numbers up to 128.
- `timeframe`: blank or standard MT5 timeframe(s), separated by `/`.
- `state`: any manual state below; default `INACTIVE`.
- `color`, `fill_color`: `#RRGGBB`. Set both for consistent zone styling. Import defaults are gold.
- `line_width`: integer 1–5; `dashed`: boolean.
- `fill_opacity`, `border_opacity`: integers 0–100, where 100 is opaque. Defaults: 20 and 100.
- `visible`, `locked`, `show_label`: booleans, default true.
- `label_position`: `LEFT` (default) or `RIGHT`.

There can be only one primary ENTRY and SL, and each TP target number must be unique. Use CUSTOM for alternative levels. Multiple Support, Resistance, Retest and other contextual fields are allowed.

## Manual states

`INACTIVE`, `WAITING`, `WAITING_BREAKOUT`, `BREAKOUT_CONFIRMED`, `WAITING_RETEST`, `RETEST_TOUCHED`, `RETEST_CONFIRMED`, `WAITING_REJECTION`, `REJECTION_CONFIRMED`, `ENTRY_READY`, `ACTIVE`, `FAILED`, `INVALIDATED`, `EXPIRED`, `UNDEFINED`, `CANDIDATE`, `READY`, `FILLED`, `CONDITIONAL`.

No state is inferred from price movement. Conditions and decisions are stored text, not executable rules.

## Provenance

The scenario keeps the snapshot to which its levels belong separately from the latest known snapshot. Editing **Latest snapshot** alone marks retained prices **OLD SNAPSHOT**. **Use for these levels** explicitly reattributes them after confirmation. A validated full import replaces all fields and binds them to the imported snapshot. The indicator does not watch exporter folders or claim to discover newer snapshots on its own.
