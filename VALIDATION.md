
## Clear all update, 2026-09-17

Version 1.0.2 compiled with zero errors and zero warnings and installed; source/binary hashes match the installed files. Reviewed the save-before-redraw path, optimistic revision protection, exact-symbol notification, and clearing of both line and zone endpoints while preserving row metadata. Click events are now scoped to this panel. The Clear all button has not been clicked on the user's saved levels; the user was testing Snapshot during this update.

## Template reload fix, 2026-09-17 — version 1.0.3

The user's template included the LevelsZones indicator and a serialized LZ_INSTANCE object. Version 1.0.2 mistook that stale object for an active instance and failed initialization. The error was reproduced in a dedicated temporary chart using the old compiled indicator.

The repaired build uses an atomic session-only chart lock and discards restored objects owned by this tool before rebuilding from saved symbol data. A rejected duplicate does not clean up the active instance.

Executed TemplateTests in MT5 under Wine: 15 checks passed, zero failed. Covered old-build reproduction, repaired startup, preservation of an unrelated object, repeated template application, timeframe change, duplicate rejection, removal by a template without the indicator, lock release and loading again. The harness waits for asynchronous indicator initialization rather than assuming it has finished after a fixed short delay.

Main indicator and test script compiled with zero errors and zero warnings. Existing saved level files were checked before and after the run and were unchanged. No trading action was performed. Templates without the indicator still remove it normally.
