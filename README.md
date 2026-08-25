# GF(2^256) Recursive Karatsuba Multiplier (SystemVerilog)

A SystemVerilog implementation of multiplication in the binary finite field
GF(2^256), built recursively out of GF(2) bit multipliers using a
Karatsuba-style decomposition, followed by modular reduction against the
field polynomial:

```
x^256 + x^10 + x^5 + x^2 + 1
```

## How it works

| Module | Purpose |
|---|---|
| `gf2raw.sv` | Base case: raw (unreduced) GF(2) multiply of two 2-bit operands. |
| `gf256raw.sv` (`module gfraw`) | Recursive Karatsuba-style carry-less multiplier. Splits each `WIDTH`-bit operand into high/low halves and recurses down to `gf2raw` at `WIDTH == 2`. |
| `gf256red.sv` | Reduces the 511-bit raw product modulo `x^256 + x^10 + x^5 + x^2 + 1`, producing the final 256-bit field element. |
| `top.sv` | Top-level: wires `gfraw` (raw multiply) into `gf256red` (reduction) to compute `out = ina * inb` in GF(2^256). |

```
ina, inb (256b) -> gfraw (511b raw product) -> gf256red (mod reduce) -> out (256b)
```

## Testbenches

Two testbenches are provided in `tb/`:

- **`tb_top_simple.sv`** — a minimal, non-self-checking testbench. Applies a
  handful of input vectors (zero, identity, small powers of x, arbitrary
  values, a random pair) and just prints `out` with `$display` so you can
  eyeball the results.
- **`tb_top.sv`** — a self-checking testbench. It re-implements GF(2^256)
  multiplication independently (a plain O(n^2) shift-and-XOR carry-less
  multiply, followed by the same modular reduction) as a reference model,
  then runs directed corner cases plus 300 randomized vectors against it,
  reporting pass/fail.

### Running with Icarus Verilog

```bash
# simple testbench
iverilog -g2012 -o sim.out rtl/gf2raw.sv rtl/gf256raw.sv rtl/gf256red.sv rtl/top.sv tb/tb_top_simple.sv
vvp sim.out

# self-checking testbench
iverilog -g2012 -o sim.out rtl/gf2raw.sv rtl/gf256raw.sv rtl/gf256red.sv rtl/top.sv tb/tb_top.sv
vvp sim.out
```

Any SystemVerilog-2012-capable simulator (Questa, VCS, Xcelium, Verilator)
should also work.

## Future Work: Iterative FSM-Based Architecture

The current `gf256raw.sv` / `top.sv` implement a **fully instantiated,
hierarchical** Karatsuba multiplier — every recursion level physically
instantiates three lower-level multipliers, all operating in parallel. This
gives minimal latency (a single combinational pass) at the cost of a large
number of sub-modules switching simultaneously.

Per RajaRaja et al., *"A Power-Efficient 256-bit Overlap-Free Karatsuba
Multiplier Architecture for ECC on FPGA Platforms,"* IETE Journal of
Research (2026), an **iterative, FSM-controlled, resource-shared**
architecture is significantly more power-efficient for exactly this kind of
256-bit GF(2^m) Karatsuba multiplier:

- Instead of instantiating three separate 2×2 Karatsuba sub-multipliers per
  recursion level, a **single** sub-multiplier is time-multiplexed across
  clock cycles under FSM control to compute the three partial products
  `P0 = A_L·B_L`, `P1 = A_H·B_H`, `P2 = (A_L⊕A_H)·(B_L⊕B_H)` sequentially.
- Only one sub-module is active per cycle instead of all of them switching
  at once, which is what drives the reported power savings.
- The FSM moves through `IDLE → DECOMPOSE → COMPUTE → RECONSTRUCT → DONE`,
  with `COMPUTE` iterating across the partial products at each recursion
  level.
- Reported post-synthesis results on Xilinx Virtex-7 (xc7vx690tffg1761-2)
  show the iterative architecture cutting estimated dynamic power by
  ~89.5% (590.37 W → 62.00 W) and total on-chip power by ~88.9% (599.658 W
  → 66.325 W) relative to the fully instantiated design, at the cost of a
  ~90% increase in LUT usage and roughly 24 clock cycles of latency instead
  of one combinational pass.

**Plan:** rework this multiplier from the current fully instantiated form
into the iterative FSM-based form described above, reusing a single 2-bit
Karatsuba unit across cycles instead of instantiating the full recursion
tree in parallel. This is tracked as the next step for this repo.


