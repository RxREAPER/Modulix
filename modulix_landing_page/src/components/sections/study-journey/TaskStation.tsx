import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { PlayCircle, HelpCircle, FileText, RotateCcw, ArrowUp, Calendar, Flag, Check } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TaskStation({ isActive }: StationProps) {
  const { isDark } = useTheme()
  const [typedText, setTypedText] = useState("")
  const [selectedType, setSelectedType] = useState<string | null>(null)
  const [isSubmitted, setIsSubmitted] = useState(false)

  const fullText = "Robbins Pathology · Neoplasia"

  // 4 Task Types strictly from tasks_quick_add_sheet.dart
  const taskTypes = [
    { name: "Video", duration: 35, icon: PlayCircle, color: "#3B82F6" },
    { name: "Q-Bank", duration: 40, icon: HelpCircle, color: "#10B981" },
    { name: "Notes", duration: 25, icon: FileText, color: "#F59E0B" },
    { name: "Revision", duration: 20, icon: RotateCcw, color: "#8B5CF6" },
  ]

  useEffect(() => {
    if (!isActive) {
      setTypedText("")
      setSelectedType(null)
      setIsSubmitted(false)
      return
    }

    // Step 1: Type out the task text
    let index = 0
    setTypedText("")
    setIsSubmitted(false)
    setSelectedType(null)

    const typeInterval = setInterval(() => {
      index++
      if (index <= fullText.length) {
        setTypedText(fullText.slice(0, index))
      } else {
        clearInterval(typeInterval)
        // Step 2: Select 'Video · 35m'
        setTimeout(() => {
          setSelectedType("Video")
        }, 300)
        // Step 3: Trigger submit pulse
        setTimeout(() => {
          setIsSubmitted(true)
        }, 900)
      }
    }, 45)

    return () => clearInterval(typeInterval)
  }, [isActive])

  return (
    <div className="w-full flex flex-col items-center justify-center p-2 sm:p-4 select-none">
      {/* ── Docked Quick Add Sheet (TasksQuickAddSheet) ── */}
      <motion.div
        layout
        className={`w-full max-w-sm rounded-2xl border p-4 shadow-lg transition-colors relative overflow-hidden ${
          isDark
            ? "bg-[#18191D] border-white/10 shadow-[0_12px_32px_rgba(0,0,0,0.5)]"
            : "bg-[#FCFAF5] border-[#E8DEC8] shadow-[0_10px_28px_rgba(0,0,0,0.06)]"
        }`}
      >
        {/* Top Handle Bar */}
        <div className="w-9 h-1 rounded-full bg-black/15 dark:bg-white/15 mx-auto mb-3" />

        {/* Header Label: Daily Desk // Quick Add */}
        <div className="flex items-center justify-between pb-2 mb-2 border-b border-black/[0.06] dark:border-white/[0.06] text-[10px] font-mono tracking-wider opacity-60">
          <span className="font-semibold">DAILY DESK · QUICK ADD</span>
          <span>EST. 35 MIN</span>
        </div>

        {/* Text Input Row */}
        <div className="flex items-center gap-2.5 py-1">
          <div className="w-5 h-5 rounded-full border border-black/20 dark:border-white/20 flex items-center justify-center flex-shrink-0">
            {isSubmitted ? (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 400, damping: 20 }}
              >
                <Check size={12} className="text-[#10B981] stroke-[2.5]" />
              </motion.div>
            ) : (
              <div className="w-1.5 h-1.5 rounded-full bg-black/20 dark:bg-white/20" />
            )}
          </div>

          {/* Typing Input Field */}
          <div className="flex-1 font-mono text-xs sm:text-sm font-medium text-[var(--ink-foreground)] flex items-center min-h-[22px]">
            <span>{typedText || <span className="opacity-40 font-sans">What needs to get done?</span>}</span>
            {isActive && !isSubmitted && (
              <motion.span
                animate={{ opacity: [1, 0, 1] }}
                transition={{ duration: 0.8, repeat: Infinity }}
                className="w-[2px] h-4 bg-[var(--accent)] ml-0.5"
              />
            )}
          </div>

          {/* Submit Action Button (IconButton with arrow_upward_rounded) */}
          <motion.div
            animate={{
              scale: isSubmitted ? [1, 1.2, 1] : 1,
              backgroundColor: isSubmitted ? "#10B981" : "var(--accent)",
            }}
            transition={{ duration: 0.3 }}
            className="w-7 h-7 rounded-full text-white flex items-center justify-center shadow-sm cursor-pointer"
          >
            <ArrowUp size={15} className="stroke-[2.5]" />
          </motion.div>
        </div>

        {/* 4 Task Type Selector Pills (Video, Q-Bank, Notes, Revision) */}
        <div className="flex items-center gap-1.5 overflow-x-auto py-2.5 scrollbar-none">
          {taskTypes.map((type) => {
            const Icon = type.icon
            const isSelected = selectedType === type.name
            return (
              <motion.div
                key={type.name}
                animate={{
                  scale: isSelected ? 1.05 : 1,
                  backgroundColor: isSelected
                    ? `${type.color}1F`
                    : isDark
                    ? "rgba(255,255,255,0.03)"
                    : "rgba(0,0,0,0.02)",
                  borderColor: isSelected ? type.color : isDark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.08)",
                }}
                transition={{ duration: 0.2 }}
                className="flex items-center gap-1 px-2 py-1 rounded-lg border text-[11px] font-medium whitespace-nowrap cursor-pointer transition-colors"
                style={{
                  color: isSelected ? type.color : "var(--muted-text)",
                }}
              >
                <Icon size={12} style={{ color: isSelected ? type.color : undefined }} />
                <span>
                  {type.name} · {type.duration}m
                </span>
              </motion.div>
            )
          })}
        </div>

        {/* Accessory Bar (Date, Priority, Project) */}
        <div className="pt-2 border-t border-black/[0.05] dark:border-white/[0.05] flex items-center gap-2 text-[10px] font-mono text-[var(--muted-text)]">
          <div className="flex items-center gap-1 px-1.5 py-0.5 rounded border border-black/10 dark:border-white/10">
            <Calendar size={10} />
            <span>Today</span>
          </div>

          <div className="flex items-center gap-1 px-1.5 py-0.5 rounded border border-red-500/30 text-red-500 font-semibold">
            <Flag size={10} />
            <span>P1 Urgent</span>
          </div>

          <div className="flex items-center gap-1.5 ml-auto opacity-70">
            <div className="w-1.5 h-1.5 rounded-full bg-[#DC2626]" />
            <span>Edition 8.0</span>
          </div>
        </div>

        {/* Ink Strikethrough Effect when submitted */}
        <AnimatePresence>
          {isSubmitted && (
            <motion.div
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
              className="absolute left-10 top-[4.7rem] h-[1.5px] bg-[var(--accent)] origin-left pointer-events-none"
              style={{ width: "65%" }}
            />
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  )
}
