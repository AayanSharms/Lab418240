# Breakout on an FPGA (18-240, Lab 4)

A playable Breakout game written in SystemVerilog for a Spartan-7 FPGA (Boolean board, `xc7s50csga324-1`). It drives an 800×600 display over HDMI from a 40 MHz pixel clock. Built for 18-240 (Structure and Design of Digital Systems) at Carnegie Mellon, Fall 2026.

## How it plays

- BTN2 and BTN3 move the paddle left and right. BTN1 serves the ball. BTN0 resets.
- The ball bounces off the walls, the paddle, and a grid of bricks. Each brick disappears when it's hit.
- You get 3 lives, shown on the seven-segment display. Losing all of them, or clearing every brick, pauses the game until BTN1 restarts it.

## Design

Everything is synchronous to the 40 MHz pixel clock. Each module looks at the current pixel's `row` and `col` and decides whether to draw itself there, and the top level ORs their colors together.

| Module | What it does |
|---|---|
| `VGA` | Generates HS, VS, and blank, plus the visible `row` and `col` counters for 800×600 |
| `GameClock` | Produces one game tick per frame so all motion updates together |
| `Synchronizer` | Two flip-flop synchronizer for the async button inputs |
| `Paddle` | Paddle position, movement, and wall limits |
| `Ball` | Ball position and direction, serving, collision response, and lives |
| `Brick` / `Bricks` | Parameterized brick (position and size) and the full grid with hit tracking |
| `Wall` | Border walls and their collision signals |
| `Score` / `BCDtoSevenSegment` | Lives left on the seven-segment display |
| `Intermission` | Detects a win or loss and handles the restart |
| `ChipInterface` | Top level that wires the board pins, clock wizard, HDMI IP, and game modules together |

The library of smaller building blocks from earlier tasks (`RangeCheck`, `OffsetCheck`, `Comparator`, `Multiplexer`, `Register`, `Counter`, and others) is in `sv_files/lab4library.sv`.

## Testbenches

All in `sv_files/`, simulated with Synopsys VCS:

- **`VGA_test`** steps through every clock of a full frame and checks HS, VS, blank, `row`, and `col` against the expected values at each one. It reports any mismatch.
- **`Ball_Test`** covers the serve, movement, bounces, losing a life, game over, and restarting.
- **`Paddle_Test`** covers left and right movement, both buttons or neither held, and stopping at the walls.
- **`Brick_Test`**, **`Wall_Test`**, **`RangeCheck_Test`**, and **`OffsetCheck_test`** cover hit detection and the range-check building blocks.

## Layout

```
sv_files/               SystemVerilog sources and testbenches
breakout/lab4.sv        Top level used by the Vivado project
breakout/Boolean240.xdc Pin constraints for the Boolean board
breakout/hdmi_tx_1.0/   Course-provided HDMI transmitter IP
breakout/lab4/lab4.xpr  Vivado project file
```
