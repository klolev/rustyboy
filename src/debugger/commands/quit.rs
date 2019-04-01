use crate::bus::Bus;
use crate::debugger::commands::{Command, CommandResult, Debugger};
use crate::debugger::{DebugInfo, DebuggerState};
use crate::processor::registers::Registers;

const MATCHING_VALUES: &'static [&'static str] = &["quit", "q"];

pub struct QuitCommand {}

impl QuitCommand {
    pub fn create_command() -> Box<dyn Command> {
        Box::new(QuitCommand {})
    }
}

impl Command for QuitCommand {
    fn matching_value(&self) -> &[&str] {
        MATCHING_VALUES
    }

    fn execute(
        &self,
        input: &[&str],
        debugger: &mut DebuggerState,
        debug_info: &DebugInfo,
        _: &Bus,
    ) -> CommandResult {
        std::process::exit(0);
        CommandResult::Quit
    }
}
