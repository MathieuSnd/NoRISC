
## Overview of the PAF Core

Figure 1 shows a simplified diagram of the implementation. It is a simple 5 stage pipelined core:
- Instruction Fetch (IF): Fetches the instruction in data memory
-  Instruction Decode (ID): the instruction is decoded to determine its opcode and operands.
- Execute (EX) the instruction is executed. This typically involves performing calculations or memory accesses based on the instruction and its operands.
- Memory Access (MEM): In this stage, memory accesses specified by the instruction are performed. This includes reading or writing data from memory.




![fig1](cpu.svg)
__Figure 1 - simplified PAF core implementation diagram__




## Bugs and fixes in the PAF Core


As the basis for this research on RISC-V extension formal verification, I needed a RISC-V core that was not formally verified. I picked the PAF core, written by Florian Tarazona and Erwan Glazsiou, students at Telecom Paris in 2021 for a univeristy project. However, the core was found to be quite buggy and in need of significant modifications in order to be compatible with the riscv-formal tool, which is used to prove that a processor is correct according to the RISC-V ISA.

### Initial modifications

The first modification made to the PAF core was the implementation of trapping, which detects ill-formed instructions and unaligned accesses.
This change was necessary in order for the core to pass the riscv-formal formal tests.    

ill-formed instructions are detected in the ID pipeline stage, and miss-align exceptions are detected in the EX stage. When a trap happens, the pipeline is flushed and the core halts.



Besides, some instructions went missing:
- AUIPC - Add Upper Immediate to PC - is an instruction that allows the program counter (PC) to be modified by adding an upper immediate value to it. This instruction is typically used to facilitate the loading of program addresses into registers, allowing for program branching and subroutine calls. 
- LB, LH, LBU, LHU - These instructions are used to load a 
- SB, SH - These instructions are used to store a single byte or half word (two bytes)

Implementing the missing load/store instructions required to include byte masks in the memory interface, which was not done already. 

For writes, a shift is required before sending the word to memory. It is done in the EX stage. A similar shift is also required for reads, which is done in the WB stage.






### Bugs found and fixes
Missing instructions for accessing memory bytes and half-words: New instructions were implemented.
Add write strobe mask to the core's data memory interface: The write strobe mask was added to the core's data memory interface.
JALR instruction clearing the last two bits: The instruction was modified to properly align the jump target address.
Registers being latches: The implementation was changed to use registers that correctly hold the state of the processor.
No detection of ill-formed instructions: New code was added to detect and trap these instructions.
Pipeline stalls not properly implemented when load instruction followed by another instruction: The implementation was changed to properly handle the forwarding of load results to other instructions that use them.
Bad forwarding from memory to execution stage: The forwarding mechanism for JAL, JALR and AUIPC instructions was modified.
Load instruction triggers trap on miss-aligned addresses: The implementation was changed to avoid triggering a trap in these cases.
BGE and BGEU instructions branch if strictly greater: The instructions were modified to branch if greater or equal.
AUIPC instruction not implemented: The instruction was added to the core.
JAL instruction not trapping when branch value is miss-aligned: The JAL instruction was modified to properly trap in these cases.
Random memory errors: Future work could be directed to address these bugs.
Overall, these modifications allowed the PAF core to pass the riscv-formal formal tests and fully implement the 'B' extension.