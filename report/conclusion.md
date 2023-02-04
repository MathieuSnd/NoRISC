# Conclusions

## PAF rv32ib synthesis 

This sections presents the synthesis of the PAF core.
The synthesis is made using _Altera Quartus_ 2020, targeting the Cyclone V 5CSEMA5F31C6 FPGA.

The core's carry less multiplier takes N cycles where N is a synthesis parameter. It allowed to test multiple values and compare the timing and area cost between values.


### Timing analisys


The _Quartus_ timing analysis showed that the critical path of the design is the following:  

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

The main contribution of this project is the verification and implementation of the rv32ib PAF core, as an exploration of the open source verification tool `riscv-formal`. It is to note that although the __bug hunting verification__ mehodology is very useful in practice, it des not provide a complete correctness proof. 

Further work can be done to fully prove the core, using __unbounded model checking__ or __theorem proving__ methods. Besides, as briefly discussed in the last section, the implementation can be improved. The area and timing analysis lead highlight the following potential improvements:

- better decoding in the `ID` stage to decrease the area.
- the addition of a pipeline stall when a byte load or a half-word load instruction is followed by `JALR` to improve the critical path.
- the addition of a new pipeline stage to improve the critical path.





### riscv-formal

`riscv-formal` is a promising open-source RISC-V bounded model checking verification tool. Though it lacks of support for multicore architechtures. 

### PAF core

As stated in the synthesis analysis section, the PAF core implementation is to be imprpoved, by working on:

- a better decoding in the `ID` stage to decrease the area.
- the addition of a pipeline stall when a byte load or a half-word load instruction is followed by `JALR` to improve the critical path.
- the addition of a new pipeline stage to improve the critical path.

It also lacks of an interrupt mechanism.
