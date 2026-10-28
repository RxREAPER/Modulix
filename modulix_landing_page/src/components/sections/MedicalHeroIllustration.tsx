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
      className="relative w-full max-w-3xl mx-auto flex items-center justify-center select-none perspective-[1200px]"
    >
      <motion.div
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d",
        }}
        className={`w-full aspect-video rounded-2xl sm:rounded-3xl overflow-hidden border shadow-xl relative ${
          isDark
            ? "border-white/10 bg-[#16171B] shadow-[0_20px_50px_rgba(0,0,0,0.5)]"
            : "border-black/[0.08] bg-[#FBF9F5] shadow-[0_16px_40px_rgba(0,0,0,0.06)]"
        }`}
      >
        <video
          autoPlay
          loop
          muted
          playsInline
          preload="auto"
          poster="/hero/poster.jpg"
          className="w-full h-full object-cover"
        >
          <source src="/hero/FINAL.mp4" type="video/mp4" />
          {/* Fallback for environments where video is disabled */}
          <img
            src="/hero/FINAL.gif"
            alt="Modulix Clinical Study Illustration"
            className="w-full h-full object-cover"
          />
        </video>
      </motion.div>
    </div>
  )
}
