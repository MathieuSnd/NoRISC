# NoRISC

NoRISC is a university project ran by Mathieu Serandour (mathieu.serandour@telecom-paris.fr) and supervised by Ulrich Khune (ukhune@telecom-paris.fr).

This project consisted in formally verifying a rv32i core written by two students at Telecom Paris, and implement and verify the RISC-V Bit Manipulation "B" extension. For this project I also implemented a formal axi4-lite memory slave that always reads arbitrary values and answers in an arbitrary time. I then used it to verify the picorv32 core with an axi memory interface.


See [paf-formal](./paf-formal/) to reproduct the verification of the rv32ib core. 

See [riscv-axi-formal](riscv-axi-formal) for more details.


See the (project report)[./report/everything.md] for the implementation details.