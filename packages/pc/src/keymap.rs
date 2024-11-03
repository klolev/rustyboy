use glium::backend::winit::event::{KeyEvent, ElementState};
use glium::backend::winit::keyboard::{KeyCode, PhysicalKey};

use rustyboy_core::hardware::joypad::{Button, Input, InputType};

pub fn keymap(input: KeyEvent) -> Option<Input> {
    let button = match input.physical_key {
        PhysicalKey::Code(KeyCode::ArrowUp) => Button::Up,
        PhysicalKey::Code(KeyCode::ArrowDown) => Button::Down,
        PhysicalKey::Code(KeyCode::ArrowLeft) => Button::Left,
        PhysicalKey::Code(KeyCode::ArrowRight) => Button::Right,
        PhysicalKey::Code(KeyCode::Enter) => Button::Start,
        PhysicalKey::Code(KeyCode::Space) => Button::Select,
        PhysicalKey::Code(KeyCode::KeyX) => Button::B, // TODO: use scancode for those so keymaps dont change the position
        PhysicalKey::Code(KeyCode::KeyZ) => Button::A,
        _ => return None,
    };

    let input_type = if input.state == ElementState::Pressed {
        InputType::Down
    } else {
        InputType::Up
    };

    Some(Input { input_type, button })
}
