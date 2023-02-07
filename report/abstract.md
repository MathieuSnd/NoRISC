# Abstract

The RISC-V instruction set architecture (ISA) has been designed to be highly modular. This makes it an ideal platform for processor formal verification, which is a critical step in the design of processor cores. This report presents the formal verification of the PAF Core that was used as the basis for this research. This core is an open-source RISC-V processor core written as a university project at Telecom Paris by Florian Tarazona and Erwan Glazsiou. The PAF Core was found to be quite buggy and in need of significant modifications to be compatible with the riscv-formal tool, which is used to prove that a processor is correct according to the RISC-V ISA.

The formal verification of the PAF Core covered the base RISC-V ISA (rv32i) and the B extension (Bit manipulation). The core was modified to implement trapping, which detects ill-formed instructions and unaligned accesses. Several bugs were found and fixed such as missing instructions, pipeline stalls not properly implemented, bad forwarding and load instruction triggering trap on miss-aligned addresses.

In addition to the formal verification of the PAF Core, the report also includes the formal verification of an AXI-lite random memory controller, which I used to formally verify AXI-lite variant of the picorv32 core.

The report concludes with an analysis of the contributions of the research, including a timing and area analysis of the PAF processor. The results of this work provide a strong foundation for further improvements to the PAF Core.  


