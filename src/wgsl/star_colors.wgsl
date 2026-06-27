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
// seconds. The cycle below has 22 stages, so the full loop takes 22
// times this value before it repeats from the start.
const SECONDS_PER_STAGE: f32 = 16.0;

// ---------------------------------------------------------------------
// Color cycle overview
//
// The star fades through the stages below, in this order, then loops
// back to stage 0 once stage 21 finishes. The numbers match the
// "stage == N" checks used in evaluate_stage further down, so any
// color can be found quickly by searching for its stage number.
//
//  0  pure white               flat, no shading
//  1  pure yellow               hex ffff00
//  2  amber orange              hex FFA000
//  3  pumpkin orange            hex FF5F1F
//  4  burnt red orange          hex cc1900
//  5  teal green                hex 009373
//  6  green teal                hex 00934e
//  7  bright green              hex 00932a
//  8  the star's original green color, moved here from stage 0
//  9  bright green again, hex 00932a, same color as stage 7
// 10  dark green                hex 00601b
// 11  dark teal green           hex 00604b
// 12  light blue                hex 73a9e6, already in this file
// 13  ultramarine blue          already in this file
// 14  lavender blue              hex 6d84ff, already in this file
// 15  pale lavender white       hex e8edff
// 16  light grey                hex eeeeee
// 17  titanium grey             hex b1aaa2, already in this file
// 18  medium grey               hex a5a6a6
// 19  dark grey                 hex 5a5959
// 20  pure black                flat, no shading
// 21  frosty glass              transparent rim highlight, already in this file
// ---------------------------------------------------------------------

// Stage 8, the star's original green color. The values are left
// untouched, this color simply no longer plays right at the start of
// the cycle, it now plays partway through instead, see stage 0 below
// for the new starting color.
const SHADOW_COLOR: vec3<f32> = vec3<f32>(0.0, 0.047058823529411764, 0.0);
const BASE_COLOR: vec3<f32> = vec3<f32>(0.0, 0.25, 0.0);
const HIGHLIGHT_COLOR: vec3<f32> = vec3<f32>(0.0, 0.937, 0.0);

// Stage 1, pure yellow, hex ffff00.
const PURE_YELLOW_BASE: vec3<f32> = vec3<f32>(1.0, 1.0, 0.0);
// Stage 2, amber orange, hex FFA000.
const AMBER_ORANGE_BASE: vec3<f32> = vec3<f32>(1.0, 0.6275, 0.0);
// Stage 3, pumpkin orange, hex FF5F1F.
const PUMPKIN_ORANGE_BASE: vec3<f32> = vec3<f32>(1.0, 0.3725, 0.1216);
// Stage 4, burnt red orange, hex cc1900.
const BURNT_RED_ORANGE_BASE: vec3<f32> = vec3<f32>(0.8, 0.0980, 0.0);
// Stage 5, teal green, hex 009373.
const TEAL_GREEN_BASE: vec3<f32> = vec3<f32>(0.0, 0.5765, 0.4510);
// Stage 6, green teal, hex 00934e.
const GREEN_TEAL_BASE: vec3<f32> = vec3<f32>(0.0, 0.5765, 0.3059);
// Stage 7 and stage 9, bright green, hex 00932a. This color plays
// twice, right before the star's original green at stage 8 and again
// right after it, so that original green fades in and back out through
// the same neighbor color on both sides instead of jumping straight to
// a different color on the way out.
const BRIGHT_GREEN_BASE: vec3<f32> = vec3<f32>(0.0, 0.5765, 0.1647);
// Stage 10, dark green, hex 00601b.
const DARK_GREEN_BASE: vec3<f32> = vec3<f32>(0.0, 0.3765, 0.1059);
// Stage 11, dark teal green, hex 00604b.
const DARK_TEAL_GREEN_BASE: vec3<f32> = vec3<f32>(0.0, 0.3765, 0.2941);

// Stage 12, light blue, hex 73a9e6. Already in this file, value left
// unchanged, only the stage number and the constant name changed since
// this color now plays much later in the cycle than before.
const LIGHT_BLUE_BASE: vec3<f32> = vec3<f32>(0.4510, 0.6627, 0.9020);
// Stage 13, ultramarine blue. Already in this file, value left
// unchanged.
const ULTRAMARINE_BLUE_BASE: vec3<f32> = vec3<f32>(0.125, 0.298, 0.953);
// Stage 14, lavender blue, hex 6d84ff. Already in this file, value
// left unchanged.
const LAVENDER_BLUE_BASE: vec3<f32> = vec3<f32>(0.4275, 0.5176, 1.0);

// Stage 15, pale lavender white, hex e8edff.
const PALE_LAVENDER_WHITE_BASE: vec3<f32> = vec3<f32>(0.9098, 0.9294, 1.0);
// Stage 16, light grey, hex eeeeee.
const LIGHT_GREY_BASE: vec3<f32> = vec3<f32>(0.9333, 0.9333, 0.9333);
// Stage 17, titanium grey, hex b1aaa2. Already in this file, value
// left unchanged.
const TITANIUM_GREY_BASE: vec3<f32> = vec3<f32>(0.6941, 0.6667, 0.6353);
// Stage 18, medium grey, hex a5a6a6.
const MEDIUM_GREY_BASE: vec3<f32> = vec3<f32>(0.6471, 0.6510, 0.6510);
// Stage 19, dark grey, hex 5a5959.
const DARK_GREY_BASE: vec3<f32> = vec3<f32>(0.3529, 0.3490, 0.3490);

// Stage 21, frosty glass. A very light, slightly blue tint, kept apart
// from the other base colors above because this stage also needs its
// own alpha value, which none of the others do. Already in this file,
// value left unchanged.
const FROSTY_GLASS_TINT: vec3<f32> = vec3<f32>(0.85, 0.93, 0.98);

// Stage 0, pure white, the starting color of the cycle. Flat and
// unlit, no shadow or highlight, the same treatment as pure black
// below. Already in this file, value left unchanged.
const WHITE_FLAT: vec3<f32> = vec3<f32>(1.0, 1.0, 1.0);
// Stage 20, pure black. Flat and unlit, no shadow or highlight.
// Already in this file, value left unchanged.
const BLACK_FLAT: vec3<f32> = vec3<f32>(0.0, 0.0, 0.0);

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
// stage of the cycle described in the overview comment above. diffuse
// drives the normal shadow and highlight ramp used by every stage
// except the flat white and black stages and the original green
// stage. fresnel drives the rim based look used by the frosty glass
// stage, since that one depends on how much a facet faces the camera
// rather than how much it faces the light.
fn evaluate_stage(stage: i32, diffuse: f32, fresnel: f32) -> vec4<f32> {
    if (stage == 0) {
        // Pure white, flat and unlit, no shadow or highlight.
        return vec4<f32>(WHITE_FLAT, 1.0);
    }
    if (stage == 1) {
        return vec4<f32>(shade(PURE_YELLOW_BASE, diffuse), 1.0);
    }
    if (stage == 2) {
        return vec4<f32>(shade(AMBER_ORANGE_BASE, diffuse), 1.0);
    }
    if (stage == 3) {
        return vec4<f32>(shade(PUMPKIN_ORANGE_BASE, diffuse), 1.0);
    }
    if (stage == 4) {
        return vec4<f32>(shade(BURNT_RED_ORANGE_BASE, diffuse), 1.0);
    }
    if (stage == 5) {
        return vec4<f32>(shade(TEAL_GREEN_BASE, diffuse), 1.0);
    }
    if (stage == 6) {
        return vec4<f32>(shade(GREEN_TEAL_BASE, diffuse), 1.0);
    }
    if (stage == 7 || stage == 9) {
        // Bright green, see the comment on BRIGHT_GREEN_BASE above for
        // why this same color is used on both sides of stage 8.
        return vec4<f32>(shade(BRIGHT_GREEN_BASE, diffuse), 1.0);
    }
    if (stage == 8) {
        // The star's original green look, kept exactly as it was
        // before, just moved here instead of being the starting color.
        var color = mix(SHADOW_COLOR, BASE_COLOR, smoothstep(0.0, 0.55, diffuse));
        color = mix(color, HIGHLIGHT_COLOR, smoothstep(0.55, 1.0, diffuse));
        return vec4<f32>(color, 1.0);
    }
    if (stage == 10) {
        return vec4<f32>(shade(DARK_GREEN_BASE, diffuse), 1.0);
    }
    if (stage == 11) {
        return vec4<f32>(shade(DARK_TEAL_GREEN_BASE, diffuse), 1.0);
    }
    if (stage == 12) {
        return vec4<f32>(shade(LIGHT_BLUE_BASE, diffuse), 1.0);
    }
    if (stage == 13) {
        return vec4<f32>(shade(ULTRAMARINE_BLUE_BASE, diffuse), 1.0);
    }
    if (stage == 14) {
        return vec4<f32>(shade(LAVENDER_BLUE_BASE, diffuse), 1.0);
    }
    if (stage == 15) {
        return vec4<f32>(shade(PALE_LAVENDER_WHITE_BASE, diffuse), 1.0);
    }
    if (stage == 16) {
        return vec4<f32>(shade(LIGHT_GREY_BASE, diffuse), 1.0);
    }
    if (stage == 17) {
        return vec4<f32>(shade(TITANIUM_GREY_BASE, diffuse), 1.0);
    }
    if (stage == 18) {
        return vec4<f32>(shade(MEDIUM_GREY_BASE, diffuse), 1.0);
    }
    if (stage == 19) {
        return vec4<f32>(shade(DARK_GREY_BASE, diffuse), 1.0);
    }
    if (stage == 20) {
        // Pure black, flat and unlit, no shadow or highlight.
        return vec4<f32>(BLACK_FLAT, 1.0);
    }
    // Stage 21, frosty glass. No directional shadow or highlight, the
    // rim term takes their place instead. The middle of each facet
    // stays mostly see through, the rim catches the light and turns
    // almost white, the way light catches the edge of a piece of
    // frosted glass.
    let rim = smoothstep(0.35, 0.95, fresnel);
    let color = mix(FROSTY_GLASS_TINT, vec3<f32>(1.0, 1.0, 1.0), rim);
    let alpha = clamp(0.18 + rim * 0.67, 0.0, 0.85);
    return vec4<f32>(color, alpha);
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

    // Walk through the 22 stage cycle described in the overview
    // comment above. local_t is how far along the star is between the
    // current stage and the next one, 0 right after a stage begins and
    // 1 right before the next one takes over. The whole loop repeats
    // every 22 times SECONDS_PER_STAGE seconds.
    let stage_count: i32 = 22;
    let raw: f32 = uniforms.time / SECONDS_PER_STAGE;
    let current_stage: i32 = i32(floor(raw)) % stage_count;
    let next_stage: i32 = (current_stage + 1) % stage_count;
    let local_t: f32 = smoothstep(0.0, 1.0, fract(raw));

    let current_color = evaluate_stage(current_stage, diffuse, fresnel);
    let next_color = evaluate_stage(next_stage, diffuse, fresnel);

    return mix(current_color, next_color, local_t);
}
