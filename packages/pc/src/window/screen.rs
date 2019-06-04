use glium::glutin::EventsLoop;
use glium::texture::RawImage2d;
use glium::uniforms::MagnifySamplerFilter;
use glium::{Display, Surface};

use rustyboy_core::gameboy::Gameboy;

use super::{create_display, Window};

pub struct MainWindow {
    pub display: Display,
}

impl MainWindow {
    pub fn new(events_loop: &EventsLoop) -> MainWindow {
        MainWindow {
            display: create_display("Rustyboy", &events_loop, (160, 144)),
        }
    }
}

impl Window for MainWindow {
    fn update(&self, gameboy: &Gameboy) {
        let mut target = self.display.draw();
        target.clear_color(0.0, 0.0, 1.0, 1.0);
        let screen = gameboy.hardware().video().screen();
        let buf = screen.draw(gameboy.hardware().video());
        let img = RawImage2d::from_raw_rgb_reversed(
            &buf,
            (screen.dimensions.0 as u32, screen.dimensions.1 as u32),
        );
        glium::Texture2d::new(&self.display, img)
            .unwrap()
            .as_surface()
            .fill(&target, MagnifySamplerFilter::Nearest);

        target.finish().unwrap();
    }
}