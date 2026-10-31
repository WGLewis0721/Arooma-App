// Arooma holographic foil, rendered on the GPU as a SwiftUI colorEffect.
//
// Physically driven, no clock. Inputs are the light and eye directions in the CARD's frame,
// which the app derives from the iPhone's attitude (Core Motion), the card's own pose (deck yaw /
// flip angle) and a finger press. A stationary card therefore changes only when the phone
// tilts, the card turns, or it is touched.
//
// The approved card photograph is the input colour; light is ADDED on top (screen-style,
// bounded) so lettering and art stay crisp and the master is never altered.
//
// Optical channels:
//   1. Specular   - Blinn-Phong with a finite eye distance, so the highlight is a spot that
//                   travels across the card as the phone tilts (broad sheen + tight core).
//   2. Diffraction - grating equation: colour = f(sin θin + sin θout) along the grating vector.
//                   Shifts hue coherently across the card with tilt. Masked to the foil rim and
//                   to the bright, low-saturation (metallic) regions of THIS card's art.
//   3. Glitter    - per-cell micro-facets that flash only when their normal meets the
//                   half-vector: sparkles appear and vanish as you tilt, never on their own.
//   4. Press      - the finger bends the foil locally (normal perturbation), so a glint rolls
//                   around the touch point.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static half3 aroomaSpectrum(float t) {
    float3 c = 0.5 + 0.5 * cos(6.2831853 * (t + float3(0.0, 0.33, 0.67)));
    return half3(c);
}

static float2 aroomaHash2(float2 p) {
    float3 a = fract(float3(p.xyx) * float3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(float2(a.x * a.y, a.y * a.z));
}

[[ stitchable ]] half4 aroomaFoil(float2 position,
                                  half4 color,
                                  float2 size,
                                  float3 lightDir,   // toward the light, card frame (x right, y up, z out)
                                  float3 eyeDir,     // toward the viewer, card frame
                                  float3 touch,      // uv.x, uv.y, pressure 0...1
                                  float strength,
                                  float rimWidth,
                                  half4 tint) {
    if (color.a < 0.004h || strength <= 0.001) {
        return color;
    }
    float2 uv = position / max(size, float2(1.0));
    float aspect = size.x / max(size.y, 1.0);

    // Surface point in card-height units, origin at the centre, y up.
    float3 P = float3((uv.x - 0.5) * aspect, 0.5 - uv.y, 0.0);
    float3 eye = normalize(eyeDir) * 2.1;          // viewer ~2 card heights away
    float3 V = normalize(eye - P);
    float3 L = normalize(lightDir);

    // Surface normal, bent locally under a pressing finger.
    float3 N = float3(0.0, 0.0, 1.0);
    if (touch.z > 0.001) {
        float2 d = (uv - touch.xy) * float2(aspect, 1.0);
        float bump = touch.z * exp(-dot(d, d) / 0.018);
        N = normalize(float3(d * bump * 9.0, 1.0));
    }
    float3 H = normalize(L + V);
    float ndh = max(dot(N, H), 0.0);
    float ndv = max(dot(N, V), 0.0);
    float fresnel = 0.04 + 0.96 * pow(1.0 - ndv, 5.0);

    float sheen = pow(ndh, 18.0);
    float core = pow(ndh, 220.0);

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
    float foil = clamp(rim * 0.95 + metallic * 0.6, 0.0, 1.0);

    // Diffraction grating along a diagonal; order m=1 colour from the grating equation.
    float3 T = normalize(float3(0.82, 0.57, 0.0));
    float g = dot(L, T) + dot(V, T);
    half3 rainbow = aroomaSpectrum(g * 2.4 + dot(P.xy, float2(0.35, 0.2)));
    float diffractWindow = pow(max(dot(N, normalize(L + V + float3(T * 0.35))), 0.0), 6.0);
    float diffraction = foil * (0.25 + 0.75 * diffractWindow);

    // Glitter: micro-facets on a fine grid, each with its own tilted normal.
    float2 cell = floor(position / 2.5);
    float2 r = aroomaHash2(cell) - 0.5;
    float3 facet = normalize(float3(r * 0.7, 1.0));
    float glint = pow(max(dot(facet, H), 0.0), 900.0) * step(0.55, aroomaHash2(cell + 7.0).x);
    float glitter = glint * (rim + metallic * 0.5);

    half3 add = rainbow * half(diffraction * 0.34)
              + tint.rgb * half(sheen * (0.16 + 0.2 * fresnel))
              + half3(1.0h) * half(core * (0.18 + 0.4 * metallic))
              + half3(1.0h) * half(min(glitter, 1.0) * 0.9);
    add *= half(strength);

    // Screen blend in unpremultiplied space, then re-premultiply.
    half3 lit = base + add * (1.0h - base);
    return half4(lit * color.a, color.a);
}
