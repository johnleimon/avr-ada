mk_ada_app.sh is a VERY simple skeleton application creator.
It only replaces some variables by some user-defined strings.

It should create a ready-to-compile skeleton project.

Please send any problems, enhancements, etc to the avr-ada list - thanks.

-----------------------------------------------------------------------------
Usage:
sh mk_ada_app.sh Directory_Name project_name main_package_name mcu_name

note: project_name, main_package_name, mcu_name have to be lower case!

-----------------------------------------------------------------------------
Example:
$ sh mk_ada_app.sh /tmp/6_Channel_DVM dvm dvm_main atmega8
mk_ada_app 0.2

directory: "/tmp/6_Channel_DVM"
  project: "dvm"
  package: "dvm_main"

Creating directory "/tmp/6_Channel_DVM"..
Preprocessing start files..
Preprocessing main package files..
Creating Makefile..
Creating dvm.gpr file..

Done. (Now, try 'make -C "/tmp/6_Channel_DVM"')

$ ls /tmp/6_Channel_DVM/
Makefile  dvm.adb  dvm.ads  dvm.gpr  dvm_main.adb  dvm_main.ads

After successfuly test-compiling the empty project, you may want to 
start editing the file /tmp/6_Channel_DVM/dvm_main.adb.

-----------------------------------------------------------------------------
todo:
- make avr-* packages selectable
- ?
