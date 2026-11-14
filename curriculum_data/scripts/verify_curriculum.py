#!/usr/bin/env python3
"""
verify_curriculum.py
Comprehensive data integrity & security validation for Marrow Curriculum datasets:
- Checks sequential continuity of assignedNumber (strictly 1..N per subject with no gaps or duplicates)
- Enforces strict monotonic ordering across and within chapters
- Guards against placeholder, fake, or corrupted topic titles
- Guards against intra-subject duplicate titles and duplicate IDs
- Reconciles declared chapter module counts against actual item lengths
- Validates duration and MCQ ranges
- Verifies canonical subject registries and strict edition isolation
"""

import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(SCRIPT_DIR, '..', 'raw')

# Canonical 20 NEET-PG subject IDs
CANONICAL_E8_SUBJECTS = [
    'anatomy', 'biochemistry', 'physiology', 'pharmacology', 'microbiology',
    'pathology', 'community_medicine', 'forensic_medicine', 'ophthalmology',
    'otorhinolaryngology__ent_', 'anaesthesia', 'dermatology', 'psychiatry',
    'radiology', 'medicine', 'surgery', 'orthopaedics', 'paediatrics',
    'obstetrics___gynaecology', 'revision_videos'
]

CANONICAL_E65_SUBJECTS = [
    'anatomy', 'biochemistry', 'physiology', 'pharmacology', 'microbiology',
    'pathology', 'community_medicine', 'forensic_medicine', 'ophthalmology',
    'ent', 'anaesthesia', 'dermatology', 'psychiatry',
    'radiology', 'medicine', 'surgery', 'orthopaedics', 'paediatrics',
    'obstetrics___gynaecology', 'e6_5_revision_videos'
]

CANONICAL_QBANK_SUBJECTS = [
    'anatomy', 'physiology', 'biochemistry', 'pharmacology', 'pathology',
    'microbiology', 'forensic_medicine', 'community_medicine', 'ophthalmology',
    'otorhinolaryngology__ent_', 'medicine', 'surgery', 'obstetrics___gynaecology',
    'paediatrics', 'orthopaedics', 'dermatology', 'psychiatry', 'anaesthesia',
    'radiology'
]

# Patterns that indicate fake, placeholder, or draft items
# Note: Valid medical terms like "Thyroid function test" or "Sample size calculation"
# are preserved by targeting explicit placeholder structures.
FAKE_PATTERNS = [
    re.compile(r'^(untitled|dummy|placeholder|sample\s+(?:video|topic|item|\d+)|test\s+(?:video|topic|item|\d+))\b', re.IGNORECASE),
    re.compile(r'^(temp\b|temporary\b|coming\s+soon|to\s+be\s+added|tbd\b|tba\b|new\s+(?:video|topic))\b', re.IGNORECASE),
    re.compile(r'\b(lorem\s+ipsum|fake\s+(?:topic|video))\b', re.IGNORECASE),
    re.compile(r'(\[draft\]|\[placeholder\]|\[dummy\]|\[test\])', re.IGNORECASE),
]

def check_fake_title(title):
    if not title or not title.strip():
        return "Empty or whitespace-only title"
    clean = title.strip()
    if len(clean) < 2:
        return f"Suspiciously short title ({len(clean)} chars): '{clean}'"
    if re.match(r'^[0-9\W]+$', clean):
        return f"Title contains no letters: '{clean}'"
    for pat in FAKE_PATTERNS:
        if pat.search(clean):
            return f"Matches placeholder pattern ({pat.pattern}): '{clean}'"
    return None

def verify_video_dataset(filepath, name, canonical_subjects, expected_total_videos=None):
    print(f"\n{'='*20} VERIFYING {name} {'='*20}")
    if not os.path.exists(filepath):
        print(f"[FATAL] File not found: {filepath}")
        return False

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    errors = []
    total_videos = 0
    all_video_ids = set()

    # 1. Subject list verification
    found_subject_ids = [s.get('id') for s in data]
    if len(found_subject_ids) != len(canonical_subjects):
        errors.append(f"Subject count mismatch: expected {len(canonical_subjects)}, found {len(found_subject_ids)}")

    missing_subjects = set(canonical_subjects) - set(found_subject_ids)
    if missing_subjects:
        errors.append(f"Missing canonical subjects: {missing_subjects}")

    extra_subjects = set(found_subject_ids) - set(canonical_subjects)
    if extra_subjects:
        errors.append(f"Extra/unrecognized subjects: {extra_subjects}")

    # 2. Iterate each subject
    for s_idx, s in enumerate(data, 1):
        s_id = s.get('id', '')
        s_name = s.get('subject', '')
        chapters = s.get('chapters', [])

        if not s_id or not s_id.strip():
            errors.append(f"Subject at index {s_idx} has empty ID")
        if not s_name or not s_name.strip():
            errors.append(f"Subject '{s_id}' has empty name")
        if not chapters:
            errors.append(f"Subject '{s_id}' has zero chapters/units")

        s_videos = []
        last_assigned_num = 0
        seen_titles = {}

        for ch_idx, ch in enumerate(chapters, 1):
            ch_name = ch.get('name', '')
            vids = ch.get('videos', [])

            if not ch_name or not ch_name.strip():
                errors.append(f"Subject '{s_id}' -> Unit {ch_idx} has empty name")
            if ch_name != ch_name.strip():
                errors.append(f"Subject '{s_id}' -> Unit '{ch_name}' has untrimmed whitespace")
            if not vids:
                errors.append(f"Subject '{s_id}' -> Unit '{ch_name}' has zero video modules")

            declared_modules = ch.get('modules')
            if declared_modules != len(vids):
                errors.append(f"Subject '{s_id}' -> Unit '{ch_name}': declared modules ({declared_modules}) != actual videos ({len(vids)})")

            for v in vids:
                v_id = v.get('id', '')
                v_title = v.get('title', '')
                assigned_num = v.get('assignedNumber')
                dm = v.get('durationMins', 0)
                ds = v.get('durationSecs', 0)

                # Whitespace checks
                if v_id != v_id.strip():
                    errors.append(f"Whitespace in video ID '{v_id}' in '{s_id}'")
                if v_title != v_title.strip():
                    errors.append(f"Whitespace in video title '{v_title}' in '{s_id}'")

                # ID format & uniqueness
                if not v_id:
                    errors.append(f"Empty video ID in '{s_id}' -> Unit '{ch_name}'")
                elif v_id in all_video_ids:
                    errors.append(f"Duplicate video ID '{v_id}' across dataset")
                all_video_ids.add(v_id)

                # Fake/placeholder detection
                fake_err = check_fake_title(v_title)
                if fake_err:
                    errors.append(f"Fake topic guard in '{s_id}' module '{v_id}': {fake_err}")

                # Intra-subject duplicate title check
                norm_title = v_title.strip().lower()
                if norm_title in seen_titles:
                    errors.append(f"Duplicate title within '{s_id}': '{v_title}' (module {v_id} in '{ch_name}' duplicate of {seen_titles[norm_title]})")
                seen_titles[norm_title] = f"{v_id} in '{ch_name}'"

                # Duration validation
                if not isinstance(dm, int) or not isinstance(ds, int):
                    errors.append(f"Non-integer duration in '{v_id}': {dm}m {ds}s")
                elif dm < 0 or ds < 0:
                    errors.append(f"Negative duration in '{v_id}': {dm}m {ds}s")
                elif ds >= 60:
                    errors.append(f"durationSecs >= 60 in '{v_id}': {ds}s")
                elif (dm == 0 and ds == 0):
                    errors.append(f"Zero duration in module '{v_id}'")
                elif dm >= 600:
                    errors.append(f"Absurdly large duration (>10h) in '{v_id}': {dm}m")

                # Assigned number validation
                if assigned_num is None or not isinstance(assigned_num, int):
                    errors.append(f"Invalid assignedNumber '{assigned_num}' in module '{v_id}'")
                else:
                    if assigned_num != last_assigned_num + 1:
                        errors.append(f"Non-contiguous sequence in '{s_id}': expected #{last_assigned_num + 1}, got #{assigned_num} in '{v_id}'")
                    last_assigned_num = assigned_num

                s_videos.append(v)

        total_videos += len(s_videos)

        # Final sequence check
        assigned_nums = [v.get('assignedNumber') for v in s_videos]
        expected_nums = list(range(1, len(s_videos) + 1))
        if assigned_nums != expected_nums:
            errors.append(f"Final sequence validation failed for '{s_id}': len={len(s_videos)}")

    if expected_total_videos is not None and total_videos != expected_total_videos:
        errors.append(f"Total video count mismatch: expected {expected_total_videos}, found {total_videos}")

    if errors:
        print(f"[FAILED] {name} encountered {len(errors)} errors:")
        for err in errors[:25]:
            print(f"  ❌ {err}")
        if len(errors) > 25:
            print(f"  ... and {len(errors) - 25} more errors.")
        return False
    else:
        print(f"[SUCCESS] {name} is 100% valid! ({len(data)} subjects, {total_videos} video modules, 0 errors)")
        return True

def verify_qbank_dataset(filepath):
    name = "Marrow Q-Bank"
    print(f"\n{'='*20} VERIFYING {name} {'='*20}")
    if not os.path.exists(filepath):
        print(f"[FATAL] File not found: {filepath}")
        return False

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    errors = []
    total_topics = 0
    total_mcqs = 0
    all_topic_ids = set()

    found_subject_ids = [s.get('id') for s in data]
    if len(found_subject_ids) != len(CANONICAL_QBANK_SUBJECTS):
        errors.append(f"Q-Bank subject count mismatch: expected {len(CANONICAL_QBANK_SUBJECTS)}, found {len(found_subject_ids)}")

    missing_subjects = set(CANONICAL_QBANK_SUBJECTS) - set(found_subject_ids)
    if missing_subjects:
        errors.append(f"Missing Q-Bank subjects: {missing_subjects}")

    extra_subjects = set(found_subject_ids) - set(CANONICAL_QBANK_SUBJECTS)
    if extra_subjects:
        errors.append(f"Extra Q-Bank subjects: {extra_subjects}")

    for s in data:
        s_id = s.get('id', '')
        s_name = s.get('subject', '')
        chapters = s.get('chapters', [])

        if not s_id or not s_id.strip():
            errors.append(f"Empty subject ID in Q-Bank")
        if not s_name or not s_name.strip():
            errors.append(f"Empty subject name in Q-Bank for '{s_id}'")

        s_topics = []
        last_assigned_num = 0
        seen_titles = {}

        for ch in chapters:
            ch_name = ch.get('name', '')
            topics = ch.get('topics', [])

            if not ch_name or not ch_name.strip():
                errors.append(f"Empty chapter name in Q-Bank subject '{s_id}'")
            if ch_name != ch_name.strip():
                errors.append(f"Untrimmed chapter name '{ch_name}' in Q-Bank '{s_id}'")
            if not topics:
                errors.append(f"Empty chapter '{ch_name}' in Q-Bank '{s_id}'")

            declared_topics = ch.get('totalTopics')
            if declared_topics != len(topics):
                errors.append(f"Q-Bank '{s_id}' -> '{ch_name}': declared topics ({declared_topics}) != actual ({len(topics)})")

            for t in topics:
                t_id = t.get('id', '')
                t_title = t.get('title', '')
                assigned_num = t.get('assignedNumber')
                mcqs = t.get('totalMcqs')

                if t_id != t_id.strip():
                    errors.append(f"Whitespace in Q-Bank topic ID '{t_id}'")
                if t_title != t_title.strip():
                    errors.append(f"Whitespace in Q-Bank title '{t_title}'")

                if not t_id:
                    errors.append(f"Empty topic ID in Q-Bank '{s_id}'")
                elif t_id in all_topic_ids:
                    errors.append(f"Duplicate Q-Bank topic ID '{t_id}'")
                all_topic_ids.add(t_id)

                fake_err = check_fake_title(t_title)
                if fake_err:
                    errors.append(f"Fake topic guard in Q-Bank '{s_id}' topic '{t_id}': {fake_err}")

                norm_title = t_title.strip().lower()
                if norm_title in seen_titles:
                    errors.append(f"Duplicate title within Q-Bank '{s_id}': '{t_title}' ({t_id} in '{ch_name}' vs {seen_titles[norm_title]})")
                seen_titles[norm_title] = f"{t_id} in '{ch_name}'"

                if not isinstance(mcqs, int) or mcqs <= 0:
                    errors.append(f"Invalid MCQs ({mcqs}) in Q-Bank topic '{t_id}'")
                elif mcqs > 2000:
                    errors.append(f"Absurdly large MCQ count ({mcqs}) in '{t_id}'")

                if assigned_num is None or not isinstance(assigned_num, int):
                    errors.append(f"Invalid assignedNumber '{assigned_num}' in Q-Bank '{t_id}'")
                else:
                    if assigned_num != last_assigned_num + 1:
                        errors.append(f"Non-contiguous sequence in Q-Bank '{s_id}': expected #{last_assigned_num + 1}, got #{assigned_num}")
                    last_assigned_num = assigned_num

                s_topics.append(t)
                total_mcqs += mcqs

        total_topics += len(s_topics)

    if errors:
        print(f"[FAILED] Marrow Q-Bank encountered {len(errors)} errors:")
        for err in errors[:25]:
            print(f"  ❌ {err}")
        if len(errors) > 25:
            print(f"  ... and {len(errors) - 25} more errors.")
        return False
    else:
        print(f"[SUCCESS] Marrow Q-Bank is 100% valid! ({len(data)} subjects, {total_topics} topics, {total_mcqs:,} MCQs)")
        return True

def verify_edition_isolation(e8_file, e65_file, qb_file):
    print(f"\n{'='*20} VERIFYING STRICT EDITION SEPARATION {'='*20}")
    errors = []

    with open(e8_file, 'r', encoding='utf-8') as f:
        e8 = json.load(f)
    with open(e65_file, 'r', encoding='utf-8') as f:
        e65 = json.load(f)
    with open(qb_file, 'r', encoding='utf-8') as f:
        qb = json.load(f)

    # 1. Total counts must be strictly as defined (no cross-contamination)
    e8_videos = sum(len(ch['videos']) for s in e8 for ch in s.get('chapters', []))
    e65_videos = sum(len(ch['videos']) for s in e65 for ch in s.get('chapters', []))
    qb_topics = sum(len(ch['topics']) for s in qb for ch in s.get('chapters', []))

    if e8_videos != 1558:
        errors.append(f"Edition 8 video count altered: expected 1558, got {e8_videos}")
    if e65_videos != 1593:
        errors.append(f"Edition 6.5 video count altered: expected 1593, got {e65_videos}")
    if qb_topics != 835:
        errors.append(f"Q-Bank topic count altered: expected 835, got {qb_topics}")

    # 2. Q-Bank topics must not overlap with video IDs
    qb_ids = set(t['id'] for s in qb for ch in s.get('chapters', []) for t in ch.get('topics', []))
    e8_ids = set(v['id'] for s in e8 for ch in s.get('chapters', []) for v in ch.get('videos', []))
    e65_ids = set(v['id'] for s in e65 for ch in s.get('chapters', []) for v in ch.get('videos', []))

    qb_e8_collision = qb_ids.intersection(e8_ids)
    if qb_e8_collision:
        errors.append(f"Collision between Q-Bank topic IDs and Edition 8 video IDs: {list(qb_e8_collision)[:5]}")

    qb_e65_collision = qb_ids.intersection(e65_ids)
    if qb_e65_collision:
        errors.append(f"Collision between Q-Bank topic IDs and Edition 6.5 video IDs: {list(qb_e65_collision)[:5]}")

    if errors:
        print(f"[FAILED] Edition Isolation encountered {len(errors)} errors:")
        for err in errors:
            print(f"  ❌ {err}")
        return False
    else:
        print(f"[SUCCESS] Editions are strictly separated! (E8: 1,558 videos, E6.5: 1,593 videos, Q-Bank: 835 topics)")
        return True

def verify_all():
    e8_file = os.path.join(RAW_DIR, 'edition_8.json')
    e65_file = os.path.join(RAW_DIR, 'edition_6_5.json')
    qb_file = os.path.join(RAW_DIR, 'qbank.json')

    ok8 = verify_video_dataset(e8_file, "Marrow Edition 8", CANONICAL_E8_SUBJECTS, 1558)
    ok65 = verify_video_dataset(e65_file, "Marrow Edition 6.5", CANONICAL_E65_SUBJECTS, 1593)
    okqb = verify_qbank_dataset(qb_file)
    ok_iso = verify_edition_isolation(e8_file, e65_file, qb_file)

    if ok8 and ok65 and okqb and ok_iso:
        print("\nAll curriculum datasets passed validation and strict edition isolation cleanly.")
        return True
    else:
        print("\nOne or more validation checks failed.")
        return False

def main():
    if verify_all():
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
