use glium::{
    backend::glutin::simple_window_builder::{GliumEventLoop, SimpleWindowBuilder},
    Display,
};
use glium::backend::glutin::glutin::surface::WindowSurface;
use rustyboy_core::gameboy::Gameboy;

pub mod background;
pub mod screen;
pub mod tile_data;

pub trait Window {
    fn update(&mut self, gameboy: &mut Gameboy) -> UpdateResult;
}

pub fn create_display(
    title: &str,
    dimensions: (usize, usize),
    events_loop: &dyn GliumEventLoop,
) -> Display<WindowSurface> {
    SimpleWindowBuilder::new()
        .with_title(title)
        .with_inner_size(dimensions.0 as f64, dimensions.1 as f64)
        .build(events_loop).1
}

pub enum UpdateResult {
    Continue,
    Close,
}
