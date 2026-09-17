# Validation — version 2.0.0

Tested on September 17, 2026, in MetaTrader 5 on macOS through Wine.

## Completed checks

- Production indicator, scenario fixture, launcher and reload script compiled with **0 errors and 0 warnings**.
- Core price and storage suite executed: **24 passed, 0 failed**. Includes strict price parsing, exact symbol isolation, persistent round trips, revision conflicts, backups and corrupt-file protection.
- Scenario integration suite executed: **31 passed, 0 failed**, using the actual production event handlers, store, panel and renderer on a synthetic, non-tradable symbol. Covers all six requested acceptance cases: WAIT → SELL without Entry/SL; manual confirmation without price changes; open-position current/proposed levels; snapshot A/B provenance and full replacement; reversed-zone rejection; Apply/Clear/Reload/state operations.
- Additional integration checks cover draft recovery, visibility without deletion, unlocked chart hit testing, preserving zone endpoints during type changes, invalid JSON types/duplicate keys, symbol mismatch, BUY/SELL level ordering, legacy v1 migration and UTF-8 file import.
- Installed production build passed **5 reload checks**: initial load, template reapplication, timeframe change and return, and a single active instance.
- Actual mouse checks: dragged the whole panel, collapsed and expanded it, hid and reopened it. The chart drawings remained visible. No frame-rate benchmark was performed.
- Production source audit found no order/position APIs, trading library or DLL imports. The test buttons ran only on the synthetic chart. No trading action was performed or requested by the code.

The earlier template bug remains fixed. Version 1.0.3 had separately passed 15 template checks, including reproduction with the old build, stale marker cleanup, duplicate rejection and preservation of an unrelated object. Version 2.0.0's reload checks are recorded separately above.

## Limits

The integration tests invoke MT5 event handlers programmatically; they do not simulate every mouse click or clipboard operation. A full terminal restart and an exhaustive clipboard/focus test across Wine versions were not performed. Draft round trips and template/timeframe restarts were tested.

State changes, conditions, Bid/Ask and position-management values are manual or imported. The plugin does not evaluate conditions, read account positions or automatically discover a newer exporter snapshot. A supplied timestamp is retained as text.

The activation editor shows three editable lines at a time with scrolling. On a small chart, use PanelScale, row scrolling or collapse the panel. Competing unapplied edits on multiple charts share one recovery draft per exact symbol; the most recently edited recovery draft wins, while committed data remains protected by revision checks.

Test instructions are in [tests/SCENARIOS.md](tests/SCENARIOS.md). Only synthetic results and examples belong in the repository; personal stores and exported market/account files are excluded.
