# STNICC demo (written for the Commander X16 in assembly)

To generate files:

   python file_splitter.py
   python generate_intro_binaries.py

To compile: (this assumes cc65 is installed)

    cl65 -t cx16 -o STNICCC.PRG stniccc.asm

To run:

    x16emu.exe -prg STNICCC.PRG -run -ram 2048

Notes: 

- This only works on the x16 emulator with 2MB of RAM
- It uses the original data (but its split into 8kb blocks, so it can fit into banked ram)
- Waaaayyy to much time is spend on the core-loop to make it perform *this* fast!
- My estimate is that it can be improved by 10-15 seconds (I have a design really, but it requires a re-write of the core-loop)
- Keep in mind the Commander X16 only has:
    - An 8-bit 6502 cpu (8MHz)
    - No DMA
    - No Blitter
   -> Yet it keeps up with 16-bit machines like the Amiga! (actually its even faster right now)
- It uses a "stream" of audio-file data and produces 24Khz mono sound (this will not work on the real x16, since loading the files that fast is a feature of the emulator alone)