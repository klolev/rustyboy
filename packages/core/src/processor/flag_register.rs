use crate::processor::register::{DualRegister, Register, SingleRegister};
use crate::util::bitflags::Bitflags;

pub struct FlagRegister {
    register: DualRegister,
}

impl FlagRegister {
    pub fn new() -> FlagRegister {
        FlagRegister {
            register: DualRegister::from(0x01B0),
        }
    }

    pub fn accumulator(&self) -> &SingleRegister {
        &self.register.high
    }

    pub fn flags(&self) -> &SingleRegister {
        &self.register.low
    }

    pub fn set_accumulator(&mut self, value: u8) {
        self.register.high.set(value as u16);
    }

    pub fn set_flags(&mut self, value: u8) {
        self.register.low.set(value as u16 & 0xF0);
    }

    pub fn register(&self) -> &DualRegister {
        &self.register
    }

    pub fn set(&mut self, value: u16) {
        self.set_flags(value as u8);
        self.set_accumulator((value >> 8) as u8);
    }
}

impl Bitflags<Flag> for FlagRegister {
    fn register(&self) -> u8 {
        self.register.low.get() as u8
    }

    fn set_register(&mut self, value: u8) {
        self.register.low.set(value as u16);
    }
}

#[derive(Copy, Clone, Debug)]
pub enum Flag {
    Carry = 16,     // c, set when an addition becomes bigger than 0xFF or 0xFFFF
    HalfCarry = 32, // h
    AddSub = 64,    // n
    Zero = 128,     // z, set when an operation has been zero
}

impl Into<u8> for Flag {
    fn into(self) -> u8 {
        self as u8
    }
}

pub const fn half_carry_add(value1: u8, value2: u8) -> bool {
    (((value1 & 0xf) + (value2 & 0xf)) & 0x10) == 0x10
}

pub const fn half_carry_add16(value1: u16, value2: u16) -> bool {
    (((value1 & 0xfff) + (value2 & 0xfff)) & 0x1000) == 0x1000
}

pub const fn half_carry_sub(value1: u8, value2: u8) -> bool {
    value1 & 0xF < value2 & 0xF
}

pub fn carry_add(value1: u8, value2: u8) -> bool {
    value1.overflowing_add(value2).1
}
