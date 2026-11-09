#!/usr/bin/env python3
"""Fail early when a global obsolete compiler has accidentally been selected."""
import re
import subprocess
result = subprocess.run(['moonc','-v'],capture_output=True,text=True,check=True)
text = result.stdout + result.stderr
match = re.search(r'(\d+)\.(\d+)\.(\d+)',text)
if not match or tuple(map(int,match.groups())) < (0,10,16):
    raise SystemExit('moonc >= 0.10.16 is required')
print(text.strip())
