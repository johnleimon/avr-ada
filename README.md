# AVR Ada
A clone of Rolf Ebert's AVR Ada project. Build script by Tero Koskinen.

Introduction:

This is my sandbox where I'm working to make the process of building the AVR Ada cross compiler
easier and less monolithic. In going forward the goal is to add support for more peripherals and devices.

Rolf's AVR Ada project page is here: http://sourceforge.net/projects/avr-ada/

Tero's original AVR Ada build script is here: https://bitbucket.org/tkoskine/avr-ada-build-script

Prerequisites:

> apt-get install build-essential libc6-dev gnat-4.6 libgmp-dev bison flex libmpfr-dev libmpc-dev texinfo zlib1g-dev

Building:

Run the build script:

> ./build.sh

Binaries:

AVR Ada binaries will be built in ./avr-ada-47/bin
