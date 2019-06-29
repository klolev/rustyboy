use glium::glutin::{Event, EventsLoop, WindowEvent};
use glium::texture::RawImage2d;
use glium::uniforms::MagnifySamplerFilter;
use glium::{Display, Surface};
use std::process::exit;

use rustyboy_core::gameboy::Gameboy;
use rustyboy_core::video::debugging::tile_buffer;
use rustyboy_core::video::screen::BACKGROUND_SIZE;

use super::{create_display, Window};
use crate::keymap::keymap;
use rustyboy_core::video::color::{ColorFormat, Color};

const TILE_SIZE: usize = 8;
const GRID_DIMENSIONS: (usize, usize) = (12, 32);

pub struct TileDataWindow {
    display: Display,
    events_loop: EventsLoop,
}

impl TileDataWindow {
    pub fn new() -> TileDataWindow {
        let events_loop = EventsLoop::new();

        TileDataWindow {
            display: create_display("Rustyboy | Tile data", BACKGROUND_SIZE, &events_loop),
            events_loop,
        }
    }
}

impl Window for TileDataWindow {
    fn update(&mut self, gameboy: &mut Gameboy) {
        let mut target = self.display.draw();
        target.clear_color(0.0, 0.0, 1.0, 1.0);

        let tile_data = gameboy.hardware().video().memory().tile_data();

        let buffer: Vec<u8> = (0..GRID_DIMENSIONS.1 * TILE_SIZE).flat_map(|y| {
            (0..GRID_DIMENSIONS.0).flat_map(|grid_x| {
                vec![]
//                let grid_y = (y - y % TILE_SIZE) / TILE_SIZE;
//                let tile_y = y % TILE_SIZE;
//                let base_tile_index = grid_y * GRID_DIMENSIONS.0;
//                let tile = tile_data[base_tile_index + grid_x];
//                tile.colored_line(tile_y as u8, false, false).to_vec()
            })
            .collect()
        })
        .collect();

        let img = RawImage2d::from_raw_rgb_reversed(
            &buffer,
            ((GRID_DIMENSIONS.0 * TILE_SIZE) as u32, (GRID_DIMENSIONS.1 * TILE_SIZE) as u32),
        );
        glium::Texture2d::new(&self.display, img)
            .unwrap()
            .as_surface()
            .fill(&target, MagnifySamplerFilter::Nearest);

        target.finish().unwrap();

        self.events_loop.poll_events(|event| match event {
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => {
                exit(0);
            }
            Event::WindowEvent {
                event: WindowEvent::KeyboardInput { input, .. },
                ..
            } => {
                let input = keymap(input);
                if let Some(input) = input {
                    gameboy.send_input(input);
                }
            }
            _ => {}
        })
    }
}
