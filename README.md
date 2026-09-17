# MT5 Levels and Zones

A manual scenario panel for MetaTrader 5. Keep price levels, zones, timeframes, setup states and confirmation notes together on a chart. Enter everything yourself or import a JSON scenario.

It draws only. It does not read positions, evaluate conditions, generate signals or place orders.

![Original design reference](docs/gui-reference.png)

*Original design reference. The working panel uses native MT5 controls and includes the scenario fields described below.*

## Use

Choose a direction and status in the header. Each row has a price, optional zone endpoint, timeframe, manual state, color, visibility and lock. Entry and SL can stay empty while a scenario is waiting for confirmation.

- **SETUP** includes Entry Price, Breakout Level, Retest Zone, Rejection Zone, Support, Resistance, SL, TP 1 and TP 2.
- **OPEN_POSITION** separates the supplied open price, Bid/Ask, current SL/TP, proposed management levels and invalidation. LONG/SHORT and LASCIA/CHIUDI/DATI_INSUFFICIENTI are manual descriptions. Switching mode starts an empty draft after confirmation.
- **...** opens field settings: Level/Zone, state, line style and width, colors, label visibility and position, opacity, row order and deletion. Edit Name and TF in the row above. TP target numbers remain explicit even when rows are renamed or reordered.
- **+ Add field** offers Level, Zone, Support, Resistance, TP and Custom. Set the new row's name, type and timeframe before applying.
- **Up/Down** scrolls rows. **Move up/down** in row settings changes their saved order.
- **Activation condition** is a scrollable multiline editor with three visible lines. Its arrows move through the text and allow additional lines. Nothing in this text is executed.
- **Apply** validates, draws, saves and syncs the exact symbol. A complete BUY requires SL < Entry < TP1 < TP2; SELL requires TP2 < TP1 < Entry < SL. WAIT can have undefined prices. Reversed zones are rejected.
- **Clear all** asks for confirmation when prices exist, then clears prices, states, activation notes and the indicator's drawings. It keeps row definitions and styles.
- **Load last scenario** discards the draft and loads the last applied scenario.
- **Scenario / Import** manages provenance and imports a complete JSON scenario. See the [format and examples](docs/SCENARIO-FORMAT.md).

Under Wine, double-click a price field to edit it. Prices accept a decimal point or comma, without thousands separators. Fields marked LEVEL have their To input disabled; select ZONE in settings before entering two endpoints.

Visibility hides a drawing without erasing its price. Lock prevents chart dragging while still allowing explicit panel edits. Apply or discard a draft before dragging a line, zone edge or whole zone. Escape cancels a drag. The title bar moves the panel; `-` collapses it and `x` hides it while keeping drawings visible.

Chart labels include name, timeframe, price and state. Nearby labels share a hover tooltip; labels become compact when the panel leaves little room. Line colors and state badge colors are independent.

## Saved data and snapshots

Applied scenarios and recovery drafts are stored per exact symbol in `MQL5/Files/LevelsZones`. Changes are autosaved as a draft after editing; drawings change on Apply. A draft based on an older saved revision cannot overwrite newer applied data from another chart. The latest edited recovery draft for a symbol is shared; avoid editing competing drafts on two charts at once.

Charts with the indicator and the same exact symbol share applied scenarios across timeframes. Different pairs and broker suffixes stay separate. A `.bak` file holds the previous applied version. Version 1 saved levels are migrated on read, keeping their prices and styles; the original remains untouched until the first Apply. Keep a copy before downgrading: version 1 cannot read the new scenario format.

Changing **Latest snapshot** leaves the levels bound to their original snapshot and marks them **OLD SNAPSHOT**. Reattribution requires an explicit confirmation. Import replaces the entire draft and does not carry old prices into a new snapshot. The plugin does not automatically discover exporter snapshots.

## Install

Download the ZIP from [Releases](https://github.com/MaurizioPremici/mt5-levels-zones/releases), then copy `MQL5/Indicators/LevelsZones` into your MT5 data folder. Refresh Navigator and add **LevelsZones → LevelsZones** to each chart you want to use. Remove and reattach an already running copy after updating.

To build with the standard macOS Wine installation:

```sh
python3 build/compile.py
python3 build/install.py
```

Or open `src/LevelsZones.mq5` in MetaEditor and compile with the accompanying headers. `PanelScale` adjusts the panel size; display DPI is handled separately.

Templates must include the indicator to keep it attached. The fix for restored template objects remains in place: an old template marker cannot be mistaken for a running instance.

## Version 2.0.0

Adds manual scenarios, setup and open-position modes, timeframes and states, editable confirmation notes, JSON import, snapshot provenance, draft recovery and explicit zone validation. Existing drawing, dragging, symbol synchronization and template behavior are retained.

See [validation notes](docs/VALIDATION.md) for actual checks and remaining limitations. The original GUI source is in `reference`.
