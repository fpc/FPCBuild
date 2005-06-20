This is the readme for the amiga scripts for creation
of snapshots and releases of the amiga compiler.

This assumes that a valid compiler is already 
available and is in the path with all correct
tools installed.

Pre-requisites:
1) Requires also trhat GNU make and ksh be installed.
2) Assumes that the fpc source tree is placed in work3:/fpc
3) Assumes that the snapshot creation will be done in the work: volume
4) makensap / makerelease should be copied to work3:/fpc

----------------
1) go into ksh and go to /work3/fpc/
2) export OS_TARGET=amiga
3) export CPU_TARGET=m68k
4) export PP=location of ppc68k (e.g : /work2/pp/bin/amiga/ppc68k)
5) make clean
6) cd rtl
7) make (to compile the amiga rtl)
8) exit ksh
9) execute makesnap
10) baseami.lha should be present! which is the amiga snapshot!



