#!/usr/bin/env python3
"""
compile_curriculum.py
Single source of truth compilation script:
- Reads raw/edition_8.json, raw/edition_6_5.json, and raw/qbank.json
- Exports to Flutter Dart data files (syllabus_marrow8.dart, syllabus_marrow65.dart, syllabus_qbank.dart)
- Exports to Web JavaScript files (data.js, data_marrow_6_5.js, data_qbank.js)
- Generates comprehensive human-readable Markdown curriculum tables
- Synchronizes output between web and flutter projects
"""

import json
import os
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
RAW_DIR = os.path.join(BASE_DIR, 'raw')

FLUTTER_DATA_DIRS = [
    os.path.join(os.path.dirname(BASE_DIR), 'lib', 'data'),
    '/home/safi/Documents/flowmd_flutter/lib/data'
]
WEB_DATA_DIRS = [
    os.path.join(os.path.dirname(os.path.dirname(BASE_DIR)), 'Modulix_web'),
    '/home/safi/SAFI/Modulix_web'
]
FLUTTER_CURRICULUM_DIRS = [
    BASE_DIR,
    '/home/safi/Documents/flowmd_flutter/curriculum_data'
]

def load_json(name):
    path = os.path.join(RAW_DIR, f"{name}.json")
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def generate_video_markdown(data, output_path, title):
    total_subjects = len(data)
    total_videos = sum(len(ch.get('videos', [])) for s in data for ch in s.get('chapters', []))
    total_minutes = sum(v.get('durationMins', 0) + v.get('durationSecs', 0)/60.0 for s in data for ch in s.get('chapters', []) for v in ch.get('videos', []))
    total_hours = round(total_minutes / 60.0, 1)

    lines = []
    lines.append(f"# {title} — Curriculum & Master Index")
    lines.append("")
    lines.append(f"> **Quick Stats**: {total_subjects} Subjects · {total_videos} Modules · {total_hours} Hours (~{int(total_minutes)} mins)")
    lines.append("")
    lines.append("## Table of Contents")
    lines.append("")
    for i, s in enumerate(data, 1):
        s_name = s.get('subject')
        v_count = sum(len(ch.get('videos', [])) for ch in s.get('chapters', []))
        ch_count = len(s.get('chapters', []))
        anchor = s_name.lower().replace(' ', '-').replace('&', '').replace('(', '').replace(')', '').replace('.', '')
        lines.append(f"{i}. [{s_name}](#{anchor}) — *{ch_count} units, {v_count} modules*")
    lines.append("")
    lines.append("---")
    lines.append("")

    for s_idx, s in enumerate(data, 1):
        s_name = s.get('subject')
        chapters = s.get('chapters', [])
        s_videos = [v for ch in chapters for v in ch.get('videos', [])]
        s_mins = sum(v.get('durationMins', 0) + v.get('durationSecs', 0)/60.0 for v in s_videos)
        s_hours = round(s_mins / 60.0, 1)

        lines.append(f"## {s_idx}. {s_name}")
        lines.append("")
        lines.append(f"- **Total Units**: {len(chapters)}")
        lines.append(f"- **Total Modules**: {len(s_videos)}")
        lines.append(f"- **Total Duration**: {s_hours} hours ({int(s_mins)} mins)")
        lines.append(f"- **Assigned Number Range**: `#{s_videos[0].get('assignedNumber', 1)}` to `#{s_videos[-1].get('assignedNumber', len(s_videos))}`" if s_videos else "")
        lines.append("")

        for ch_idx, ch in enumerate(chapters, 1):
            ch_name = ch.get('name')
            vids = ch.get('videos', [])
            ch_mins = sum(v.get('durationMins', 0) + v.get('durationSecs', 0)/60.0 for v in vids)
            ch_hours = round(ch_mins / 60.0, 1)

            lines.append(f"### Unit {ch_idx}: {ch_name}")
            lines.append(f"*{len(vids)} modules · {ch_hours} hrs ({int(ch_mins)} mins)*")
            lines.append("")
            lines.append("| # | Video | Title | Duration | Video ID |")
            lines.append("|:---:|:---:|:---|:---:|:---|")

            for v in vids:
                num = v.get('assignedNumber', '')
                v_num = v.get('videoNumber', '')
                title = v.get('title', '').replace('|', '\\|')
                dm = v.get('durationMins', 0)
                ds = v.get('durationSecs', 0)
                dur = f"{dm}m" if ds == 0 else f"{dm}m {ds}s"
                vid = v.get('id', '')
                lines.append(f"| **#{num}** | `{v_num}` | {title} | {dur} | `{vid}` |")

            lines.append("")
        lines.append("---")
        lines.append("")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"[OK] Generated {output_path}")

def generate_qbank_markdown(qbank_data, output_path):
    lines = []
    lines.append("# Marrow Q-Bank Master Curriculum & Index")
    lines.append("")
    lines.append("> **Official Verified NEET-PG Q-Bank Directory**")
    lines.append(f"> * **19 Subjects** · **192 Units** · **835 Topics** · **16,155 MCQs**")
    lines.append("> * **Permanent Assigned Numbers**: `#1` to `#{total}` per subject, strictly immutable.")
    lines.append("")
    lines.append("## Master Subject Overview")
    lines.append("")
    lines.append("| # | Subject | Units | Topics | In-App Assigned Range | Total MCQs |")
    lines.append("| :---:| :--- | :---:| :---:| :---:| :---:|")

    for i, s in enumerate(qbank_data, 1):
        lines.append(f"| {i} | **{s['subject']}** | {s['totalUnits']} | {s['totalTopics']} | `#{1}` to `#{s['totalTopics']}` | **{s['totalMcqs']:,}** |")

    lines.append(f"| **ALL** | **TOTAL** | **192 Units** | **835 Topics** | **Sequential & Immutable** | **16,155 MCQs** |")
    lines.append("")
    lines.append("---")
    lines.append("")

    for s_idx, s in enumerate(qbank_data, 1):
        lines.append(f"## {s_idx}. {s['subject']}")
        lines.append("")
        lines.append(f"- **Total Units**: {s['totalUnits']}")
        lines.append(f"- **Total Topics**: {s['totalTopics']}")
        lines.append(f"- **Total MCQs**: {s['totalMcqs']:,}")
        lines.append(f"- **Assigned Number Range**: `#1` to `#{s['totalTopics']}`")
        lines.append("")

        for ch_idx, ch in enumerate(s['chapters'], 1):
            lines.append(f"### Unit {ch_idx}: {ch['name']}")
            lines.append(f"*{ch['totalTopics']} topics · {ch['totalMcqs']} MCQs*")
            lines.append("")
            lines.append("| # | Topic Name | MCQs | Topic ID |")
            lines.append("|:---:|:---|:---:|:---|")

            for t in ch['topics']:
                lines.append(f"| **#{t['assignedNumber']}** | {t['title']} | {t['totalMcqs']} | `{t['id']}` |")
            lines.append("")
        lines.append("---")
        lines.append("")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"[OK] Generated {output_path}")

def generate_dart(data, output_path, var_name):
    json_str = json.dumps(data, ensure_ascii=False)
    content = f"// Generated from canonical JSON curriculum dataset\nconst List<Map<String, dynamic>> {var_name} = {json_str};\n"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"[OK] Generated Flutter Dart: {output_path}")

def generate_js(data, output_path, var_name, title):
    json_str = json.dumps(data, indent=2, ensure_ascii=False)
    header = f"""/* ============================================================
   MODULIX V2 — NEET-PG SYLLABUS DATASET ({title})
   Generated from canonical JSON curriculum dataset.
   ============================================================ */

const {var_name} = {json_str};

if (typeof module !== 'undefined' && module.exports) {{
  module.exports = {var_name};
}}
"""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(header)
    print(f"[OK] Generated Web JS: {output_path}")

def main():
    print("Compiling Marrow Curriculum & Q-Bank Data...")
    e8 = load_json('edition_8')
    e65 = load_json('edition_6_5')
    qb = load_json('qbank')

    # 1. Generate Markdowns
    generate_video_markdown(e8, os.path.join(BASE_DIR, 'EDITION_8_CURRICULUM.md'), 'Marrow Edition 8')
    generate_video_markdown(e65, os.path.join(BASE_DIR, 'EDITION_6_5_CURRICULUM.md'), 'Marrow Edition 6.5')
    generate_qbank_markdown(qb, os.path.join(BASE_DIR, 'QBANK_CURRICULUM.md'))

    # 2. Generate Flutter Dart files
    for f_dir in FLUTTER_DATA_DIRS:
        if os.path.exists(f_dir):
            generate_dart(e8, os.path.join(f_dir, 'syllabus_marrow8.dart'), 'marrow8Raw')
            generate_dart(e65, os.path.join(f_dir, 'syllabus_marrow65.dart'), 'marrow65Raw')
            generate_dart(qb, os.path.join(f_dir, 'syllabus_qbank.dart'), 'marrowQBankRaw')

    # 3. Generate Web JS files
    for w_dir in WEB_DATA_DIRS:
        if os.path.exists(w_dir):
            generate_js(e8, os.path.join(w_dir, 'data.js'), 'syllabusData', 'EDITION 8 STRUCTURE')
            generate_js(e65, os.path.join(w_dir, 'data_marrow_6_5.js'), 'syllabusData65', 'EDITION 6.5 STRUCTURE')
            generate_js(qb, os.path.join(w_dir, 'data_qbank.js'), 'qbankData', 'OFFICIAL Q-BANK DATASET')

    # 4. Mirror to Flutter repository directory
    if os.path.exists(os.path.dirname(FLUTTER_CURRICULUM_DIRS[1])):
        target_curriculum = FLUTTER_CURRICULUM_DIRS[1]
        os.makedirs(target_curriculum, exist_ok=True)
        os.makedirs(os.path.join(target_curriculum, 'raw'), exist_ok=True)
        os.makedirs(os.path.join(target_curriculum, 'scripts'), exist_ok=True)
        
        for item in ['EDITION_8_CURRICULUM.md', 'EDITION_6_5_CURRICULUM.md', 'QBANK_CURRICULUM.md', 'SUBJECT_SUMMARY.md', 'MARROW-QBANK-INDEX.md', 'README.md']:
            src = os.path.join(BASE_DIR, item)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(target_curriculum, item))
        for item in ['edition_8.json', 'edition_6_5.json', 'qbank.json']:
            src = os.path.join(RAW_DIR, item)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(target_curriculum, 'raw', item))
        for item in ['compile_curriculum.py', 'verify_curriculum.py']:
            src = os.path.join(SCRIPT_DIR, item)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(target_curriculum, 'scripts', item))
        print(f"[OK] Mirrored curriculum_data to {target_curriculum}")

    print("\nCompilation completed successfully!")

if __name__ == '__main__':
    main()
