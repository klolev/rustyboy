use crate::bus::Readable;
use crate::processor::decoder::Decoder;
use crate::processor::instruction::{
    Condition, InstructionInfo, Mnemonic, Operand, Prefix, Reference, ValueType,
};
use crate::processor::operand_parser::OperandParser;
use crate::processor::registers::flag_register::Flag;
use crate::processor::registers::program_counter::ProgramCounter;
use crate::processor::registers::register::Register;
use crate::processor::registers::{RegisterType, Registers};
use crate::util::bitflags::Bitflags;

pub struct ProcessorDebugInfo {
    pub registers: Registers,
}

pub struct DebugInfo {
    pub cpu_debug_info: ProcessorDebugInfo,
    pub bus: Vec<u8>,
}

impl DebugInfo {
    pub fn current_line(&self) -> u16 {
        self.cpu_debug_info.registers.program_counter.get()
    }

    pub fn parse_all(&self, address: u16) -> Vec<DebugInstructionInfo> {
        let mut parser = DebugOperandParser::new(address, &self);
        let mut instructions = vec![];
        loop {
            if let Some(instruction) = self.parse_instruction_with_parser(&mut parser) {
                instructions.push(instruction);
            }

            if parser.program_counter.get() == address {
                break;
            }
        }

        instructions
    }

    pub fn parse_instruction(&self, address: u16) -> Option<DebugInstructionInfo> {
        let mut parser = DebugOperandParser::new(address, &self);
        self.parse_instruction_with_parser(&mut parser)
    }

    fn parse_instruction_with_parser(
        &self,
        parser: &mut DebugOperandParser<'_>,
    ) -> Option<DebugInstructionInfo> {
        let bus = ReadableVec { value: &self.bus };
        let address = parser.program_counter.get();

        let instruction = Decoder::decode_opcode(parser.program_counter.fetch(&bus), Prefix::None)?;
        let instruction = if let Mnemonic::CB = instruction.mnemonic() {
            Decoder::decode_opcode(parser.program_counter.fetch(&bus), Prefix::CB)?
        } else {
            instruction
        };

        let parsed_operands = if let Some(operands) = instruction.operands() {
            operands
                .iter()
                .map(|operand| Self::parse_operand(&bus, parser, *operand))
                .collect()
        } else {
            vec![]
        };

        Some(DebugInstructionInfo {
            line: address,
            instruction,
            parsed_operands,
        })
    }

    fn parse_operand(
        bus: &ReadableVec<'_>,
        parser: &mut DebugOperandParser<'_>,
        operand: Operand,
    ) -> ParsedOperand {
        match operand {
            Operand::Value(value) => {
                let parsed_value = parser.operand_value(bus, value);
                ParsedOperand::Value((value, parsed_value))
            }
            Operand::Condition(condition) => {
                let parsed_condition = parser.operand_condition(condition);
                ParsedOperand::Condition((condition, parsed_condition))
            }
            Operand::Reference(reference) => ParsedOperand::Reference(reference),
        }
    }
}

#[derive(Copy, Clone, Debug)]
pub enum ParsedOperand {
    Value((ValueType, u16)),
    Condition((Condition, bool)),
    Reference(Reference),
}

pub struct DebugInstructionInfo {
    pub line: u16,
    pub instruction: InstructionInfo,
    pub parsed_operands: Vec<ParsedOperand>,
}

pub struct DebugOperandParser<'a> {
    program_counter: ProgramCounter,
    debug_info: &'a DebugInfo,
}

impl<'a> DebugOperandParser<'a> {
    pub fn new(start_address: u16, debug_info: &'a DebugInfo) -> Self {
        Self {
            program_counter: ProgramCounter::new(start_address),
            debug_info,
        }
    }
}

impl OperandParser for DebugOperandParser<'_> {
    fn mut_program_counter(&mut self) -> &mut ProgramCounter {
        &mut self.program_counter
    }

    fn reg(&self, register: RegisterType) -> u16 {
        self.debug_info.cpu_debug_info.registers.reg(register)
    }

    fn flag(&self, flag: Flag) -> bool {
        self.debug_info.cpu_debug_info.registers.af.flag(flag)
    }
}

struct ReadableVec<'a> {
    pub value: &'a Vec<u8>,
}

impl Readable for ReadableVec<'_> {
    fn read(&self, address: u16) -> u8 {
        self.value[address as usize]
    }
}
