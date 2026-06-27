struct Uniforms
{
    mvp: mat4x4<f32>,
    model: mat4x4<f32>,
    time: f32,
    pad0: f32,
    pad1: f32,
    pad2: f32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

struct VertexInput 
{
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VertexOutput 
{
    @builtin(position) clip_position: vec4<f32>,
    @location(0) world_normal: vec3<f32>,
}

@vertex
fn vs_main(in: VertexInput) -> VertexOutput 
{
    var out: VertexOutput;
    out.clip_position = uniforms.mvp * vec4<f32>(in.position, 1.0);
    let model3 = mat3x3<f32>(uniforms.model[0].xyz, uniforms.model[1].xyz, uniforms.model[2].xyz);
    out.world_normal = model3 * in.normal;
    return out;
}

// How long the star spends fading from one stage into the next, in
// seconds. The cycle below has 9 stages, so the full loop takes
// 9 times this value before it repeats from the start.
const SECONDS_PER_STAGE: f32 = 16.0;

// Stage 0, the original star color. Left untouched as requested.
const SHADOW_COLOR: vec3<f32> = vec3<f32>(0.0, 0.047058823529411764, 0.0);
const BASE_COLOR: vec3<f32> = vec3<f32>(0.0, 0.25, 0.0);
const HIGHLIGHT_COLOR: vec3<f32> = vec3<f32>(0.0, 0.937, 0.0);

// Stage 1, blue, hex 73a9e6
const STAGE1_BASE: vec3<f32> = vec3<f32>(0.4510, 0.6627, 0.9020);
// Stage 2, ultramarine blue, RGB(32, 0, 128)
const STAGE2_BASE: vec3<f32> = vec3<f32>(0.125, 0.298, 0.953);
// Stage 3, lavender blue, hex 6d84ff
const STAGE3_BASE: vec3<f32> = vec3<f32>(0.4275, 0.5176, 1.0);
// Stage 4, hex b1aaa2
const STAGE4_BASE: vec3<f32> = vec3<f32>(0.6941, 0.6667, 0.6353);

// Stage 5, frosty glass. A very light, slightly blue tint, kept apart
// from the other base colors above because this stage also needs its
// own alpha value, which none of the others do.
const STAGE5_TINT: vec3<f32> = vec3<f32>(0.85, 0.93, 0.98);

// Stage 6, pure white. Flat and unlit, no shadow or highlight by request.
const STAGE6_FLAT: vec3<f32> = vec3<f32>(1.0, 1.0, 1.0);
// Stage 7, pure black, RGB(0, 0, 0). Flat and unlit, no shadow or highlight by request.
const STAGE7_FLAT: vec3<f32> = vec3<f32>(0.0, 0.0, 0.0);
// Stage 8, the outline color for the pure black stage, RGB(0, 64, 0).
const STAGE8_OUTLINE: vec3<f32> = vec3<f32>(0.0, 0.2510, 0.0);

// Derives a shadow tone from any base color by darkening it toward
// black while keeping the same hue. 0.22 mirrors how dark the original
// green shadow sits relative to its own base color.
fn shadow_of(base: vec3<f32>) -> vec3<f32> {
    return base * 0.22;
}

// Derives a highlight tone from any base color by lightening it toward
// white and then boosting it a little further, mirroring how much
// brighter the original green highlight sits relative to its own base.
fn highlight_of(base: vec3<f32>) -> vec3<f32> {
    let lightened = mix(base, vec3<f32>(1.0, 1.0, 1.0), 0.45);
    return clamp(lightened * 1.15, vec3<f32>(0.0, 0.0, 0.0), vec3<f32>(1.0, 1.0, 1.0));
}

// Shades a base color using the same shadow, base, highlight ramp the
// original green star uses, just with a derived shadow and highlight
// instead of hand picked ones.
fn shade(base: vec3<f32>, diffuse: f32) -> vec3<f32> {
    var color = mix(shadow_of(base), base, smoothstep(0.0, 0.55, diffuse));
    color = mix(color, highlight_of(base), smoothstep(0.55, 1.0, diffuse));
    return color;
}

// Returns the fully shaded color, alpha included, for one discrete
// stage of the cycle. diffuse drives the normal shadow and highlight
// ramp. fresnel drives the rim based look used by the frosty glass
// and outline stages, since those depend on how much a facet faces
// the camera rather than how much it faces the light.
fn evaluate_stage(stage: i32, diffuse: f32, fresnel: f32) -> vec4<f32> {
    if (stage == 0) {
        var color = mix(SHADOW_COLOR, BASE_COLOR, smoothstep(0.0, 0.55, diffuse));
        color = mix(color, HIGHLIGHT_COLOR, smoothstep(0.55, 1.0, diffuse));
        return vec4<f32>(color, 1.0);
    }
    if (stage == 1) {
        return vec4<f32>(shade(STAGE1_BASE, diffuse), 1.0);
    }
    if (stage == 2) {
        return vec4<f32>(shade(STAGE2_BASE, diffuse), 1.0);
    }
    if (stage == 3) {
        return vec4<f32>(shade(STAGE3_BASE, diffuse), 1.0);
    }
    if (stage == 4) {
        return vec4<f32>(shade(STAGE4_BASE, diffuse), 1.0);
    }
    if (stage == 5) {
        // Frosty glass. No directional shadow or highlight, the rim
        // term takes their place instead. The middle of each facet
        // stays mostly see through, the rim catches the light and
        // turns almost white, the way light catches the edge of a
        // piece of frosted glass.
        let rim = smoothstep(0.35, 0.95, fresnel);
        let color = mix(STAGE5_TINT, vec3<f32>(1.0, 1.0, 1.0), rim);
        let alpha = clamp(0.18 + rim * 0.67, 0.0, 0.85);
        return vec4<f32>(color, alpha);
    }
    if (stage == 6) {
        // Pure white, flat and unlit as requested.
        return vec4<f32>(STAGE6_FLAT, 1.0);
    }
    if (stage == 7) {
        // Pure black, flat and unlit as requested.
        return vec4<f32>(STAGE7_FLAT, 1.0);
    }
    // Stage 8. Pure black fill with a green outline along the silhouette.
    let edge = smoothstep(0.55, 0.85, fresnel);
    let color = mix(STAGE7_FLAT, STAGE8_OUTLINE, edge);
    return vec4<f32>(color, 1.0);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> 
{
    let normal = normalize(in.world_normal);
    let light_direction = normalize(vec3<f32>(0.4, 0.6, 1.0));
    let diffuse = max(dot(normal, light_direction), 0.0);

    // The camera never moves and sits roughly along the positive Z
    // axis relative to the star, see the fixed view transform in
    // render_frame.rs. The star is small compared to the camera
    // distance, so a constant view direction is a close enough stand
    // in for a real camera position uniform, without adding one just
    // for this.
    let view_direction = vec3<f32>(0.0, 0.0, 1.0);
    let fresnel = pow(1.0 - max(dot(normal, view_direction), 0.0), 2.5);

    // Walk through the 9 stage cycle. local_t is how far along we are
    // between the current stage and the next one, 0 right after a
    // stage begins and 1 right before the next one takes over. The
    // whole loop repeats every 9 times SECONDS_PER_STAGE seconds.
    let stage_count: i32 = 9;
    let raw: f32 = uniforms.time / SECONDS_PER_STAGE;
    let current_stage: i32 = i32(floor(raw)) % stage_count;
    let next_stage: i32 = (current_stage + 1) % stage_count;
    let local_t: f32 = smoothstep(0.0, 1.0, fract(raw));

    let current_color = evaluate_stage(current_stage, diffuse, fresnel);
    let next_color = evaluate_stage(next_stage, diffuse, fresnel);

    return mix(current_color, next_color, local_t);
}
