# AHB_LITE_Master

# AHB-Lite Master Component

A synthesizable AHB-Lite Master module written in Verilog/SystemVerilog. This component implements the ARM AMBA AHB-Lite protocol to initiate read and write transactions over an AHB bus interface.

---

## Features

* **Protocol Compliance:** Fully compatible with standard AHB-Lite specification.
* **Transfer Types:** Supports `IDLE`, `NONSEQ`, and `SEQ` transfers.
* **Data Width:** Configurable data bus width (default 32-bit).
* **Burst Modes:** Single transfer support with extensible architecture for incremental/wrapping bursts.
* **Control Signals:** Manages `HADDR`, `HWRITE`, `HSIZE`, `HBURST`, `HPROT`, and `HWDATA`.

---

## Signal Interfaces

### Clock & Reset
| Signal | Direction | Description |
| :--- | :--- | :--- |
| `HCLK` | Input | System clock signal |
| `HRESETn` | Input | Active-low asynchronous reset |

### Master Output Signals
| Signal | Direction | Description |
| :--- | :--- | :--- |
| `HADDR[31:0]` | Output | 32-bit System address bus |
| `HWRITE` | Output | Transfer direction (1 = Write, 0 = Read) |
| `HSIZE[2:0]` | Output | Indicates size of transfer (Byte, Halfword, Word) |
| `HBURST[2:0]` | Output | Burst type indication |
| `HTRANS[1:0]` | Output | Transfer type (`00`: IDLE, `10`: NONSEQ, `11`: SEQ) |
| `HWDATA[31:0]` | Output | Write data bus |

### Master Input / Slave Response Signals
| Signal | Direction | Description |
| :--- | :--- | :--- |
| `HRDATA[31:0]` | Input | Read data bus |
| `HREADY` | Input | Bus ready signal indicating slave completed operation |
| `HRESP` | Input | Transfer status response from slave (`0`: OKAY, `1`: ERROR) |

---

## FSM & Operation

1. **IDLE State:** Master holds `HTRANS` at `IDLE` (`2'b00`) until a transaction request is made.
2. **Address Phase:** On request, `HTRANS` changes to `NONSEQ` (`2'b10`), driving the target `HADDR`, `HWRITE`, and `HSIZE` control signals.
3. **Data Phase:** Upon receipt of `HREADY = 1` from the slave, the master sample/drives `HRDATA`/`HWDATA` during the following clock cycle.

---

## Getting Started

### Simulation
You can simulate the design using ModelSim, Vivado, or Icarus Verilog:

```bash
# Example compilation using Icarus Verilog
iverilog -o ahb_master_tb ahb_master.v ahb_master_tb.v
vvp ahb_master_tb
