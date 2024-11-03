use rand::{Rng, SeedableRng};
use rand::rngs::SmallRng;
use crate::gameboy::CLOCK_SPEED;
use crate::bus::{Readable, Writable};
use crate::sound::volume_envelope::VolumeEnvelope;
use crate::util::bits;

pub struct NoiseChannel {
    rng_generator: SmallRng,
    pub sound_length: u8,
    pub volume_envelope: VolumeEnvelope,
    pub shift_register: u8,
    pub frequency_randomness_register: u8
}

impl Default for NoiseChannel {
    fn default() -> Self {
        NoiseChannel {
            rng_generator: SmallRng::from_entropy(),
            sound_length: 0,
            volume_envelope: VolumeEnvelope::default(),
            shift_register: 0,
            frequency_randomness_register: 0
        }
    }
}

impl NoiseChannel {
    fn is_long_mode(&self) -> bool {
        bits::get_bit(self.frequency_randomness_register, 3)
    }

    fn trigger(&mut self) {
        self.volume_envelope.trigger();
    }

    fn shift(&mut self) {
        let result = bits::get_bit(self.shift_register, 0) ^ bits::get_bit(self.shift_register, 1);
        let next_bit: bool = self.rng_generator.gen();
        self.shift_register = (self.shift_register >> 1) & (next_bit as u8);

        self.shift_register = bits::set_bit(self.shift_register, 15, result);
        if self.is_long_mode() {
            self.shift_register = bits::set_bit(self.shift_register, 7, result);
        }
    }

    pub fn output(&self) -> f64 {
        (if bits::get_bit(self.shift_register, 0) { 1.0 } else { -1.0 }) * self.volume_envelope.current_volume()
    }

    fn divider(&self) -> f64 {
        ((self.frequency_randomness_register & 0b111) as f64).max(0.5)
    }

    fn clock_shift(&self) -> u8 {
        self.frequency_randomness_register >> 4
    }

    pub fn clock(&mut self) {
        let shift_count = (self.shift_frequency() / CLOCK_SPEED) as u32;
        for _ in 0..shift_count {
            self.shift();
        }
    }

    pub fn tick(&mut self) {
        self.volume_envelope.tick()
    }

    /// number of cycles required to shift
    fn shift_frequency(&self) -> f64 {
        262144.0 / (self.divider() * (1 << self.clock_shift()) as f64)
    }
}

impl Readable for NoiseChannel {
    fn read(&self, address: u16) -> u8 {
        match address {
            0xFF20 => self.sound_length,
            0xFF21 => self.volume_envelope.register,
            0xFF22 => self.frequency_randomness_register,
            0xFF23 => { 0xFF },
            _ => { unimplemented!() }
        }
    }
}

impl Writable for NoiseChannel {
    fn write(&mut self, address: u16, value: u8) {
        match address {
            0xFF20 => { self.sound_length = value },
            0xFF21 => { self.volume_envelope.register = value },
            0xFF22 => { self.frequency_randomness_register = value },
            0xFF23 => {
                if bits::get_bit(value, 7) {
                    self.trigger();
                }
            },
            _ => { unimplemented!() }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn channel(seed: u64) -> NoiseChannel {
        NoiseChannel {
            rng_generator: SmallRng::seed_from_u64(seed),
            sound_length: 0,
            volume_envelope: VolumeEnvelope::default(),
            shift_register: 0,
            frequency_randomness_register: 0
        }
    }

    #[test]
    fn test_frequency() {
        let mut channel = channel(0);
        let expected = 262144.0 / (0.5 * (1u8 << channel.clock_shift()) as f64);
        let actual = channel.shift_frequency();
        assert_eq!(actual, expected)
    }
}
