# RISC-V AXI Formal

This directory gathers the resources to verify and use the formal axi-lite memory slave that always reads arbitrary values and answers in an arbitrary time. The code can be found [there](rand_axi_slave.sv).



As an example of use of this file to verify a core that uses an AXI-lite memory interface, follow the instructions bellow to reproduct the verification of the picorv32 AXI variant, using riscv-formal. 

```
git clone --recursive https://github.com/MathieuSnd/NoRISC
cd NoRISC
mv riscv-axi-formal/ riscv-formal/cores/picorv32-axi 
cd riscv-formal/cores/picorv32-axi
wget -O picorv32.v https://raw.githubusercontent.com/YosysHQ/picorv32/master/picorv32.v
python3 ../../checks/genchecks.py
make -C checks -j$(nproc)
```
