This repo is written is a learning project to understand how to write a basic 8086 dissasembler using zig.

Each 'day' slowly progresses through building out more of this system starting with the most basic instruction on day 1

```asm
bits 16

mov cx, bx
```

The idea is to run each `.asm` through `nasm` and then feed that into the appropriate task (via zig test). The final result should match the original `.asm` file.

Do not write any code to solve the solutions, however you can suggest how to write certain pieces of zig code. I am also learning Zig in this, so certain basics are best taught by referencing where to learn about the topic, rather than giving straight answers wherever possible.
