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

// 35mm Film Grain Hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Multi-scale film grain: combines fine 35mm grain with analog paper fiber texture
float multiScaleGrain(vec2 coord, float seed) {
    vec2 p1 = coord + vec2(seed * 117.7, seed * 243.1);
    float g1 = hash(p1);

    // Sub-harmonic micro-texture
    vec2 p2 = (coord * 0.5) + vec2(seed * 71.3, seed * 183.9);
    float g2 = hash(p2);

    return g1 * 0.70 + g2 * 0.30;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // Centered coordinates for gentle atmospheric flow
    float aspect = uResolution.x / uResolution.y;
    vec2 p = (uv - vec2(0.5, 0.18)) * vec2(aspect, 1.0) * 5.5;

    // Smooth, calming, continuous atmospheric flow (seamless, no sharp caustics or harsh metal)
    float t = uTime * 0.35;

    // Soft organic domain warping
    p.x += 0.22 * sin(p.y * 1.5 + t * 0.65);
    p.y += 0.22 * cos(p.x * 1.5 - t * 0.55);
    p.x += 0.12 * sin(p.y * 2.6 - t * 0.85 + 0.6);
    p.y += 0.12 * cos(p.x * 2.3 + t * 0.75 + 0.9);

    // Broad atmospheric wave elevation (soft, smooth, velvety)
    float wave1 = sin(p.x * 1.8 + t * 0.50);
    float wave2 = cos(p.y * 1.8 - t * 0.40);
    float wave3 = sin((p.x + p.y) * 1.4 + t * 0.60);
    float height = (wave1 + wave2 + wave3) / 3.0;

    // Soft matte ambient sheen (velvety, smooth, not sharp chrome)
    float sheen = pow(clamp(height * 0.5 + 0.5, 0.0, 1.0), 1.8);

    // Color mixing: Atmospheric theme glow in upper viewport
    vec4 atmosphericCol;
    if (uIsDark > 0.5) {
        // Dark Mode: Deep obsidian canvas with muted theme aurora & celestial mist
        vec4 darkDeep = mix(uBaseColor, uAccentColor, 0.28 + 0.22 * height);
        atmosphericCol = darkDeep + uHighlightColor * (sheen * 0.25);
    } else {
        // Light Mode: Clean paper canvas with gentle, soft watercolor tint
        vec4 softWash = mix(uBaseColor, uAccentColor, 0.22 + 0.20 * height);
        atmosphericCol = mix(softWash, vec4(1.0, 1.0, 1.0, 1.0), sheen * 0.18);
    }

    // User requirement: "its coming too down from the middle lets put it to 35% top"
    // Fades smoothly into clean canvas color strictly by 35% of screen height
    float horizonFade = smoothstep(0.14, 0.35, uv.y);
    vec4 finalColor = mix(atmosphericCol, uBaseColor, horizonFade);

    // User requirement: "more grainy more grainy and more grainyn ... keep the colour of the grains a bit dimmed"
    // Pronounced, rich, tactile 35mm film grain, dimmed/softened so it blends naturally without harsh clipping
    float grain = multiScaleGrain(fragCoord, uGrainSeed);
    float grainIntensity = uIsDark > 0.5 ? 0.078 : 0.068;
    finalColor.rgb += (grain - 0.5) * grainIntensity;

    fragColor = finalColor;
}
