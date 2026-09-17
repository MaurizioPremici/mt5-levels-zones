#!/usr/bin/env python3
"""Install compiled QA fixtures without changing normal charts or saved scenarios."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
mt = Path.home() / 'Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5'
for name, folder in [('ScenarioTests', 'Indicators'), ('ScenarioLauncher', 'Scripts'), ('ScenarioSmoke', 'Scripts')]:
    src = root / 'tests' / f'{name}.ex5'
    if not src.is_file():
        raise SystemExit(f'Compile {src.name} first')
    dest = mt / 'MQL5' / folder / 'LevelsZones_QA'
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest / src.name)
text = (root / 'tests/ScenarioQA.tpl').read_text()
templates = mt / 'MQL5/Profiles/Templates'
(templates / 'LZScenarioQA.tpl').write_bytes(text.replace('\n', '\r\n').encode('utf-16'))
text = text.replace(r'Indicators\LevelsZones_QA\ScenarioTests.ex5', r'Indicators\LevelsZones\LevelsZones.ex5')
(templates / 'LZScenarioProduction.tpl').write_bytes(text.replace('\n', '\r\n').encode('utf-16'))
print('QA fixtures installed. Refresh Navigator; run ScenarioLauncher, then ScenarioSmoke.')
