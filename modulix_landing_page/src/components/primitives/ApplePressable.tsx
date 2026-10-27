import { ReactNode } from "react"
import { motion, HTMLMotionProps } from "framer-motion"
import { cn } from "../../lib/cn"

interface ApplePressableProps extends HTMLMotionProps<"button"> {
  children: ReactNode
  scale?: number
  className?: string
  onClick?: () => void
  disabled?: boolean
}

export function ApplePressable({
  children,
  scale = 0.96,
  className,
  onClick,
  disabled,
  ...props
}: ApplePressableProps) {
  return (
    <motion.button
      type="button"
      whileTap={disabled ? undefined : { scale }}
      transition={{ type: "spring", stiffness: 420, damping: 24 }}
      onClick={disabled ? undefined : onClick}
      disabled={disabled}
      className={cn(
        "cursor-pointer select-none outline-none inline-flex items-center justify-center transition-opacity active:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed",
        className
      )}
      {...props}
    >
      {children}
    </motion.button>
  )
}
