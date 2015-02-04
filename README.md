Design of a General Purpose Microprocessor
===================================
#### Features
- Full custom design.&nbsp;<br />
- General purpose Multi-Cycle Microprocessor.&nbsp;<br />
- Consist of SRAM, ALU and Register Files.&nbsp;<br />
- Support 13 different instructions including:&nbsp;<br />
&nbsp; &nbsp; &nbsp;memory instructions like LOAD STORE,&nbsp;<br />
&nbsp; &nbsp; &nbsp;logic instructions like AND OR XOR, ADD instructions with 3 different burst lengths<br />
&nbsp; &nbsp; 16-bit division instruction. &nbsp;<br />
- Optimized in terms of area, delay and power consumption. &nbsp;<br />
- Perl script used as decode stage of the processor(decoding instructions by generating input control signals)<br />
- Result verification by perl script.<br />
- Frequency:<br />
 


## Design Detail


#### Phase 1: Divider Design

See [here](https://github.com/CWang24/16-bit-Unsigned-Divider)

#### Phase 2: Microprocessor Overview

Our Microprocessor consists of three parts: SRAM, Register Files and ALU. Since we merged the divider with all other function units, multiply select signals and transmisstion gate have been designed to ensure the paths are correct to realize the operation of each intruction.

###### 2.1 SRAM
This part we directly used the SRAM design in Lab2([part1](https://github.com/CWang24/SRAM_Part1) and [part2](https://github.com/CWang24/SRAM_Part2). However we replaced the DFFs with Register Files here.
###### 2.2 Register Files
Put 16 DFFs in a row, place them behind the SRAM. (TBC...)
###### 2.3 ALU
We designed two ALUs, they are almost identical in terms of structure. Placing two ALUs here is a compromise after a trade-off between area and speed. With two ALU, each 16 bits, we could do 32 bits calcultions directly.
The only difference between the two is the sizing of some paths due to their different positions in this processor.
###### 2.4 Overall schematic
###### 2.5 Perl Scripting
The perl code is [CPU_vec_gen.pl](https://github.com/CWang24/Design-of-a-General-Purpose-Microprocessor/blob/master/CPU_vec_gen.pl). It reads the instruction file “cmd.txt”, and generate the corresponding vector file “CPU.vec”.
