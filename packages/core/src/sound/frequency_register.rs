use crate::util::bits;

#[derive(Copy, Clone, Default)]
pub struct FrequencyRegister {
    pub low_register: u8,
    pub high_register: u8,
}

impl FrequencyRegister {
    pub fn period(self) -> i16 {
        let value: i16 = -((((self.high_register as u16 & 0b111) << 8) | (self.low_register as u16)) as i16);
        return 2048_i16 - value;
    }

    /// Whether the output stops once the sound length is attained
    pub fn is_finite(self) -> bool {
        bits::get_bit(self.high_register, 6)
    }

    pub fn is_triggered(self) -> bool {
        bits::get_bit(self.high_register, 7)
    }
}
