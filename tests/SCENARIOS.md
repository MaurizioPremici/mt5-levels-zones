# Scenario acceptance checks

These tests create and use `__LZ_QA_SCENARIO`, a custom symbol with synthetic candles and trading disabled. No live symbol data or account APIs are used. Run in a test terminal with no trading program in its default template; creating a chart may apply that terminal's default template.

For the standard macOS Wine installation:

```sh
python3 build/compile.py
python3 build/install.py
python3 build/compile.py tests/ScenarioTests.mq5
python3 build/compile.py tests/ScenarioLauncher.mq5
python3 build/compile.py tests/ScenarioSmoke.mq5
python3 build/prepare_qa.py
python3 build/verify_no_trading.py
```

Refresh MT5 Navigator, run `Scripts/LevelsZones_QA/ScenarioLauncher`, and wait for the result shown in the test panel. The indicator fixture includes the production source and invokes the real button/edit event handlers. It checks the six requested acceptance cases, invalid imports, persistence, obsolete-draft removal, semantic TP validation and legacy-store migration. It also runs the existing core suite.

Then run `ScenarioSmoke`. It loads the installed production indicator on a separate synthetic chart, reapplies its template, changes timeframe and verifies that one active instance remains. It may close the launcher chart if that chart is the synthetic test symbol. It does not close normal charts.

Reports are written in the terminal Common Files folder:

- `LZ_core_test_results.txt`
- `LZ_scenario_test_results.txt`
- `LZ_smoke_test_results.txt`

The integration test's chart images are under `MQL5/Files/LevelsZones/qa-*.png`. They contain only the synthetic chart. Actual mouse interaction remains a separate check; handler-based tests do not prove every aspect of macOS/Wine clipboard or focus behavior.

Remove the QA charts and test indicator/script binaries after testing. Never treat the example scenarios or synthetic candles as market analysis.
