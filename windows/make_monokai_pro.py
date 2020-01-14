import json
import copy
import yaml
from pathlib import Path
import pystache

colors = None
scheme_name = ''
with open('monokai_pro.yaml') as file:
    temp = yaml.load(file, yaml.BaseLoader)
    scheme_name = copy.copy(temp['scheme'])
    del temp['author']
    del temp['scheme']
    colors = {k:{'r': v[0:2], 'g': v[2:4], 'b': v[4:6]} for k, v in temp.items()}
    for v in colors.values():
        v['R'] = v['r'].upper()
        v['G'] = v['g'].upper()
        v['B'] = v['b'].upper()

theme_files = None
with open('theme_files.json') as file:
    theme_files = json.loads(file.read())

for o in theme_files:
    content = ''
    with open(f'theme_templates/{o["filepath"]}.mustache') as file:
        base16_strings = {k:o['colorformat'].format(**v) for k,v in colors.items()}
        base16_strings['name'] = scheme_name
        content = file.read()
        content = pystache.render(content, base16_strings)
    out_dir = Path(f'monokai_pro/{o["filepath"]}').parent
    out_dir.mkdir(parents=True,exist_ok=True)
    with open(f'monokai_pro/{o["filepath"]}', 'w+') as out_file:
        out_file.write(content)
    
