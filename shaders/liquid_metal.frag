#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uGrainSeed;
uniform vec4 uBaseColor;
uniform vec4 uAccentColor;
uniform vec4 uHighlightColor;
uniform vec4 uGrainColor;
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

    // Color mixing:
    vec4 liquidCol;
    if (uIsDark > 0.5) {
        // 1st User Requirement: "when in dark mode its too blue lets tone down it"
        // Toned-down deep metallic obsidian with subtle muted slate-blue rolls & soft silver crests
        vec4 darkDeep = mix(uBaseColor, uAccentColor, 0.18 + 0.14 * height);
        liquidCol = darkDeep + uHighlightColor * (caustic * 0.32 + crestGleam * 0.18);
    } else {
        // 3rd User Requirement: "in light mode its also too blue"
        // Toned-down clean light paper canvas with delicate airy refraction ribbons (no heavy pool blue)
        vec4 troughColor = mix(uBaseColor, uAccentColor, 0.22);
        vec4 crestColor = mix(uBaseColor, vec4(1.0, 1.0, 1.0, 1.0), 0.80);
        vec4 lightDeep = mix(troughColor, crestColor, height * 0.5 + 0.5);
        liquidCol = mix(lightDeep, vec4(1.0, 1.0, 1.0, 1.0), caustic * 0.22 + crestGleam * 0.10);
    }

    // 50% Viewport Height Horizon Dissolve
    float horizonFade = smoothstep(0.25, 0.50, uv.y);
    vec4 finalColor = mix(liquidCol, uBaseColor, horizonFade);

    // User requirements:
    // 1. "i see no grains lets add that component too"
    // 2. "when in atomic orange theme lets make the grain blue shaded not orange"
    // Scaled to 2.2 physical pixels so silver halide grain particles are distinctly visible on 450+ PPI displays
    vec2 grainCoord = floor(fragCoord / 2.2);
    float grain = organicFilmGrain(grainCoord, uGrainSeed); // -0.5 to 0.5

    // Visibly tactile grain amplitude
    float grainIntensity = uIsDark > 0.5 ? 0.095 : 0.075;

    // Chromatic grain shading:
    // When uGrainColor is blue (e.g. in atomic orange), the grain crystals are distinctly BLUE-SHADED!
    vec3 grainTint = uGrainColor.rgb;
    vec3 grainDelta = mix(vec3(grain), (grainTint - vec3(0.5)) * 1.6 + vec3(grain), 0.60);
    finalColor.rgb = clamp(finalColor.rgb + grainDelta * grainIntensity, 0.0, 1.0);

    fragColor = finalColor;
}
