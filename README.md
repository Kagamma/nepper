# nepper

An attempt to write an OPL2/3 tracker that can run on IBM XT and its clones.

Motivation: I just want a tracker that can run on my Book 8088 laptop, which is basically an IBM XT clone with a built-in OPL3 chip.

The UI of the program is inspired by Faust Music Creator, while its playback engine is more in line with Adlib Tracker II.

The program supports the following file formats:
- `.NTR` (Nepper's TRack) [R/W]
- `.NIS` (Nepper's InStrument) [R/W]
- `.RAD` (Reality AdLib Tracker v1) [R]

While the program can load RAD files, it might sound weird due to incompatible playback engine.

Documentation:
- See `bin\FORMAT.TXT` for `NTR` file format, `bin\INSTR.TXT` and `bin\PATTERN.TXT` for how to use the program.
- You can also access `bin\INSTR.TXT` and `bin\PATTERN.TXT` in Nepper by pressing `F1`.

How to build:
- You need a Free Pascal cross-compiler for msdos-8086, with Compact memory model.

![1](/doc/img/nepper_000.png)

![2](/doc/img/nepper_001.png)

![3](/doc/img/nepper_book8088.png)
