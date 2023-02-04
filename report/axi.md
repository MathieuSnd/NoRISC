# Formal AXI slave

Model checking works in such a way that memory reads must be formally randomized. Indeed, a proof of correctness for a core means that it does not violates the specification, no matter the code it executes and the data it reads.

The riscv-formal tool puts symbolic inputs for each cycle and signal. The space of inputs can then be restricted by adding hypotheses, such as SystemVerilog assumptions.

The tool provides example of cores to verify, using a wrapper which generates symbolic inputs respecting the memory protocol. For every example the tool provides, the native memory interface is always quite simple. Figure ??? gives the example for the picorv32 memory interface.


input/output signal | size | meaning
|-- |-- |--
output | 1  | `mem_valid` | valid handhake for read / write
output | 1  | `mem_instr` | 0 for writes, 1 for reads.
input  | 1  | `mem_ready` | ready handshake for read / write
output | 32 | `mem_addr`  | read / write address
output | 32 | `mem_wdata` | data to be written
input  | 32 | `mem_rdata` | read data 
output | 4  | `mem_wstrb` | byte selection in `mem_wdata`

__Figure ??: picorv32 native memory interface__

The protocol has a single read/write channel and only two inputs. Therefore it is not hard to meet the specification in this case. The example puts random values in both `mem_rdata` and `mem_ready` at every clock cycle. 

However, some processor cores export more complex native memory interfaces. For example, in a real-case System-On-Chip with no cache, the core is often connected to an AHB, APB or AXI-lite bus atrbitrer. This fact motivates the need of a formal memory slave.

The picorv32 is available in 3 different versions: 

- `picorv32`, wich uses the native memory interface presented on figure ??.
- `picorv32_axi`, which uses an AXI-lite memory interface.
- `picorv32_wb`, which uses a WhishBone memory interface.


This project provides the way to verify a core with a AXI-lite memory interface. The solution was to write a memory slave which reads symbolic values and ignores writes. To take memory stalls in consideration and potentially find associated bugs, the slave responds in a random time.


## AXI-lite protocol

AXI-lite is a light-weight adaptation of the ARM's Advanced eXtensible Interface protocol. It introduces the concept of __master__, __slave__, __channels__ and __handshakes__.
The master is the initiator of the requests. It asks the slave to read or to write and the slave acknowledges.

AXI-lite provides the following channels:

- Address Read
- Read Response
- Data Write
- Address Write
- Write Response



While the Address Read, Address Write and Data Write channels are driven by the master, the Read Response and Write Response channels are driven by the slave.
The channel driver controls a `VALID` sigal while the other end controls a `READY` signal. A transaction happens in a channel whenever both `VALID` and `READY` are asserted at the same time during one cycle. It is called a handshake.

A read sequence happens when a handshake on the Read Response Channel follows a handshake on the Read Address Channel.


A write sequence happens when handshakes on the Address Write and Data Write channels are followed by a handshake on the Write Response channel. Figure ?? shows the main AXI-lite signals. 

Figure ?? and ?? show the dependancy between the channels for read and write sequences.


  
    
       

<br/>
<br/>
<br/>



__Address Read Channel__

name | size (bits) | driver |  meaning 
-- |-- |-- |--
ARVALID | 1  |  master | valid signal
ARREADY | 1  |  slave  | ready signal
ARADDR  | 32 |  master | read address

__Read Response Channel__

name | size (bits) | driver |  meaning 
-- |-- |-- |--
RVALID | 1  | slave  | valid signal
RREADY | 1  | master | ready signal
RDATA  | 32 | slave  | read data
RRESP  | 2  | slave  | read response (for errors)



Address Write Channel
name | size (bits) | driver |  meaning 
-- |-- |-- |--
AWVALID   | 1  | master  | valid signal
AWREADY   | 1  | slave   | ready signal
AWADDR    | 32 | master  | write address



Data Write Channel

name | size (bits) | driver |  meaning 
-- |-- |-- |--
WVALID    | 1  | master | valid signal
WREADY    | 1  | slave  | ready signal
WDATA     | 32 | master | write data
WSTRB     | 4  | master | 



Write Response Channel

name | size (bits) | driver |  meaning 
-- |-- |-- |--
BVALID    | 1  | slave  | valid signal
BREADY    | 1  | master | ready signal
BRESP     | 1  | slave  | write response (for errors)


__Figure ??: AXI-lite signals__






![fig23](./AXI_read.png)

__Figure ??: Read  transaction handshake dependencies, from the AXI Specification[6]__

<br/>

![fig24](./AXI_write.png)

__Figure ??: Write transaction handshake dependencies, from the AXI Specification[6]__





## Implementation

`riscv-formal` provides a way to generate N bit symbolic registers - Registers that can potentially hold any possible value at every clock cycle. The slave is based on the use of these registers. However the AXI-lite specification requires the following main properties for a slave:

- P1 - `RDATA` and `RRESP` must be stable while `RVALID` is asserted.
- P2 - `BRESP` must be stable while `BVALID` is asserted.
- P3 - `RVALID` must eventually rise after a handshake on the address read channel.
- P4 - `RVALID` must only rise after a handshake on the address read channel.
- P5 - `BVALID` must eventually rise after a handshake of both the write and address write channels.
- P6 - `BVALID` must only rise after a handshake of both the write and address write channels.



The `ARREADY`, `RVALID`, `AWREADY`, `WREADY` and `BVALID` signals are symbolic and still 


`RRESP` and `BRESP` are not used by the `picorv32_axi` core, so they are not geneated by the slave. However, a core could make use of these signals to generate memory access exceptions. For such a core, it would be usefull to give it a symbolic value when `RVALID` and respectively `BVALID` are asserted.


## Verification


The random slave has been first verified in simulation, using _Mentor Questa Simulator_ and random values. As stated in the introduction section, simulation-based verification is not enough to provide a proof of correctness, so  the slave has then been formally verified using __unbounded model checking__. The Mentor Verification tool ran SystemVerilog assertions and proved P1 - P6. Note that the verification module has been done as a part of a University lab at Telecom Paris.



## Liveness conditions

As an example of use, the `picorv32_axi` core is verified using presented formal axi-lite slave. See the git repository for instruction to reproduce the verification.

Note that this method won't provide a proof of correctness for the AXI-lite port. A formal checker can be used conjointly to prove it.

The `riscv-formal` liveness check requires stronger assumtions on the memory interface. Indeed, the slave can take an arbitrary time to response. The verification wrapper is modified so that memory transactions take at most 9 clock cycles. The liveness check is passed using this value, for a symbolic execution of 30 clock cycles.

