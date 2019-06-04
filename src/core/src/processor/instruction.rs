use crate::processor::flag_register::Flag;
use crate::processor::registers::RegisterType;

#[derive(Copy, Clone)]
pub enum Prefix {
    CB,
    None,
}

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum Mnemonic {
    CB,
    LD,
    LDHL,
    LDI,
    LDD,
    PUSH,
    POP,
    ADD,
    ADC,
    SUB,
    SBC,
    AND,
    XOR,
    OR,
    CP,
    INC,
    DEC,
    DAA,
    CPL,
    RLC,
    RLCA,
    RL,
    RLA,
    RRC,
    RRCA,
    RR,
    RRA,
    SLA,
    SWAP,
    SRA,
    SRL,
    BIT,
    SET,
    RES,
    CCF,
    SCF,
    NOP,
    HALT,
    STOP,
    DI,
    EI,
    JP,
    JR,
    CALL,
    RET,
    RETI,
    RST,
}

#[derive(Copy, Clone, Debug)]
pub enum Operand {
    Reference(Reference),
    Value(ValueType),
    Condition((Flag, bool)),
}

#[derive(Copy, Clone, Debug)]
pub enum Reference {
    Register(RegisterType),
    Address(AddressType),
}

impl Reference {
    pub fn is16bit(&self) -> bool {
        if let Reference::Register(register) = self {
            register.is16bit()
        } else {
            false
        }
    }
}

// Increment versions are incremented with 0xFF00
#[derive(Copy, Clone, Debug)]
pub enum AddressType {
    Register(RegisterType),
    IncRegister(RegisterType),
    Immediate,
    IncImmediate,
}

#[derive(Copy, Clone, Debug)]
pub enum ValueType {
    Register(RegisterType),
    Immediate,
    SignedImmediate,
    Immediate16,
    Address(AddressType),
    Constant(u16),
}

#[derive(Debug, Clone)]
pub struct InstructionInfo {
    opcode: u8,
    mnemonic: Mnemonic,
    operands: Option<Vec<Operand>>,
    cycle_count: u8,
}

impl InstructionInfo {
    pub fn new(
        opcode: u8,
        mnemonic: Mnemonic,
        operands: Option<Vec<Operand>>,
        cycle_count: u8,
    ) -> InstructionInfo {
        InstructionInfo {
            opcode,
            mnemonic,
            operands,
            cycle_count,
        }
    }

    pub fn mnemonic(&self) -> &Mnemonic {
        &self.mnemonic
    }

    pub fn operands(&self) -> &Option<Vec<Operand>> {
        &self.operands
    }

    pub fn cycle_count(&self) -> u8 {
        self.cycle_count
    }
}