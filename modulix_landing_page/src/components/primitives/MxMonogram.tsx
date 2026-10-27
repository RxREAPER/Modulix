import { useTheme } from "../../lib/theme"
import { cn } from "../../lib/cn"

interface MxMonogramProps {
  size?: number
  className?: string
  alt?: string
}

export function MxMonogram({ size = 30, className, alt = "Modulix" }: MxMonogramProps) {
  const { isDark } = useTheme()
  const src = isDark
    ? "/brand/modulix_monogram_white.png"
    : "/brand/modulix_monogram_dark.png"

  return (
    <img
      src={src}
      width={size}
      height={size}
      alt={alt}
      className={cn("object-contain pointer-events-none select-none", className)}
      loading="eager"
    />
  )
}
