use std::cmp::{min, max};

#[derive(Copy, Clone)]
pub struct VolumeEnvelope {
    pub register: u8,
    cycles_left: u8,
    ticks: u8,
    pub volume_adjustment: i8
}

impl Default for VolumeEnvelope {
    fn default() -> Self {
        Self {
            register: 0,
            cycles_left: 8,
            ticks: 0,
            volume_adjustment: 0
        }
    }
}

enum Direction {
    Up,
    Down
}

impl VolumeEnvelope {
    pub fn trigger(&mut self) {
        self.volume_adjustment = 0;
    }

    pub fn tick(&mut self) {
        self.cycles_left = self.cycles_left.saturating_sub(1);
        let sweep_time = self.envelope_sweep();
        if self.cycles_left == 0 && sweep_time > 0 {
            self.cycles_left = 8;
            self.ticks = self.ticks + 1;
            if self.ticks >= sweep_time {
                self.ticks = 0;
                self.apply_envelope();
            }
        }
    }

    fn apply_envelope(&mut self) {
        match self.direction() {
            Direction::Up => { self.volume_adjustment = min(self.volume_adjustment + 1, 0xF) },
            Direction::Down => { self.volume_adjustment = max(self.volume_adjustment- 1, -0xF) },
        }
    }

    pub fn initial_volume(self) -> u8 {
        self.register >> 4
    }

    pub fn direction(self) -> Direction {
        let value = (self.register >> 3) & 1;

        if value == 0 { Direction::Down } else { Direction::Up }
    }

    pub fn envelope_sweep(self) -> u8 {
        self.register & 0b111
    }

    pub fn current_volume(self) -> f64 {
        (self.initial_volume()
            .saturating_add_signed(self.volume_adjustment)
            .min(15)
            .max(0) as f64) / 15.0
    }
}
