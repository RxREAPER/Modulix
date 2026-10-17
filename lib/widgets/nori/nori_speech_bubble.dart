import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NoriSpeechBubble extends StatelessWidget {
  final String text;
  final String? badge;
  final VoidCallback? onTap;

  const NoriSpeechBubble({
    super.key,
    required this.text,
    this.badge,
    this.onTap,
  });

  static const List<String> highYieldPearls = [
    'DOC for acute anaphylaxis? IM Adrenaline 1:1000 in anterolateral thigh!',
    'Most common cause of Postpartum Hemorrhage? Uterine Atony!',
    'Rule out Ectopic Pregnancy first in any acute lower abdominal pain in reproductive age!',
    'Penta of TTP: FAT RN (Fever, Anemia, Thrombocytopenia, Renal, Neuro)!',
    'Drug of choice for PSVT? Rapid intravenous push of Adenosine!',
    'Bence Jones proteins are light chains detected in urine heat test, not serum electrophoresis!',
    'Painless hematuria in an elderly smoker = Bladder Carcinoma until proven otherwise!',
    'First line for Status Epilepticus: IV Lorazepam 0.1 mg/kg!',
    'Classic triad of Normal Pressure Hydrocephalus: Wet, Wobbly, Wacky (Incontinence, Ataxia, Dementia)!',
    'Most common pathogen in Community Acquired Pneumonia: Streptococcus pneumoniae!',
    'DOC for Trigeminal Neuralgia: Carbamazepine!',
    'Aspirin toxicity signs: Respiratory alkalosis first, then mixed Metabolic Acidosis!',
    'Beck\'s Triad in Cardiac Tamponade: Hypotension, JVD, Muffled Heart Sounds!',
    'Curtain-falling vision loss (Amaurosis Fugax) suggests Carotid Artery stenosis / embolus!',
    'Most sensitive enzyme for early Acute Pancreatitis: Serum Lipase!',
    'Primary hyperaldosteronism (Conn syndrome): HTN + Hypokalemia with suppressed Plasma Renin!',
    'Charcot\'s Triad in Acute Cholangitis: Fever, Jaundice, RUQ Pain (+ Shock/AMS = Reynolds Pentad)!',
    'Most common primary cardiac tumor in adults: Left Atrial Myxoma!',
    'DOC for Paracetamol (Acetaminophen) toxicity: N-Acetylcysteine (NAC)!',
    'Virchow\'s Triad for Thrombosis: Endothelial injury, Stasis, Hypercoagulability!',
  ];

  static String getRandomPearl() {
    final rand = math.Random();
    return highYieldPearls[rand.nextInt(highYieldPearls.length)];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.sketchBorderColor,
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x181C1C1C),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFE5F55), // Coral
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFFFE5F55),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
