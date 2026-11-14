# FlowMD NEET-PG Curriculum & Q-Bank Master Archive

This directory serves as the **single source of truth** for all video curriculum and Q-Bank datasets used across FlowMD (both the Flutter mobile application and the Web platform).

It automates and standardizes curriculum compilation, eliminating manual compilation errors, broken numbering sequences, or divergent data files between platforms.

---

## Directory Structure

```text
curriculum_data/
├── README.md                      # Architecture guide, schemas, & workflow instructions
├── SUBJECT_SUMMARY.md             # Side-by-side comparison matrix (E8 vs E6.5)
├── EDITION_8_CURRICULUM.md        # Full master markdown curriculum for Edition 8 Videos
├── EDITION_6_5_CURRICULUM.md      # Full master markdown curriculum for Edition 6.5 Videos
├── QBANK_CURRICULUM.md            # Full master markdown directory for Marrow Q-Bank
├── MARROW-QBANK-INDEX.md          # Upstream verified screenshot-validated Q-Bank reference
├── raw/
│   ├── edition_8.json             # Canonical master JSON for Marrow Edition 8 (Videos)
│   ├── edition_6_5.json           # Canonical master JSON for Marrow Edition 6.5 (Videos)
│   └── qbank.json                 # Canonical master JSON for Marrow Q-Bank (Shared across editions)
└── scripts/
    ├── compile_curriculum.py      # Multi-target compiler (Flutter Dart, Web JS, Markdown)
    └── verify_curriculum.py       # Automated data integrity & continuity checker
```

---

## Dataset Statistics

| Metric | Marrow Edition 8 (Videos) | Marrow Edition 6.5 (Videos) | Marrow Q-Bank (All Editions) |
| :--- | :---: | :---: | :---: |
| **Total Subjects** | 20 | 20 | **19** |
| **Total Units (Chapters)** | 148 | 143 | **192** |
| **Total Modules / Topics** | **1,558 Videos** | **1,593 Videos** | **835 Topics** |
| **Total Runtime / MCQs** | **~886.8 hours** | **~865.1 hours** | **16,155 MCQs** |
| **Assigned Numbering** | Continuous `#1` – `#total` | Continuous `#1` – `#total` | Continuous `#1` – `#total` |

---

## Data Schema Reference

### 1. Q-Bank Subject & Unit Object (`raw/qbank.json`)
```json
{
  "id": "anatomy",
  "subject": "Anatomy",
  "chapters": [
    {
      "name": "EMBRYOLOGY",
      "totalTopics": 10,
      "totalMcqs": 183,
      "topics": [
        {
          "id": "qb_anatomy_t1",
          "title": "Gametogenesis",
          "assignedNumber": 1,
          "totalMcqs": 19,
          "chapterName": "EMBRYOLOGY"
        }
      ]
    }
  ]
}
```

### 2. Video Subject & Chapter Object (`raw/edition_8.json`, `raw/edition_6_5.json`)
```json
{
  "id": "radiology",
  "subject": "Radiology",
  "chapters": [
    {
      "name": "SYSTEMIC RADIOLOGY",
      "modules": 23,
      "hours": 15.6,
      "videos": [
        {
          "id": "radiology__v35",
          "videoNumber": "#35",
          "assignedNumber": 35,
          "title": "Hydatid Cyst Imaging",
          "durationMins": 12,
          "durationSecs": 0
        }
      ]
    }
  ]
}
```

---

## Automated Tooling & Compilation

### 1. Verifying Curriculum & Q-Bank Integrity
Run this automated validation suite to check all three datasets:

```bash
python3 curriculum_data/scripts/verify_curriculum.py
```

Checks performed:
- [x] Sequential continuity of `assignedNumber` (`1` through `N` for every subject)
- [x] No duplicate numbers or IDs across all 1,558 E8 videos, 1,593 E6.5 videos, and 835 Q-Bank topics
- [x] Declared chapter `modules` / `totalTopics` match actual list lengths
- [x] No empty titles, zero MCQs, or negative durations

### 2. Compiling Across All Platforms
To propagate any changes made in `raw/` across all platforms:

```bash
python3 curriculum_data/scripts/compile_curriculum.py
```

This single command automatically updates:
1. **Flutter Mobile**:
   - `lib/data/syllabus_marrow8.dart`
   - `lib/data/syllabus_marrow65.dart`
   - `lib/data/syllabus_qbank.dart`
2. **Web Application**:
   - `FlowMD_web/data.js`
   - `FlowMD_web/data_marrow_6_5.js`
   - `FlowMD_web/data_qbank.js`
3. **Markdown Documentation**:
   - `curriculum_data/EDITION_8_CURRICULUM.md`
   - `curriculum_data/EDITION_6_5_CURRICULUM.md`
   - `curriculum_data/QBANK_CURRICULUM.md`
   - `curriculum_data/SUBJECT_SUMMARY.md`
