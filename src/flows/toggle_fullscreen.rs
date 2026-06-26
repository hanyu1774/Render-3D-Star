use winit::window::Fullscreen;

pub fn run(current: Option<Fullscreen>) -> Option<Fullscreen> {
    match current {
        Some(_) => None,
        None => Some(Fullscreen::Borderless(None)),
    }
}
