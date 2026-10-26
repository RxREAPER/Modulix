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

// High-frequency pseudo-random hash for 35mm film grain
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // Centered aspect-corrected coordinates for fluid wave domain
    float aspect = uResolution.x / uResolution.y;
    vec2 p = (uv - vec2(0.5, 0.32)) * vec2(aspect, 1.0) * 8.5;

    float t = uTime * 0.75;

    // Multi-octave domain warping: Apple Metal fluid water simulation
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

    // Specular light caustics: intense ribbons of focused light
    float ripple = abs(sin(p.x * 2.2 + t * 0.75) * cos(p.y * 2.2 - t * 0.75));
    float caustic = pow(clamp(1.0 - ripple, 0.0, 1.0), 4.8);
    float crestGleam = pow(clamp(height * 0.5 + 0.5, 0.0, 1.0), 2.5);

    // Color mixing: Rich theme fluid depth
    vec4 liquidCol;
    if (uIsDark > 0.5) {
        // Dark Mode: Deep metallic obsidian base with rich theme liquid waves & luminous cyan/silver caustics
        vec4 darkDeep = mix(uBaseColor, uAccentColor, 0.38 + 0.32 * height);
        liquidCol = darkDeep + uHighlightColor * (caustic * 0.72 + crestGleam * 0.40);
    } else {
        // Light Mode: Physical water refraction
        // Deep translucent watercolor in wave troughs, crisp light silver canvas at crests, with brilliant white caustic light ribbons
        vec4 troughColor = mix(uAccentColor, uBaseColor, 0.42);
        vec4 crestColor = mix(uBaseColor, vec4(1.0, 1.0, 1.0, 1.0), 0.60);
        vec4 lightDeep = mix(troughColor, crestColor, height * 0.5 + 0.5);
        liquidCol = mix(lightDeep, vec4(1.0, 1.0, 1.0, 1.0), caustic * 0.58 + crestGleam * 0.22);
    }

    // Horizon dissolve: Smoothly transitions the liquid motion into the clean canvas color
    // between 56% and 86% viewport height, ensuring bottom tasks have perfect readability
    float horizonFade = smoothstep(0.56, 0.86, uv.y);
    vec4 finalColor = mix(liquidCol, uBaseColor, horizonFade);

    // Active 24/30 FPS 35mm film grain jitter across the entire screen
    float grain = hash(fragCoord + vec2(uGrainSeed * 117.7, uGrainSeed * 243.1));
    float grainIntensity = uIsDark > 0.5 ? 0.048 : 0.038;
    finalColor.rgb += (grain - 0.5) * grainIntensity;

    fragColor = finalColor;
}
