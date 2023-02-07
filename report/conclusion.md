# 4. Conclusions

## 4.1. PAF rv32ib synthesis 

This sections presents the synthesis of the PAF core.
The synthesis is made using _Altera Quartus_ 2020, targeting the Cyclone V 5CSEMA5F31C6 FPGA.

The core's carry less multiplier takes N cycles where N is a synthesis parameter. It allowed to test multiple values and compare the timing and area cost between values.


### 4.1.1. Timing analysis


The _Quartus_ timing analysis showed that the critical path of the design is the following:  

- data read register
- WB shift (LB/LH)
- WB->EX forwarding
- EX ADD rs1 + imm12
- new PC register


It means that the implementation of the bit manipulation extension does not decrease the timing performance, even with a single cycle carry less multiplier. The critical instruction sequence that lead to this data path being used is the showed on figure 9.

It is notable that the instruction sequence showed in figure 9 is actually never executed in common code. Indeed, it is very usual to load a address from memory and then jump to it, though an address is usually a word rather than a byte. 


```
# Load a byte from memory, zero extend it
# and save it to r1
LB r1, r2, $0

# jump to the address in
JALR r0, r1, $0
```
__Figure 9: critical instruction sequence__



Despite these dependencies, the design was able to achieve a frequency of 87 MHz. However, the write-back shifter used for the LB and LH instructions was found to be quite expensive, adding 1.5 ns to the critical path and potentially leading to a loss of 10 MHz.


### 4.1.2. Area analysis


Figure 10 shows the synthesis area results, for the core supporting rv32i. Figure 11 shows the synthesis area results for the core when supporting rv32ib, with a 4-cycle carry-less multiplier. The 4-cycle `clmul` is a trade-off between speed and area. Indeed, a core with single-cycle `clmul` takes around 8% more space for this target, as shows Figure 12.

Note that for the rv32i implementation, the `EX` stage module represents 79% of the total area.
It hides the fact that the `EX` module hosts the register file. Besides, the instruction decoding is quite poor, which explains why the `ID` stage takes so few ALUTs compared to other stages. It might decrease the total area size to improve the instruction decoding in the `ID` stage.

Note that the cost for the "B" extension is __36% of the total core area__ for a 4-cycle `clmul`, and grows to __48%__ for a single cycle `clmul`.




Module hierarchy | cumulated ALUTs used by the module and sub-modules | ALUTs used by the module |
---| --- | --- |
`top`            | 1569.5  | 129.9  |
`top:EX`         | 1237.0  | 1237.0 |
`top:ID`         | 10.2    | 10.2   |
`top:IF`         | 75.3    | 75.3   |
`top:MEM`        | 19.9    | 19.9   |
`top:WB`         | 97.2    | 97.2   |
__Figure 10: area analysis of the rv32i core__



Module hierarchy | cumulated ALUTs used by the module and sub-modules | ALUTs used by the module |
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
__Figure 11: area analysis of the rv32ib core, with a 4-cycle `clmul`__


Module hierarchy | cumulated ALUTs used by the module and sub-modules | ALUTs used by the module |
---| --- | --- |
`top`            | 2319.0  | 144.9  |         
`top:EX`         | 1947.3  | 1386.5 |         
`top:EX:clmul`   | 505.8   | 505.8  |         
`top:EX:cpop`    | 22.3    | 22.3   |     
`top:EX:ctz`     | 16.4    | 16.4   |     
`top:EX:ctz`     | 15.5    | 15.5   |     
`top:ID`         | 31.8    | 31.8   |     
`top:IF`         | 86.8    | 86.8   |     
`top:MEM`        | 16.6    | 16.6   |     
`top:WB`         | 89.3    | 89.3   |     
----------------  --------- -------- 
__Figure 12: area analysis of the rv32ib core, with a single cycle `clmul`__




## 4.2. further work
### 4.2.1. riscv-formal

`riscv-formal` is a promising open-source RISC-V bounded model checking verification tool. Though it lacks of support for multi-core  architectures, and supports few RISC-V extensions.

### 4.2.2. PAF core

The main contribution of this project is the verification and implementation of the rv32ib PAF core, as an exploration of the open source verification tool `riscv-formal`. It is to note that although the __bug hunting verification__ methodology is very useful in practice, it des not provide a complete correctness proof. 

Further work can be done to fully prove the core, using __unbounded model checking__ or __theorem proving__ methods. Besides, as briefly discussed in the synthesis analysis section, the implementation can be improved. The area and timing analysis lead highlight the following potential improvements:

- a better decoding in the `ID` stage to decrease the area.
- the addition of a pipeline stall when a byte load or a half-word load instruction is followed by `JALR` to improve the critical path.
- the addition of a new pipeline stage to improve the critical path.

It also lacks of an interrupt mechanism.


