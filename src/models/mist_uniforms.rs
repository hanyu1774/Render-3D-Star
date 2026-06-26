#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct MistUniforms {
    pub time: f32,
    pub aspect: f32,
    pub _pad0: f32,
    pub _pad1: f32,
}
