import json
import yaml
from pathlib import Path

colors = None
with open('monokai.yaml') as file:
    temp = yaml.load(file, yaml.BaseLoader)
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
    encoding = o['encoding'] if 'encoding' in o else 'utf-8'
    with open(o['filepath'], encoding=encoding) as file:
        content = file.read()
        for k, v in colors.items():
            if 'altmustache' in o and len(o['altmustache']) > 1:
                content = content.replace(o['colorformat'].format(**v), '{}& {}{}'.format(o['altmustache'][0], k, o['altmustache'][1]))
            else:
                content = content.replace(o['colorformat'].format(**v), '{{{{& {}}}}}'.format(k))
            
        if 'altmustache' in o and len(o['altmustache']) > 1:
            content = f'{{{{={o["altmustache"][0]} {o["altmustache"][1]}=}}}}\n' + content +f'{o["altmustache"][0]}={{{{ }}}}={o["altmustache"][1]}\n'
            
    out_dir = Path(f'theme_templates/{o["filepath"]}.mustache').parent
    out_dir.mkdir(parents=True,exist_ok=True)
    with open(f'theme_templates/{o["filepath"]}.mustache', 'w+', encoding=encoding) as out_file:
        out_file.write(content)
        
