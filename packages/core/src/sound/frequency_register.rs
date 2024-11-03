use crate::util::bits;

#[derive(Copy, Clone)]
pub struct FrequencyRegister {
    pub low_register: u8,
    pub high_register: u8,
    counter: u16,
    duty_step: u8
}

impl Default for FrequencyRegister {
    fn default() -> Self {
        Self {
            low_register: 0,
            high_register: 0,
            counter: 2048,
            duty_step: 0
        }
    }
}

impl FrequencyRegister {
    pub fn clock(&mut self) {
        self.counter -= 1;
        if self.counter == 0 {
            self.counter = (2048 - self.period_value()) * 4;
            self.duty_step = (self.duty_step + 1) % 8;
        }
    }

    pub fn trigger(&mut self) {
        self.counter = (2048 - self.period_value()) * 4;
    }

    pub fn set_period_value(&mut self, value: u16) {
        self.low_register = value as u8;
        self.high_register = (self.high_register & 0b1111_1000) | (value >> 8) as u8
    }

    pub fn period_value(&self) -> u16 {
        (self.low_register as u16) | (((self.high_register as u16) & 0b111) << 8)
    }

    /// Whether the output stops once the sound length is attained
    pub fn is_finite(self) -> bool {
        bits::get_bit(self.high_register, 6)
    }

    pub fn is_triggered(self) -> bool {
        bits::get_bit(self.high_register, 7)
    }

    pub fn duty_step(&self) -> u8 {
        self.duty_step
    }
}
