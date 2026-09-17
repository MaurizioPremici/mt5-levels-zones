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
