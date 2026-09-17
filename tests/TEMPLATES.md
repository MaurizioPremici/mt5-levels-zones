# Template regression check

`TemplateTests.mq5` is a manual MT5 regression script. It creates its own chart and never writes level prices or calls trading functions. Run it on a chart without another script attached. Use a clean default template without an Expert Advisor or script; the test also checks the newly opened chart.

The check uses four local fixtures in `MQL5/Profiles/Templates`. Prepare them from a chart template containing only the main chart and LevelsZones, with no expert or script:

- `LZLegacy.tpl`: use the current indicator path, add a hidden label named `LZ_INSTANCE`, a label named `LZ_UI_STALE`, and an unrelated label named `LZ_TEST_USER_OBJECT`.
- `LZLegacyOld.tpl`: the same fixture, but point the custom indicator at `Indicators\LevelsZones_QA\Legacy.ex5`. Copy the compiled 1.0.2 indicator from its release ZIP to that path.
- `LZDuplicate.tpl`: the repaired fixture with the LevelsZones indicator section repeated twice.
- `LZClean.tpl`: the same chart appearance, with the custom indicator and test objects removed.

These fixture names must be reserved for the test. The user's original template is not modified. The executed local check used copies of the reported template; those personal template files are not published.

Compile with `python3 build/compile.py tests/TemplateTests.mq5`, copy the resulting script to `MQL5/Scripts/LevelsZones_QA`, refresh Navigator, and run it. Results are written to the terminal's common Files directory as `LZ_template_test_results.txt`. The script closes its chart on success and leaves it available for inspection on failure. Close that test chart before running it again.

The check covers legacy failure, repaired startup, unrelated-object preservation, repeated template loading, timeframe changes, duplicate-instance rejection, runtime-lock release and loading after removal. Remove the local fixtures and legacy test binary when finished.
