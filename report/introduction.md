# 1. Introduction

## 1.1. Formal Verifications of Processor Cores


Verification is a critical step in processor design. It was in the 1990s, as for the MIPS 4000, each additional month of design time would cost between $3 million and $8 million. Besides, 27% of the design time was devoted to verification and testing[3]. It is still the case, nowadays the verification process has become considerably more extensive than design efforts[4]. 


Most bugs can be found using simulation based verification: The design under test is simulated in a test bench  that gives inputs and checks coherency of the design's outputs.

Another method that is usually used to find more bugs is to simulate the design, with randomly generated inputs. This method can
find cases the usual test bench  doesn't consider, thus find more bugs. This function is efficient at finding bugs though it does not
give any proof of correctness. Even after simulating during days on random inputs, one untested input can still lead to a state that violates the specification. 

This is where formal verification comes to play. it is a process of mathematically proving the correctness of a design, in this case, a processor design. The verification process of the pentium 4 involved formal verification, which made possible to find around 200 bugs that weren't emphasized by simulation based verification methods.



The principle of hardware formal verification is to define a formal specification of the design, and then use mathematical logic and automated theorem provers to prove that the design meets that specification. This can provide a high degree of confidence that the design is free from certain classes of errors and will function as intended.

The first step is to define a formal specification of the design. This typically involves writing a mathematical model of the design that defines its behavior in terms of input and output relations. The model is usually written in a formal language, such as first-order logic or temporal logic.

There are serval verification methodologies, such as **model checking** and **theorem proving**. While theorem proving gives stronger proofs of correctness, it is difficult to automate and highly relly on the design under verification. 

Model checking works by exhaustively exploring the state space of the system under consideration and looking for a state that violates the specification. In model checking, a mathematical model of the system is created, and a formal specification is defined in terms of properties that the system should satisfy. The model checker then explores the state space of the system, using algorithms to check that the system satisfies the specification. Model checkers can check both safety properties (properties that must always hold) and liveness properties (properties that eventually hold).


**Unbounded model checking** searches for any reachable state that violates the specification. It usually target small systems for which the set of reachable states is handleable, whereas it is not for big end-to-end systems, like advanced processor cores. Indeed, the size of the set of reachable states grows exponentially with the size of the system. Thus, **bounded model checking** is often used instead to find bugs. The principle is to restrict the set of states to check to the set of reachable states after a few clock cycles. The number of considered clock cycles usually depends on the pipeline depth of the processor core. This method is sometimes called *bug hunting*: it does not prove correctness of the design overtime, though, this method is still very efficient at finding bugs.

The model checking problem is equivalent to a satisfiability (SAT) problem. Model checkers usually create a logic formula that should be unsatisfiable if and only if the design is correct. It then involves a SAT solver to prove that the formula is unsatisfiable and thus prove correctness of the design. Modern model checkers speed up the solving process by constructing a Satisfiability Modulo Theories (SMT) problem instead of a SAT one. SMT problems are similar to SAT but are easier to solve for bit vector operations, like additions.



## 1.2. Limits of model checking

The SAT problem is NP-complete in the worst case. It means that checking that a vector of variables satisfy a formula is possible in a polynomial time. Though finding such a vector is only possible in exponential time in the worst case. 

While most SAT problem instances doesn't need an exponential time, which makes possible the use of such a tool for formal verification, some logical structures actually take an exponential time to verify. 

It is the case for multipliers, divisors, and for some floating points operators. It means that bounded model checking cannot be used to prove correctness of such circuits. 

Verifying very big end-to-end systems can also not be achievable. It is usual to verify parts of such systems independently instead. For example, for a processor core, formally verifying the Arithmetic Logic Unit (ALU), the register file and other parts independently is easier than verifying the whole core.


## 1.3. `riscv-formal`

The work presented in this report is based on the open source `riscv-formal` tool. It is an open source tool to formally verify RISC-V processor cores. It is written in the SVA (SystemVerilog Assertions) language and uses the SymbiYosys verification tool to perform the formal verification. It is based on the bounded model checking method, and use SymbiYosys to generate and solve a SMT problem. 



In order to be verified using this tool, a core must implement the RISC-V Formal Interface (RVFI). 
It is a set of signals that a core must export to make visible its behavior.


It is a set of signals and a protocol introduced by `riscv-formal`, that allows formal verification tools to access and interact with the internal state of a RISC-V core. This interface exposes the behavior of the core in a way that can be easily understood and verified by formal verification engines. These signals include the inputs and outputs of the core, as well as internal signals such as register values and memory states. RVFI can be used for a variety of formal verification tools and methodologies.

Figure 1 shows a subset of the RVFI signals, for a 32 bit RISC-V core.


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



When `valid` is asserted, an instruction is executed and the other signals are set. `insn` indicates the executed RISC-V instruction. `pc_rdata` is set to the instruction's PC, and `pc_wdata` is set to the next instruction's PC - PC + 4 or a jump address if the instruction is a branch, or a trap handler if the instruction traps.
Every instruction is associated with a unique `order` value, in order to verify the sequential consistency of a core. If the instruction uses registers, `rs*_rdata` and `rd_rdata` are set to the decoded addresses. If the instruction reads data from memory, `mem_addr` is set to the associated address, and `mem_rdata` is set to the read word. `mem_addr` and `mem_wdata` are set similarly in case the instruction operates a memory write. If the instruction traps, `trap` is set.  

Note that the RVFI interface doesn't support instructions that both read and write from memory, or reads / writes twice. It is not a problem to verify the base ISA and most standard extension in which every instruction does at most one read or one write. Some modifications are however needed to verify the Atomic "A" standard extension, as it introduces atomic read then write instructions, like `AMOADD` - Atomic Memory Operation Add. To verify this extension, some extra signals are added to RVFI.





As explained earlier, some operations are to hard to verify formally using the bounded model checking methodology. It is the case for the multiplication and division. it means that the Multiplier "M" standard RSC-V extension cannot be fully verified easily. The solution brought by `riscv-formal` is to replace such operations by alterative ones for instructions that cannot be verified in a reasonable time. It expects the processor under test to implement these alternative operations instead of the standard multiplication and division operations. Commutative operations like multiplication are replaced with addition followed by applying XOR with a bit mask that indicates the type of the operation. Non-commutative operations like division are replaced with subtraction followed by applying XOR with a bit mask that indicates the type of the operation. The bit masks are 64 bits wide. RV32 implementations only use the lower 32 bits of the bit masks.

Note that using alterative operations, no proof of correctness is given to the instruction. Other verification methods should then be used. The reason to use `riscv-formal` in such a case is that the only part that is not virified to be correct is the multiplier or the divisor. If the processor under verification uses a multiplier and a divisor that are already verified to be correct, it is not a problem. 

The `riscv-formal` verification procedure is divided into serval tests. The tests required to prove bounded correctness of the processor (liveness and safety) are:


- `liveness` - this test checks that the core never freezes unless it halts.  
- safety tests
    - Consistency checks: this set of tests aims to prove the consistency of sequences of instructions.
        - `reg` - prove that every register read return the previously written value.
        - `pc_fwd` - prove consistency of the PC.
        - `unique`: check that every retired instruction's `order` is unique and increasing.
    - `insn_`*  - instruction check: One check is generated for each instruction in the ISA. It compares the instruction decoding, result and whether it traps or not to the behavior described in the ISA.
    - out of order checks:
        - `causal` - check causality of instructions: if $I_2$ depends on the result of $I_1$, then $I_2$ is retired after $I_1$.
        - `pc_bwd` - prove consistency of the PC in an out of order context.



As is, `riscv-formal` is able to verify the following Instruction Set Architectures (ISAs):
- `rv32i`:  base 32 bit ISA
- `rv64i`:  base 64 bit ISA
- `rv32im`: base 32 bit ISA with multiplier
- `rv64im`: base 64 bit ISA with multiplier

Note that the tool is extensible for other ISA extensions. Adding the support to an ISA means generating one check per introduced instruction. This report include the support for the `rv32ib` as an example. 



## 1.4. Contributions

In this report are presented three contributions:

- A __random memory AXI-lite slave__ that ignores writes and reads random values, that yosys interprets as symbolic values. The response times are also randomized, to test the AXI-lite specification. This slave has been used to formally verify the AXI-lite variant of the picorv32. This contribution is described in section 2.

- The support of the Bit Manipulation "B" RISC-V extension for the __risv-formal__ tool for 32 bit processors. This contribution is described in section 3.

- The __formal verification of the PAF Core__, an open-source RISC-V processor core written as a university project at Telecom Paris. This included the modification of the core to implement trapping, which detects ill-formed instructions and unaligned accesses, as well as the detection and fixing of several bugs. The formal verification of the PAF Core covered the base RISC-V ISA (rv32i) and the B extension (Bit manipulation) and the results of this work provide a strong foundation for further improvements to the PAF Core. This contribution is described in section 3. The synthesis of the core is presented in section 4.


