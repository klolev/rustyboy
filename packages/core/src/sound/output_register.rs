use crate::util::bits;

#[derive(Copy, Clone, Default)]
pub struct OutputRegister {
    pub pan_register: u8,
    pub toggle_register: u8,
    pub master_register: u8
}

impl OutputRegister {
    pub fn channel1_pan(self) -> (bool, bool) {
        (
            bits::get_bit(self.pan_register, 0),
            bits::get_bit(self.pan_register, 4)
        )
    }

    pub fn channel2_pan(self) -> (bool, bool) {
        (
            bits::get_bit(self.pan_register, 1),
            bits::get_bit(self.pan_register, 5)
        )
    }

    pub fn channel3_pan(self) -> (bool, bool) {
        (
            bits::get_bit(self.pan_register, 2),
            bits::get_bit(self.pan_register, 6)
        )
    }

    pub fn channel4_pan(self) -> (bool, bool) {
        (
            bits::get_bit(self.pan_register, 3),
            bits::get_bit(self.pan_register, 7)
        )
    }

    pub fn master_volume(&self) -> (u8, u8) {
        (
            (self.master_register >> 4) & 0b111,
            self.master_register & 0b111
        )
    }

    pub fn sound_enabled(&self) -> bool {
        bits::get_bit(self.toggle_register, 7)
    }

    pub fn channel1_on(&self) -> bool {
        bits::get_bit(self.toggle_register, 0)
    }

    pub fn channel2_on(&self) -> bool {
        bits::get_bit(self.toggle_register, 1)
    }

    pub fn channel3_on(&self) -> bool {
        bits::get_bit(self.toggle_register, 2)
    }

    pub fn channel4_on(&self) -> bool {
        bits::get_bit(self.toggle_register, 3)
    }
}
