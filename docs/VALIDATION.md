# Validation notes

September 17, 2026.

## Checked

- The current indicator builds with MetaEditor under Wine: **0 errors, 0 warnings**.
- The compiled indicator and its source files are installed in MT5.
- The panel opens on a chart. Panel and label sizing were corrected for Retina displays.
- A single entered price draws a horizontal line.
- Two entered prices draw a filled horizontal zone.
- Applied values remain available after switching between H4 and H1.
- Production source contains no order, position, account, network, or DLL import calls.

## Still to check

The owner will continue manual testing. Clipboard replacement under Wine, dragging and locking, appearance controls, custom fields, separate-chart synchronization, symbol isolation, and a full terminal restart have not all been verified interactively.

`tests/LevelTests.mq5` compiles without errors or warnings. No execution report was obtained, so these automated tests are **not recorded as passed**.

The repository image is a design reference, not a screenshot of the running indicator. Test prices are examples only and are not included in the default saved state or release package.

## Version 1.0.1

- Translated all built-in interface text, tooltips, status messages, and validation errors into English. Existing user-defined names are preserved.
- Removed chart-wide object enumeration and synchronous coordinate reads from the panel drag loop. Control positions are cached when the panel is built.
- Limited panel movement updates to one per 33 ms, with an unconditional final update on release. Escape restores the panel position from the start of the drag.
- Avoided reading unchanged panel inputs during the saved-state polling loop.
- Compiled with 0 errors and 0 warnings and installed the new EX5.

The English panel was opened and expanded in MT5 under Wine. A short drag moved the complete panel to the requested position while preserving the displayed values. No frame-rate benchmark was run; the owner will check how it feels in normal use.


## Clear all update, 2026-09-17

Version 1.0.2 compiled with zero errors and zero warnings and installed; source/binary hashes match the installed files. Reviewed the save-before-redraw path, optimistic revision protection, exact-symbol notification, and clearing of both line and zone endpoints while preserving row metadata. Click events are now scoped to this panel. The Clear all button has not been clicked on the user's saved levels; the user was testing Snapshot during this update.

## Template reload fix, 2026-09-17 — version 1.0.3

The user's template included the LevelsZones indicator and a serialized LZ_INSTANCE object. Version 1.0.2 mistook that stale object for an active instance and failed initialization. The error was reproduced in a dedicated temporary chart using the old compiled indicator.

The repaired build uses an atomic session-only chart lock and discards restored objects owned by this tool before rebuilding from saved symbol data. A rejected duplicate does not clean up the active instance.

Executed TemplateTests in MT5 under Wine: 15 checks passed, zero failed. Covered old-build reproduction, repaired startup, preservation of an unrelated object, repeated template application, timeframe change, duplicate rejection, removal by a template without the indicator, lock release and loading again. The harness waits for asynchronous indicator initialization rather than assuming it has finished after a fixed short delay.

Main indicator and test script compiled with zero errors and zero warnings. Existing saved level files were checked before and after the run and were unchanged. No trading action was performed. Templates without the indicator still remove it normally.
