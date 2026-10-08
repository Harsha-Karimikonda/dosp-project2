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
  1. `gossip`: Information propagation where a rumor is disseminated. Each node tracks receipt count, transmits periodically to random neighbors, and halts active transmission after hearing the rumor 10 times. The master monitors convergence and declares completion once all $N$ nodes have received the rumor 10 times and terminated transmission.
  2. `push-sum`: Sum computation where each node maintains $(s, w)$, initially $s = i, w = 1$. Nodes exchange half of $(s, w)$ upon receipt. Each node monitors the ratio $s/w$. When the ratio changes by less than $10^{-10}$ across 3 consecutive rounds, the node terminates its local computation. Converged nodes transition to an inert routing state that forwards incoming $(s, w)$ pairs without modifying estimation state, guaranteeing exact conservation of total network mass ($\sum s, \sum w$) and preventing graph disconnection in sparse topologies.
* **Accurate Monotonic Timing**: Running time is measured using `erlang:monotonic_time(microsecond)`.
* **Execution**:
  * Command-line wrapper: `./project2 numNodes topology algorithm`
  * Direct Erlang invocation: `erl -noshell -pa ebin -s project2 main numNodes topology algorithm`

---

## Largest Network Handled

| Topology | Algorithm | Largest Network Handled | Convergence Time | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Full Network (`full`)** | Gossip | **10,000 nodes** | 70.51 ms | 100% Converged |
| **Full Network (`full`)** | Push-Sum | **10,000 nodes** | 1,072.15 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Gossip | **4,900 nodes** | 66.17 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Push-Sum | **2,500 nodes** | 606.31 ms | 100% Converged |
| **2D Grid (`2D`)** | Gossip | **2,500 nodes** | 84.10 ms | 100% Converged |
| **2D Grid (`2D`)** | Push-Sum | **1,600 nodes** | 11,598.95 ms | 100% Converged |
| **Line (`line`)** | Gossip | **300 nodes** | 763.26 ms | 100% Converged |
| **Line (`line`)** | Push-Sum | **200 nodes** | 1,190.15 ms | 100% Converged |

---

## Instructions to Run

### Compilation
From the `project2` directory:
```bash
make
# Or directly with erlc:
erlc -o ebin src/*.erl
```

### Running the Simulator
```bash
./project2 1000 full gossip
./project2 1000 imp2D push-sum
```
