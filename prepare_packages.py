#!/usr/bin/env python3
import json
import os
import re
import shutil
import zipfile
from collections import defaultdict

# Greek letters and variants that need space after them when followed by a letter
GREEK_LETTERS = [
    'alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta',
    'iota', 'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi', 'rho',
    'sigma', 'tau', 'upsilon', 'phi', 'chi', 'psi', 'omega',
    'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta',
    'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 'Xi', 'Omicron', 'Pi', 'Rho',
    'Sigma', 'Tau', 'Upsilon', 'Phi', 'Chi', 'Psi', 'Omega',
    'varepsilon', 'vartheta', 'varpi', 'varrho', 'varsigma', 'varphi',
]

def fix_latex(text: str) -> str:
    if not text:
        return text
    for letter in GREEK_LETTERS:
        # Match backslash + letter + lookahead for another letter
        pattern = r'\\' + letter + r'(?=[a-zA-Z])'
        text = re.sub(pattern, r'\\' + letter + ' ', text)
    text = re.sub(r'\$~\$', '', text)
    text = re.sub(r'\$~ \$', '', text)
    def fix_tilde_range(match):
        content = match.group(1)
        # Use \\\\sim for literal \sim in the replacement string
        fixed = re.sub(r'(\d)~(\d)', r'\1 \\sim \2', content)
        fixed = re.sub(r'([°%])~(\d)', r'\1 \\sim \2', fixed)
        return f'${fixed}$'
    text = re.sub(r'\$([^$]+~[^$]+)\$', fix_tilde_range, text)
    return text

def fix_assets_path(text: str) -> str:
    if not text:
        return text
    return text.replace('assets/images/', 'images/')

def transform_question(q):
    formatted_q = {
        'content': fix_assets_path(fix_latex(q.get('content', ''))),
        'explanation': fix_assets_path(fix_latex(q.get('explanation', ''))),
    }
    
    # Handle choices
    if 'choices' in q and q['choices']:
        choices = []
        for c in q['choices']:
            choices.append({
                'key': c['key'],
                'html': fix_assets_path(fix_latex(c.get('text', c.get('html', ''))))
            })
        formatted_q['choices'] = choices
        formatted_q['answer'] = q.get('answer', '')

    # Handle nested questions (children -> questions)
    if 'children' in q and q['children']:
        formatted_q['questions'] = [transform_question(child) for child in q['children']]
    elif 'questions' in q and q['questions']:
        formatted_q['questions'] = [transform_question(sub_q) for sub_q in q['questions']]
        
    return formatted_q

def find_asset_references(data):
    assets = set()
    text = json.dumps(data)
    # Match patterns like images/xxx.png, ensuring we don't catch escaped quotes or backslashes incorrectly
    for match in re.finditer(r'images/[^"\\\s]+\.(png|jpg|gif|webp|mp4)', text):
        assets.add(match.group(0))
    return assets

def convert_and_package(input_path, output_dir, assets_src_dir):
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    book = data['book']
    chapters_list = data.get('chapters', [])
    sections_list = data.get('sections', [])
    questions_list = data.get('questions', [])

    sections_by_chapter = defaultdict(list)
    for s in sections_list:
        sections_by_chapter[s['chapter_id']].append(s)

    questions_by_section = defaultdict(list)
    for q in questions_list:
        questions_by_section[q['section_id']].append(q)

    chapters_nested = []
    for chapter in chapters_list:
        chapter_id = chapter['id']
        sections_nested = []
        for section in sections_by_chapter.get(chapter_id, []):
            section_id = section['id']
            questions = questions_by_section.get(section_id, [])
            formatted_questions = [transform_question(q) for q in questions]
            sections_nested.append({
                'title': section.get('title', ''),
                'questions': formatted_questions,
            })
        chapters_nested.append({
            'title': chapter.get('title', ''),
            'sections': sections_nested,
        })

    package_data = {
        'subject_name_zh': book.get('subject_name_zh', ''),
        'subject_name_en': book.get('subject_name_en', ''),
        'chapters': chapters_nested,
    }

    # Find referenced assets
    referenced_assets = find_asset_references(package_data)
    
    subject_en = book.get('subject_name_en', 'unknown')
    temp_dir = os.path.join(output_dir, f'_tmp_{subject_en}')
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)
    
    # Write data.json
    with open(os.path.join(temp_dir, 'data.json'), 'w', encoding='utf-8') as f:
        json.dump(package_data, f, ensure_ascii=False, indent=2)
        
    # Copy images
    images_dir = os.path.join(temp_dir, 'images')
    if referenced_assets:
        os.makedirs(images_dir, exist_ok=True)
        for asset_path in referenced_assets:
            filename = os.path.basename(asset_path)
            src = os.path.join(assets_src_dir, filename)
            if os.path.exists(src):
                shutil.copy(src, os.path.join(images_dir, filename))
            else:
                print(f"  Warning: Asset not found: {src}")

    # Create zip
    zip_path = os.path.join(output_dir, f'{subject_en}.zip')
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arc_name = os.path.relpath(file_path, temp_dir)
                zf.write(file_path, arc_name)
                
    shutil.rmtree(temp_dir)
    print(f"  Created {zip_path} ({len(referenced_assets)} images)")

def main():
    input_dir = os.path.expanduser('~/projects/chuanyuanyi-data/data/07a-markdown')
    output_dir = os.path.expanduser('~/projects/quiz-flutter/output')
    assets_src_dir = os.path.join(input_dir, 'assets/images')
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    json_files = [f for f in os.listdir(input_dir) if f.endswith('.json')]
    print(f"Found {len(json_files)} subjects to process.")
    
    for filename in sorted(json_files):
        print(f"Processing {filename}...")
        input_path = os.path.join(input_dir, filename)
        convert_and_package(input_path, output_dir, assets_src_dir)
        
    print("All packages created in 'output' directory.")

if __name__ == '__main__':
    main()
