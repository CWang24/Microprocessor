#Design of a General Purpose Microprocessor<br />
<br />
<br />
Full custom design.&nbsp;<br />
General purpose Multi-Cycle Microprocessor.&nbsp;<br />
Consist of SRAM, ALU and Register Files.&nbsp;<br />
Support 13 different instructions including:&nbsp;<br />
&nbsp; &nbsp; &nbsp;memory instructions like LOAD STORE,&nbsp;<br />
&nbsp; &nbsp; &nbsp;logic instructions like AND OR XOR, ADD instructions with 3 different burst lengths<br />
&nbsp; &nbsp; 16-bit division instruction. &nbsp;<br />
Optimized in terms of area, delay and power consumption. &nbsp;<br />
Perl script used as decode stage of the processor(decoding instructions by generating input control signals)<br />
Result verification by perl script.<br />
======================================================================<br />
![image](https://dl.dropboxusercontent.com/s/em253abjckwr6k4/Virtuoso.png)

#Laravel Virtuoso

####Laravel Composable View Composers Package

Increase flexibility and reduce code duplication by easily composing complex View Composers from simple 
component Composers without unnecessary indirection or boilerplate code.

## Background

In many of our projects, the same data is often repeated on multiple pages. This presents the challenge 
of preparing this data in our Controllers and providing it to our various Views without an undue amount 
of code repetition. Laravel provides us with the ability to limit this potential repetition through an 
abstraction known as the View Composer. A View Composer allows you to abstract this code to a single 
location and make it available to multiple Views. A View Composer is simply a piece of code which is 
bound to a View and executed whenever that View is requested.

An example View Composer from the Laravel documentation:

``` php
View::composer('profile', function($view)
{
	$view->with('count', User::count());
}
```
