use crate::models::input_action::InputAction;
use winit::event::{ElementState, KeyEvent, WindowEvent};
use winit::keyboard::{KeyCode, PhysicalKey};

pub fn run(event: &WindowEvent) -> InputAction {
    match event {
        WindowEvent::CloseRequested => InputAction::Quit,
        WindowEvent::KeyboardInput {
            event:
                KeyEvent {
                    physical_key: PhysicalKey::Code(KeyCode::Escape),
                    state: ElementState::Pressed,
                    ..
                },
            ..
        } => InputAction::Quit,
        WindowEvent::Resized(size) => InputAction::Resize(size.width, size.height),
        WindowEvent::RedrawRequested => InputAction::Redraw,
        _ => InputAction::Ignore,
    }
}
