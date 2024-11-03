use crate::processor::ProcessorStepResult;
use crate::video::status_register::StatusMode;

#[derive(Default, Copy, Clone)]
pub struct StepInput {
    pub held_buttons: u8,
    pub serial_data_input: Option<bool>
}

/// Represents the result of a single GameBoy step
pub struct GameboyStepResult(pub ProcessorStepResult, pub Option<StatusMode>);
