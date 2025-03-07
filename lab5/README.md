# FPGA Lab 5: UART, FIFO, Memory Controller
<p align="center">
Prof. John Wawryznek 
</p>
<p align="center">
TAs: (ordered by section) Rahul Kumar, Yukio Miyasaka, Dhruv Vaish </p>
<p align="center">
Department of Electrical Engineering and Computer Science
</p>
<p align="center">
College of Engineering, University of California, Berkeley
</p>

## Before You Begin

Ensure that you have a backup copy of your debouncer, synchronizer, and edge detector.
Then pull the latest lab skeleton.
```shell 
cd fpga_labs_sp23-username
git pull skeleton main
```

Replace the following files with the files you backed up.
 - `lab5/src/debouncer.v`
 - `lab5/src/synchronizer.v`
 - `lab5/src/edge_detector.v`

 Remember that you must not use any `always @(posedge clk)` blocks in modules intended for synthesis.
 Use the registers in the `EECS151.v` library instead.
 Using `always @(posedge clk)` in testbenches is fine, since they are not synthesizable.

### Reading
- Read this document on [ready-valid interfaces](https://inst.eecs.berkeley.edu/~eecs151/fa21/files/verilog/ready_valid_interface.pdf)

## Debugging

If your Verilog isn't working as expected, here are some things you should check:
* Does `make lint` report any errors/warnings (besides the `UNOPTFLAT` issue)?
* Are you using any `posedge clk` blocks? You should only be using combinational always blocks.
* Are all your registers instantiations of the ones in the `EECS151.v` library?
* Are there any inferred latches in the synthesis logs? Any warnings about multi-driven nets?
  If a variable is assigned in one combinational logic branch, remember that it must be assigned in **all** branches.
* Have you looked at the waveforms for relevant signals?
  Look for off-by-one-cycle timing issues and Xs (red waveforms).
* Does your code use non-synthesizable constructs?
  Ensure you are not using system functions, delays, or X's/Z's in modules you intend to synthesize.

## Overview

This lab is divided into 2 parts.
You should ask a TA to check you off once you have finished **both** parts.

### Part 1

- Understand the ready-valid interface
- Design a universal asynchronous receiver/transmitter (UART) circuit
- Design a first-in-first-out (FIFO) circuit 

There is no FPGA testing required for this part.

### Part 2
- Connect the FIFO and UART circuits together, bridging two ready-valid interfaces 
- Design a memory controller that takes read and write commands from a FIFO, interacts with a synchronous memory accordingly, and returns read results over another FIFO.
- We may add an optional section where you can build a piano that plays notes of a fixed length.

This part will involve testing your design on FPGA.

## Ready-Valid Interfaces
Often, we want to design modules that pass data between each other but are unaware of each other's internal timing.
The *ready-valid interface* is a standardized interface and protocol for timing-agnostic unidirectional data transfer between 2 modules.

The ready-valid interface is used to send data from a *source* to a *sink*.

<p align=center>
  <img height=150 src="./figs/sink_source.png" />
</p>

It consists of 3 wires:
  - `valid` (1 bit, driven by source, received by sink)
  - `data` (D bits, driven by source, received by sink)
  - `ready` (1 bit, driven by sink, received by source)

The sink uses the `ready` signal to tell the source if the sink is able to receive a new piece of data.
Usually the sink can only take in a certain number of data pieces until it is full and has to process what it has already received before it can receive any more.

The source uses the `valid` signal to tell the sink that the `data` bus has data it wishes to send to the sink.

A ready-valid *transaction* only occurs when both `ready` and `valid` are high on a rising clock edge.
If both `ready` and `valid` are high on a rising edge, the source can assume that the sink has received and *internally stored* the bits on `data`.

Here are a few examples:
<!--
wavedrom.com/editor.html
{signal: [
  {name: 'clk', wave: 'p......'},
  {name: 'data', wave: 'x3x33x.', data: ['a', 'x', 'b']},
  {name: 'valid', wave: '010.10.'},
  {name: 'ready', wave: '1......'}
]}
Save a .svg from the wavedrom webapp
Then to convert to .png
rsvg-convert image.svg -f pdf -o image.pdf
convert -density 300 image.pdf image.png
-->

<p align=center>
  <img height=150 src="./figs/2_rv_beats.png" />
</p>

There are two transactions that take place on the 3rd and 6th rising clock edges.
Note that the source can change `data` when `valid` is low.

<p align=center>
  <img height=150 src="./figs/backpressure.png" />
</p>
<!--
{signal: [
  {name: 'clk', wave: 'p......'},
  {name: 'data', wave: 'x3..3.x', data: ['a', 'b']},
  {name: 'valid', wave: '01....0'},
  {name: 'ready', wave: '10.1010'}
]}
-->

The sink can pull `ready` low whenever it isn't ready to accept new data.
In this example, there are 2 transactions that take place on the 5th and 7th rising clock edges.
When the source has `valid` high, but the sink has `ready` low we say that the sink is applying *backpressure* to the source.

The data transfer from source to sink only occurs when *both* `ready` and `valid` are high on a rising edge.

## UART Serial Device
In this lab, we will design a circuit that implements the UART serial protocol for transmitting and receiving data over a serial interface.
This will enables circuits on the FPGA to communicate with the workstation, which will allow us to programmatically send data to and from the FPGA.

UART is a 2 wire protocol with one wire carrying data from the workstation to the FPGA and the other one carrying data from the FPGA to the workstation.
Here is an overview of the setup we will use:

<p align=center>
  <img height=200 src="./figs/high_level_diagram.png"/>
</p>
<p align=center>
  <em>Diagram of the entire setup</em>
</p>

The UART transmit and receive modules use a *ready-valid interface* to communicate with other modules on the FPGA.
Both the UART’s receive and transmit modules will have their own separate ready-valid interface connected appropriately to other modules.

Please note that the serial line itself is not a ready/valid interface.
Rather, it is the modules you will work with in this lab (`uart_transmitter` and `uart_receiver`) that use the ready-valid handshake.

### UART Packet Framing
On the `PYNQ-Z1` board, the physical signaling aspects (such as voltage level) of the serial connection will be taken care of by off-FPGA devices.
From the FPGA's perspective, there are two signals, `FPGA_SERIAL_RX` and `FPGA_SERIAL_TX`, which correspond to the receive-side and transmit-side pins of the serial port.
The FPGA's job is to correctly frame 8-bit data words going back and forth across the serial connection.
The figure below shows how a single 8-bit data word is transferred over the serial line using the UART protocol.

<p align=center>
  <img height=200 src="./figs/uart_frame.png"/>
</p>
<p align=center>
  <em>Framing of a UART packet</em>
</p>

In the idle state the serial line is held high.
When the TX side is ready to send a 8-bit word, it pulls the line low.
This is called the start bit.
Because UART is an asynchronous protocol, all timing within the frame is relative to when the start bit is first sent (or detected, on the receive side).

The frame is divided into 10 uniformly sized bits: the start bit, 8 data bits, and then the stop bit.
The width of a bit in cycles of the system clock is given by the system clock frequency (`125 MHz`) divided by the baudrate.
The baudrate is the number of bits sent per second; in this lab the baudrate will be **115200**.
Notice that both sides must agree on a baudrate for this scheme to be feasible.

### UART Receiver
<p align=center>
  <img height=125 src="./figs/uart_rx.png"/>
</p>
<p align=center>
  <em>Connectivity of the UART receiver</em>
</p>

The receive side of the UART is just a shift register that shifts bits in from the serial line.
However, care must be taken into determining *when* to shift bits in.
If we attempt to sample the `FPGA_SERIAL_RX` signal directly on the edge between two symbols, we are likely to sample on the wrong side of the edge and get the wrong value for that bit.
One solution is to wait halfway into a cycle (until `SampleTime` on the diagram) before reading a bit in to the shift register.

The UART receiver module sends the received 8-bit word to a consumer block on the FPGA via a ready-valid interface.
Once we have received a full UART packet over the serial port, the `valid` signal should go high until the `ready` signal goes high, after which the `valid` signal will be driven low until we receive another UART packet.

You do not need to implement the UART receiver as it is provided to you in `lab5/src/uart_receiver.v`, but you should refer to its implementation when writing the `uart_transmitter`.

### UART Transmitter
<p align=center>
  <img height=125 src="./figs/uart_tx.png"/>
</p>
<p align=center>
  <em>Connectivity of the UART transmitter</em>
</p>

The UART Transmitter receives an 8-bit word from a producer block on FPGA via the ready-valid interface.
Once we have a 8-bit word that we want to send (i.e., once `valid` is high, and the transmitter is `ready`), transmitting it involves shifting each bit of the `data[7:0]` bus, plus the start and stop bits, out of a shift register on to the serial line.

Remember, the serial baudrate is much slower than the system clock, so we must wait `SymbolEdgeTime = ClockFreq / BaudRate` cycles between changing the bit we're putting on the serial line.
After we have shifted all 10 bits out of the shift register, we are done unless we have to send another frame immediately after.
The transmitter should not be `ready` when it is in a middle of sending a frame.

**Your task** is to complete the implementation of the UART transmitter in `lab5/src/uart_transmitter.v`.

### UART Transmitter Verification
We have provided 2 testbenches to verify the UART transmitter.
  - `sim/uart_transmitter_tb.v`
  - `sim/uart2uart_tb.v`

You can run them as usual; they will print out any errors during execution.

## FIFO
A FIFO (first in, first out) data buffer is a circuit that allows data elements to be queued through a write interface, and read out sequentially by a read interface.
The FIFO we will build in this section will have both the read and write interfaces clocked by the same clock; this circuit is known as a synchronous FIFO.

### FIFO Functionality
A FIFO is implemented with a circular buffer and two pointers: a read pointer and a write pointer.
These pointers address the buffer inside the FIFO, and they indicate where the next read or write operation should be performed.
When the FIFO is reset, these pointers are set to the same value.

When a write to the FIFO is performed, the write pointer increments and the data provided to the FIFO is written to the buffer.
When a read from the FIFO is performed, the read pointer increments, and the data present at the read pointer's location is sent out of the FIFO.

When the read pointer equals the write pointer, the FIFO is either full or empty.
The implementation of the FIFO logic is up to you,
but you may wish to store one extra bit of state to distinguish these two conditions.
The `Electronics` section of the [FIFO Wikipedia article](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)) will likely aid you in creating your FIFO.

Here is a block diagram of a FIFO similar to the one you should create, from page 103 of the [Xilinx FIFO IP Manual](https://www.xilinx.com/support/documentation/ip_documentation/fifo_generator_ug175.pdf).

<p align=center>
  <img src="./figs/sync_fifo_diagram.png" height=300 />
</p>

The interface of our FIFO will contain a *subset* of the signals enumerated in the diagram above.

### FIFO Interface
Look at the FIFO skeleton in `src/fifo.v`.

The FIFO is parameterized by:
  - `WIDTH` - The number of bits per entry in the FIFO
  - `DEPTH` - The number of entries in the FIFO.
  - `POINTER_WIDTH` - The width of the read and write pointers.

The common FIFO signals are:
  - `clk` - Clock used for both read and write interfaces of the FIFO.
  - `rst` - Reset (synchronous with `clk`); should force the FIFO to become empty.

The FIFO write interface consists of:
  - `input wr_en` - When this signal is high, on the rising edge of the clock, the data on `din` should be written to the FIFO.
  - `input [WIDTH-1:0] din` - The data to be written to the FIFO.
  - `output full` - When this signal is high, the FIFO is full.
When the FIFO is full, you should not accept any new data, even if `wr_en` is high.

The FIFO read interface consists of:
  - `input rd_en` - When this signal is high, on the rising edge of the clock, the FIFO should output the data indexed by the read pointer on `dout`.
  - `output [WIDTH-1:0] dout` - The data that was read from the FIFO after the rising edge on which `rd_en` was asserted.
  - `output empty` - When this signal is high, the FIFO is empty.
Attempting to read from an empty FIFO (by raising `rd_en`) should not corrupt any of the internal state of your FIFO.

### FIFO Timing
The FIFO that you design should conform to the specs above.
Here is a timing diagram for a *2-entry* FIFO.
Note that the data on `dout` only changes *after the rising edge* when `rd_en` is high.

<p align=center>
  <img height=300 src="./figs/fifo_timing.svg" />
</p>

<!--
https://wavedrom.com/editor.html
{signal: [
  {name: 'clk', wave: 'p........'},
  {name: 'wr_en', wave: '01.0.....'},
  {name: 'din', wave: 'x44x.....', data: ['a', 'b']},
  {name: 'full', wave: '0..1.0...'},
  {},
  {name: 'dout', wave: 'xxxxx5.5.', data: ['a', 'b']},
  {name: 'empty', wave: '1.0....1.'},
  {name: 'rd_en', wave: '0...1010.'}
]}
-->

### FIFO Testing
We have provided a testbench in `sim/fifo_tb.v`.

The testbench performs the following test sequence:
- Checks initial conditions after reset (FIFO not full and is empty)
- Generates random data which will be used for testing
- Pushes the data into the FIFO, and checks at every step that the FIFO is no longer empty
- When the last piece of data has been pushed into the FIFO, it checks that the FIFO is not empty and is full
- Verifies that cycling the clock and trying to overflow the FIFO doesn't cause any corruption of data or corruption of the full and empty flags
- Reads the data from the FIFO, and checks at every step that the FIFO is no longer full
- When the last piece of data has been read from the FIFO, it checks that the FIFO is not full and is empty
- Verifies that cycling the clock and trying to underflow the FIFO doesn't cause any corruption of data or corruption of the full and empty flags
- Checks that the data read from the FIFO matches the data that was originally written to the FIFO
- Prints out test debug info

This testbench tests one particular way of interfacing with the FIFO.
Of course, it is not comprehensive, and there are conditions and access patterns it does not test.
We recommend adding some more tests to this testbench (or writing a new testbench) to verify your FIFO performs as expected.
Here are a few tests to try:
  - Several times in a row, write to, then read from the FIFO with no clock cycle delays.
      This will test the FIFO in a way that it's likely to be used when buffering user I/O.
  - Try writing and reading from the FIFO on the same cycle.
      This will require you to use fork/join to run two threads in parallel.
      Make sure that no data gets corrupted.
      
## End of Part 1

Once you have finished implementing and testing the UART and FIFO, you are done with part 1!

Commit and push your code to GitHub.
Check that you are not pushing generated files (such as waveform dumps).
Do commit the Verilog source for any testbenches you write/modify.

## Memory Controller

One of the key enabling blocks for the RISC-V CPU on the Final Project of this course is Memory-Mapped I/O. Specifically, we will use UART that we build in this lab to interface between a host computer and a synchronous memory block. An instance of its use is to write instructions into the instruction memory with the UART interface so our CPU can run those instructions. In this lab, we will build a simple UART-FIFO-MEMORY interface to get you familiarized with working with RAMs.

<p align=center>
  <img height=550 src="./figs/Lab5_Block_Diagram.png"/>
</p>
<p align=center>
  <em>Block diagram of the system, note that the connections here are just for the purpose of illustration and do not represent all connections</em>
</p>

### Read/Write Packet
The host side (your workstation computer) will send a two-byte packet (for read operation) or a three-byte packet (for write operation) to the FPGA via UART. 
<p align=center>
  <img height=100 src="./figs/mem_packets.png"/>
</p>
<p align=center>
  <em>Format of data packets, write (ASCII '1' = 8'd49) is 1 on the keyboard, and read (ASCII '0' = 8'd48) is 0 on the keyboard</em>
</p>


### Operation of the Memory Controller
<!-- There are two modes of operation that you need to implement in memory_controller.v, which are controlled by SWITCH[0] on your FPGA board. -->
The role of the memory controller is to handle memory reads and writes based on commands
that the user sends from the host computer. Each operation is a multi-cycle process which
consists of different states. You do not need to support simultaneous reads and writes.
Your FSM needs to set the `mem_din` (memory input data), `mem_addr` (memory address), `mem_we` (memory write enable)
and FIFO communication signals properly.

Commands are either 2 bytes long (for reads), or 3 bytes long (for writes).
The first byte indicates whether you should perform a read or a write.
The second byte is the address to read from or write to.
For write commands, the third byte is the data to write into memory.

1. Your memory controller FSM should start with an IDLE state upon pressing the reset button.
It should make a read (**the 1st byte**) from the RX FIFO whenever the `rx_fifo_empty` signal becomes 0.
Remember that we're using a **synchronous** FIFO.
Then, it should wait for the next packet (the address byte) to arrive at the FIFO, so it can read that byte (**the 2nd byte**). 

2. Next, depending on whether a Read (8'd48, or key 0 on the keyboard) or a Write (8'd49, or key 1 on the keyboard) command has been received for the first byte, the memory controller transitions into different states.

3. 
  - If the command was "write", then the FSM should wait for the data byte (**the 3rd byte**) to become available in the FIFO.
    Once the data byte is read, the controller should write the data byte into the correct address in memory, then return to IDLE.
  - If the command was "read", then the value at the corrsponding address should be read from the RAM,
    and then sent to the TX_FIFO (setting control signals accordingly), followed by returning to the IDLE state.
    Again, remember the implications that a synchronous FIFO has for the timing of your control signals.

You can use `state_leds` to monitor current state on the FPGA. Some states will pass too quickly to be visible, but the "IDLE" and input states involve waiting 
and hence should be easily visible. We will not be testing you on the use of `state_leds`.

<p align=center>
  <img height=300 src="./figs/flowchart.png"/>
</p>
<p align=center>
  <em>Flow diagram of the FSM. Note that transitions back to the current state are not shown here</em>
</p>

Keep in mind that the input bytes might not be sent back-to-back, so your FSM has to wait in the current state until it receives the next byte.

Implement your FSM in `src/mem_controller.v`.
We've provided suggested variables and states, but you are free to modify them as you see fit.
However, you should not change the controller interface.

### Running the testbench
Once you finish `mem_controller.v` run the `sim/mem_controller_tb.v` testbench.

If the simulation doesn't finish (gets stuck), press `ctrl+c` and type `quit`,
then open up the `dve` tool to check the waveform.
Does the timing of each state transition and control signal look correct (refer to the FIFO timing diagram above)?

If you see all tests passed, proceed to running the system level testbench `sim/system_tb.v`,
which requires your top level, uart, fifo, and memory controller to all work together.

Note that both `mem_controller_tb.v` and `system_tb.v` require a correct
FIFO to interface with the memory controller.

If everything looks correct, program your FPGA (see next section).

## On the FPGA
Use the standard `make impl` and `make program` to create and program a bitstream.

**Pay attention to the warnings** generated by Vivado in `build/synth/synth.log`.
It's possible to write your Verilog in such a way that it passes behavioural simulation but doesn't work in implementation.
Warnings about `multi driven nets`, for example, can lead to certain logic pathways being optimized out. Latch synthesis is another notable cause of mismatch between simulation and FPGA behavior.

### PMOD USB-UART
The PYNQ-Z1 does not have an RS-232 serial interface connected to the FPGA fabric.
So we'll be using the [PMOD USB-UART](https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/) extension module to add a UART interface to the Pynq board.
Connect the PMOD module to the **top** row of the PMOD A port on the Pynq, and connect a USB cable from the USB-UART PMOD to your computer (this is already done in the Cory 111 workstations).

*Note:* Make sure that the power selection jumper on the PMOD USB-UART is set to LCL3V3.

<p align=center>
  <img height=250 src="./figs/pmod_a.jpg"/>
</p>
<p align=center>
  <em>PMOD USB-UART plugged in with correct power jumper setting (blue).</em>
</p>

### Hello World
Make sure `SWITCH[0]` is at "off(0)" position so you are in the memory controller mode. Reset the UART circuit on your FPGA with `buttons[0]`.

On your workstation, run:
```shell
screen $SERIALTTY 115200
```

This opens `screen`, a terminal emulator, connected to the serial device with a baud rate of 115200.
When you type a character into the terminal, it is sent to the FPGA over the `FPGA_SERIAL_RX` line, encoded in ASCII.
When the memory controller sends a new character, it will be pushed over the `FPGA_SERIAL_TX` line to your workstation computer.
When `screen` receives a character, it will display it in the terminal.

<!--- If you have a working design, you can **type a few characters into the terminal** and have them echoed to you.
Make sure that if you type really fast that all characters still display properly.--->

To test your implementation, type one character at a time. Send write packets (remember the byte corresponding to each character will be its ASCII value; ASCII charts are readily available online). Then send read packets with addresses you've written to and ensure you receive the data written earlier. 

If you see some weird garbage symbols then the data is getting corrupted and something is likely wrong. 
If you see this happening very infrequently, don't just hope that it won't happen while the TA is doing the checkoff; take the time now to figure out what is wrong.
UART bugs are a common source of headaches for groups during the final project.

**To close `screen`, type `Ctrl-a` then `Shift-k` and answer `y` to the confirmation prompt.**
If you don't close `screen` properly, other students won't be able to access the serial port on your workstation.

If you try opening `screen` and it terminates after a few seconds with an error saying `Sorry, can't find a PTY` or `Device is busy`, execute the command `killscreen` which will kill all open screen sessions that other students may have left open.
Then run `screen` again.

Use `screen -r` to re-attach to a non-terminated screen session.
You can also reboot the computer to clear all active `screen` sessions.

## Lab Deliverables

### Lab Checkoff
To checkoff for this lab, have these things ready to show the TA:
  - Go through the UART simulation results and show that your UART behaves as expected. What do the testbenches do?
  - Go through the FIFO simulation results and show it works correctly.
  - Demonstrate on FPGA that it can perform write and read operations with the memory: 1. read after write, in random addresses and orders (e.g. W-R-W-R or W-W-R-R etc.)

## Acknowledgement
This lab is the result of the work of many EECS151/251 GSIs over the years including:
- Sp12: James Parker, Daiwei Li, Shaoyi Cheng
- Sp13: Shaoyi Cheng, Vincent Lee
- Fa14: Simon Scott, Ian Juch
- Fa15: James Martin
- Fa16: Vighnesh Iyer
- Fa17: George Alexandrov, Vighnesh Iyer, Nathan Narevsky
- Sp18: Arya Reais-Parsi, Taehwan Kim
- Fa18: Ali Moin, George Alexandrov, Andy Zhou
- Sp19: Christopher Yarp, Arya Reais-Parsi
- Fa19: Vighnesh Iyer, Rebekah Zhao, Ryan Kaveh
- Sp20: Tan Nguyen
- Fa20: Charles Hong, Kareem Ahmad, Zhenghan Lin
- Sp21: Sean Huang, Tan Nguyen
- Fa21: Vighnesh Iyer, Charles Hong, Zhenghan Lin, Alisha Menon
- Sp22: Alisha Menon, Yikuan Chen, Seah Kim
- Fa22: Yikuan Chen, Raghav Gupta, Ella Schwarz, Paul Kwon, Jennifer Zhou
- Sp23: Rahul Kumar, Yukio Miyasaka, Dhruv Vaish
