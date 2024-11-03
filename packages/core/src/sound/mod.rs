use crate::bus::{Readable, Writable};
use crate::sound::channels::wave_channel::WaveChannel;
use crate::sound::channels::noise_channel::NoiseChannel;
use crate::sound::channels::channel1::Channel1;
use crate::sound::channels::channel2::Channel2;
use crate::sound::output_register::OutputRegister;
use crate::util::bits;

mod channels;
mod frequency_register;
mod output_register;
mod sweep_register;
mod volume_envelope;
mod wave_duty_register;

pub const SOUND_BUFFER_SIZE: usize = 2048;
pub const SOUND_BUFFER_CLOCKS_PER_SAMPLE: usize = 87;

pub struct Sound {
    pub channel1: Channel1,
    pub channel2: Channel2,
    wave_channel: WaveChannel, // wave output
    pub noise_channel: NoiseChannel,
    pub output_register: OutputRegister,
    last_divider: u8,
    samples_buffer: [AudioSample; SOUND_BUFFER_SIZE],
    current_sample_buffer: [AudioSample; SOUND_BUFFER_CLOCKS_PER_SAMPLE],
    buffer_position: usize,
    clocks_count: usize,
}

impl Default for Sound {
    fn default() -> Self {
        Self {
            channel1: Channel1::default(),
            channel2: Channel2::default(),
            wave_channel: WaveChannel::default(),
            noise_channel: NoiseChannel::default(),
            output_register: OutputRegister::default(),
            last_divider: 0,
            samples_buffer: [AudioSample::default(); SOUND_BUFFER_SIZE],
            current_sample_buffer: [AudioSample::default(); SOUND_BUFFER_CLOCKS_PER_SAMPLE],
            buffer_position: 0,
            clocks_count: 0,
        }
    }
}

#[derive(Default, Copy, Clone)]
pub struct AudioSample {
    pub left: f64,
    pub right: f64
}

impl Sound {
    pub fn clock(&mut self, divider: u8) {
        if bits::get_bit(self.last_divider, 4) && !bits::get_bit(divider, 4) {
            self.tick();
        }

        self.channel1.clock();
        self.channel2.clock();
        self.noise_channel.clock();

        self.last_divider = divider;

        self.current_sample_buffer[self.clocks_count] = self.output();
        self.clocks_count = (self.clocks_count + 1) % SOUND_BUFFER_CLOCKS_PER_SAMPLE;
        if self.clocks_count == 0 {
            let mut average = AudioSample::default();
            for i in 0..SOUND_BUFFER_CLOCKS_PER_SAMPLE {
                average.left += self.current_sample_buffer[i].left;
                average.right += self.current_sample_buffer[i].right;
            }

            self.samples_buffer[self.buffer_position] = AudioSample {
                left: average.left / SOUND_BUFFER_CLOCKS_PER_SAMPLE as f64,
                right: average.right / SOUND_BUFFER_CLOCKS_PER_SAMPLE as f64,
            };
            self.buffer_position = (self.buffer_position + 1) % SOUND_BUFFER_SIZE;
        }
    }

    pub fn is_buffer_ready(&self) -> bool {
        self.buffer_position == 0
    }

    fn tick(&mut self) {
        self.channel1.tick();
        self.channel2.tick();
        self.noise_channel.tick();
    }

    pub fn sample(&self) -> Vec<AudioSample> {
        self.samples_buffer.to_vec()
    }

    pub fn output(&self) -> AudioSample {
        if !self.output_register.sound_enabled() {
            return AudioSample::default();
        }

        let (panned_volumes, max_amplitude) = [
            (
                self.channel1.output(), 
                self.output_register.channel1_pan()
            ),
            (
                self.channel2.output(), 
                self.output_register.channel2_pan()
            ),
            (
                self.noise_channel.output(), 
                self.output_register.channel4_pan()
            )
        ].iter().fold(((0f64, 0f64), 0u8), |acc, value| {
            let (output, pan) = value;

            let mut next = acc.0;
            if pan.0 {
                next.0 += *output;
            }
            if pan.1 {
                next.1 += *output;
            }

            return (next, acc.1 + 0xF);
        });

        let adjusted_volume = |volume: f64, adjustment: u8| {
            let adjusted_adjustment = ((adjustment + 1) as f64) / 8.0;
            ((volume as f64) * adjusted_adjustment) / max_amplitude as f64
        };

        let (left_volume, right_volume) = self.output_register.master_volume();
        return AudioSample {
            left: adjusted_volume(panned_volumes.0, left_volume),
            right: adjusted_volume(panned_volumes.1, right_volume)
        };
    }
}

impl Readable for Sound {
    fn read(&self, address: u16) -> u8 {
        match address {
            0xFF10..=0xFF14 => self.channel1.read(address),
            0xFF16..=0xFF19 => self.channel2.read(address),
            0xFF1A..=0xFF1E
            | 0xFF30..=0xFF3F => self.wave_channel.read(address),
            0xFF20..=0xFF23 => self.noise_channel.read(address),
            0xFF24 => self.output_register.master_register,
            0xFF25 => self.output_register.pan_register,
            0xFF26 => self.output_register.toggle_register,
            _ => { 0xFF }
        }
    }
}

impl Writable for Sound {
    fn write(&mut self, address: u16, value: u8) {
        match address {
            0xFF10..=0xFF14 => self.channel1.write(address, value),
            0xFF16..=0xFF19 => self.channel2.write(address, value),
            0xFF1A..=0xFF1E
            | 0xFF30..=0xFF3F => self.wave_channel.write(address, value),
            0xFF20..=0xFF23 => self.noise_channel.write(address, value),
            0xFF24 => self.output_register.master_register = value,
            0xFF25 => self.output_register.pan_register = value,
            0xFF26 => self.output_register.toggle_register = (value & 0b1000_0000) | (self.output_register.toggle_register & 0xF),
            _ => {}
        }
    }
}
