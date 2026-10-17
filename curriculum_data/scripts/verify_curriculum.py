#!/usr/bin/env python3
"""
verify_curriculum.py
Validates integrity of Marrow Edition 8, Edition 6.5, and Q-Bank datasets:
- Checks sequential continuity of assignedNumber (1..N per subject)
- Ensures no duplicate numbers or IDs
- Validates chapter module counts and calculated hours / MCQs
- Checks for empty titles or invalid durations
"""

import json
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(SCRIPT_DIR, '..', 'raw')

def verify_video_dataset(filepath, name):
    print(f"\n{'='*20} VERIFYING {name} {'='*20}")
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    total_errors = 0
    total_videos = 0
    all_video_ids = set()

    print(f"Total Subjects Found: {len(data)}")

    for s_idx, s in enumerate(data, 1):
        s_id = s.get('id')
        s_name = s.get('subject')
        chapters = s.get('chapters', [])
        
        s_videos = [v for ch in chapters for v in ch.get('videos', [])]
        total_videos += len(s_videos)

        # Check assignedNumber continuity
        assigned_nums = [v.get('assignedNumber') for v in s_videos]
        expected_nums = list(range(1, len(s_videos) + 1))

        if assigned_nums != expected_nums:
            total_errors += 1
            print(f"[ERROR] {s_name}: assignedNumber sequence is invalid!")
            missing = set(expected_nums) - set(assigned_nums)
            dupes = [x for x in assigned_nums if assigned_nums.count(x) > 1]
            if missing:
                print(f"   Missing numbers: {sorted(list(missing))[:10]}")
            if dupes:
                print(f"   Duplicate numbers: {set(dupes)}")
        
        # Check individual modules
        for ch_idx, ch in enumerate(chapters, 1):
            ch_name = ch.get('name')
            vids = ch.get('videos', [])
            declared_mod = ch.get('modules')
            if declared_mod != len(vids):
                total_errors += 1
                print(f"[ERROR] {s_name} -> {ch_name}: declared modules ({declared_mod}) != actual videos ({len(vids)})")

            for v in vids:
                v_id = v.get('id')
                v_title = v.get('title')
                dm = v.get('durationMins', 0)
                ds = v.get('durationSecs', 0)

                if not v_title or not v_title.strip():
                    total_errors += 1
                    print(f"[ERROR] Empty title for module {v_id} in {s_name}")

                if dm < 0 or ds < 0:
                    total_errors += 1
                    print(f"[ERROR] Negative duration in {v_id}: {dm}m {ds}s")

                if v_id in all_video_ids:
                    total_errors += 1
                    print(f"[ERROR] Duplicate video ID {v_id}")
                all_video_ids.add(v_id)

    if total_errors == 0:
        print(f"[SUCCESS] {name} is 100% valid! (Checked {len(data)} subjects, {total_videos} video modules)")
        return True
    else:
        print(f"[FAILED] {name} encountered {total_errors} errors!")
        return False

def verify_qbank_dataset(filepath):
    print(f"\n{'='*20} VERIFYING Marrow Q-Bank {'='*20}")
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    total_errors = 0
    total_topics = 0
    total_mcqs = 0
    all_topic_ids = set()

    print(f"Total Q-Bank Subjects Found: {len(data)}")

    for s in data:
        s_id = s.get('id')
        s_name = s.get('subject')
        chapters = s.get('chapters', [])

        s_topics = [t for ch in chapters for t in ch.get('topics', [])]
        total_topics += len(s_topics)
        total_mcqs += sum(t.get('totalMcqs', 0) for t in s_topics)

        # Check assignedNumber continuity
        assigned_nums = [t.get('assignedNumber') for t in s_topics]
        expected_nums = list(range(1, len(s_topics) + 1))

        if assigned_nums != expected_nums:
            total_errors += 1
            print(f"[ERROR] {s_name} Q-Bank: assignedNumber sequence invalid!")
            missing = set(expected_nums) - set(assigned_nums)
            dupes = [x for x in assigned_nums if assigned_nums.count(x) > 1]
            if missing:
                print(f"   Missing numbers: {sorted(list(missing))[:10]}")
            if dupes:
                print(f"   Duplicate numbers: {set(dupes)}")

        # Check topics
        for ch in chapters:
            ch_name = ch.get('name')
            topics = ch.get('topics', [])
            if ch.get('totalTopics') != len(topics):
                total_errors += 1
                print(f"[ERROR] {s_name} -> {ch_name}: totalTopics mismatch")

            for t in topics:
                t_id = t.get('id')
                t_title = t.get('title')
                mcqs = t.get('totalMcqs', 0)

                if not t_title or not t_title.strip():
                    total_errors += 1
                    print(f"[ERROR] Empty title for Q-Bank topic {t_id}")

                if mcqs <= 0:
                    total_errors += 1
                    print(f"[ERROR] Non-positive MCQs ({mcqs}) in {t_id}")

                if t_id in all_topic_ids:
                    total_errors += 1
                    print(f"[ERROR] Duplicate Q-Bank topic ID {t_id}")
                all_topic_ids.add(t_id)

    if total_errors == 0:
        print(f"[SUCCESS] Marrow Q-Bank is 100% valid! (Checked {len(data)} subjects, {total_topics} topics, {total_mcqs:,} MCQs)")
        return True
    else:
        print(f"[FAILED] Marrow Q-Bank encountered {total_errors} errors!")
        return False

def main():
    e8_file = os.path.join(RAW_DIR, 'edition_8.json')
    e65_file = os.path.join(RAW_DIR, 'edition_6_5.json')
    qb_file = os.path.join(RAW_DIR, 'qbank.json')

    ok8 = verify_video_dataset(e8_file, "Marrow Edition 8")
    ok65 = verify_video_dataset(e65_file, "Marrow Edition 6.5")
    okqb = verify_qbank_dataset(qb_file)

    if ok8 and ok65 and okqb:
        print("\nAll curriculum datasets (Videos E8, Videos E6.5, and Q-Bank) passed validation cleanly.")
        sys.exit(0)
    else:
        print("\nOne or more datasets failed validation.")
        sys.exit(1)

if __name__ == '__main__':
    main()
