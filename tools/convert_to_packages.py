#!/usr/bin/env python3
"""
Convert flat JSON quiz data to nested package format for the Flutter quiz app.
"""
import json
import os
import re
import sys
from collections import defaultdict

# Greek letters and variants that need space after them when followed by a letter
GREEK_LETTERS = [
    # Lowercase Greek
    'alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta',
    'iota', 'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi', 'rho',
    'sigma', 'tau', 'upsilon', 'phi', 'chi', 'psi', 'omega',
    # Uppercase Greek
    'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta',
    'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 'Xi', 'Omicron', 'Pi', 'Rho',
    'Sigma', 'Tau', 'Upsilon', 'Phi', 'Chi', 'Psi', 'Omega',
    # Variants
    'varepsilon', 'vartheta', 'varpi', 'varrho', 'varsigma', 'varphi',
]

def fix_latex(text: str) -> str:
    """Fix common LaTeX issues in text."""
    if not text:
        return text

    # 1. Fix Greek letters without space: \Deltav -> \Delta v
    for letter in GREEK_LETTERS:
        # Match \letter followed by a letter (not a space, brace, or backslash)
        pattern = rf'(\\{letter})([a-zA-Z])'
        text = re.sub(pattern, r'\1 \2', text)

    # 2. Fix standalone tilde in math: $~$ -> (remove or replace with space)
    text = re.sub(r'\$~\$', '', text)
    text = re.sub(r'\$~ \$', '', text)

    # 3. Fix tilde as range separator in math: $10~13$ -> $10 \\sim 13$
    # Match patterns like $number~number$ or $number~numberUnit$
    def fix_tilde_range(match):
        content = match.group(1)
        # Replace ~ with \sim when it's between numbers/values
        fixed = re.sub(r'(\d)~(\d)', r'\1 \\sim \2', content)
        # Also handle cases like $\theta=80°~120°$
        fixed = re.sub(r'([°%])~(\d)', r'\1 \\sim \2', fixed)
        return f'${fixed}$'

    text = re.sub(r'\$([^$]+~[^$]+)\$', fix_tilde_range, text)

    return text


def fix_latex_in_dict(obj):
    """Recursively fix LaTeX in all string values of a dict/list."""
    if isinstance(obj, str):
        return fix_latex(obj)
    elif isinstance(obj, dict):
        return {k: fix_latex_in_dict(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [fix_latex_in_dict(item) for item in obj]
    return obj


def convert_to_package(input_path: str, output_path: str):
    """Convert a single JSON file to package format."""
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    book = data['book']
    chapters_list = data.get('chapters', [])
    sections_list = data.get('sections', [])
    questions_list = data.get('questions', [])

    # Build lookup maps
    # Group sections by chapter_id
    sections_by_chapter = defaultdict(list)
    for s in sections_list:
        sections_by_chapter[s['chapter_id']].append(s)

    # Group questions by section_id
    questions_by_section = defaultdict(list)
    for q in questions_list:
        questions_by_section[q['section_id']].append(q)

    # Build nested structure
    chapters_nested = []
    for chapter in chapters_list:
        chapter_id = chapter['id']
        sections_nested = []

        for section in sections_by_chapter.get(chapter_id, []):
            section_id = section['id']
            questions = questions_by_section.get(section_id, [])

            # Transform questions to expected format
            formatted_questions = []
            for q in questions:
                formatted_q = {
                    'content': fix_latex(q.get('content', '')),
                    'choices': fix_latex_in_dict(q.get('choices', [])),
                    'answer': q.get('answer', ''),
                    'explanation': fix_latex(q.get('explanation', '')),
                }
                formatted_questions.append(formatted_q)

            sections_nested.append({
                'title': section.get('title', ''),
                'questions': formatted_questions,
            })

        chapters_nested.append({
            'title': chapter.get('title', ''),
            'sections': sections_nested,
        })

    # Create package
    package = {
        'subject_name_zh': book.get('subject_name_zh', ''),
        'subject_name_en': book.get('subject_name_en', ''),
        'chapters': chapters_nested,
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(package, f, ensure_ascii=False, indent=2)

    # Print stats
    total_questions = sum(
        len(s['questions'])
        for c in chapters_nested
        for s in c['sections']
    )
    print(f"  Chapters: {len(chapters_nested)}")
    print(f"  Sections: {sum(len(c['sections']) for c in chapters_nested)}")
    print(f"  Questions: {total_questions}")


def main():
    input_dir = os.path.expanduser('~/projects/chuanyuanyi-data/data/07a-markdown')
    output_dir = os.path.expanduser('~/projects/quiz-flutter/output')

    os.makedirs(output_dir, exist_ok=True)

    # Find all JSON files
    json_files = [f for f in os.listdir(input_dir) if f.endswith('.json')]

    if not json_files:
        print("No JSON files found in input directory")
        sys.exit(1)

    print(f"Found {len(json_files)} JSON files to convert\n")

    for filename in sorted(json_files):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename)

        print(f"Converting: {filename}")
        try:
            convert_to_package(input_path, output_path)
            print(f"  -> {output_path}\n")
        except Exception as e:
            print(f"  ERROR: {e}\n")

    print("Done!")


if __name__ == '__main__':
    main()
