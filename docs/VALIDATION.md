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
