import 'package:flutter/material.dart';
import '../../data/subjects_metadata.dart';

/// Renders the user-selected high-resolution (512x512) Flaticon subject icons.
class SubjectSketchIcon extends StatelessWidget {
  final String subjectId;
  final double size;
  final Color? color;

  const SubjectSketchIcon({
    super.key,
    required this.subjectId,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = _subjectAssetMap[subjectId];
    final meta = subjectMeta(subjectId);

    if (assetPath != null) {
      final isMultiColor = _multiColorSubjects.contains(subjectId);
      final shouldTint = (color != null) || (!isMultiColor);
      final tintColor = color ?? meta.accent;

      final cacheDim = (size * 3.0).toInt().clamp(64, 160);

      return Image.asset(
        assetPath,
        width: size,
        height: size,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        color: shouldTint ? tintColor : null,
      );
    }

    // Fallback to meta icon
    return Icon(
      meta.icon,
      size: size,
      color: color ?? meta.accent,
    );
  }
}

const Map<String, String> _subjectAssetMap = {
  'anatomy': 'assets/icons/subjects/anatomy.png',
  'physiology': 'assets/icons/subjects/physiology.png',
  'biochemistry': 'assets/icons/subjects/biochemistry.png',
  'pathology': 'assets/icons/subjects/pathology.png',
  'pharmacology': 'assets/icons/subjects/pharmacology.png',
  'microbiology': 'assets/icons/subjects/microbiology.png',
  'forensic_medicine': 'assets/icons/subjects/forensic_medicine.png',
  'community_medicine': 'assets/icons/subjects/community_medicine.png',
  'ophthalmology': 'assets/icons/subjects/ophthalmology.png',
  'otorhinolaryngology__ent_': 'assets/icons/subjects/otorhinolaryngology__ent_.png',
  'anaesthesia': 'assets/icons/subjects/anaesthesia.png',
  'dermatology': 'assets/icons/subjects/dermatology.png',
  'psychiatry': 'assets/icons/subjects/psychiatry.png',
  'radiology': 'assets/icons/subjects/radiology.png',
  'medicine': 'assets/icons/subjects/medicine.png',
  'surgery': 'assets/icons/subjects/surgery.png',
  'orthopaedics': 'assets/icons/subjects/orthopaedics.png',
  'paediatrics': 'assets/icons/subjects/paediatrics.png',
  'obstetrics___gynaecology': 'assets/icons/subjects/obstetrics___gynaecology.png',
};

const Set<String> _multiColorSubjects = {
  'biochemistry',
  'physiology',
  'microbiology',
  'obstetrics___gynaecology',
};
