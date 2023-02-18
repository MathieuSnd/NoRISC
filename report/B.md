## 3.4. Overview of the extension

The goal of the RISC-V Bit Manipulation ISA extension is to accelerate some operations that are regularly executed in common RISC-V code. It is divided into three sub-extensions, for a total of 31 instructions (and 12 other instructions for rv64).

### 3.4.1. Zba (Array Indexing)

The Zba instructions are designed to accelerate the generation of addresses that index into arrays of basic types (half word, word, and double word). These instructions allow the addition of a shifted index to a base address. The shift amount is limited to 1, 2, or 3 but can be used to index arrays of wider elements by combining with the `SLLI` (Shift Left Logical by Immediate) instruction from the base ISA.

### 3.4.2. Zbb (Basic Bit-Manipulation)

The Zbb instructions provide basic bit-manipulation operations such as logical with negate, counting leading/trailing zero bits, counting population, finding integer minimum/maximum and sign- and zero-extension. These operations can be used to improve performance, reduce code size and energy consumption in applications.

### 3.4.3. Zbs (Single bit instruction)

The Zbs instructions provide operations to set, clear, invert or extract a single bit in a word. Common code usually make such operations, using sequences of shift and bit-wise instructions. This instruction set aims to improve performance of such operations, while reducing code size and energy consumption. 

### 3.4.3. Zbc (Carry-less Multiplication)

The Zbc extension provides carry-less multiplication, a multiplication operation in the polynomial ring over GF(2). This extension includes instructions clmul and clmulh to produce the lower and upper half of the carry-less product respectively. The instruction clmulr produces bits 62:31 of the carry-less product. This extension can be used for efficient cryptography and hashing operations.



## 3.5. Verification

As explained in the introduction, `riscv-formal` allows to add ISA extensions by adding one check for each introduced instruction. Checks are generated in the python script `/insn/generate.py`. This script allows to easily describe an instruction, given its encoding and its result. A __SyemVerilog__ verification file is generated for each instruction. Figure 7 shows the example for the 
`ADDI` and `ADD` instructions. 

<br/>


```
insn_imm("addi",  "000", "rvfi_rs1_rdata + insn_imm")
...
insn_alu("add",  "0000000", "000", "rvfi_rs1_rdata + rvfi_rs2_rdata")
```
__Figure 7: generation of checks for instructions `ADDI` and `ADD`__

<br/>


The check's computation is made naive and compared to the more complex implementation in the core. The resulting file can be found on the github sub repository, which has been forked an modified from the original YosysHQ repository. Figure 8 shows the example for some Zbs instructions. The whole "B" instruction set contains 36 instructions for  the 32 bit version, and 44 for the 64 bit version. Only the 32 bit version has been done for this project, as the PAF core is 32 bit.

<br/>

```
insn_alu("bclr",    "0100100", "001", "rvfi_rs1_rdata  & ~(1 << (rvfi_rs2_rdata & 31))", misa=MISA_B)
insn_alu("bext",    "0100100", "101", "(rvfi_rs1_rdata  >> (rvfi_rs2_rdata & 31)) & 1", misa=MISA_B)
insn_alu("binv",    "0110100", "001", "rvfi_rs1_rdata  ^ (1 << (rvfi_rs2_rdata & 31))", misa=MISA_B)
insn_alu("bset",    "0010100", "001", "rvfi_rs1_rdata  | (1 << (rvfi_rs2_rdata & 31))", misa=MISA_B)
```
__Figure 8: generation of checks for Zbs instructions__

<br/>


## 3.6. Implementation

The implementation is described in sections 3.6.1 - 3.6.7. Its verification was achieved using the modifications made to `riscv-formal` described in section 3.5.

### 3.6.1. Implementing Zba

The Zba extension only has three instructions that add a shifted integer to another integer: `SH1ADD`, `SH2ADD` and `SH3ADD`.
They are implemented using the regular ALU's full adder that is already used for the `ADD` and `ADDI` instructions, by adding a barrel shifter.


### 3.6.2. Implementing Zbb

Simple Zbb operations are implemented naively:
logical and, or and xor with negate, reverse byte order, byte granule bit-wise OR-Combine, and sign- and zero- extend operations. Other instructions required area and timing considerations to be efficiently implemented.


### 3.6.3. Population count operations

Operations that count bits (cpop, ctz and clz) are done in a single cycle.
the data path for the computation is a tree that operates on a part of the word, and compresses to give the result.


### 3.6.4. rotate operations

Zbb introduces ROL and ROR instructions. A left shifter and a right shifter were already in the ALU to implement the SLL and SLR instructions. To reduce the area cost of the extension, the left shifter and the right shifter are also used for the ROL and ROR ALU operations. 
Indeed, the bit rotate right of `A` by `B` is equal to: `(A << B) | (A >> (32 - B))`. Likewise, the bit rotate left of `A` by `B` is equal to: `(A >> B) | (A << (32 - B))`.
By multiplexing the inputs of the shifters, they are enough to implement every shift and rotate instructions. 

### 3.6.5. single bit operations

Zbs introduce single bit operations: `BCLR`, `BCLRI`, `BEXT`, `BEXTI`, `BINV`, `BINVI`, `BSET` and `BSETI`. These operations can be implemented using the left and right shifters as for `ROL` and `ROR`:


- `BCLR` `A`, bit `n`: `A` & ~(1 << `n`)  
- `BINV` `A`, bit `n`: `A` ^  (1 << `n`)  
- `BSET` `A`, bit `n`: `A` |  (1 << `n`)  
- `BEXT` `A`, bit `n`: (`A` >> `n`) & 1  


### 3.6.6. integer minimum / maximum

The base rv32i ISA includes the instructions `BLT` - Branch if Less Than, `BGE` - Branch if Greater or Equal, `SLT` - Set if Less Than, and their unsigned equivalents: `BLTU`, `BGEU`, and `SLTU`. 
Therefore, the ALU already contains the logic for integer comparisons.

The Zbb integer min/max are `MAX`, `MAXU`, `MIN`, `MINU`. They all were implemented use the comparaison logic already introduced to minimize the area cost.


###  3.6.7. Zbc

Zbc `clmul` and `clmulh` are implemented using a parametrized N-cycle carry less  multiplier that outputs the 64 bit product. `clmulr` returns the carry less product shifted left by one bit.


