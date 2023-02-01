# Abstract

The RISC-V instruction set architecture (ISA) has been designed to be highly modular and customizable through the use of extensions. This makes it an ideal platform for processor formal verification, which is a critical step in the design of processor cores. This report presents the formal verification of the PAF Core that was used as the basis for this research. This core is an open-source RISC-V processor core written as a university project at Telecom Paris by Florian Tarazona and Erwan Glazsiou. The PAF Core was found to be quite buggy and in need of significant modifications to be compatible with the riscv-formal tool, which is used to prove that a processor is correct according to the RISC-V ISA.

The formal verification of the PAF Core covered the base RISC-V ISA (rv32i) and the B extension (Bit manipulation). The core was modified to implement trapping, which detects ill-formed instructions and unaligned accesses. Several bugs were found and fixed such as missing instructions, pipeline stalls not properly implemented, bad forwarding and load instruction triggering trap on miss-aligned addresses.

In addition to the formal verification of the PAF Core, the report also includes the formal verification of an AXI-lite random memory controller, which I used to formally verify AXI-lite variant of the picorv32 core.

The report concludes with an analysis of the contributions of the research, including a timing and area analysis of the PAF processor. The results of this work provide a strong foundation for further improvements to the PAF Core.  

# Introduction
## formal verifications for processor cores


Verification is a critical step in processor design. It was in the 1990s, as for the MIPS 4000, each additional month of design time would cost between $3 million and $8 million. Besides, 27% of the design time was devoted to verification and testing[3]. It is still the case, nowadays the verification process has become considerably more extensive than design efforts[4]. 


Most bugs can be found using simulation based verification: The design under test is simulated in a testbench that gives inputs and checks coherency of the design's outputs.

Another method that is usually used to find more bugs is to simulate the design, with randomly generated inputs. This method can
find cases the usual testbench doesn't consider, thus find more bugs. This function is efficient at finding bugs though it does not
give any proof of correctness. Even after simulating during days on random inputs, one untested input can still lead to a state that violates the specification. 

This is where formal verification comes to play. it is a process of mathematically proving the correctness of a design, in this case, a processor design. The verification process of the pentium 4 involved formal verification, which made possible to find around 200 bugs that weren't emphasized by simulation based verification methods.



The principle of hardware formal verification is to define a formal specification of the design, and then use mathematical logic and automated theorem provers to prove that the design meets that specification. This can provide a high degree of confidence that the design is free from certain classes of errors and will function as intended.

The first step is to define a formal specification of the design. This typically involves writing a mathematical model of the design that defines its behavior in terms of input and output relations. The model is usually written in a formal language, such as first-order logic or temporal logic.

There are serval verification methodologies, such as **model checking** and **theorem proving**. While theorem proving gives stronger proofs of correctness, it is difficult to automate and highly relly on the design under verification. 

Model checking works by exhaustively exploring the state space of the system under consideration and looking for a state that violates the specification. In model checking, a mathematical model of the system is created, and a formal specification is defined in terms of properties that the system should satisfy. The model checker then explores the state space of the system, using algorithms to check that the system satisfies the specification. Model checkers can check both safety properties (properties that must always hold) and liveness properties (properties that eventually hold).


**Unbounded model checking** searches for any reachable state that violates the specification. It usually target small systems for which the set of reachable states is handlable, whereas it is not for big end-to-end systems, like advanced processor cores. Indeed, the size of the set of reachable states grows exponnentially with the size of the system. Thus, **bounded model checking** is often used instead to find bugs. The principle is to restrict the set of states to check to the set of reachable states after a few clock cycles. The number of considered clock cycles usually depends on the pipeline depth of the processor core. This method is sometimes called *bug hunting*: it does not prove correctness of the design overtime, though, this method is still very efficient at finding bugs.

The model checking problem is equivalent to a satifiability (SAT) problem. Model checkers usually create a logic formula that should be unsatifiable if and only if the design is correct. It then involves a SAT solver to prove that the formula is unsatisfiable and thus prove correctness of the design. Modern model checkers speed up the solving process by construsting a SMT problem instead of a SAT one.



#### Limits of model checking

The SAT problem is NP-complete in the worst case. It means that checking that a vector of variables satisfy a formula is possible in a polynomial time. Though finding such a vector is only possible in exponential time in the worst case. 

While most SAT problem instances doesn't need an exponential time, which makes possible the use of such a tool for formal verification, some logical structures actually take an exponential time to verify. 

It is the case for multipliers, divisors, and for some floating points operators. It means that bounded model checking cannot be used to prove correctness of such such circuts. 

Verifying very big end-to-end systems can also not be achievable. It is usual to verify parts of such systems independently instead. For example, for a processor core, formally verifying the ALU, the register file and other parts independently is easier than verifying the whole core.


## `riscv-formal`

The work presented in this report is based on the open source `riscv-formal` tool. It is an open source tool to formally verify RISC-V processor cores. It is written in the SVA (SystemVerilog Assertions) language and uses the SymbiYosys verification tool to perform the formal verification. It is based on the bounded model checking method, and use SymbiYosys to generate and solve a SMT problem. 



In order to be verified using this tool, a core must implement the RISC-V Formal Interface (RVFI). 
It is a set of signals that a core must export to make visible its behaviour.


It is a set of signals and a protocol introduced by `riscv-formal`, that allows formal verification tools to access and interact with the internal state of a RISC-V core. This interface exposes the behavior of the core in a way that can be easily understood and verified by formal verification engines. These signals include the inputs and outputs of the core, as well as internal signals such as register values and memory states. RVFI can be used for a variety of formal verification tools and methodologies.

Figure 1 shows a subset of the RVFI signals, for a 32 bit RISC-V core.



When `valid` is asserted, an instruction is executed and the other signals are set. `insn` indicates the executed RISC-V instruction. `pc_rdata` is set to the instruction's PC, and `pc_wdata` is set to the next instruction's PC - PC + 4 or a jump address if the instruction is a branch, or a trap handler if the instruction traps.
Every instruction is associated with a unique `order` value, in order to verify the sequencial consistency of a core. If the instruction uses registers, `rs*_rdata` and `rd_rdata` are set to the decoded addresses. If the instruction reads data from memory, `mem_addr` is set to the associated address, and `mem_rdata` is set to the read word. `mem_addr` and `mem_wdata` are set similarly in case the instruction operates a memory write. If the instruction traps, `trap` is set.  

Note that the RVFI interface doesn't support instructions that both read and write from memory, or reads / writes twice. It is not a problem to verify the base ISA and most standard extension in which every instruction does at most one read or one write. Some modifications are however needed to verify the Atomic "A" standard extension, as it introduces atomic read then write instructions, like `AMOADD` - Atomic Memory Operation Add. To verify this extension, some extra signals are added to RVFI.



name | size (bits) | meaning |
---| --- | --- |
`valid`           | 1  | indicates whether the current instruction is valid or not. Every other signal is only valid when `rvfi_valid` is asserted. |  
`order`           | 64 | order of the instruction |  
`insn`            | 32 | binary instruction that is currently being executed |  
`trap`            | 1  | indicates if the current instruction is a trap instruction or not |  
`rs1_addr`        | 5  | address of the first source register (RS1) that is used by the instruction, if any |  
`rs1_rdata`       | 32 | the value of the first source register (RS1) that is used by the instruction, if any |  
`rs2_addr`        | 5  | address of the second source register (RS2) that is used by the instruction, if any |  
`rs2_rdata`       | 32 | contains the value of the second source register (RS2) that is used by the instruction, if any |  
`rd_addr`         | 5  | address of the destination register (RD) that is used by the instruction, if any |  
`rd_wdata`        | 32 | value that will be written to the destination register (RD) by the instruction, if any |  
`pc_rdata`        | 32 | current value of the program counter (PC) |  
`pc_wdata`        | 32 | new value of the program counter (PC) after the instruction is executed (PC + 4 or a jump address) |  
`mem_addr`        | 32 | memory address that is being accessed by the instruction, if any |  
`mem_rdata`       | 32 | value read from memory by the instruction, if any |  
`mem_wdata`       | 32 | value that will be written to memory by the instruction, if any |  

__Figure 1 - subset of the RVFI signals, for a 32 bit RISC-V core__



As explained earlier, some operations are to hard to verify formally using the bounded model checking methodology. It is the case for the multiplication and division. it means that the Multiplier "M" standard RSC-V extension cannot be fully verified easily. The solution brought by `riscv-formal` is to replace such operations by alterative ones for instructions that cannot be verified in a reasonable time. It expects the processor under test to implement these alternative operations instead of the standard multiplication and division operations. Commutative operations like multiplication are replaced with addition followed by applying XOR with a bitmask that indicates the type of the operation. Noncommutative operations like division are replaced with subtraction followed by applying XOR with a bitmask that indicates the type of the operation. The bitmasks are 64 bits wide. RV32 implementations only use the lower 32 bits of the bitmasks.

Note that using alterative operations, no proof of correctness is given to the instruction. Other verification methods should then be used. The reason to use `riscv-formal` in such a case is that the only part that is not virified to be correct is the multiplier or the divisor. If the processor under verification uses a multiplier and a divisor that are already verified to be correct, it is not a problem. 

The `riscv-formal` verification procedure is divided into serval tests. The tests required to prove bounded correctness of the processor (liveness and safety) are:


- `liveness` - this test checks that the core never freezes unless it halts.  
- safety tests  
    - Consistency checks: this set of tests aims to prove the consistency of sequences of instructions.  
        - `reg` - prove that every register read return the previously written value.  
        - `pc_fwd` - prove consistency of the PC.  
        - `unique`: check that every retired instruction's `order` is unique and increasing.  
    - `insn_`*  - instruction check: One check is generated for each instruction in the isa. It compares the instruction decoding, result and whether it traps or not to the behaviour described in the ISA.  
    - out of order checks:  
        - `causal` - check causality of instructions: if $I_2$ depends on the result of $I_1$, then $I_2$ is retired after $I_1$.  
        - `pc_bwd` - prove consistency of the PC in an out of order context.



As is, `riscv-formal` is able to verify the following Instruction Set Architectures (ISAs):
- `rv32i`:  base 32 bit ISA
- `rv64i`:  base 64 bit ISA
- `rv32im`: base 32 bit ISA with multiplier
- `rv64im`: base 64 bit ISA with multiplier

Note that the tool is extensible for other ISA extensions. Adding the support to an ISA means generating one check per introduced instruction. This report include the support for the `rv32ib` as an example. 



## Contributions

In this report are presented three contributions:

- A __random memory AXI-lite slave__ that ingore writes and reads random values, that yosys interprets as symbolic values. The response times are also randomized, to test the AXI-lite specification. This slave has been used to foramlly verify the AXI-lite varient of the picorv32. This contribution is described in section ?.

- The support of the Bit Manipulation "B" RISC-V extension for the __risv-formal__ tool for 32 bit processors. This contribution is described in section ?.

- The __formal verification of the PAF Core__, an open-source RISC-V processor core written as a university project at Telecom Paris. This included the modification of the core to implement trapping, which detects ill-formed instructions and unaligned accesses, as well as the detection and fixing of several bugs. The formal verification of the PAF Core covered the base RISC-V ISA (rv32i) and the B extension (Bit manipulation) and the results of this work provide a strong foundation for further improvements to the PAF Core. This contribution is described in section ?.


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
Overall, these modifications allowed the PAF core to pass the riscv-formal formal tests and fully implement the 'B' extension.# Implementation and verification of the RISC-V "B" extension


## Overview of the extension

The goal of the RISC-V Bit Manipulation ISA extension is to accelerate some operations that are regularily executed in common RISC-V code. It is divided into three subextensions, for a total of 31 instructions (and 12 other instructions for rv64).

### Zba (Array Indexing)

The Zba instructions are designed to accelerate the generation of addresses that index into arrays of basic types (halfword, word, doubleword). These instructions allow the addition of a shifted index to a base address. The shift amount is limited to 1, 2, or 3 but can be used to index arrays of wider elements by combining with the slli instruction from the base ISA.

### Zbb (Basic Bit-Manipulation)

The Zbb instructions provide basic bit-manipulation operations such as logical with negate, counting leading/trailing zero bits, counting population, finding integer minimum/maximum and sign- and zero-extension. These operations can be used to improve performance, reduce code size and energy consumption in applications.


### Zbc (Carry-less Multiplication)

The Zbc extension provides carry-less multiplication, a multiplication operation in the polynomial ring over GF(2). This extension includes instructions clmul and clmulh to produce the lower and upper half of the carry-less product respectively. The instruction clmulr produces bits 2✕XLEN−2:XLEN-1 of the carry-less product. This extension can be used for efficient cryptography and hashing operations.



## Verification

As explained in the introduction, `riscv-formal` allows to add ISA extensions by adding one check for each introduced instruction. Checks are generated in the python script `/insn/generate.py`. This script allows to easily describe an instruction, given its encoding and its result. A __SyemVerilog__ verification file is generated for each instruction. __Figure 3__ shows the example for the 
`ADDI` and `ADD` instructions. 

```
insn_imm("addi",  "000", "rvfi_rs1_rdata + insn_imm")
...
insn_alu("add",  "0000000", "000", "rvfi_rs1_rdata + rvfi_rs2_rdata")
```
__Figure 3: generation of checks for instructions `ADDI` and `ADD`__

The check's computation is made naive and compared to the more complex implementation in the core. The resulting file can be found on the github sub repository, which has been forked an modified from the original YosysHQ repository.




## Implementation


### Zba

The Zba extension only has three instructions that add a shifted integer to another integer: `SH1ADD`, `SH2ADD` and `SH3ADD`.
They are implemented using the regular ALU's full adder that is already used for the `ADD` and `ADDI` instructions, by adding a barrel shifter.


### Implementing Zbb

Simple Zbb operations are implemented naively:
logical and, or and xor with negate, reverse byte order, byte granule bitwise OR-Combine, and sign- and zero- extend operations. Other instructions required area and timing considerations to be efficiently implemented.


### Population count openrations

Operations that count bits (cpop, ctz and clz) are done in a single cycle.
the data path for the computation is a tree that operates on a part of the word, and compresses to give the result.


### rotate operations

Zbb introduces ROL and ROR instructions. A left shifter and a right shifter were already in the ALU to implement the SLL and SLR instructions. To reduce the area cost of the extension, the left shifter and the right shifter are also used for the ROL and ROR ALU operations. 
Indeed, the bit rotate right of `A` by `B` is equal to: `(A << B) | (A >> (32 - B))`. Likewise, the bit rotate left of `A` by `B` is equal to: `(A >> B) | (A << (32 - B))`.
By multiplexing the inputs of the shifters, they are made sufficent to implement every shift and rotate instructions. 

### single bit operations

Zbb introduce single bit operations: `BCLR`, `BCLRI`, `BEXT`, `BEXTI`, `BINV`, `BINVI`, `BSET` and `BSETI`. These operations can be implemented using the left and right shifters as for `ROL` and `ROR`:


- `BCLR` `A`, bit `n`: `A` & ~(1 << `n`)  
- `BINV` `A`, bit `n`: `A` ^  (1 << `n`)  
- `BSET` `A`, bit `n`: `A` |  (1 << `n`)  
- `BEXT` `A`, bit `n`: (`A` >> `n`) & 1  


### integer minimum / maximum

The base rv32i ISA includes the instructions `BLT` - Branch if Less Than, `BGE` - Branch if Greater or Equal, `SLT` - Set if Less Than, and their unsigned equivalents: `BLTU`, `BGEU`, and `SLTU`. 
Therefore, the ALU already contains the logic for integer comparisons.

The Zbb integer min/max are `MAX`, `MAXU`, `MIN`, `MINU`. They all were implemented use the comparaison logic already introduced to minimize the area cost.


### Zbc

Zbc clmul and clmulh are implemented using a parametrized N-cycle carry less  multiplier that outputs the 64 bit product. clmulr gives the result of clmul shifted left by one bit.
# Conclusions

## PAF rv32ib synthesis 

This sections presents the synthesis of the PAF core.
The synthesis is made using Quartus 2020, targeting the Cyclone V 5CSEMA5F31C6 FPGA.

The core's carry less multiplier takes N cycles where N is a synthesis parameter. It allowed to test multiple values and compare the timing and area cost between values.


### Timing analisys


The quartus timing analysis showed that the critical path of the design is the following:  

- data read register
- WB shift (LB/LH)
- WB->EX forwarding
- EX ADD rs1 + imm12
- new PC register


It means that the implentation of the bit manipulation extension does not decrease the timing performance, even with a single cycle carry less multiplier. The critical instruction sequence that lead to this data path being used is the showed on __figure 4__.

It is notable that this sequence is actually never executed in common code. Indeed, it is usual to load a address from memory and then jump to it, though an address is usually a word rather than a byte. 


```
# Load a byte from memory, zero extend it
# and save it to r1
LB r1, r2, $0

# jump to the address in
JALR r0, r1, $0
```
__Figure 4: critical instruction sequence__



Despite these dependencies, the design was able to achieve a frequency of 87 MHz. However, the write-back shifter used for the LB and LH instructions was found to be quite expensive, adding 1.5 ns to the critical path and potentially leading to a loss of 10 MHz.


### Area analisys


Figure 5 shows the synthesis area results, for the core supporting rv32i. Figure 6 shows the synthesis area results for the core when supporting rv32ib, with a 4-cycle carry-less multiplier. The 4-cycle clmul is a trade-off between speed and area. Indeed, a core with single-cycle clmul takes around 20% more space for this target, as shows Figure 7.

Note that for the rv32i implementation, the `EX` stage module represents 79% of the total area.
It hides the fact that the `EX` module hosts the register file. Besides, the instruction decoding is quite poor, which explains why the `ID` stage takes so few ALUTs compared to other stages. It might decrease the total area size to improve the instruction decoding in the `ID` stage.

We can see that the cost for the "B" extension is __36% of the total core area__ for a 4-cycle clmul.




Module hierarchy | cumulated ALUTs used by the module and submodules | ALUTs used by the module |
---| --- | --- |
`top`            | 1569.5  | 129.9  |
`top:EX`         | 1237.0  | 1237.0 |
`top:ID`         | 10.2    | 10.2   |
`top:IF`         | 75.3    | 75.3   |
`top:MEM`        | 19.9    | 19.9   |
`top:WB`         | 97.2    | 97.2   |
__Figure 5: area analysis of the rv32i core__



Module hierarchy | cumulated ALUTs used by the module and submodules | ALUTs used by the module |
---| --- | --- |
`top`            | 2139.0  | 143.6  |
`top:EX`         | 1769.9  | 1555.3 |
`top:EX:clmul`   | 147.8   | 147.8  |
`top:EX:cpop`    | 31.8    | 31.8   |
`top:EX:ctz`     | 19.0    | 19.0   |
`top:EX:ctz`     | 15.8    | 15.8   |
`top:ID`         | 32.3    | 32.3   |
`top:IF`         | 76.2    | 76.2   |
`top:MEM`        | 19.6    | 19.6   |
`top:WB`         | 97.4    | 97.4   |
__Figure 6: area analysis of the rv32ib core, with a 4-cycle clmul__



???
__Figure 7: area analysis of the rv32ib core, with a single cycle clmul__




## further work





### riscv-formal
### PAF core


1. M. Sheeran, S. Singh, and G. Stålmarck, ‘Checking Safety Properties Using Induction and a SAT-Solver’, in Proceedings of the Third International Conference on Formal Methods in Computer-Aided Design, 2000, pp. 108–125.


2. J. R. Burch and D. L. Dill, ‘Automatic Verification of Pipelined Microprocessor Control’, in CAV, 1994.

3. J. L. Hennessy. Designing a computer as a microprocessor: Experience and lessons from the MIPS 4000. A lecture at the Symposium on Integrated Systems, Seattle, Washington, March 14, 1993.


4. Wagner I., Bertacco V., (2011). 'Verification of a Modern Processor'. In 'Post-Silicon and Runtime Verification for Modern Processors' (p. 4). New York: Springer. 




Post-Silicon and Runtime Verification for Modern Processors, Springer, by Ilya Wagner Valeria Bertacco,
Springer Science+Business Media, LLC 2011 