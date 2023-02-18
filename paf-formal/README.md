# Formal PAF


This directory gathers the resources to formally verify the PAF core, see [paf core repository](https://github.com/MathieuSnd/paf-riscv), using [riscv-formal](https://github.com/YosysHQ/riscv-formal). 

To run the formal tests, run the following commands:

```
git clone --recursive https://github.com/MathieuSnd/NoRISC
cd NoRISC
mv paf-formal/verif-wrapper riscv-formal/cores/paf
cd riscv-formal/cores/paf
python3 ../../checks/genchecks.py
make -C checks 
```

