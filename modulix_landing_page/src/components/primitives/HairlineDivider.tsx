import { cn } from "../../lib/cn"

interface HairlineDividerProps {
  className?: string
}

export function HairlineDivider({ className }: HairlineDividerProps) {
  return (
    <div
      className={cn(
        "w-full h-[0.6px] bg-[var(--border-subtle)] my-4 opacity-80",
        className
      )}
    />
  )
}
