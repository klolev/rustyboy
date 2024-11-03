use std::cmp::max;

#[derive(Default, Copy, Clone)]
pub struct WaveDutyRegister {
    timer: u8,
    duty_cycle: u8
}

pub enum WaveDutyRegisterClockResult {
    Stop,
    None
}

impl WaveDutyRegister {
    pub fn tick(&mut self) -> WaveDutyRegisterClockResult {
        self.timer = (self.timer + 1).min(64);
        if self.timer == 64 {
            WaveDutyRegisterClockResult::Stop
        } else {
            WaveDutyRegisterClockResult::None
        }
    }

    pub fn enabled(&self) -> bool {
        self.timer != 64
    }

    pub fn trigger(&mut self) {
        self.timer = 0;
    }

    pub fn output(&self, index: u8) -> f64 {
        if !self.enabled() {
            return 0.0;
        }

        match self.duty_cycle {
            0 => if index == 7 { -1.0 } else { 1.0 },
            1 => if index == 0 || index == 7 { -1.0 } else { 1.0 },
            2 => if index == 0 || index > 4 { -1.0 } else { 1.0 },
            _ => if index == 0 || index == 7 { 1.0 } else { -1.0 }
        }
    }

    pub fn read(&self) -> u8 {
        (self.duty_cycle << 6) | self.timer
    }

    pub fn write(&mut self, value: u8) {
        self.duty_cycle = value >> 6;
        self.timer = value & 0b111111;
    }
}
