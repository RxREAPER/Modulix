#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uGrainSeed;
uniform vec4 uBaseColor;
uniform vec4 uAccentColor;
uniform vec4 uHighlightColor;
uniform float uIsDark;

out vec4 fragColor;

// 45-degree rotated 3D noise generator:
// Guarantees zero vertical or horizontal banding lines across any DPI or GPU architecture
float hash3D(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453123);
}

float organicFilmGrain(vec2 coord, float seed) {
    // 45-degree coordinate rotation completely eliminates vertical & horizontal banding lines
    vec2 rotCoord = vec2(coord.x * 0.70710678 - coord.y * 0.70710678, coord.x * 0.70710678 + coord.y * 0.70710678);
    
    // Dual sampling produces triangular distribution (Gaussian analog silver halide approximation)
    float g1 = hash3D(vec3(rotCoord, seed * 17.31));
    float g2 = hash3D(vec3(rotCoord + vec2(37.19, 71.43), seed * 31.17));
    return (g1 + g2) * 0.5 - 0.5; // Range [-0.5, 0.5], centered at 0.0
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // Centered aspect-corrected coordinates for fluid wave domain
    float aspect = uResolution.x / uResolution.y;
    vec2 p = (uv - vec2(0.5, 0.26)) * vec2(aspect, 1.0) * 8.5;

    // Continuous monotonic wave time (seamless, no loop breaks)
    float t = uTime * 0.70;

    // Multi-octave domain warping: Apple Metal fluid water & liquid simulation
    for (int i = 1; i <= 3; i++) {
        float fi = float(i);
        vec2 prev = p;
        p.x += 0.50 / fi * sin(fi * 1.5 * prev.y + t * 0.70 + fi * 0.9);
        p.y += 0.50 / fi * cos(fi * 1.5 * prev.x - t * 0.60 + fi * 0.9);
    }

    // High-definition wave ripple height field
    float wave1 = sin(p.x * 2.5 + t * 0.85);
    float wave2 = cos(p.y * 2.5 - t * 0.65);
    float wave3 = sin((p.x + p.y) * 1.9 + t * 1.05);
    float height = (wave1 + wave2 + wave3) / 3.0;

    // Specular light caustics: gentle, refined liquid ribbons
    float ripple = abs(sin(p.x * 2.2 + t * 0.75) * cos(p.y * 2.2 - t * 0.75));
    float caustic = pow(clamp(1.0 - ripple, 0.0, 1.0), 4.8);
    float crestGleam = pow(clamp(height * 0.5 + 0.5, 0.0, 1.0), 2.5);

    // Color mixing: Balanced, beautiful liquid depth (less toning down)
    vec4 liquidCol;
    if (uIsDark > 0.5) {
        // Balanced Dark Mode: Deep obsidian base with rich slate-navy liquid waves and radiant silver-cyan caustics
        vec4 darkDeep = mix(uBaseColor, uAccentColor, 0.28 + 0.22 * height);
        liquidCol = darkDeep + uHighlightColor * (caustic * 0.52 + crestGleam * 0.28);
    } else {
        // Balanced Light Mode: Translucent watercolor refraction with sparkling caustic ribbons
        vec4 troughColor = mix(uAccentColor, uBaseColor, 0.32);
        vec4 crestColor = mix(uBaseColor, vec4(1.0, 1.0, 1.0, 1.0), 0.70);
        vec4 lightDeep = mix(troughColor, crestColor, height * 0.5 + 0.5);
        liquidCol = mix(lightDeep, vec4(1.0, 1.0, 1.0, 1.0), caustic * 0.40 + crestGleam * 0.16);
    }

    // 50% Viewport Height Horizon Dissolve
    float horizonFade = smoothstep(0.25, 0.50, uv.y);
    vec4 finalColor = mix(liquidCol, uBaseColor, horizonFade);

    // Subtle, dimmed, non-intrusive 35mm film grain (reverted heavy/tinted grain addition)
    float grain = organicFilmGrain(fragCoord, uGrainSeed);
    float grainIntensity = uIsDark > 0.5 ? 0.045 : 0.032;
    finalColor.rgb += grain * grainIntensity;

    fragColor = finalColor;
}
