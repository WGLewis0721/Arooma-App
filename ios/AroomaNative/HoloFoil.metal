// Arooma holographic foil, rendered on the GPU as a SwiftUI colorEffect.
//
// The approved card photograph is the input colour; this shader only ADDS light on top of it
// (screen-style, bounded), so lettering and art stay crisp and unaltered on disk.
//
// Optical channels, each masked differently so every card answers the light in its own way:
//   1. Broad specular sheen   - a soft lobe that follows the light, tinted by the theme.
//   2. Tight glint            - a small hot core, strongest on bright metallic regions.
//   3. Diffraction            - spectral bands whose phase follows the light direction; masked
//                               to the foil rim and to bright, low-saturation (metallic) pixels
//                               of THIS card's art, so a gold-lettered card and a dark card
//                               visibly behave differently.
//   4. Rim sparkle            - sparse glitter on the selective foil edge only.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static half3 aroomaSpectrum(float t) {
    float3 c = 0.5 + 0.5 * cos(6.2831853 * (t + float3(0.0, 0.33, 0.67)));
    return half3(c);
}

static float aroomaHash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

[[ stitchable ]] half4 aroomaFoil(float2 position,
                                  half4 color,
                                  float2 size,
                                  float2 light,
                                  float time,
                                  float strength,
                                  float rimWidth,
                                  half4 tint) {
    if (color.a < 0.004h || strength <= 0.001) {
        return color;
    }
    float2 uv = position / max(size, float2(1.0));
    float aspect = size.x / max(size.y, 1.0);

    // Where the light source reflects on the card, in card space.
    float2 centre = float2(0.5) + light * float2(0.62, 0.48);
    float2 q = (uv - centre) * float2(aspect, 1.0);
    float r2 = dot(q, q);
    float sheen = exp(-r2 * 7.5);
    float glint = exp(-r2 * 70.0);

    // Selective foil edge.
    float2 edge = min(position, size - position);
    float e = min(edge.x, edge.y);
    float rim = 1.0 - smoothstep(rimWidth * 0.3, rimWidth, e);

    // Material estimate from the art itself (unpremultiplied).
    half3 base = color.rgb / max(color.a, 0.001h);
    float lum = float(dot(base, half3(0.299h, 0.587h, 0.114h)));
    float hi = float(max(base.r, max(base.g, base.b)));
    float lo = float(min(base.r, min(base.g, base.b)));
    float sat = hi > 0.001 ? (hi - lo) / hi : 0.0;
    float metallic = smoothstep(0.42, 0.88, lum) * (1.0 - sat * 0.65);

    // Diffraction: band phase depends on position along a diagonal and on the light angle.
    float2 dir = normalize(float2(0.82, 0.57) + light * 0.35);
    float phase = dot(uv - 0.5, dir) * 2.4 + light.x * 0.95 + light.y * 0.6 + time * 0.012;
    half3 rainbow = aroomaSpectrum(phase);
    float diffraction = clamp(rim * 0.95 + metallic * 0.6, 0.0, 1.0) * (0.3 + 0.7 * sheen);

    // Sparse glitter on the rim, twinkling as the light passes.
    float2 cell = floor(position / 2.5);
    float h = aroomaHash(cell);
    float twinkle = pow(max(0.0, sin(time * 1.7 + h * 40.0 + (light.x + light.y) * 9.0)), 10.0);
    float sparkle = step(0.982, h) * rim * twinkle;

    half3 add = rainbow * half(diffraction * 0.30)
              + tint.rgb * half(sheen * 0.17)
              + half3(1.0h) * half(glint * (0.10 + 0.22 * metallic))
              + half3(1.0h) * half(sparkle * 0.85);
    add *= half(strength);

    // Screen blend in unpremultiplied space, then re-premultiply.
    half3 lit = base + add * (1.0h - base);
    return half4(lit * color.a, color.a);
}
