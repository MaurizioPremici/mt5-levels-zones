#!/usr/bin/env python3
"""Install only this indicator's files into a MetaTrader 5 data directory."""
from pathlib import Path
import argparse, shutil
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--data-dir',type=Path,default=Path.home()/'Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5')
args=parser.parse_args()
if not (args.data_dir/'MQL5').is_dir(): parser.error('MQL5 not found; select the MT5 data directory')
source=root/'src'
if not (source/'LevelsZones.ex5').is_file(): parser.error('Compile LevelsZones.mq5 first')
dest=args.data_dir/'MQL5/Indicators/LevelsZones';dest.mkdir(parents=True,exist_ok=True)
for name in ['LevelsZones.mq5','LevelsZones.ex5','LevelModel.mqh','LevelStore.mqh','LevelRenderer.mqh','LevelPanel.mqh','ScenarioImport.mqh']:
    shutil.copy2(source/name,dest/name)
print('Installed:',dest)
