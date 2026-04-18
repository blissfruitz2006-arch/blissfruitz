import sys, json
from graphify.extract import collect_files, extract
from pathlib import Path

code_files = []
with open('graphify-out/.graphify_detect.json', 'r', encoding='utf-8') as f:
    detect = json.load(f)

for f in detect.get('files', {}).get('code', []):
    p = Path(f)
    if p.exists():
        code_files.extend(collect_files(p) if p.is_dir() else [p])

if code_files:
    result = extract(code_files)
    with open('graphify-out/.graphify_ast.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2)
    print(f"AST: {len(result['nodes'])} nodes, {len(result['edges'])} edges")
else:
    with open('graphify-out/.graphify_ast.json', 'w', encoding='utf-8') as f:
        json.dump({'nodes':[],'edges':[],'input_tokens':0,'output_tokens':0}, f)
    print('No code files - skipping AST extraction')
