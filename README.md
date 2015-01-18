Design of a General Purpose Microprocessor
===================================
##### Features
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
### Design Detail
****

### Phase 1: Divider Design
Mechanism explained in pseudo code
```
if D == 0 then throw an Exception end
Q = 0; R = 0;
for i =  ?
? -1..0 do // n is data width of N
R = R << 2 
R(1:0) = N(2i+1:2i) 
if R >= 3D then
R = R – 3D; Q(2i+1:2i) = 3; end
else if R >= 2D then
R = R – 2D; Q(2i+1:2i) := 2; end
else if R>= D then
R = R – D; Q(2i+1:2i) := 1; end
end
```

[image]: https://dl.dropboxusercontent.com/s/kx1ykn9j2o9fqyw/image2.jpeg?dl=0
