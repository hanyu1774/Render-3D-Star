/// Returns true if a resize happened (caller should then refresh the
/// depth buffer via flows::depth::run), false if the size was degenerate.
pub fn run(
    device: &wgpu::Device,
    surface: &wgpu::Surface,
    config: &mut wgpu::SurfaceConfiguration,
    width: u32,
    height: u32,
) -> bool {
    if width == 0 || height == 0 {
        return false;
    }
    config.width = width;
    config.height = height;
    surface.configure(device, config);
    true
}
