import { useRef } from "react"
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion"
import { useTheme } from "../../lib/theme"

export function MedicalHeroIllustration() {
  const { isDark } = useTheme()
  const containerRef = useRef<HTMLDivElement>(null)

  // Interactive 3D mouse tilt
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)

  const springConfig = { damping: 25, stiffness: 200 }
  const rotateX = useSpring(useTransform(mouseY, [-0.5, 0.5], [10, -10]), springConfig)
  const rotateY = useSpring(useTransform(mouseX, [-0.5, 0.5], [-14, 14]), springConfig)

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
      className="relative w-full max-w-2xl mx-auto h-[320px] sm:h-[400px] flex items-center justify-center cursor-pointer select-none perspective-[1200px]"
    >
      {/* 3D Motion Container */}
      <motion.div
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d",
        }}
        animate={{
          y: [0, -7, 0],
        }}
        transition={{
          repeat: Infinity,
          duration: 4.8,
          ease: "easeInOut",
        }}
        className="relative w-[340px] sm:w-[480px] h-[280px] sm:h-[350px] flex items-center justify-center"
      >
        {/* Ambient Glow Base beneath workstation */}
        <div
          className="absolute -bottom-4 w-72 sm:w-96 h-16 rounded-full blur-2xl opacity-40 transition-colors pointer-events-none"
          style={{
            background: isDark
              ? "radial-gradient(circle, rgba(10, 132, 255, 0.45) 0%, transparent 70%)"
              : "radial-gradient(circle, rgba(0, 122, 255, 0.3) 0%, transparent 70%)",
            transform: "translateZ(-40px)",
          }}
        />

        {/* Master SVG Composition */}
        <svg
          viewBox="0 0 520 380"
          className="w-full h-full overflow-visible drop-shadow-md"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            {/* Gradients */}
            <linearGradient id="bookCoverBlue" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor={isDark ? "#1E3A8A" : "#2563EB"} />
              <stop offset="100%" stopColor={isDark ? "#0F172A" : "#1D4ED8"} />
            </linearGradient>

            <linearGradient id="bookCoverTeal" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor={isDark ? "#065F46" : "#0D9488"} />
              <stop offset="100%" stopColor={isDark ? "#022C22" : "#0F766E"} />
            </linearGradient>

            <linearGradient id="bookCoverBurgundy" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor={isDark ? "#701A75" : "#9D174D"} />
              <stop offset="100%" stopColor={isDark ? "#380438" : "#831843"} />
            </linearGradient>

            <linearGradient id="ipadGlass" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={isDark ? "#18181B" : "#F8FAFC"} />
              <stop offset="100%" stopColor={isDark ? "#09090B" : "#EDE9FE"} />
            </linearGradient>

            <linearGradient id="metalChrome" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="#E2E8F0" />
              <stop offset="50%" stopColor="#FFFFFF" />
              <stop offset="100%" stopColor="#94A3B8" />
            </linearGradient>

            <linearGradient id="liquidBlue" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="#38BDF8" stopOpacity="0.8" />
              <stop offset="100%" stopColor="#0284C7" stopOpacity="0.9" />
            </linearGradient>
          </defs>

          {/* ── LAYER 1: BASE STACKED MEDICAL BOOKS ────────────────────── */}
          {/* Bottom Heavy Book: Harrison's Internal Medicine */}
          <g style={{ transform: "translate(90px, 175px)" }}>
            {/* Pages edge */}
            <path
              d="M 25 32 L 290 32 L 310 18 L 45 18 Z"
              fill={isDark ? "#27272A" : "#F4F4F5"}
              stroke={isDark ? "#3F3F46" : "#E4E4E7"}
              strokeWidth="1.2"
            />
            {/* Front cover */}
            <rect
              x="20"
              y="32"
              width="275"
              height="28"
              rx="4"
              fill="url(#bookCoverBurgundy)"
              stroke={isDark ? "#86198F" : "#701A75"}
              strokeWidth="1.2"
            />
            {/* Spine detail */}
            <rect x="20" y="32" width="22" height="28" rx="2" fill={isDark ? "#4A044E" : "#831843"} />
            <text
              x="60"
              y="50"
              fill="#FDF4FF"
              fontSize="10"
              fontFamily="Georgia, serif"
              fontStyle="italic"
              letterSpacing="0.5"
              opacity="0.95"
            >
              HARRISON'S INTERNAL MEDICINE · ED. 21
            </text>
          </g>

          {/* Middle Book: Robbins Pathology */}
          <g style={{ transform: "translate(75px, 142px)" }}>
            <path
              d="M 22 26 L 275 26 L 295 14 L 42 14 Z"
              fill={isDark ? "#27272A" : "#FAFAFA"}
              stroke={isDark ? "#3F3F46" : "#E4E4E7"}
              strokeWidth="1.2"
            />
            <rect
              x="18"
              y="26"
              width="262"
              height="25"
              rx="4"
              fill="url(#bookCoverTeal)"
              stroke={isDark ? "#065F46" : "#0F766E"}
              strokeWidth="1.2"
            />
            <rect x="18" y="26" width="20" height="25" rx="2" fill={isDark ? "#022C22" : "#115E59"} />
            <text
              x="55"
              y="42"
              fill="#ECFDF5"
              fontSize="10"
              fontFamily="Georgia, serif"
              fontStyle="italic"
              letterSpacing="0.5"
              opacity="0.95"
            >
              ROBBINS CLINICAL PATHOLOGY
            </text>
          </g>

          {/* Top Book: Gray's Anatomy */}
          <g style={{ transform: "translate(60px, 112px)" }}>
            <path
              d="M 20 24 L 260 24 L 278 12 L 38 12 Z"
              fill={isDark ? "#27272A" : "#FFFFFF"}
              stroke={isDark ? "#3F3F46" : "#E4E4E7"}
              strokeWidth="1.2"
            />
            <rect
              x="16"
              y="24"
              width="248"
              height="24"
              rx="4"
              fill="url(#bookCoverBlue)"
              stroke={isDark ? "#1E40AF" : "#1D4ED8"}
              strokeWidth="1.2"
            />
            <rect x="16" y="24" width="18" height="24" rx="2" fill={isDark ? "#0F172A" : "#1E3A8A"} />
            {/* Golden Bookmark ribbon hanging out */}
            <path
              d="M 180 24 L 180 58 L 186 52 L 192 58 L 192 24 Z"
              fill="#F59E0B"
              stroke="#D97706"
              strokeWidth="0.8"
            />
            <text
              x="50"
              y="39"
              fill="#EFF6FF"
              fontSize="10"
              fontFamily="Georgia, serif"
              fontStyle="italic"
              letterSpacing="0.5"
              opacity="0.95"
            >
              GRAY'S ANATOMY · 19 SUBJECTS
            </text>
          </g>

          {/* ── LAYER 2: IPAD / TABLET (Tilted on top of books) ───────── */}
          <g style={{ transform: "translate(80px, 35px)" }}>
            {/* iPad Chassis */}
            <rect
              x="25"
              y="18"
              width="215"
              height="145"
              rx="14"
              fill={isDark ? "#09090B" : "#F8FAFC"}
              stroke={isDark ? "#3F3F46" : "#CBD5E1"}
              strokeWidth="2.5"
            />
            {/* Screen Bezel */}
            <rect
              x="33"
              y="26"
              width="199"
              height="129"
              rx="8"
              fill={isDark ? "#121214" : "#FFFFFF"}
              stroke={isDark ? "#27272A" : "#E2E8F0"}
              strokeWidth="1"
            />

            {/* Modulix Screen Content */}
            {/* Screen Header */}
            <circle cx="48" cy="40" r="4.5" fill="#3B82F6" />
            <rect x="58" y="38" width="55" height="5" rx="2.5" fill={isDark ? "#E4E4E7" : "#0F172A"} />
            <rect x="195" y="38" width="24" height="5" rx="2.5" fill="#10B981" />

            {/* Mini Study Desk Clock / Focus Timer Widget */}
            <rect
              x="42"
              y="52"
              width="181"
              height="40"
              rx="6"
              fill={isDark ? "#1E293B" : "#F1F5F9"}
              stroke={isDark ? "#334155" : "#E2E8F0"}
              strokeWidth="0.8"
            />
            <circle cx="58" cy="72" r="10" fill="#007AFF" />
            {/* Play icon inside timer circle */}
            <polygon points="56,68 63,72 56,76" fill="#FFFFFF" />
            <text
              x="76"
              y="70"
              fill={isDark ? "#FFFFFF" : "#0F172A"}
              fontSize="11"
              fontWeight="bold"
              fontFamily="system-ui, sans-serif"
            >
              25:00
            </text>
            <text
              x="76"
              y="81"
              fill={isDark ? "#94A3B8" : "#64748B"}
              fontSize="8"
              fontFamily="system-ui, sans-serif"
            >
              Neuroanatomy · Unit 04 Focus
            </text>

            {/* Checklist / Modules on iPad screen */}
            <rect x="42" y="100" width="181" height="15" rx="4" fill={isDark ? "#18181B" : "#F8FAFC"} />
            <circle cx="52" cy="107.5" r="3.5" fill="#10B981" />
            <rect x="62" y="105.5" width="85" height="4" rx="2" fill={isDark ? "#A1A1AA" : "#64748B"} />
            <rect x="195" y="105.5" width="18" height="4" rx="2" fill={isDark ? "#3F3F46" : "#CBD5E1"} />

            <rect x="42" y="120" width="181" height="15" rx="4" fill={isDark ? "#18181B" : "#F8FAFC"} />
            <circle cx="52" cy="127.5" r="3.5" fill="#F59E0B" />
            <rect x="62" y="125.5" width="105" height="4" rx="2" fill={isDark ? "#A1A1AA" : "#64748B"} />
            <rect x="190" y="125.5" width="23" height="4" rx="2" fill="#F59E0B" opacity="0.8" />
          </g>

          {/* ── LAYER 3: ANATOMICAL SKULL (Artistic Line Work) ─────────── */}
          <g style={{ transform: "translate(345px, 60px)" }}>
            {/* Skull Cranium */}
            <path
              d="M 45 10 C 20 10 5 30 5 58 C 5 78 18 96 28 108 L 28 124 C 28 128 32 132 36 132 L 64 132 C 68 132 72 128 72 124 L 72 108 C 82 96 95 78 95 58 C 95 30 80 10 45 10 Z"
              fill={isDark ? "#18181B" : "#F8FAFC"}
              stroke={isDark ? "#A1A1AA" : "#64748B"}
              strokeWidth="2.2"
              strokeLinejoin="round"
            />
            {/* Temporal line sutures */}
            <path
              d="M 45 10 Q 52 28 48 42"
              stroke={isDark ? "#52525B" : "#CBD5E1"}
              strokeWidth="1.2"
              strokeDasharray="2 2"
            />
            {/* Eye sockets */}
            <ellipse
              cx="30"
              cy="62"
              rx="11"
              ry="13"
              fill={isDark ? "#09090B" : "#E2E8F0"}
              stroke={isDark ? "#71717A" : "#94A3B8"}
              strokeWidth="1.8"
            />
            <ellipse
              cx="68"
              cy="62"
              rx="11"
              ry="13"
              fill={isDark ? "#09090B" : "#E2E8F0"}
              stroke={isDark ? "#71717A" : "#94A3B8"}
              strokeWidth="1.8"
            />
            {/* Nasal cavity */}
            <path
              d="M 49 76 L 45 92 L 53 92 Z"
              fill={isDark ? "#09090B" : "#E2E8F0"}
              stroke={isDark ? "#71717A" : "#94A3B8"}
              strokeWidth="1.5"
            />
            {/* Maxilla & Teeth vertical lines */}
            <line x1="36" y1="118" x2="64" y2="118" stroke={isDark ? "#71717A" : "#94A3B8"} strokeWidth="1.5" />
            <line x1="42" y1="114" x2="42" y2="126" stroke={isDark ? "#71717A" : "#94A3B8"} strokeWidth="1.5" />
            <line x1="49" y1="114" x2="49" y2="126" stroke={isDark ? "#71717A" : "#94A3B8"} strokeWidth="1.5" />
            <line x1="56" y1="114" x2="56" y2="126" stroke={isDark ? "#71717A" : "#94A3B8"} strokeWidth="1.5" />
          </g>

          {/* ── LAYER 4: STETHOSCOPE ───────────────────────────────────── */}
          <g style={{ transform: "translate(20px, 45px)" }}>
            {/* Tubing flowing across the workspace */}
            <path
              d="M 40 160 C 20 220, 110 300, 240 285 C 340 270, 390 220, 360 170 C 340 140, 290 150, 270 200 C 255 240, 220 255, 185 245"
              fill="none"
              stroke={isDark ? "#0A84FF" : "#007AFF"}
              strokeWidth="6"
              strokeLinecap="round"
            />
            {/* Binaural Chrome Tubes */}
            <path
              d="M 38 160 L 25 110 C 22 95, 32 82, 48 82 L 58 82"
              fill="none"
              stroke="url(#metalChrome)"
              strokeWidth="4"
              strokeLinecap="round"
            />
            <path
              d="M 42 160 L 52 110 C 55 95, 68 85, 84 85 L 94 85"
              fill="none"
              stroke="url(#metalChrome)"
              strokeWidth="4"
              strokeLinecap="round"
            />
            {/* Earpieces */}
            <circle cx="58" cy="82" r="3.5" fill={isDark ? "#27272A" : "#334155"} />
            <circle cx="94" cy="85" r="3.5" fill={isDark ? "#27272A" : "#334155"} />

            {/* Chestpiece / Bell sitting gracefully at bottom right */}
            <circle cx="185" cy="245" r="18" fill="url(#metalChrome)" stroke="#64748B" strokeWidth="1.5" />
            <circle cx="185" cy="245" r="13" fill={isDark ? "#18181B" : "#F1F5F9"} stroke="#94A3B8" strokeWidth="1" />
            <circle cx="185" cy="245" r="5" fill={isDark ? "#007AFF" : "#3B82F6"} />
          </g>

          {/* ── LAYER 5: SURGICAL SCALPEL ──────────────────────────────── */}
          <g style={{ transform: "translate(300px, 260px) rotate(-16deg)" }}>
            {/* Handle */}
            <path
              d="M 0 5 L 120 5 C 124 5 128 7 132 10 L 145 10 L 145 0 L 132 0 C 128 3 124 5 120 5 Z"
              fill="url(#metalChrome)"
              stroke="#64748B"
              strokeWidth="0.8"
            />
            {/* Grip ridges */}
            <line x1="50" y1="2" x2="50" y2="8" stroke="#475569" strokeWidth="0.8" />
            <line x1="60" y1="2" x2="60" y2="8" stroke="#475569" strokeWidth="0.8" />
            <line x1="70" y1="2" x2="70" y2="8" stroke="#475569" strokeWidth="0.8" />
            <line x1="80" y1="2" x2="80" y2="8" stroke="#475569" strokeWidth="0.8" />
            {/* Scalpel Blade (No. 10 curved belly) */}
            <path
              d="M 145 10 C 158 11, 185 8, 192 -2 C 175 1, 155 -1, 145 0 Z"
              fill="#F8FAFC"
              stroke="#94A3B8"
              strokeWidth="1.2"
            />
          </g>

          {/* ── LAYER 6: CLINICAL GRADUATED SYRINGE ─────────────────────── */}
          <g style={{ transform: "translate(65px, 265px) rotate(8deg)" }}>
            {/* Barrel Glass Tube */}
            <rect
              x="20"
              y="5"
              width="85"
              height="22"
              rx="3"
              fill={isDark ? "rgba(255,255,255,0.08)" : "rgba(255,255,255,0.8)"}
              stroke={isDark ? "#71717A" : "#94A3B8"}
              strokeWidth="1.5"
            />
            {/* Liquid inside */}
            <rect x="23" y="8" width="55" height="16" rx="2" fill="url(#liquidBlue)" />
            {/* Plunger */}
            <rect x="75" y="9" width="38" height="14" fill={isDark ? "#3F3F46" : "#CBD5E1"} />
            <line x1="113" y1="2" x2="113" y2="30" stroke={isDark ? "#71717A" : "#64748B"} strokeWidth="2.5" />
            {/* Graduation lines */}
            <line x1="35" y1="5" x2="35" y2="10" stroke={isDark ? "#E4E4E7" : "#0F172A"} strokeWidth="1" />
            <line x1="45" y1="5" x2="45" y2="12" stroke={isDark ? "#E4E4E7" : "#0F172A"} strokeWidth="1" />
            <line x1="55" y1="5" x2="55" y2="10" stroke={isDark ? "#E4E4E7" : "#0F172A"} strokeWidth="1" />
            <line x1="65" y1="5" x2="65" y2="12" stroke={isDark ? "#E4E4E7" : "#0F172A"} strokeWidth="1" />
            {/* Needle hub & steel needle */}
            <polygon points="20,11 12,13 12,19 20,21" fill="url(#metalChrome)" />
            <line x1="12" y1="16" x2="-22" y2="16" stroke="url(#metalChrome)" strokeWidth="1.5" strokeLinecap="round" />
          </g>
        </svg>
      </motion.div>
    </div>
  )
}
