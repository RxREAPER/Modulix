import { useRef } from "react"
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion"
import { useTheme } from "../../lib/theme"

export function MedicalHeroIllustration() {
  const { isDark } = useTheme()
  const containerRef = useRef<HTMLDivElement>(null)

  // Subtle interactive 3D mouse tilt (Switch-Lit style)
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)

  const springConfig = { damping: 30, stiffness: 220 }
  const rotateX = useSpring(useTransform(mouseY, [-0.5, 0.5], [5, -5]), springConfig)
  const rotateY = useSpring(useTransform(mouseX, [-0.5, 0.5], [-7, 7]), springConfig)

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!containerRef.current) return
    const rect = containerRef.current.getBoundingClientRect()
    const x = (e.clientX - rect.left) / rect.width - 0.5
    const y = (e.clientY - rect.top) / rect.height - 0.5
    mouseX.set(x)
    mouseY.set(y)
  }

  const handleMouseLeave = () => {
    mouseX.set(0)
    mouseY.set(0)
  }

  return (
    <div
      ref={containerRef}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      onTouchEnd={handleMouseLeave}
      onTouchCancel={handleMouseLeave}
      className="relative w-full max-w-4xl mx-auto flex items-center justify-center select-none perspective-[1200px]"
    >
      <motion.div
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d",
        }}
        className="w-full relative flex items-center justify-center"
      >
        {/* ── Native Master Vector Composition (Gathered from GIF/Artwork) ── */}
        <svg
          viewBox="0 0 920 520"
          className="w-full h-auto max-h-[500px] overflow-visible drop-shadow-md"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="metalChrome" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#94A3B8" />
              <stop offset="45%" stopColor="#FFFFFF" />
              <stop offset="100%" stopColor="#64748B" />
            </linearGradient>

            <linearGradient id="boneSkull" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={isDark ? "#E2E8F0" : "#FFFDF8"} />
              <stop offset="100%" stopColor={isDark ? "#94A3B8" : "#E2D9C8"} />
            </linearGradient>

            <linearGradient id="needleLiquid" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="#0284C7" stopOpacity="0.85" />
              <stop offset="100%" stopColor="#38BDF8" stopOpacity="0.9" />
            </linearGradient>

            <linearGradient id="goldSheen" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#FDE047" />
              <stop offset="100%" stopColor="#CA8A04" />
            </linearGradient>

            {/* Subtle Stippled Paper Background Grid */}
            <pattern id="stipplePaper" width="16" height="16" patternUnits="userSpaceOnUse">
              <circle cx="2" cy="2" r="0.75" fill={isDark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.04)"} />
              <circle cx="10" cy="10" r="0.75" fill={isDark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.04)"} />
            </pattern>
          </defs>

          {/* 0. Canvas Ground Shadow & Paper Texture Backdrop */}
          <rect width="920" height="520" fill="url(#stipplePaper)" rx="24" className="opacity-70" />
          <ellipse cx="460" cy="445" rx="390" ry="24" fill={isDark ? "rgba(0,0,0,0.5)" : "rgba(0,0,0,0.07)"} filter="blur(8px)" />

          {/* 1. LEFT TILTED BURGUNDY TEXTBOOK (Pathology Volume) */}
          <g transform="translate(130, 435) rotate(-24)">
            <rect x="0" y="-195" width="38" height="195" rx="4" fill="#991B1B" stroke="#7F1D1D" strokeWidth="2" />
            <polygon points="38,-195 140,-195 130,0 38,0" fill={isDark ? "#27272A" : "#FAF5EE"} stroke={isDark ? "#3F3F46" : "#E2D9C8"} strokeWidth="1.8" />
            <rect x="135" y="-195" width="6" height="195" rx="2" fill="#B91C1C" stroke="#7F1D1D" strokeWidth="1.5" />
          </g>

          {/* 2. TWO CLINICAL GLASS SYRINGES (Foreground Left) */}
          <g transform="translate(175, 410) rotate(-65)">
            <rect x="0" y="0" width="14" height="75" rx="3" fill={isDark ? "rgba(255,255,255,0.12)" : "rgba(255,255,255,0.8)"} stroke="#64748B" strokeWidth="1.5" />
            <rect x="2" y="15" width="10" height="40" fill="url(#needleLiquid)" rx="1" />
            <line x1="7" y1="-28" x2="7" y2="0" stroke="url(#metalChrome)" strokeWidth="1.5" strokeLinecap="round" />
            <rect x="2" y="75" width="10" height="25" fill="#94A3B8" />
            <line x1="-3" y1="100" x2="17" y2="100" stroke="#64748B" strokeWidth="2.5" />
          </g>
          <g transform="translate(125, 435) rotate(-62)">
            <rect x="0" y="0" width="16" height="85" rx="3" fill={isDark ? "rgba(255,255,255,0.15)" : "rgba(255,255,255,0.85)"} stroke="#475569" strokeWidth="1.8" />
            <rect x="2" y="18" width="12" height="48" fill="url(#needleLiquid)" rx="1" />
            <line x1="3" y1="25" x2="7" y2="25" stroke="#1E293B" strokeWidth="1" />
            <line x1="3" y1="35" x2="9" y2="35" stroke="#1E293B" strokeWidth="1" />
            <line x1="3" y1="45" x2="7" y2="45" stroke="#1E293B" strokeWidth="1" />
            <line x1="3" y1="55" x2="9" y2="55" stroke="#1E293B" strokeWidth="1" />
            <polygon points="5,0 8,-5 11,0" fill="url(#metalChrome)" />
            <line x1="8" y1="-5" x2="8" y2="-34" stroke="url(#metalChrome)" strokeWidth="1.8" strokeLinecap="round" />
            <rect x="3" y="85" width="10" height="28" fill="#64748B" />
            <line x1="-2" y1="113" x2="18" y2="113" stroke="#334155" strokeWidth="3" />
          </g>

          {/* 3. CURVED SAGE GREEN BOOK WITH RED MAP PINS */}
          <g transform="translate(135, 170)">
            <path
              d="M 15 85 Q 90 20 180 50 L 195 110 Q 110 80 15 145 Z"
              fill="#2D7D6E"
              stroke="#1B4D43"
              strokeWidth="2.2"
            />
            <path
              d="M 15 145 Q 110 80 195 110 L 195 125 Q 110 95 15 160 Z"
              fill={isDark ? "#1F2937" : "#F4EFE6"}
              stroke="#1B4D43"
              strokeWidth="1.5"
            />
            {[
              { x: 50, y: 72 },
              { x: 85, y: 55 },
              { x: 125, y: 62 },
              { x: 160, y: 80 },
              { x: 105, y: 85 },
            ].map((p, i) => (
              <g key={i}>
                <line x1={p.x} y1={p.y} x2={p.x} y2={p.y + 10} stroke="#94A3B8" strokeWidth="1.5" />
                <circle cx={p.x} cy={p.y} r="6" fill="#E11D48" stroke="#9F1239" strokeWidth="1.2" />
                <circle cx={p.x - 2} cy={p.y - 2} r="2" fill="#FECDD3" />
              </g>
            ))}
          </g>

          {/* 4. BASE BACK BOOKS (Yellow & Navy Under Open Atlas) */}
          <rect x="220" y="145" width="125" height="55" rx="3" fill="#D97706" stroke="#92400E" strokeWidth="2" />
          <polygon points="345,145 425,145 425,200 345,200" fill={isDark ? "#27272A" : "#F4EFE6"} stroke="#78350F" strokeWidth="1.5" />
          <rect x="250" y="85" width="180" height="60" rx="3" fill="#1E3A8A" stroke="#172554" strokeWidth="2" />

          {/* 5. OPEN ANATOMY ATLAS ON TOP (Breathing Animated Leaves) */}
          <motion.g
            animate={{ y: [0, -2, 0] }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
            transform="translate(250, 45)"
          >
            <path d="M 130 18 L 130 95" stroke="#64748B" strokeWidth="2.5" />
            <path
              d="M 130 18 Q 80 10 10 25 L 12 90 Q 75 75 130 95 Z"
              fill={isDark ? "#1E2024" : "#FFFDF8"}
              stroke="#0F172A"
              strokeWidth="2"
            />
            <path
              d="M 130 18 Q 180 10 250 25 L 248 90 Q 185 75 130 95 Z"
              fill={isDark ? "#1E2024" : "#FFFDF8"}
              stroke="#0F172A"
              strokeWidth="2"
            />
            <line x1="28" y1="36" x2="112" y2="32" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />
            <line x1="28" y1="46" x2="105" y2="42" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />
            <line x1="28" y1="56" x2="114" y2="52" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />
            <line x1="28" y1="66" x2="100" y2="62" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />

            <line x1="148" y1="32" x2="232" y2="36" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />
            <line x1="148" y1="42" x2="225" y2="46" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />
            <line x1="148" y1="52" x2="234" y2="56" stroke={isDark ? "#4B5563" : "#CBD5E1"} strokeWidth="1.5" />
          </motion.g>

          {/* 6. CLINICAL IPAD TABLET (Pulsing Vector ECG Trace) */}
          <g transform="translate(290, 210) rotate(10)">
            <rect x="0" y="0" width="140" height="205" rx="16" fill={isDark ? "#0F172A" : "#1E293B"} stroke="#0F172A" strokeWidth="2.2" />
            <rect x="6" y="6" width="128" height="193" rx="11" fill={isDark ? "#080C14" : "#F0F9FF"} />
            <circle cx="70" cy="11" r="1.5" fill="#64748B" />

            <g transform="translate(10, 50)">
              <line x1="0" y1="20" x2="108" y2="20" stroke={isDark ? "#1E293B" : "#E2E8F0"} strokeWidth="0.8" />
              <line x1="0" y1="50" x2="108" y2="50" stroke={isDark ? "#1E293B" : "#E2E8F0"} strokeWidth="0.8" />
              <line x1="0" y1="80" x2="108" y2="80" stroke={isDark ? "#1E293B" : "#E2E8F0"} strokeWidth="0.8" />

              <motion.path
                d="M 0 50 L 15 50 Q 20 44 25 50 L 32 50 L 35 62 L 42 10 L 48 76 L 53 50 L 60 50 Q 68 38 75 50 L 92 50 Q 96 44 100 50 L 108 50"
                fill="none"
                stroke="#E11D48"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                initial={{ pathLength: 0 }}
                animate={{ pathLength: [0, 1, 1] }}
                transition={{ duration: 2.2, repeat: Infinity, ease: "linear" }}
              />
            </g>

            <text x="14" y="26" fill={isDark ? "#94A3B8" : "#475569"} fontSize="8" fontFamily="monospace" fontWeight="700">
              LEAD II · 72 BPM
            </text>
            <circle cx="98" cy="23" r="3" fill="#10B981" />
          </g>

          {/* 7. FOREGROUND ANATOMICAL SKULL (Pure Vector Craniometry) */}
          <g transform="translate(390, 395)">
            <ellipse cx="44" cy="46" rx="42" ry="10" fill="rgba(0,0,0,0.22)" filter="blur(3px)" />
            <path
              d="M 12 30 C 10 5, 78 5, 76 30 C 76 40, 68 46, 68 52 L 20 52 C 20 46, 12 40, 12 30 Z"
              fill="url(#boneSkull)"
              stroke="#1C1917"
              strokeWidth="2.2"
            />
            <rect x="26" y="52" width="36" height="15" rx="3" fill="url(#boneSkull)" stroke="#1C1917" strokeWidth="2" />
            <ellipse cx="28" cy="34" rx="8" ry="11" fill="#1C1917" />
            <ellipse cx="60" cy="34" rx="8" ry="11" fill="#1C1917" />
            <path d="M 44 38 L 41 47 L 47 47 Z" fill="#1C1917" />
            <line x1="33" y1="52" x2="33" y2="67" stroke="#1C1917" strokeWidth="1.5" />
            <line x1="40" y1="52" x2="40" y2="67" stroke="#1C1917" strokeWidth="1.5" />
            <line x1="48" y1="52" x2="48" y2="67" stroke="#1C1917" strokeWidth="1.5" />
            <line x1="55" y1="52" x2="55" y2="67" stroke="#1C1917" strokeWidth="1.5" />
          </g>

          {/* 8. MAIN TALL MEDICAL BOOK STACK (Center-Right) */}
          <g transform="translate(470, 395)">
            <rect x="0" y="0" width="280" height="36" rx="4" fill="#C86D51" stroke="#9A3412" strokeWidth="2.2" />
            <rect x="18" y="4" width="254" height="28" fill={isDark ? "#27272A" : "#FFFDF8"} stroke="#9A3412" strokeWidth="1.5" />
            <line x1="25" y1="12" x2="265" y2="12" stroke={isDark ? "#3F3F46" : "#E2E8F0"} strokeWidth="1" />
            <line x1="25" y1="20" x2="265" y2="20" stroke={isDark ? "#3F3F46" : "#E2E8F0"} strokeWidth="1" />
          </g>

          <g transform="translate(450, 345)">
            <rect x="0" y="0" width="295" height="50" rx="4" fill="#1E293B" stroke="#0F172A" strokeWidth="2.2" />
            <rect x="22" y="6" width="265" height="38" fill={isDark ? "#27272A" : "#FFFDF8"} stroke="#0F172A" strokeWidth="1.5" />
            <rect x="250" y="10" width="6" height="30" fill="url(#goldSheen)" rx="1" />
            <rect x="262" y="10" width="6" height="30" fill="url(#goldSheen)" rx="1" />
            <path d="M 120 44 Q 115 75 125 90 L 133 85 L 140 90 Q 130 75 128 44 Z" fill="#DC2626" />
          </g>

          <g transform="translate(460, 290)">
            <rect x="0" y="0" width="285" height="55" rx="4" fill="#5B9EA6" stroke="#2E6B74" strokeWidth="2.2" />
            <rect x="20" y="6" width="255" height="43" fill={isDark ? "#27272A" : "#FFFDF8"} stroke="#2E6B74" strokeWidth="1.8" />
            <rect x="75" y="-5" width="26" height="15" rx="2" fill="#F59E0B" stroke="#D97706" strokeWidth="1" />
          </g>

          {/* 9. THE WOODEN LADDER */}
          <g transform="translate(640, 275)">
            <line x1="0" y1="170" x2="35" y2="0" stroke="#795548" strokeWidth="4.5" strokeLinecap="round" />
            <line x1="0" y1="170" x2="35" y2="0" stroke="#3E2723" strokeWidth="1" />
            <line x1="38" y1="170" x2="73" y2="0" stroke="#795548" strokeWidth="4.5" strokeLinecap="round" />
            <line x1="38" y1="170" x2="73" y2="0" stroke="#3E2723" strokeWidth="1" />
            <line x1="5" y1="145" x2="43" y2="145" stroke="#8D6E63" strokeWidth="3" />
            <line x1="11" y1="116" x2="49" y2="116" stroke="#8D6E63" strokeWidth="3" />
            <line x1="17" y1="87" x2="55" y2="87" stroke="#8D6E63" strokeWidth="3" />
            <line x1="23" y1="58" x2="61" y2="58" stroke="#8D6E63" strokeWidth="3" />
            <line x1="29" y1="29" x2="67" y2="29" stroke="#8D6E63" strokeWidth="3" />
            <line x1="35" y1="4" x2="73" y2="4" stroke="#8D6E63" strokeWidth="3" />
          </g>

          {/* 10. THE ANIMATED ÉCORCHÉ ANATOMY CLIMBER (Hero Figure) */}
          <motion.g
            animate={{
              x: [640, 652, 664, 676, 688, 700, 700, 700, 640],
              y: [405, 370, 335, 300, 260, 240, 240, 240, 405],
              rotate: [16, 14, 12, 8, 3, 0, 0, 0, 16],
            }}
            transition={{
              duration: 8.5,
              repeat: Infinity,
              times: [0, 0.16, 0.32, 0.48, 0.64, 0.78, 0.90, 0.96, 1],
              ease: "easeInOut",
            }}
          >
            <circle cx="0" cy="-4" r="6" fill="#F87171" stroke="#DC2626" strokeWidth="1.2" />
            <path d="M -3 -6 Q 0 -9 3 -6" stroke="#FEF2F2" strokeWidth="1" fill="none" />
            <path d="M -6 4 L -8 20 L -4 28 L 4 28 L 8 20 L 6 4 Z" fill="#DC2626" stroke="#991B1B" strokeWidth="1.4" />
            <line x1="0" y1="4" x2="0" y2="28" stroke="#FEF2F2" strokeWidth="1.2" />
            <line x1="-5" y1="12" x2="5" y2="12" stroke="#FEF2F2" strokeWidth="0.8" />
            <line x1="-6" y1="18" x2="6" y2="18" stroke="#FEF2F2" strokeWidth="0.8" />
            <path d="M -6 6 Q -14 12 -10 22" fill="none" stroke="#DC2626" strokeWidth="3.2" strokeLinecap="round" />
            <path d="M 6 6 Q 14 12 10 22" fill="none" stroke="#DC2626" strokeWidth="3.2" strokeLinecap="round" />
            <path d="M -4 28 Q -8 40 -5 52 L -9 55" fill="none" stroke="#DC2626" strokeWidth="3.8" strokeLinecap="round" />
            <path d="M 4 28 Q 8 40 5 52 L 9 55" fill="none" stroke="#DC2626" strokeWidth="3.8" strokeLinecap="round" />
            <circle cx="-6.5" cy="40" r="1.2" fill="#FEF2F2" />
            <circle cx="6.5" cy="40" r="1.2" fill="#FEF2F2" />
          </motion.g>

          {/* 11. UPPER RIGHT ARCHIVAL WHITE BOOKS & STETHOSCOPE */}
          <g transform="translate(540, 160)">
            <rect x="0" y="0" width="220" height="42" rx="3" fill={isDark ? "#27272A" : "#FFFFFF"} stroke="#64748B" strokeWidth="2" />
            <rect x="0" y="42" width="235" height="38" rx="3" fill="#E11D48" stroke="#9F1239" strokeWidth="2" />
            <rect x="0" y="80" width="245" height="45" rx="3" fill="#0D9488" stroke="#115E59" strokeWidth="2" />

            <g transform="translate(45, -8)">
              <rect x="0" y="0" width="115" height="7" rx="3" fill="#1E3A8A" stroke="#172554" strokeWidth="1" />
              <polygon points="115,0 128,3.5 115,7" fill="url(#metalChrome)" />
              <rect x="25" y="-1" width="12" height="9" fill="url(#goldSheen)" rx="1" />
            </g>
          </g>

          {/* 12. LITTMANN STETHOSCOPE (Looping Vector Tubing) */}
          <g>
            <path
              d="M 680 160 C 720 180, 850 250, 780 340 C 720 410, 620 320, 680 230"
              fill="none"
              stroke="rgba(0,0,0,0.18)"
              strokeWidth="11"
              strokeLinecap="round"
            />
            <path
              d="M 680 160 C 720 180, 850 250, 780 340 C 720 410, 620 320, 680 230"
              fill="none"
              stroke={isDark ? "#111827" : "#1E293B"}
              strokeWidth="8.5"
              strokeLinecap="round"
            />
            <path
              d="M 680 160 C 670 130, 690 95, 715 85"
              fill="none"
              stroke="url(#metalChrome)"
              strokeWidth="4"
              strokeLinecap="round"
            />
            <path
              d="M 680 160 C 700 140, 735 125, 750 115"
              fill="none"
              stroke="url(#metalChrome)"
              strokeWidth="4"
              strokeLinecap="round"
            />
            <circle cx="715" cy="85" r="3.5" fill="#0F172A" />
            <circle cx="750" cy="115" r="3.5" fill="#0F172A" />

            <g transform="translate(680, 230)">
              <circle cx="0" cy="0" r="22" fill="url(#metalChrome)" stroke="#475569" strokeWidth="1.2" />
              <circle cx="0" cy="0" r="18" fill={isDark ? "#1F2937" : "#334155"} />
              <circle cx="0" cy="0" r="15" fill={isDark ? "#0F172A" : "#F8FAFC"} />
              <circle cx="0" cy="0" r="4.5" fill="url(#metalChrome)" />
            </g>
          </g>

          {/* 13. RIGHTMOST SUPPORTING BOOKS */}
          <g transform="translate(730, 310)">
            <rect x="0" y="0" width="135" height="60" rx="3" fill="#EA580C" stroke="#9A3412" strokeWidth="2.2" />
            <rect x="0" y="60" width="145" height="65" rx="3" fill="#CA8A04" stroke="#854D0E" strokeWidth="2.2" />
          </g>
        </svg>
      </motion.div>
    </div>
  )
}
