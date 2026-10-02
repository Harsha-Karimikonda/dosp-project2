# COP5612 – Fall 2026: Project 2 (Gossip Simulator)

## Team Members
* **Harsha Karimikonda** (harshakarimikonda@ufl.edu)

---

## What is Working
* **Exclusively Actor-based Erlang Implementation**: Every node is an isolated Erlang actor process with its own state. Nodes communicate strictly via asynchronous message passing (`!`).
* **All Topologies Supported**:
  1. `full`: Every actor connects to all other actors. Implemented with constant-time $O(1)$ sampling and persistent lookup to handle tens of thousands of actors without memory bloat.
  2. `2D`: $K \times K$ non-toroidal grid where each node connects to up to 4 orthogonal grid neighbors. Automatically rounds up `numNodes` to the next perfect square.
  3. `line`: Linear arrangement where each interior node connects to exactly 2 neighbors (left and right), and boundary nodes connect to 1 neighbor.
  4. `imp2D`: Imperfect 2D grid where each node connects to its 2D grid neighbors plus 1 random long-range shortcut chosen uniformly from all other actors.
* **Both Algorithms Supported**:
  1. `gossip`: Information propagation where a rumor is disseminated. Each node tracks receipt count, transmits periodically to random neighbors, and halts transmission after hearing the rumor 10 times. Master tracks full network coverage and convergence.
  2. `push-sum`: Sum computation where each node maintains $(s, w)$, initially $s = i, w = 1$. Nodes exchange half of $(s, w)$ upon receipt. Each node monitors the ratio $s/w$. When the ratio changes by less than $10^{-10}$ across 3 consecutive rounds, the node terminates. Converged nodes continue forwarding message halves to ensure exact conservation of mass in the network.
* **Accurate Monotonic Timing**: Running time is measured using `erlang:monotonic_time(microsecond)`.
* **Cross-Platform Execution**:
  * Linux/macOS: `./project2 numNodes topology algorithm`
  * Windows: `project2.bat numNodes topology algorithm`
  * Direct Erlang invocation: `erl -noshell -pa ebin -s project2 main numNodes topology algorithm`

---

## Largest Network Handled

| Topology | Algorithm | Largest Network Handled | Convergence Time | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Full Network (`full`)** | Gossip | **10,000 nodes** | 209.31 ms | 100% Converged |
| **Full Network (`full`)** | Push-Sum | **10,000 nodes** | 1,833.68 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Gossip | **4,900 nodes** | 219.75 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Push-Sum | **2,500 nodes** | 936.24 ms | 100% Converged |
| **2D Grid (`2D`)** | Gossip | **2,500 nodes** | 911.26 ms | 100% Converged |
| **2D Grid (`2D`)** | Push-Sum | **1,600 nodes** | 25,409.13 ms | 100% Converged |
| **Line (`line`)** | Gossip | **300 nodes** | 4,754.12 ms | 100% Converged |
| **Line (`line`)** | Push-Sum | **200 nodes** | 23,600.85 ms | 100% Converged |

---

## Instructions to Run

### Compilation
From the `project2` directory:
```bash
make
# Or directly with erlc:
erlc -o ebin src/*.erl
```

### Running on Linux / macOS
```bash
./project2 1000 full gossip
./project2 1000 imp2D push-sum
```

### Running on Windows
```cmd
project2.bat 1000 full gossip
project2.bat 1000 imp2D push-sum
```
