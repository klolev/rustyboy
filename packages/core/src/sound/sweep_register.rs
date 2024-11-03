#[derive(Copy, Clone)]
pub struct SweepRegister {
    pub register: u8,
    cycles_left: u8
}

impl Default for SweepRegister {
    fn default() -> Self {
        Self {
            register: 0,
            cycles_left: 4
        }
    }
}

impl SweepRegister {
    fn sweep_pace(self) -> u8 {
        (self.register >> 4) & 0b111
    }

    fn sweep_modifier(self) -> SweepModifier {
        if ((self.register >> 3) & 1) == 0 {
            SweepModifier::Decrease
        } else {
            SweepModifier::Increase
        }
    }

    fn sweep_step(self) -> u8 {
        self.register & 0b111
    }

    fn apply_sweep(&mut self, period: u16) -> u16 {
        let adjustment = period / (1 << self.sweep_step() as u16);
        if self.sweep_modifier() == SweepModifier::Increase {
            (period + 1) % 0b111_1111_1111
        } else {
            period.saturating_sub(1)
        }
    }

    pub fn tick(&mut self, period: u16) -> Option<u16> {
        self.cycles_left = self.cycles_left.saturating_sub(1);
        if self.cycles_left == 0 {
            self.cycles_left = 4;
            Some(self.apply_sweep(period))
        } else {
            None
        }
    }
}

#[derive(PartialEq)]
pub enum SweepModifier {
    Increase,
    Decrease
}
