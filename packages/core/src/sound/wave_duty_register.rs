use std::cmp::max;

#[derive(Default, Copy, Clone)]
pub struct WaveDutyRegister {
    pub register: u8,
    timer: u8
}

pub enum WaveDutyRegisterClockResult {
    Stop,
    None
}

impl WaveDutyRegister {
    pub fn clock(&mut self) -> WaveDutyRegisterClockResult {
        self.timer = max(self.timer + 1, self.initial_timer_value());
        if self.timer == 128 {
            WaveDutyRegisterClockResult::Stop
        } else {
            WaveDutyRegisterClockResult::None
        }
    }

    pub fn duty(self) -> f32 {
        match self.register >> 6 {
            0 => 0.125,
            1 => 0.25,
            2 => 0.5,
            _ => 0.75
        }
    }

    fn initial_timer_value(self) -> u8 {
        self.register & 0b11_1111
    }
}
