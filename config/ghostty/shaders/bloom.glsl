// Subtle bloom + vignette for ghostty.
//
// Deliberately restrained: this runs on every frame of a terminal you read all
// day, so it lifts bright glyphs slightly and darkens the far corners, and does
// nothing else. No scanlines, no curvature, no chromatic aberration -- those
// look good in a screenshot and cost legibility everywhere else.
//
// Ghostty uses the Shadertoy entrypoint. iChannel0 is the terminal's own
// rendered output; iResolution is the surface size in pixels.
//
// Tuning: BLOOM_STRENGTH 0 disables the glow, VIGNETTE_STRENGTH 0 the corners.

#define BLOOM_STRENGTH   0.18
#define BLOOM_RADIUS     2.0
#define BLOOM_THRESHOLD  0.55
#define VIGNETTE_STRENGTH 0.22

// Luma coefficients (Rec. 709).
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Only the parts of a pixel brighter than the threshold contribute to bloom,
// so the background stays black instead of turning into grey haze.
vec3 brightPass(vec3 c) {
    float l = luma(c);
    return c * smoothstep(BLOOM_THRESHOLD, 1.0, l);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv  = fragCoord / iResolution.xy;
    vec3 src = texture(iChannel0, uv).rgb;

    // 9-tap separable-ish blur of the bright areas only. Cheap, and at this
    // radius the difference from a proper two-pass gaussian is not visible.
    vec2 px = BLOOM_RADIUS / iResolution.xy;
    vec3 sum = vec3(0.0);
    sum += brightPass(texture(iChannel0, uv + px * vec2(-1.0, -1.0)).rgb) * 0.0625;
    sum += brightPass(texture(iChannel0, uv + px * vec2( 0.0, -1.0)).rgb) * 0.1250;
    sum += brightPass(texture(iChannel0, uv + px * vec2( 1.0, -1.0)).rgb) * 0.0625;
    sum += brightPass(texture(iChannel0, uv + px * vec2(-1.0,  0.0)).rgb) * 0.1250;
    sum += brightPass(texture(iChannel0, uv + px * vec2( 0.0,  0.0)).rgb) * 0.2500;
    sum += brightPass(texture(iChannel0, uv + px * vec2( 1.0,  0.0)).rgb) * 0.1250;
    sum += brightPass(texture(iChannel0, uv + px * vec2(-1.0,  1.0)).rgb) * 0.0625;
    sum += brightPass(texture(iChannel0, uv + px * vec2( 0.0,  1.0)).rgb) * 0.1250;
    sum += brightPass(texture(iChannel0, uv + px * vec2( 1.0,  1.0)).rgb) * 0.0625;

    vec3 col = src + sum * BLOOM_STRENGTH;

    // Vignette, measured from the centre in normalised coordinates.
    vec2 d = uv - 0.5;
    float v = 1.0 - dot(d, d) * VIGNETTE_STRENGTH * 4.0;
    col *= clamp(v, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
