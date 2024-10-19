use crate::bus::{Readable, Writable};
use crate::sound::sweep_register::SweepRegister;
use crate::sound::wave_duty_register::WaveDutyRegister;
use crate::sound::volume_envelope::VolumeEnvelope;
use crate::sound::frequency_register::FrequencyRegister;

#[derive(Default)]
pub struct Channel1 {
    sweep_register: SweepRegister,
    wave_duty_register: WaveDutyRegister,
    volume_envelope: VolumeEnvelope,
    frequency_register: FrequencyRegister,
    offset: f64
}

impl Channel1 {
    pub fn clock(&mut self) {
        self.sweep_register.clock();
        self.wave_duty_register.clock();
        self.volume_envelope.clock();
    }

    fn value(&self, t: f64) {
        let period = self.frequency_register.period();

    }

    pub fn fill(buffer: &mut [f32]) {

    }
}

impl Readable for Channel1 {
    fn read(&self, address: u16) -> u8 {
        match address {
            0xFF10 => self.sweep_register.register,
            0xFF11 => self.wave_duty_register.register,
            0xFF12 => self.volume_envelope.register,
            0xFF13 => { 0xFF }, // Write-only
            0xFF14 => self.frequency_register.high_register,
            _ => panic!("Illegal sound channel 1 read")
        }
    }
}

impl Writable for Channel1 {
    fn write(&mut self, address: u16, value: u8) {
        match address {
            0xFF10 => self.sweep_register.register = value,
            0xFF11 => self.wave_duty_register.register = value,
            0xFF12 => self.volume_envelope.register = value,
            0xFF13 => self.frequency_register.low_register = value,
            0xFF14 => self.frequency_register.high_register = value,
            _ => panic!("Illegal sound channel 1 write")
        }
    }
}