use glium::backend::winit::event::{KeyEvent, ElementState};
use glium::backend::winit::keyboard::KeyCode;

use rustyboy_core::hardware::joypad::{Button, Input, InputType};

pub fn keymap(input: KeyEvent) -> Option<Input> {
    let key_code = input.virtual_keycode?;
    let button = match key_code {
        KeyCode::ArrowUp => Button::Up,
        KeyCode::ArrowDown => Button::Down,
        KeyCode::ArrowLeft => Button::Left,
        KeyCode::ArrowRight => Button::Right,
        KeyCode::Enter => Button::Start,
        KeyCode::Space => Button::Select,
        KeyCode::KeyX => Button::B, // TODO: use scancode for those so keymaps dont change the position
        KeyCode::KeyZ => Button::A,
        _ => return None,
    };

    let input_type = if input.state == ElementState::Pressed {
        InputType::Down
    } else {
        InputType::Up
    };

    Some(Input { input_type, button })
}
