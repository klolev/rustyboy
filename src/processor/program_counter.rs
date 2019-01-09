use crate::bus::Bus;
use crate::processor::register::Register;

pub struct ProgramCounter {
    value: u16
}

impl ProgramCounter {
    pub fn new() -> ProgramCounter {
        ProgramCounter {
            value: 0x100
        }
    }

    pub fn fetch<H: Bus>(&mut self, bus: &H) -> u8 {
        let value = bus.read(self.value);
        self.increment();
        value
    }
}

impl Register for ProgramCounter {
    fn get(&self) -> u16 {
        self.value
    }

    fn set(&mut self, value: u16) {
        self.value = value
    }

    fn increment(&mut self) {
        self.value = self.value.wrapping_add(1);
    }

    fn decrement(&mut self) {
        self.value = self.value.wrapping_sub(1);
    }
}