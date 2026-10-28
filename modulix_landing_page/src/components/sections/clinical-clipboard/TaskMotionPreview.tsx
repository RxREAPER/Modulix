import { useState } from "react"
import { motion } from "framer-motion"

export function TaskMotionPreview() {
  const [tasks, setTasks] = useState([
    { id: 1, title: "Robbins Pathology · Neoplasia & Cellular Adaptations", done: true },
    { id: 2, title: "General Pharmacology · Autonomic Receptors & Kinetics", done: false },
  ])

  const toggleTask = (id: number) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, done: !t.done } : t))
    )
  }

  return (
    <div className="w-full max-w-lg mx-auto py-4 space-y-3.5 select-none">
      {tasks.map((task) => (
        <div
          key={task.id}
          onClick={() => toggleTask(task.id)}
          className="group flex items-center gap-3.5 py-2.5 px-3 rounded-lg cursor-pointer transition-colors hover:bg-black/[0.025] dark:hover:bg-white/[0.035]"
        >
          {/* Tactile Circular Ink Checkbox */}
          <div className="relative w-5 h-5 flex-shrink-0 flex items-center justify-center">
            <motion.div
              animate={{
                borderColor: task.done ? "var(--accent)" : "var(--muted-text)",
                backgroundColor: task.done ? "var(--accent)" : "transparent",
              }}
              transition={{ duration: 0.2 }}
              className="w-4 h-4 rounded-full border-[1.4px] flex items-center justify-center"
            >
              <svg width="10" height="8" viewBox="0 0 10 8" fill="none">
                <motion.path
                  d="M1 4L3.8 6.8L9 1.2"
                  stroke="#FFFFFF"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  initial={false}
                  animate={{ pathLength: task.done ? 1 : 0, opacity: task.done ? 1 : 0 }}
                  transition={{ duration: 0.22, ease: "easeOut" }}
                />
              </svg>
            </motion.div>
          </div>

          {/* Task Title with Realistic Ink Strike */}
          <div className="relative flex-1 text-sm sm:text-[15px] font-medium tracking-tight text-[var(--ink-foreground)]">
            <motion.span
              animate={{
                opacity: task.done ? 0.42 : 1,
              }}
              transition={{ duration: 0.2 }}
            >
              {task.title}
            </motion.span>

            {/* Ink Strikethrough line */}
            <motion.div
              className="absolute left-0 top-1/2 -translate-y-1/2 h-[1.2px] bg-[var(--muted-text)] origin-left pointer-events-none"
              initial={false}
              animate={{ scaleX: task.done ? 1 : 0 }}
              transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }}
              style={{ width: "100%" }}
            />
          </div>
        </div>
      ))}
    </div>
  )
}
