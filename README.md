# RCS (Reverse Computer Screen)

**RCS** is an utility to reorder bytes from ZX Spectrum screens before compression.

Technically, the ZX Spectrum screen can be divided in 4 parts:

* Bitmap sector 0: upper 1/3 screen (2048 bytes located from 16384 to 18431)
* Bitmap sector 1: middle 1/3 screen (2048 bytes located from 18432 to 20479)
* Bitmap sector 2: lower 1/3 screen (2048 bytes located from 20480 to 22527)
* Attribute area (768 bytes located from 22528 to 23295)

**RCS** reorders bytes within each bitmap sector, without affecting attributes. If
you apply **RCS** encoding before compression, the obtained compression ratio should
be at least 10% better than usual.


## Usage

To apply **RCS** encoding to a file, use the command-line utility as follows:

```
rcs Cobra.scr
```

This will generate a **RCS** encoded file called "Cobra.scr.rcs", that you must now
compress using your favorite compressor (such as [ZX0](https://github.com/einar-saukas/ZX0),
[ZX1](https://github.com/einar-saukas/ZX1), 
or [ZX7](https://spectrumcomputing.co.uk/entry/27996/ZX-Spectrum/ZX7)).

Afterwards, you have the following choices to restore the original screen from
the compressed data:

* First decompress it to a temporary buffer, then use a "buffered **RCS** decoder"
  to decode it to the screen. In this case, there are 2 variants of this routine
  that you can choose: "compact" (that's very small) or "rapid" (about 2.5 times
  faster). However this option requires a 6912 bytes buffer to decompress a full 
  screen, therefore this is a good choice only if your program is already using a 
  large buffer area (such as shadow screen) anyway.

* First decompress it directly to the screen, then use "on-screen **RCS** decoder"
  to decode it. However this option will display some "garbage" on screen for
  a fraction of a second (unless you compress bitmaps and attributes separately,
  so you can hide the screen using the same INK/PAPER, decompress bitmaps only,
  decode it, then finally decompress attributes).

* Decompress and decode at the same time, directly to the screen, using a "Smart" 
  integrated decompressor (either **RCS+ZX0**, **RCS+ZX1**, or **RCS+ZX7**). When
  decompressing anything to the screen area, the "Smart" version assumes the
  compressed data was also **RCS** encoded, so it automatically decodes it. When
  decompressing to anywhere else, it assumes the compressed data is not **RCS**
  encoded, thus it works exactly like regular **ZX0**, **ZX1** or **ZX7**
  decompressors. However this option only works for currently supported compressors
  (**ZX0**, **ZX1**, and **ZX7**), and the "Smart" version is about 3 times slower
  than standard **ZX0**, **ZX1**, or **ZX7** decompressors.

* Decompress and decode at the same time, directly to the screen, using the "Agile"
  integrated decompressor (either **RCS+ZX0**, **RCS+ZX1**, or **RCS+ZX7**). It
  works exactly the same as "Smart" version, except it runs much faster (about the
  same speed as regular "Turbo" decompressor) when decompressing data outside the
  screen (without **RCS**). However the "Agile" decompressor version is larger than
  "Smart".


## Partial Screens

Since **RCS** format reorders bitmap sectors separately, it can also be used before
compressing only 1/3 or 2/3 of a ZX Spectrum screen.

Notice however that bitmaps and attributes are stored in separate memory areas
for each part of the screen:

* Upper 1/3 screen: bitmaps from 16384 to 18431, attributes from 22528 to 22783
* Middle 1/3 screen: bitmaps from 18432 to 20479, attributes from 22784 to 23039
* Lower 1/3 screen: bitmaps from 20480 to 22527, attributes from 23040 to 23295

Because of this, storing a partial screen requires either compressing bitmaps
and attributes as two distinct blocks, or using a contiguous temporary area to
copy both.

**RCS** provides exactly the same choices:

* Distinct blocks: First save the bitmap contents from 1/3 or 2/3 screen (2048
  or 4096 bytes) as binary file, encode it with **RCS** and compress it. Then save
  another binary file with the corresponding attributes (256 or 512 bytes) and
  compress it separately. Later, decompress each block separately to the screen
  (either using a regular decompressor and running the "on-screen **RCS** decoder"
  afterwards, or using an integrated **RCS+ZX0**, **RCS+ZX1**, or **RCS+ZX7** 
  decompressor).

* Temporary area: Copy the bitmap and attribute contents from 1/3 or 2/3 screen
  to a temporary area (2048+256=2304 or 4096+512=4608 bytes), save it as binary
  file, encode it with **RCS** and compress it. Later, decompress it to a temporary
  area, then use a "buffered **RCS** decoder" to copy bitmaps and attributes to the
  screen. In this case, the existing "buffered **RCS** decoder" will need trivial
  changes since it currently supports full-screen images (contact me if you need
  assistance on this).


## Tech Stuff

The following program helps visualize the regular ZX Spectrum screen ordering:

```
    10 CLS
    20 FOR F=0 TO 6143
    30 POKE 16384+F,255
    40 NEXT F
```

The **RCS** format reorganizes this data as follows:

```
    10 CLS
    20 FOR S=0 TO 2
    30 FOR C=0 TO 31
    40 FOR R=0 TO 7
    50 FOR L=0 TO 7
    60 POKE 16384+S*2048+L*256+R*32+C,255
    70 NEXT L
    80 NEXT R
    90 NEXT C
   100 NEXT S
```


## License

This utility can be used freely within your own ZX Spectrum programs, even for
commercial releases. The only condition is that you indicate somehow in your
documentation that you have used **RCS**.


## Credits

**RCS** was created by **Einar Saukas**.

Many thanks to **joefish** for suggesting to implement the "on screen" decoder,
  **Antonio Villena** for additional suggestions to improve it, and 
  **Arkannoyed** for providing the compact version of the "buffered" RCS decoder.
