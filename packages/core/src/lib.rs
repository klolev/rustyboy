uniffi::include_scaffolding!("bindings");

use std::sync::Mutex;
use crate::cartridge::Cartridge;
use crate::gameboy::{Gameboy, CLOCK_SPEED};
use crate::cartridge::{
    cartridge_metadata::{CartridgeMetadata, Destination, CGBFlag},
    cartridge_capability::CartridgeCapability,
    cartridge_metadata_error::CartridgeMetadataError
};
use crate::util::savestate::LoadSavestateError;
use crate::hardware::joypad::Button;
use crate::sound::AudioSample;
use crate::video::status_register::StatusMode;
use crate::step::{StepInput, GameboyStepResult};

pub mod bus;
pub mod step;
pub mod cartridge;
pub mod config;
pub mod debugger;
pub mod gameboy;
pub mod hardware;
pub mod processor;
pub mod util;
pub mod video;
pub mod sound;

pub struct GameGirlGameboy {
    gameboy: Mutex<Gameboy>
}

pub struct UpdateResult {
    pub frame: Option<Vec<u8>>,
    pub audio_samples: Option<Vec<AudioSample>>
}

pub struct AudioChannelDebugging {
    pub pan_left: bool,
    pub pan_right: bool,
    pub enabled: bool,
    pub volume: f64,
    pub initial_volume: u8,
    pub volume_adjustment: i8,
    pub output: f64
}

pub struct AudioDebugging {
    pub sound_enabled: bool,
    pub master_volume_left: u8,
    pub master_volume_right: u8,
    pub channel1: AudioChannelDebugging,
    pub channel2: AudioChannelDebugging,
    pub channel3: AudioChannelDebugging,
    pub channel4: AudioChannelDebugging
}

struct GameGirlCartridge {
    cartridge: Cartridge
}

impl GameGirlCartridge {
    pub fn new(buffer: Vec<u8>) -> Result<Self, CartridgeMetadataError> {
        Ok(Self {
            cartridge: Cartridge::from_buffer(buffer)?
        })
    }

    pub fn get_metadata(&self) -> CartridgeMetadata {
        self.cartridge.metadata.clone()
    }
}

impl GameGirlGameboy {
    pub fn new(buffer: Vec<u8>) -> Result<Self, CartridgeMetadataError> {
        Ok(Self {
            gameboy: Mutex::new(Gameboy::new(Cartridge::from_buffer(buffer)?))
        })
    }

    pub fn reset(&self) {
        self.gameboy.lock().unwrap().reset();
    }

    pub fn run_to_vblank(&self, input: StepInput) -> Vec<u8> {
        let mut gb = self.gameboy.lock().unwrap();
        gb.run_to_vblank(input);
        gb.hardware().video.screen().buffer.rgba().to_vec()
    }

    pub fn get_frame(&self) -> Vec<u8> {
        let gb = self.gameboy.lock().unwrap();
        gb.hardware().video.screen().buffer.rgba().to_vec()
    }

    pub fn update(&self, input: StepInput, delta_time: f64) -> UpdateResult {
        let mut gb = self.gameboy.lock().unwrap();

        let cycles = delta_time * CLOCK_SPEED;
        let mut needs_redraw = false;
        let mut audio_samples: Option<Vec<AudioSample>> = None;
        for _ in 0..(cycles as u64) {
            if let GameboyStepResult(_, Some(StatusMode::VBlank)) = gb.step(input) {
                needs_redraw = true;
            }

            if gb.hardware().sound.is_buffer_ready() {
                audio_samples = Some(gb.hardware().sound.sample());
            }
        }

        let frame = if needs_redraw {
            Some(gb.hardware().video.screen().buffer.rgba().to_vec())
        } else {
            None
        };

        UpdateResult {
            frame,
            audio_samples
        }
    }

    pub fn dump_savestate(&self) -> Vec<u8> {
        self.gameboy.lock().unwrap().dump_savestate()
    }

    pub fn get_audio_debugging(&self) -> AudioDebugging {
        let gb = self.gameboy.lock().unwrap();
        let sound = &gb.hardware().sound;

        AudioDebugging {
            sound_enabled: sound.output_register.sound_enabled(),
            master_volume_left: sound.output_register.master_volume().0,
            master_volume_right: sound.output_register.master_volume().1,
            channel1: AudioChannelDebugging {
                volume: sound.channel1.volume_envelope.current_volume(),
                enabled: sound.output_register.channel1_on(),
                pan_left: sound.output_register.channel1_pan().0,
                pan_right: sound.output_register.channel1_pan().1,
                initial_volume: sound.channel1.volume_envelope.initial_volume(),
                volume_adjustment: sound.channel1.volume_envelope.volume_adjustment,
                output: sound.channel1.output()
            },
            channel2: AudioChannelDebugging {
                volume: sound.channel2.volume_envelope.current_volume(),
                enabled: sound.output_register.channel2_on(),
                pan_left: sound.output_register.channel2_pan().0,
                pan_right: sound.output_register.channel2_pan().1,
                initial_volume: sound.channel2.volume_envelope.initial_volume(),
                volume_adjustment: sound.channel2.volume_envelope.volume_adjustment,
                output: sound.channel2.output()
            },
            channel3: AudioChannelDebugging {
                volume: 0.0,
                initial_volume: 0,
                pan_left: false,
                pan_right: false,
                enabled: false,
                volume_adjustment: 0,
                output: 0.0
            },
            channel4: AudioChannelDebugging {
                volume: sound.noise_channel.volume_envelope.current_volume(),
                enabled: sound.output_register.channel4_on(),
                pan_left: sound.output_register.channel4_pan().0,
                pan_right: sound.output_register.channel4_pan().1,
                initial_volume: sound.noise_channel.volume_envelope.initial_volume(),
                volume_adjustment: sound.noise_channel.volume_envelope.volume_adjustment,
                output: 0.0
            }
        }
    }

    pub fn load_savestate(&self, buffer: Vec<u8>) -> Result<(), LoadSavestateError> {
        self.gameboy.lock().unwrap().load_savestate(buffer)
    }
}
