export function MedicalHeroIllustration() {
  return (
    <div className="relative w-full max-w-3xl mx-auto flex items-center justify-center select-none py-2">
      {/* ── Live Looping Master Clinical Art (No 3D Tilt, Calm & Non-Interactive) ── */}
      <div className="relative w-full flex items-center justify-center">
        <video
          autoPlay
          loop
          muted
          playsInline
          poster="/hero/master_vector.svg"
          className="w-full h-auto max-h-[440px] sm:max-h-[480px] object-contain select-none pointer-events-none drop-shadow-sm"
        >
          {/* Alpha-channel transparent WebM (clean transparent background, authentic looping animation) */}
          <source src="/hero/hero_transparent.webm" type="video/webm" />
          {/* Universal MP4 fallback */}
          <source src="/hero/FINAL.mp4" type="video/mp4" />
          {/* Master Vector fallback */}
          <img
            src="/hero/master_vector.svg"
            alt="Modulix Clinical Art"
            className="w-full h-auto max-h-[440px] sm:max-h-[480px] object-contain select-none"
          />
        </video>
      </div>
    </div>
  )
}
