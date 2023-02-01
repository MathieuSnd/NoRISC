# Implementation and verification of the RISC-V "B" extension


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
