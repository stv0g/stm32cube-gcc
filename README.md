# STM32Cube Makefile

This is a template application for the STM32 ARM microcontrollers that compiles with GNU tools.

It serves as a quick-start for those who do not wish to use an IDE, but rather
develop in a text editor of choice and build from the command line.

## Target Overview

  - `all`       Builds the target ELF binary.
  - `program`   Flashes the ELF binary to the target board.
  - `debug`     Launches GDB and connects to the target.
  - `cube`      Downloads the most recent STM32Cube version from the ST website and extract it to `cube`.
  - `template`  Copies a simple example/template, startup code and a linker script from the `cube` to your `src` directory.
  - `clean`     Remove all files and directories which have been created during the compilation.

## Installing

Before building, you must install the GNU compiler toolchain.
I'm using the the `gnu-none-eabi` triple shipped with recent Debian and Ubuntu versions:

    sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi

You also might want to install some other libraries and debuggers:

    sudo apt-get install openocd gdb-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib

## Source code

Your source code has to be put in the `src` directory.
Dont forget to add your source files in the Makefile.

## Programming and debugging code on the board

First, make sure you have OpenOCD installed and in your path (see above).
Recent versions already come with full support for the discovery and nucleus boards.
Then connect your board, and load the application by saying:

    make program

To load the program and debug it using GDB, simply use the debug target:

    make debug

GDB connects to the board by launching OpenOCD in the background.
See [this blog post](http://www.mjblythe.com/hacks/2013/02/debugging-stm32-with-gdb-and-openocd/)
for info about how it works.

### UDEV Rules for the Discovery Boards

If you are not able to communicate with the Discovery board without
root privileges you should add [appropriate udev rules](49-stlink.rules).


