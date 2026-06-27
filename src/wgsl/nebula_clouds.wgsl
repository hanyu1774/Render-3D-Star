
// Same 4 float layout as MistUniforms on the Rust side (time, aspect,
// pad0, pad1). Reusing this exact layout means the existing mist_binding
// Flow and its buffer can feed this shader too, no new uniform needed.
struct NebulaUniforms {
    time: f32,
    aspect: f32,
    pad0: f32,
    pad1: f32,
};
@group(0) @binding(0) var<uniform> nebula: NebulaUniforms;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

// Same oversized full screen triangle trick as mist_clouds.wgsl, no vertex buffer needed.
@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    let positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    let pos = positions[vertex_index];

    var out: VertexOutput;
    out.clip_position = vec4<f32>(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + vec2<f32>(0.5, 0.5);
    return out;
}

// Rotates a point around the origin. Used to slowly spin the sampling
// coordinate, which is the main thing that makes this layer's motion
// read as different from the green mist's plain straight line drift.
fn rotate2d(p: vec2<f32>, angle: f32) -> vec2<f32> {
    let s = sin(angle);
    let c = cos(angle);
    return vec2<f32>(p.x * c - p.y * s, p.x * s + p.y * c);
}

fn hash(p: vec2<f32>) -> f32 {
    var p3 = fract(vec3<f32>(p.x, p.y, p.x) * vec3<f32>(0.1031, 0.1030, 0.0973));
    p3 = p3 + dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let a = hash(i);
    let b = hash(i + vec2<f32>(1.0, 0.0));
    let c = hash(i + vec2<f32>(0.0, 1.0));
    let d = hash(i + vec2<f32>(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Same 4 octave noise stack as the green mist, this is just a generic
// cloud texture generator, the colors and motion below are what give
// this layer its own identity.
fn fbm(p: vec2<f32>) -> f32 {
    var value: f32 = 0.0;
    var amplitude: f32 = 0.5;
    var freq: vec2<f32> = p;
    for (var i: i32 = 0; i < 4; i = i + 1) {
        value = value + amplitude * noise(freq);
        freq = freq * 2.0;
        amplitude = amplitude * 0.5;
    }
    return value;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var uv = in.uv;
    uv.x = uv.x * nebula.aspect; // keep the noise pattern square regardless of window shape

    // Slowly rotate the sampling coordinate around the screen center.
    // This swirl, combined with a diagonal drift below, is intentionally
    // unlike the green mist's plain horizontal pan, so the two layers
    // never move in sync with each other.
    let center = vec2<f32>(0.5 * nebula.aspect, 0.5);
    let swirl_angle = nebula.time * 0.025; // slow rotation speed
    let swirled_uv = rotate2d(uv - center, swirl_angle) + center;

    let drift = vec2<f32>(nebula.time * -0.035, nebula.time * 0.07); // diagonal drift, different bias and speed than the green mist
    let scale = 1.1; // larger, more spread out cloud bodies than the green mist

    let n1 = fbm(swirled_uv * scale + drift);
    let n2 = fbm(swirled_uv * scale * 1.55 - drift * 1.4 + vec2<f32>(7.1, -3.4));
    let density = clamp(n1 * 0.55 + n2 * 0.45, 0.0, 1.0); // overall cloud shape

    // A separate, finer noise field with its own faster drift decides
    // where the warm, glowing knots appear inside the cooler haze.
    // It moves independently from the density field above.
    let hotspot_drift = drift * 2.4;
    let hotspot = fbm(swirled_uv * scale * 3.1 + hotspot_drift + vec2<f32>(2.0, 9.0));

    // Milky way blue and ultramarine blue for the broad, diffuse haze.
    let milky_way_blue = vec3<f32>(0.59, 0.145, 0.714);
    let ultramarine = vec3<f32>(0.125, 0.298, 0.953);
    let blue = mix(milky_way_blue, ultramarine, smoothstep(0.3, 0.85, density));

    // Very bright yellow and yellow orange for the glowing core knots.
    let bright_yellow = vec3<f32>(1.0, 0.95, 0.45);
    let yellow_orange = vec3<f32>(1.0, 0.55, 0.12);
    let warm = mix(bright_yellow, yellow_orange, smoothstep(0.4, 0.9, hotspot));

    // Only let the warm colors show where both the cloud is dense and
    // the hotspot field agrees, so the bright knots sit inside the haze
    // instead of floating loose across the whole screen.
    let warm_amount = smoothstep(0.55, 0.85, density) * smoothstep(0.6, 0.95, hotspot);
    let color = mix(blue, warm, warm_amount);

    // Base transparency follows cloud density, with a small extra boost
    // in the warm core areas so those spots glow a little brighter.
    // Stars stay visible through the thinner parts of the haze.
    let base_alpha = clamp(density - 0.32, 0.0, 1.0) * 0.5;
    let alpha = clamp(base_alpha + warm_amount * 0.25, 0.0, 0.78);

    return vec4<f32>(color, alpha);
}
