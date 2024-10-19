#[derive(Copy, Clone)]
pub struct SweepRegister {
    pub register: u8,
    period: i16,
    cycles_left: u8
}

impl Default for SweepRegister {
    fn default() -> Self {
        Self {
            register: 0,
            period: 0,
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

    fn apply_sweep(&mut self) {
        let adjustment: i16 = self.period / (2_i16.pow(self.sweep_step() as u32));
        self.period = self.period.saturating_add(adjustment * (if self.sweep_modifier() == SweepModifier::Increase { 1 } else { -1 }));
    }

    pub fn clock(&mut self) {
        self.cycles_left = self.cycles_left.saturating_sub(1);
        if self.cycles_left == 0 {
            self.cycles_left = 4;
            self.apply_sweep();
        }
    }
}

#[derive(PartialEq)]
pub enum SweepModifier {
    Increase,
    Decrease
}
