/// Pure data only -- every live GPU/window handle needed across frames.
/// No methods here; construction, mutation, and rendering are all "tasks".
pub struct RenderState {
    pub surface: wgpu::Surface<'static>,
    pub device: wgpu::Device,
    pub queue: wgpu::Queue,
    pub config: wgpu::SurfaceConfiguration,
    pub pipeline: wgpu::RenderPipeline,
    pub vertex_buffer: wgpu::Buffer,
    pub index_buffer: wgpu::Buffer,
    pub index_count: u32,
    pub uniform_buffer: wgpu::Buffer,
    pub bind_group: wgpu::BindGroup,
    pub depth_view: wgpu::TextureView,

    // Green nebula clouds
    pub green_mist_pipeline: wgpu::RenderPipeline,
    pub green_mist_uniform_buffer: wgpu::Buffer,
    pub green_mist_bind_group: wgpu::BindGroup,

    // Other nebula clouds
    pub nebula_pipeline: wgpu::RenderPipeline,

    // Starfields
    pub starfield_pipeline: wgpu::RenderPipeline,
}
