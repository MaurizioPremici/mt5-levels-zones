# MT5 Levels and Zones

A chart panel for drawing horizontal lines and price zones in MetaTrader 5. Enter a price, give it a name, and choose how it looks. Built for manual chart marking, with an Italian interface.

It draws only. It does not place orders, read positions, or generate trading signals.

![Original design reference](docs/gui-reference.png)

*This image is the original design reference. The working panel uses native MT5 controls and starts with empty price fields.*

## What it does

- Includes Entry Price, Breakout Price, Retest Price, Rejection Price, Support, Resistance, SL, TP 1, and TP 2.
- Lets you rename fields and add your own.
- Draws a horizontal line for one price, or a filled zone for two prices.
- Offers line and fill colors, HEX input, solid or dashed lines, thickness, and transparency.
- Extends zones across the chart, including older candles.
- Shows names and prices on the left. Nearby labels are grouped, with details available on hover.
- Supports dragging lines, zone edges, or the whole zone. A lock prevents accidental moves.
- Saves when you click Apply or finish a drag.
- Keeps levels when you change timeframe. Charts with the same exact symbol share saved levels when the indicator is attached to each chart in the same terminal. Different symbols stay separate.

## Install

Download the ZIP from [Releases](https://github.com/MaurizioPremici/mt5-levels-zones/releases), then copy its `MQL5/Indicators/LevelsZones` folder into your MT5 data folder. You can find that folder from **File → Open Data Folder** in MT5.

Refresh the Navigator, then add **Indicators → LevelsZones → LevelsZones** to your chart. Add it to each chart you want to use.

To build from source, copy the files in `src` into `MQL5/Indicators/LevelsZones`, open `LevelsZones.mq5` in MetaEditor, and press **F7**. The indicator uses the standard libraries included with MT5.

For the standard MT5 Wine installation on macOS:

```sh
python3 build/compile.py
python3 build/install.py
```

You can pass a different MT5 data folder with `python3 build/install.py --data-dir PATH`.

## Use

Enter a price in **Prezzo / Da**. Leave **A** empty for a line, or enter the other end of the range for a zone. Click **Applica** to draw and save. Changes in the panel remain a draft until you apply them.

Under Wine, double-click a price field to edit it. Check the full value after pasting. Use a decimal point or comma, without thousands separators. Invalid text and prices with too many decimal places are rejected.

- **...** opens appearance settings.
- **ON/OFF** shows or hides a level.
- **L/U** locks or unlocks movement. Apply the change before dragging.
- **+ Aggiungi campo** adds a custom field.
- **Su/Giu** scrolls through the rows.
- **Ricarica** discards the draft and loads the last saved values.
- **x** hides the panel while keeping the drawings visible.

For a zone, drag either edge to resize it or the middle handle to move the whole range. Press Escape to cancel a drag. Apply or discard any draft before moving a drawing.

Transparency runs from 0% (opaque) to 100% (invisible). The default is 80%. `PanelScale` adjusts the panel size; display DPI is handled separately for Retina screens.

## Saved data

Levels are stored locally in `MQL5/Files/LevelsZones`. A `.bak` file keeps the previous saved version. If two charts edit the same symbol, an older draft cannot overwrite a newer save without reloading first.

Removing the indicator removes its drawings from that chart. Saved levels remain available when you add it again. The indicator supports up to 128 fields per symbol. It does not manage labels or objects created by other indicators.

## Current status

Compiled with **0 errors and 0 warnings**. Basic line drawing, zone drawing, and saved values across H4/H1 changes were checked in MT5 on macOS through Wine. Panel and label sizing were adjusted for Retina displays.

This is an initial release. Full manual testing is still in progress, including clipboard editing under Wine, dragging, and synchronization between separate charts. See [validation notes](docs/VALIDATION.md) for the checks completed so far.

The original GUI code is kept in `reference`, and the supplied design image is in `docs/gui-reference.png`.
