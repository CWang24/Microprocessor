#!/usr/local/bin/perl
$file = 'cmd.txt';
open(INFO,$file)||die"$!";
@lines=<INFO>;
close(INFO);
$file1 = 'CPU.vec';
open(OUT,">$file1");


@store_in=("store_in<[15:12]>","store_in<[11:8]>","store_in<[7:4]>","store_in<[3:0]>");
@SRAMctrl=("precharge_en","write_en","read_en","decoder_en");
@SRAMaddr=("Addr<5>","Addr<4>","Addr<3>","Addr<2>","Addr<1>","Addr<0>");
@SRAMaddr_bar=("~Addr<5>","~Addr<4>","~Addr<3>","~Addr<2>","~Addr<1>","~Addr<0>");
@itm=("itm<[31:28]>","itm<[27:24]>","itm<[23:20]>","itm<[19:16]>","itm<[15:12]>","itm<[11:8]>","itm<[7:4]>","itm<[3:0]>");
#    clk  ~clk reset
$OPR=F;
%TGsel=(
'Q_SRAM','0','R_SRAM','0','ALUhi_SRAM','0','ALUlo_SRAM','0','Pin_SRAM','0',           #SRAMsrc     5
'SRAM_N','0','SRAM_Q','0','SRAM_R','0','SRAM_D','0',       #SRAMdest   4,
'D_Bhi','0','D_Blo','0','Q_Blo','0','itmlo_Blo','0','itmhi_Bhi','0','N_Alo','0','R_Ahi','0',     #ALUsrc   7
'self_Q','0','self_N','0',# 'R_RNhi','0','N_RNlo','0' ,       # 2
'Cin1','0','Cin0','0','Pin_Cin1','0','DFF_Cin1','0','Pin_Cin0','0','DFF_Cin0','0',   # 6
'div','0');      #1
#print the head of .vec file
@TGsel_names=keys %TGsel;

print OUT "radix 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 4 4 4 4 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 4 4 4 4 4 4 4 4 4 1 1 1 1 1\n";
print OUT "io  i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i \n";
print OUT "vname  @TGsel_names @store_in @SRAMctrl @SRAMaddr @SRAMaddr_bar @itm opr<[3:0]> fi reset EN clk  ~clk\n";
print OUT "slope 0.01\nvih 1.8\ntunit ns\n";

#print out "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @itm $OPR 1 clk  ~clk;"
$time=0;
@store_in=('A', 'A', 'A', 'A');
@itm=('F', 'F', 'F', 'F', 'F', 'F', 'F', 'F');
#let's read the cmd file and output~~
# print OUT "$time @TGsel_val $store_in 0 0 0 0 @SRAMaddr $itm $OPR 1 clk  ~clk\n ";
#initialize all
foreach $instr (@lines)
{

  $reset_R=1;
  $bl=1;
  $errorCMD=0;
  $count=0;
  foreach $aa (keys %TGsel)
  { $TGsel{$aa}=0; }
  chomp $instr;
  print "$instr\n";
  print OUT ";$instr\n";
  @instr_elements=split(/\s+/,$instr);
  if($instr_elements[0]=~'OR')
  {$OPR=1;}
  if($instr_elements[0]=~'AND')
  {$OPR=2;}
  if($instr_elements[0]=~'XOR')
  {$OPR=4;}
  if(($instr_elements[0]=~'ADD')||($instr_elements[0]=~'DIV'))
  {$OPR=8;}
  print"OPR=$OPR\n";
  if($instr_elements[0]=~'STORE')
  {
    print"this is $instr_elements[0] instr.\n";
    if ($instr_elements[1]=~/B/)                                         #if find a binary address
    {$instr_elements[1]=sprintf("%X", oct( "0b$instr_elements[1]"));}    #convert it to hex
    $addr=hex($instr_elements[1]);
    #get bl and data, reporting errors if exist.
    if($instr_elements[2]=~"#")
    {$data=$instr_elements[2];}
    else
    {
      $bl=$instr_elements[2];
      $data=$instr_elements[3];
    }
    print"bl=$bl\n";    #this line can be removed later on
    &bl_err_det($addr);        #birst length error detection
    #normalize data in the instr.
    $data=substr($data,1); #knock off # sign
    while(length($data)<16)
    {$data="0".$data;}
    print"data=$data\n";
    #prepare to output
    $count=0;
    while (($count<$bl)&($errorCMD==0))
    {
      $SRAMsrc='Pin_SRAM';
      $store_in=substr($data,12-4*$count,4);   #set the pin value base on instr. and bl
      @store_in=split(//,$store_in);
      &bin_addr_gen($addr);
      print"now 16bit data on the pin is $store_in, ";
      &store;
      $addr++;
      $count++;
    }
  }
  if($instr_elements[0] eq 'LOAD')
  { print"this is $instr_elements[0] instr.\n";
    #get address
    $addr=$instr_elements[1];
    &HexOrBinAddr2Dec($addr);
    #get bl
    $instr_elements=@instr_elements;
    if ($instr_elements==3)
    {$bl=$instr_elements[2];}
    print"bl=$bl\n";     #this line can be removed later on
    &bl_err_det($addr);
    $count=0;
    while (($count<$bl)&($errorCMD==0))
    {
      $SRAMdest='SRAM_D';
      if($count==1)
      {$SRAMdest='SRAM_N';}
      if($count==2)
      {$SRAMdest='SRAM_R';}
      if($count==3)
      {$SRAMdest='SRAM_Q';}
      &bin_addr_gen($addr);
      &load;
      #create a negative edge to latch value into reg.
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends s s s\n  \n";
      $time=$time+0.8;#set up time
      $addr++;
      $count++;
    }
  }
  if(($instr_elements[0] eq 'OR')||($instr_elements[0] eq 'AND')||($instr_elements[0] eq 'XOR'))
  { print"this is $instr_elements[0] instr.\n";

    # Cin1=Cin0=0 ;Cin from Pin
    #$TGsel{'Cin1'}=1;
   # $TGsel{'Cin0'}=1;
   # $TGsel{'Pin_Cin1'}=1;
   # $TGsel{'Pin_Cin0'}=1;
    #"itmhi_Bhi=0","itmlo_Blo=0")div=0 are automatically reset to 0;
    $TGsel{'D_Bhi'}=1;
    $TGsel{'Q_Blo'}=1;
    $TGsel{'N_Alo'}=1;
    $TGsel{'R_Ahi'}=1;

    &blDestAddr_gen1;
    &bl_err_det($dest_addr);
    #get src addr
    $src_addrA=$instr_elements[$No_of_elements-2];
    $src_addrB=$instr_elements[$No_of_elements-1];
    &HexOrBinAddr2Dec($src_addrA);
    &HexOrBinAddr2Dec($src_addrB);
    #

    if($bl==1)
    {
      $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_Q';
      &bin_addr_gen($src_addrB);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      print OUT "  ;calculating...\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0;calculating...\n";
      $time=$time+2.2;#set up time
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;calculating...\n";
      $time=$time+0.8;#set up time



      $SRAMsrc='ALUlo_SRAM';
      if(($count==1)||($count==3))
      {$SRAMsrc='ALUhi_SRAM';}
      #$data16=substr($data,12-4*$count,4);
      &bin_addr_gen($dest_addr);
      &store;
    }
    $count=0;
    while(($count<2)&($bl>1))
    {
      $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_Q';
      &bin_addr_gen($src_addrB);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_R';
      $src_addrA++;
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_D';
      $src_addrB++;
      &bin_addr_gen($src_addrB);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time




      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store;
      $dest_addr++;
      $SRAMsrc='ALUhi_SRAM';
      &bin_addr_gen($dest_addr);
      &store;


      if($bl==2)
      {$count=$count+2;}
      if($bl==4)
      {$count=$count+1;}


      $src_addrA++;
      $src_addrB++;
      $dest_addr++;

    }



  }
  if(($instr_elements[0] eq 'ORI')||($instr_elements[0] eq "ANDI")||($instr_elements[0] eq "XORI"))
  { print"this is $instr_elements[0] instr.\n";
   # Cin1=Cin0=0 ;Cin from Pin
    #$TGsel{'Cin1'}=1;
 #   $TGsel{'Cin0'}=1;
   # $TGsel{'Pin_Cin1'}=1;
   # $TGsel{'Pin_Cin0'}=1;
   #"itmhi_Bhi=1","itmlo_Blo=1");
    $TGsel{'itmhi_Bhi'}=1;
    $TGsel{'itmlo_Blo'}=1;
    #div=0 are automatically reset to 0;
    #$TGsel{'D_Bhi'}=1;
    #$TGsel{'Q_Blo'}=1;
    $TGsel{'N_Alo'}=1;
    $TGsel{'R_Ahi'}=1;

    &blDestAddr_gen1;
    &bl_err_det($dest_addr);

    #get src addr
    $src_addr=$instr_elements[$No_of_elements-2];
    if ($src_addr=~/H/)                    #if find a hex address
    {$src_addr=sprintf("%B", hex($src_addr));}     #convert it to bin
    $src_addr=oct("0b$src_addr");
    #set itm pin from data in the instr.
    $itm=$instr_elements[$No_of_elements-1];
    $itmHL=substr($itm,1); #knock off # sign
    while(length($itmHL)<16)
    {$itmHL="0".$itmHL;}

    if($bl==1)
    {
      $itm=substr($itmHL,8,8);
      @itm=split(//,$itm);

      $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addr);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "  ;calculating...\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;calculating...\n";
      $time=$time+0.8;#set up time

      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0;calculating...\n";
      $time=$time+2.2;#set up time
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;calculating...\n";
      $time=$time+0.8;#set up time

      $SRAMsrc='ALUlo_SRAM';
      if(($count==1)||($count==3))
      {$SRAMsrc='ALUhi_SRAM';}
      #$data16=substr($data,12-4*$count,4);
      &bin_addr_gen($dest_addr);
      &store;
    }
    $count=0;
    while(($count<2)&($bl>1))
    {
      $itm=substr($itmHL,8,8);
      $SRAMdest='SRAM_N';
      if($count==1)
      {$itm=substr($itmHL,0,8);}
      @itm=split(//,$itm);

      $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addr);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time



      $SRAMdest='SRAM_R';
      $src_addr++;
      &bin_addr_gen($src_addr);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time




      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store;
      $dest_addr++;
      $SRAMsrc='ALUhi_SRAM';
      &bin_addr_gen($dest_addr);
      &store;


      if($bl==2)
      {$count=$count+2;}
      if($bl==4)
      {$count=$count+1;}


      $src_addr++;
      $dest_addr++;

    }
  }
  if($instr_elements[0] eq 'DIV')
  { print"this is $instr_elements[0] instr.\n";
    &blDestAddr_gen1;
    #get src addr
    $src_addrA=$instr_elements[$No_of_elements-2];
    &HexOrBinAddr2Dec($src_addrA);
    $src_addrB=$instr_elements[$No_of_elements-1];
    &HexOrBinAddr2Dec($src_addrB);
    #set path and function to DIV

    #load N then load D
    $SRAMdest='SRAM_N';
    &bin_addr_gen($src_addrA);
    &load;
    #create a negative edge to latch value into reg.
    @TGsel_val=();
    foreach $aa (keys %TGsel)
    {
      if($aa =~'SRAM_')
      {$TGsel{$aa}=0;}
      push @TGsel_val,$TGsel{$aa};
    }
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
    $time=$time+0.8;#set up time

    $SRAMdest='SRAM_D';
    &bin_addr_gen($src_addrB);
    &load;
    #create a negative edge to latch value into reg.
    @TGsel_val=();
    foreach $aa (keys %TGsel)
    {
      if($aa =~'SRAM_')
      {$TGsel{$aa}=0;}
      push @TGsel_val,$TGsel{$aa};
    }
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
    $time=$time+0.8;#set up time


    #change QRND source and all other path, start dividing
    #first all reset to 0
    #then set the following
    $TGsel{'div'}=1;
    $TGsel{'itmhi_Bhi'}=0;
    $TGsel{'itmlo_Blo'}=0;

    $TGsel{'self_Q'}=1;
    $TGsel{'SRAM_Q'}=0;
    $TGsel{'Q_SRAM'}=0;
    $TGsel{'Q_Blo'}=0;

    $TGsel{'SRAM_R'}=0;
    $TGsel{'R_SRAM'}=0;
    #$TGsel{'R_RNhi'}=1;
    $TGsel{'R_Ahi'}=0;

    $TGsel{'SRAM_N'}=0;
    $TGsel{'N_Alo'}=0;
    $TGsel{'self_N'}=1;
    #$TGsel{'N_RNlo'}=1;

    $TGsel{'D_Blo'}=1;
    $TGsel{'D_Bhi'}=1;
    $TGsel{'SRAM_D'}=0;


    $TGsel{'Cin1'}=1;
    $TGsel{'Cin0'}=1;
    $TGsel{'Pin_Cin1'}=1;
    $TGsel{'Pin_Cin0'}=1;
    @TGsel_val=();
    foreach $aa (keys %TGsel)
    {
      push @TGsel_val,$TGsel{$aa};
    }

    #generate 8 negative clk edge
    print OUT ";generate 8 negative clk edge \n";
    $count=0;
    while($count<8)
    {
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1 0\n";
    $time=$time+3;   #delay for value passing from output of Reg.s to the input of ALU, plus the ALU calculation...
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0 1\n";
    $time=$time+0.8; #latch the value
    $count++;
    }
    #store Q and R
    foreach $aa (keys %TGsel)
    { $TGsel{$aa}=0; }
    $SRAMsrc='Q_SRAM';
    &bin_addr_gen($dest_addr);
    &store;
    $SRAMsrc='R_SRAM';
    &bin_addr_gen($dest_addr+1);
    &store;
  }

  if($instr_elements[0] eq 'DIVI')
  { print"this is $instr_elements[0] instr.\n";
    &blDestAddr_gen1;
    #get src addr
    $src_addrA=$instr_elements[$No_of_elements-2];
    &HexOrBinAddr2Dec($src_addrA);
     #get itm data from instr. and output it to the pins
     $itm=$instr_elements[$No_of_elements-1];
     $itm=substr($itm,1);
     $itmlo=hex($itm);
     $itmlo=$itmlo*2;
     $itmlo=sprintf("%x",$itmlo);
     while(length($itmlo)>4)
     {$itmlo=substr($itmlo,1);}
     while(length($itmlo)<4)
     {$itmlo="0".$itmlo;}
     $itm="$itm".$itmlo;
     @itm=split(//,$itm);
     while(length($itm)<8)
     {$itm="0".$itm;}
     @itm=split(//,$itm);



    #set path and function to DIV
    #change QRND source and all other path, start dividing
    #first all reset to 0

    #load N and let the value pass on to the input of the ALU to do the first comparison


    #then set the following
    $TGsel{'div'}=1;
    $TGsel{'itmhi_Bhi'}=1;
    $TGsel{'itmlo_Blo'}=1;

    $TGsel{'self_Q'}=0;
    $TGsel{'SRAM_Q'}=0;
    $TGsel{'Q_SRAM'}=0;
    $TGsel{'Q_Blo'}=0;

    $TGsel{'SRAM_R'}=0;
    $TGsel{'R_SRAM'}=0;
   # $TGsel{'R_RNhi'}=1;
   # $TGsel{'R_Ahi'}=0;

    $TGsel{'SRAM_N'}=1;
    $TGsel{'N_Alo'}=0;
    $TGsel{'self_N'}=0;
   # $TGsel{'N_RNlo'}=1;

    $TGsel{'D_Blo'}=0;
    $TGsel{'D_Bhi'}=0;
    $TGsel{'SRAM_D'}=0;


    $TGsel{'Cin1'}=1;
    $TGsel{'Cin0'}=1;
    $TGsel{'Pin_Cin1'}=1;
    $TGsel{'Pin_Cin0'}=1;
    @TGsel_val=();
    foreach $aa (keys %TGsel)
    {
      push @TGsel_val,$TGsel{$aa};
    }
    #reset all registers in the beginning
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 0 1 1 0\n";
    $time=$time+0.1;


    $SRAMdest='SRAM_N';
    &bin_addr_gen($src_addrA);
    &load;
    #create a negative edge to latch value into reg.
    @TGsel_val=();
    foreach $aa (keys %TGsel)
    {
      if($aa =~'SRAM_')
      {$TGsel{$aa}=0;}
      push @TGsel_val,$TGsel{$aa};
    }
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
    $time=$time+0.06;#set up time

   # @TGsel_val=();
   # $TGsel{'SRAM_N'}=1;
   # foreach $aa (keys %TGsel)
   # {push @TGsel_val,$TGsel{$aa};}
   # print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0 1\n";
    $time=$time+5;  #5ns to do the first comparison
    #switch the paths to do the following 7 comparisons
    $reset_R=1;
    $TGsel{'div'}=1;
    $TGsel{'itmhi_Bhi'}=1;
    $TGsel{'itmlo_Blo'}=1;

    $TGsel{'self_Q'}=1;
    $TGsel{'SRAM_Q'}=0;
    $TGsel{'Q_SRAM'}=0;
    $TGsel{'Q_Blo'}=0;

    $TGsel{'SRAM_R'}=0;
    $TGsel{'R_SRAM'}=0;
   # $TGsel{'R_RNhi'}=1;
   # $TGsel{'R_Ahi'}=0;

    $TGsel{'SRAM_N'}=0;
    $TGsel{'N_Alo'}=0;
    $TGsel{'self_N'}=1;
   # $TGsel{'N_RNlo'}=1;

    $TGsel{'D_Blo'}=0;
    $TGsel{'D_Bhi'}=0;
    $TGsel{'SRAM_D'}=0;


    $TGsel{'Cin1'}=1;
    $TGsel{'Cin0'}=1;
    $TGsel{'Pin_Cin1'}=1;
    $TGsel{'Pin_Cin0'}=1;
    @TGsel_val=();
    foreach $aa (keys %TGsel)
    {push @TGsel_val,$TGsel{$aa};}
    #generate 7 negative clk edge
    print OUT ";generate 7 negative clk edge \n";
    $count=0;
    while($count<7)
    {
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0 1\n";
    $time=$time+5;
    print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1 0\n";
    $time=$time+0.25;
    $count++;
    }
    #store the result.
    foreach $aa (keys %TGsel)
    { $TGsel{$aa}=0; }
    $SRAMsrc='Q_SRAM';
    &bin_addr_gen($dest_addr);
    &store;
    $SRAMsrc='R_SRAM';
    &bin_addr_gen($dest_addr+1);
    &store;
  }

  if($instr_elements[0] eq 'ADD')
  { print"this is $instr_elements[0] instr.\n";

    #"itmhi_Bhi=0","itmlo_Blo=0",div=0 are automatically reset to 0;
    $TGsel{'D_Bhi'}=1;
    $TGsel{'Q_Blo'}=1;
    $TGsel{'N_Alo'}=0;
    $TGsel{'R_Ahi'}=0;

    &blDestAddr_gen1;
    &bl_err_det($dest_addr);
    #get src addr
    $src_addrA=$instr_elements[$No_of_elements-2];
    $src_addrB=$instr_elements[$No_of_elements-1];
    &HexOrBinAddr2Dec($src_addrA);
    &HexOrBinAddr2Dec($src_addrB);
    #
    if($bl==1)
    {
      #
        $TGsel{'Pin_Cin0'}=1;
        $TGsel{'DFF_Cin0'}=0;
        $TGsel{'Cin0'}=0;
        $TGsel{'Pin_Cin1'}=0;
        $TGsel{'DFF_Cin1'}=1;
        $TGsel{'Cin1'}=0;

        $SRAMdest='SRAM_N';
        &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_Q';
      &bin_addr_gen($src_addrB);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time

      #when the SRAM is in idle mode, make sure all four ctrl of SRAM are carefully valued such that
      #SRAM content is not spoiled and the power consumption is minimum, so  0 0 1 0;
      print"calculating...\n";
      #print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @itm $OPR 1 clk  ~clk;store starts\n ";
      print OUT "  ;calculating...\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+2.2;#set up time
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time
      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store;

    }
    if (($bl==2)||($bl==4))
    {
      #
        $TGsel{'Pin_Cin0'}=1;
        $TGsel{'DFF_Cin0'}=0;
        $TGsel{'Cin0'}=0;
        $TGsel{'Pin_Cin1'}=0;
        $TGsel{'DFF_Cin1'}=1;
        $TGsel{'Cin1'}=0;
      $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time


      $SRAMdest='SRAM_Q';
      &bin_addr_gen($src_addrB);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time

      $src_addrA++;
      $src_addrB++;
      $TGsel{'N_Alo'}=1;
      $TGsel{'R_Ahi'}=1;

      $SRAMdest='SRAM_R';
      &bin_addr_gen($src_addrA);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time

      $TGsel{'N_Alo'}=1;
      $TGsel{'R_Ahi'}=1;
      $SRAMdest='SRAM_D';
      &bin_addr_gen($src_addrB);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time


      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store4ADD4;
      $dest_addr++;

      $SRAMsrc='ALUhi_SRAM';
      &bin_addr_gen($dest_addr);
      &store4ADD4;

    }

    if($bl==4)
    {
      $src_addrA++;
      $src_addrB++;

      # Cin0=0 from Pin; Cin1 from DFF
     $TGsel{'Pin_Cin0'}=0;
     $TGsel{'DFF_Cin0'}=1;
     $TGsel{'Cin0'}=0;
     $TGsel{'Pin_Cin1'}=0;
     $TGsel{'DFF_Cin1'}=1;
     $TGsel{'Cin1'}=0;

      $TGsel{'N_Alo'}=0;
      $TGsel{'R_Ahi'}=0;
     $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_Q';
      &bin_addr_gen($src_addrB);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time

      $dest_addr++;
      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store;
      $dest_addr++;


      $src_addrA++;
      $src_addrB++;
      $TGsel{'N_Alo'}=1;
      $TGsel{'R_Ahi'}=1;
      $SRAMdest='SRAM_R';
      &bin_addr_gen($src_addrA);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time

      $SRAMdest='SRAM_D';
      &bin_addr_gen($src_addrB);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";


      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time





      $SRAMsrc='ALUhi_SRAM';
      &bin_addr_gen($dest_addr);
      &store;

    }



  }

  if($instr_elements[0] eq 'ADDI')
  { print"this is $instr_elements[0] instr.\n";

    #
    $TGsel{'D_Bhi'}=0;
    $TGsel{'Q_Blo'}=0;
    $TGsel{'N_Alo'}=0;     #turn on later
    $TGsel{'R_Ahi'}=0;     #turn on later
    &blDestAddr_gen1;
    &bl_err_det($dest_addr);
    #get src addr
    $src_addrA=$instr_elements[$No_of_elements-2];
    &HexOrBinAddr2Dec($src_addrA);

    #set itm pin from data in the instr.
    $itm=$instr_elements[$No_of_elements-1];
    $itmHL=substr($itm,1); #knock off # sign
    while(length($itmHL)<16)
    {$itmHL="0".$itmHL;}


    #
    if($bl==1)
    {
      #
        $TGsel{'Pin_Cin0'}=1;
        $TGsel{'DFF_Cin0'}=0;
        $TGsel{'Cin0'}=0;
        $TGsel{'Pin_Cin1'}=0;
        $TGsel{'DFF_Cin1'}=1;
        $TGsel{'Cin1'}=0;

        $SRAMdest='SRAM_N';
        &bin_addr_gen($src_addrA);
      &load;
      #"itmhi_Bhi=1","itmlo_Blo=1");
    $TGsel{'itmhi_Bhi'}=1;
    $TGsel{'itmlo_Blo'}=1;
    $TGsel{'N_Alo'}=1;
    $TGsel{'R_Ahi'}=1;
    #create a negative edge to latch value into reg.
    $itm=substr($itmHL,8,8);
    @itm=split(//,$itm);
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      #when the SRAM is in idle mode, make sure all four ctrl of SRAM are carefully valued such that
      #SRAM content is not spoiled and the power consumption is minimum, so  0 0 1 0;
      print"calculating...\n";
      #print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @itm $OPR 1 clk  ~clk;store starts\n ";
      print OUT "  ;calculating...\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+2.2;#set up time
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time

      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store;

    }
    if (($bl==2)||($bl==4))
    {
      #
        $TGsel{'Pin_Cin0'}=1;
        $TGsel{'DFF_Cin0'}=0;
        $TGsel{'Cin0'}=0;
        $TGsel{'Pin_Cin1'}=0;
        $TGsel{'DFF_Cin1'}=1;
        $TGsel{'Cin1'}=0;
      $TGsel{'itmhi_Bhi'}=0;
      $TGsel{'itmlo_Blo'}=0;

      $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.
    $itm=substr($itmHL,8,8);
    @itm=split(//,$itm);
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      $TGsel{'N_Alo'}=1;
      $TGsel{'R_Ahi'}=1;
      $TGsel{'itmhi_Bhi'}=1;
      $TGsel{'itmlo_Blo'}=1;
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time

      $src_addrA++;



      $SRAMdest='SRAM_R';
      &bin_addr_gen($src_addrA);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time         333333333333333333333333333333333

      $TGsel{'N_Alo'}=1;
      $TGsel{'R_Ahi'}=1;

      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store4ADD4;
      $dest_addr++;

      $SRAMsrc='ALUhi_SRAM';
      &bin_addr_gen($dest_addr);
      &store4ADD4;

    }

    if($bl==4)
    {
      $src_addrA++;


      # Cin0=0 from Pin; Cin1 from DFF
     $TGsel{'Pin_Cin0'}=0;
     $TGsel{'DFF_Cin0'}=1;
     $TGsel{'Cin0'}=0;
     $TGsel{'Pin_Cin1'}=0;
     $TGsel{'DFF_Cin1'}=1;
     $TGsel{'Cin1'}=0;


     $SRAMdest='SRAM_N';
      &bin_addr_gen($src_addrA);
      &load;
      #create a negative edge to latch value into reg.

      $itmlasthi=substr($itmHL,8,4);
      $itmpresentlo=substr($itmHL,4,4);
      $itm=$itmlasthi.$itmpresentlo;
      @itm=split(//,$itm);
      #print "$itm    ";
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time         333333333333333333333333333333333

      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 0 1  0;load ends\n  \n";
      $time=$time+3.7;#set up time         333333333333333333333333333333333

      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 0 0  1;load ends\n  \n";
      $time=$time+0.8;#set up time         333333333333333333333333333333333

      $dest_addr++;
      $SRAMsrc='ALUlo_SRAM';
      &bin_addr_gen($dest_addr);
      &store;
      $dest_addr++;


      $itm=substr($itmHL,0,8);
      @itm=split(//,$itm);
      $src_addrA++;
      $SRAMdest='SRAM_R';
      &bin_addr_gen($src_addrA);
      &load;
      @TGsel_val=();
      foreach $aa (keys %TGsel)
      {
        if($aa =~'SRAM_')
        {$TGsel{$aa}=0;}
        push @TGsel_val,$TGsel{$aa};
      }
      #create a negative edge to latch value into reg.
      print OUT ";create a negative edge to latch value into reg.\n";
      print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;load endsssssss\n";
      $time=$time+0.8;#set up time


      $SRAMsrc='ALUhi_SRAM';
      &bin_addr_gen($dest_addr);
      &store;

    }



  }


  print"  \n";
}
sub HexOrBinAddr2Dec
{

  if ($_[0]=~/H/)                    #if find a hex address
    {$_[0]=sprintf("%B", hex($_[0]));}     #convert it to bin
    $_[0]=oct("0b$_[0]");            #convert it to dec
}


sub blDestAddr_gen1  #for all logic instruction, both W/ or W/O itm.
{

    $No_of_elements=@instr_elements;    #can be used in other instr.
    if($No_of_elements==5)
    {$bl=$instr_elements[1];}
    else
    {$bl=1}                             #can be used in other instr.
    print"bl=$bl\n";     #this line can be removed later on
    #get dest address

    $dest_addr=$instr_elements[$No_of_elements-3];
    if ($dest_addr=~/H/)                    #if find a hex address
    {$dest_addr=sprintf("%B", hex($dest_addr));}     #convert it to bin
    $dest_addr=oct("0b$dest_addr");                              #convert it to oct

}
sub bl_err_det
{
  if(($bl!=1)&($bl!=2)&($bl!=4))
  {
    print"Error000: Command [$instr] has invalid burst length.\n";
    $errorCMD=1;
  }
  if((($bl==2)&($_[0]%2!=0))||(($bl==4)&($_[0]%4!=0)))
  {
    $errorCMD=1;
    print"Error002: Command [$instr] is not aligned properly.\n";
  }
}
sub bin_addr_gen
{
  $bin_addr=sprintf("%B", $_[0]);
  while(length($bin_addr)<6)
  {$bin_addr="0".$bin_addr;}
  $bin_addr_bar=63-$_[0];
  $bin_addr_bar=sprintf("%B", $bin_addr_bar);
  while(length($bin_addr_bar)<6)
  {$bin_addr_bar="0".$bin_addr_bar;}
}
sub store
{ print"now store from $SRAMsrc to address $bin_addr B (~:$bin_addr_bar)B\n";
  @SRAMaddr=split(//,$bin_addr);
  @SRAMaddr_bar=split(//,$bin_addr_bar);
  @TGsel_val=();
  #print OUT "$time   ";
  foreach $aa (keys %TGsel)
  {
    if($aa =~'_SRAM')
    {$TGsel{$aa}=0;}
    if($aa eq $SRAMsrc)
    {$TGsel{$aa}=1;}
    push @TGsel_val,$TGsel{$aa};

  }
  print"@TGsel_val\n";          #@store_in @SRAMctrl @SRAMaddr @itm OPR<[3:0]> reset clk  ~clk\n
  print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 0 1  0;store starts\n";
  $time=$time+2.4;
  print OUT "$time @TGsel_val @store_in 1 1 0 1 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 0 1  0;store ends before next row\n  \n";
  $time=$time+1.3;
  print OUT "$time @TGsel_val @store_in 1 1 0 1 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 0 0  1;store ends before next row\n  \n";
  $time=$time+0.8;


  #print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @itm $OPR 1 clk  ~clk\n";
  #$time=$time+0.24;

}
sub store4ADD4
{ print"now store from $SRAMsrc to address $bin_addr B (~:$bin_addr_bar)B\n";
  @SRAMaddr=split(//,$bin_addr);
  @SRAMaddr_bar=split(//,$bin_addr_bar);
  @TGsel_val=();
  #print OUT "$time   ";
  foreach $aa (keys %TGsel)
  {
    if($aa =~'_SRAM')
    {$TGsel{$aa}=0;}
    if($aa eq $SRAMsrc)
    {$TGsel{$aa}=1;}
    push @TGsel_val,$TGsel{$aa};

  }
  print"@TGsel_val\n";          #@store_in @SRAMctrl @SRAMaddr @itm OPR<[3:0]> reset clk  ~clk\n
  print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0;store starts\n";
  $time=$time+2.4;
  print OUT "$time @TGsel_val @store_in 1 1 0 1 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0;store ends before next row\n  \n";
  $time=$time+1.3;
  print OUT "$time @TGsel_val @store_in 1 1 0 1 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;store ends before next row\n  \n";
  $time=$time+0.8;


  #print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @itm $OPR 1 clk  ~clk\n";
  #$time=$time+0.24;

}
sub load  #load the value from SRAM to the input of Reg.
{ print"now load data from address $bin_addr B (~:$bin_addr_bar)B to $SRAMdest\n";
  @SRAMaddr=split(//,$bin_addr);
  @SRAMaddr_bar=split(//,$bin_addr_bar);
  @TGsel_val=();
  foreach $aa (keys %TGsel)
  {
    if($aa =~'SRAM_')
    {$TGsel{$aa}=0;}
    if($aa eq $SRAMdest)
    {$TGsel{$aa}=1;}
    push @TGsel_val,$TGsel{$aa};
  }
  #create a negative edge
  print"@TGsel_val\n";          #@store_in @SRAMctrl @SRAMaddr @itm OPR<[3:0]> reset clk  ~clk\n
  print OUT "$time @TGsel_val @store_in 0 0 0 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0;load starts\n";
  $time=$time+1.4;  #time for precharge;
  print OUT "$time @TGsel_val @store_in 1 0 0 1 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0\n";
  $time=$time+0.8;
  print OUT "$time @TGsel_val @store_in 1 0 1 1 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 1  0;load ends\n  \n";
  $time=$time+0.8;#delay from SRAM output passing TG to Reg input
 # print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 1 1 0  1;create a negative edge\n  \n";
  #$time=$time+0.09;
  #@TGsel_val=();
  #foreach $aa (keys %TGsel)
  #{
 #   if($aa =~'SRAM_')
 #   {$TGsel{$aa}=0;}
#    push @TGsel_val,$TGsel{$aa};
 # }
  #print OUT "$time @TGsel_val @store_in 0 0 1 0 @SRAMaddr @SRAMaddr_bar @itm $OPR 1 $reset_R 0  1;create a negative edge\n  \n";
 # $time=$time+0.01;
}
