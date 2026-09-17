#!/usr/bin/env python3
"""Enforce the indicator's drawing-only boundary in production source."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
for path in sorted((root / 'src').glob('*.mq*')):
    code = path.read_text()
    code = re.sub(r'/\*.*?\*/|//[^\n]*', '', code, flags=re.S)
    forbidden = re.search(r'\b(?:OrderSend\w*|OrderCheck|CTrade|AccountInfo\w*|WebRequest|Socket\w*|Position\w*|Order(?:Select|Get\w*|Calc\w*)|History(?:Order|Deal)\w*)\s*\(|#import|Trade[/\\\\]Trade\.mqh', code)
    if forbidden:
        raise SystemExit(f'FAIL {path.name}: {forbidden.group()}')
print('PASS: production source contains no order/position APIs, trading library or DLL imports')
