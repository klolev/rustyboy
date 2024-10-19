use rand;
use crate::bus::{Readable, Writable};
use crate::sound::volume_envelope::VolumeEnvelope;
use crate::util::bits;

#[derive(Default)]
pub struct NoiseChannel {
    pub sound_length: u8,
    pub volume_envelope: VolumeEnvelope,
    pub shift_register: u8,
    pub frequency_randomness_register: u8
}

impl NoiseChannel {
    fn is_long_mode(&self) -> bool {
        bits::get_bit(self.frequency_randomness_register, 3)
    }

    fn shift(&mut self) {
        let result = bits::get_bit(self.shift_register, 0) ^ bits::get_bit(self.shift_register, 1);
        let next_bit: bool = rand::random();
        self.shift_register = (self.shift_register >> 1) & (next_bit as u8);

        self.shift_register = bits::set_bit(self.shift_register, 15, result);
        if self.is_long_mode() {
            self.shift_register = bits::set_bit(self.shift_register, 7, result);
        }
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
            0xFF23 => {},
            _ => { unimplemented!() }
        }
    }
}
