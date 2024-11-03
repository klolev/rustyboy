use crate::util::bits;
use crate::bus::{Readable, Writable};
use crate::sound::sweep_register::SweepRegister;
use crate::sound::wave_duty_register::WaveDutyRegister;
use crate::sound::volume_envelope::VolumeEnvelope;
use crate::sound::frequency_register::FrequencyRegister;

#[derive(Default)]
pub struct Channel1 {
    sweep_register: SweepRegister,
    wave_duty_register: WaveDutyRegister,
    pub volume_envelope: VolumeEnvelope,
    frequency_register: FrequencyRegister
}

impl Channel1 {
    pub fn clock(&mut self) {
        self.frequency_register.clock();
    }

    pub fn tick(&mut self) {
        self.wave_duty_register.tick();
        if let Some(new_period) = self.sweep_register.tick(self.frequency_register.period_value()) {
            self.frequency_register.set_period_value(new_period);
        }
        self.volume_envelope.tick();
    }

    fn trigger(&mut self) {
        self.frequency_register.trigger();
        self.wave_duty_register.trigger();
        self.volume_envelope.trigger();
    }

    pub fn output(&self) -> f64 {
        let raw_value = self.wave_duty_register.output(self.frequency_register.duty_step());
        return raw_value * self.volume_envelope.current_volume();
    }
}

impl Readable for Channel1 {
    fn read(&self, address: u16) -> u8 {
        match address {
            0xFF10 => self.sweep_register.register,
            0xFF11 => self.wave_duty_register.read(),
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
            0xFF11 => self.wave_duty_register.write(value),
            0xFF12 => self.volume_envelope.register = value,
            0xFF13 => self.frequency_register.low_register = value,
            0xFF14 => {
                self.frequency_register.high_register = value;
                if bits::get_bit(value, 7) {
                    self.trigger();
                }
            },
            _ => panic!("Illegal sound channel 1 write")
        }
    }
}
