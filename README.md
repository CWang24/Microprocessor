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
This part we directly used the SRAM design in Lab2(You could find it [here(part1)](https://github.com/CWang24/SRAM) and [here(part2)](https://github.com/CWang24/SRAM_Part2). However we replaced the DFFs with Register Files here.
###### 2.2 Register Files
The DFF design is [here](https://github.com/CWang24/DFF)
###### 2.3 ALU
We design two ALUs, they are almost identical in terms of structure. We name them as “Left ALU” and “Right ALU” based on their locations in the schematic. The only difference between the two is the sizing of some paths due to their different positions in this processor.
###### 2.4 Overall schematic
###### 2.5 Perl Scripting
The perl code is [here](http://www.dushibaiyu.com). It reads the instruction file “cmd.txt”, and generate the corresponding vector file “CPU.vec”.
