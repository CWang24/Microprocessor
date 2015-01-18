#!/usr/local/bin/perl

$file1 = 'divider.vec';
open(OUT,">$file1");
#print the head of .vec file
print OUT "radix 4 4 1 1 1 1 \n";
print OUT "io  i  i  i  i  i  i \n";
print OUT "vname Ni<15:12> Ni<11:8> Ni<7:4> Ni<3:0> D<3:0> D<15:12> D<11:8> D<7:4> D<3:0> Nselect reset clk ~clk\n";
print OUT "slope 0.01\nvih 1.8\ntunit ns\n";
#let's read this cmd file~~
$N='0008';
@N=split(//,$N);
$D='0003';
@D=split(//,$D);
#reset all the flip-flops(NDQR)
$time=0;
print OUT "$time @N @D 0 0 1 0\n";
#wait a certain time for the output of the comparator to be stable, then create negtive edge of clk to latch MOD(R,D) into R;
$comp_time=5;
$time=$time+$comp_time;
print OUT "$time @N @D 0 1 0 1\n";
$count=0;
while($count<=8)
{#change NQselect to 1, NQ now get input from circuit instead of input pins.
$time=$time+2.5;#hold time=0ns actually
print OUT "$time @N @D 1 1 1 0\n";
$time=$time+$comp_time/2;
print OUT "$time @N @D 1 1 0 1\n";
$count=$count+1;
}
