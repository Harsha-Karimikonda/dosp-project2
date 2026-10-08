# COP5612 (Fall 2026) – Project 2: Gossip & Push-Sum Simulator

**Author / Group Member:** Harsha Karimikonda (hkarimkonda@ufl.edu)  
**Instructor:** Prof. Alin Dobra  

---

## Deliverables Summary

* `project2/`: Core implementation containing:
  * `src/`: Erlang source code (`project2.erl`, `worker.erl`, `topology.erl`).
  * `ebin/`: Compiled `.beam` actor binaries.
  * `project2`: Executable Unix shell script.
  * `Makefile`: Erlang build configuration.
  * `README.md`: Project-specific requirements, largest network sizes table, and instructions.
* `project2-bonus/`: 30% Bonus implementation containing:
  * `src/`: Bonus Erlang source code (`project2_bonus.erl`, `worker_bonus.erl`, `topology.erl`).
  * `ebin/`: Compiled bonus `.beam` binaries.
  * `project2_bonus`: Unix executable script.
  * `Makefile`: Erlang build configuration.
  * `README.md`: Failure models and experiment guide.
* `Report.pdf`: Formal PDF report containing:
  * Theoretical analysis of Gossip and Push-Sum algorithms.
  * Overlapped logarithmic convergence plots across all 4 topologies.
  * Largest network handled benchmarks.
  * In-depth observations (small-world phenomenon, mass conservation, diameter limits).
* `Report-bonus.pdf`: Formal bonus report containing:
  * Formulation of Node Crash and Link Drop models.
  * Percolation threshold experiments and comparative resilience plots.
  * Architectural analysis of network partitioning in 1D vs. high-dimensional topologies.
* Submission Archives:
  * `project2.zip` (Core project code archive)
  * `project2-bonus.zip` (Bonus project code archive)

---

## What is Working

* **Exclusively Actor-based Erlang Implementation**: Every node is an isolated Erlang actor process with its own state. Nodes communicate strictly via asynchronous message passing (`!`). Zero shared memory, locks, or external state.
* **All Topologies Supported**:
  1. `full`: Every actor connects to all other $N-1$ actors. Implemented with constant-time $O(1)$ sampling and persistent lookup to handle 10,000+ actors with zero memory bloat.
  2. `2D`: $K \times K$ non-toroidal grid where each node connects to up to 4 orthogonal grid neighbors. Automatically rounds up `numNodes` to the next perfect square.
  3. `line`: Linear arrangement where each interior node connects to exactly 2 neighbors (left and right), and boundary nodes connect to 1 neighbor.
  4. `imp2D`: Imperfect 2D grid where each node connects to its 4 orthogonal grid neighbors plus 1 random long-range shortcut chosen uniformly from all other actors.
* **Both Algorithms Supported**:
  1. `gossip`: Decentralized rumor dissemination. Each node periodically transmits rumors to random neighbors and halts active transmission after hearing the rumor 10 times. The master monitors convergence and completes when all $N$ nodes have received the rumor 10 times and terminated transmission.
  2. `push-sum`: Decentralized average/sum computation where each node maintains $(s, w)$ (initially $s = i, w = 1$). Nodes exchange half of $(s, w)$ upon receipt. Each node monitors the ratio $s/w$. When the ratio changes by less than $10^{-10}$ across 3 consecutive rounds, the node terminates its local computation. Converged nodes transition to an inert routing state that forwards incoming mass pairs without modifying estimation state, guaranteeing exact global conservation of total mass ($\sum s, \sum w$) and preventing graph partitioning in sparse topologies.
* **Accurate Monotonic Timing**: Measured using the assignment-specified `measure_running_time/1` function with `erlang:monotonic_time(microsecond)`.
* **Bonus Failure Models Supported (`project2-bonus`)**:
  1. `node_crash`: Parameterized crash-stop model ($P_{fail} \in [0.0, 1.0]$) where failing actors execute real process termination (`exit(crashed)`).
  2. `connection_loss`: Parameterized lossy network link model ($P_{loss} \in [0.0, 1.0]$) where messages are dropped probabilistically in transit.
* **Execution**:
  * Command-line wrapper: `./project2 numNodes topology algorithm` and `./project2_bonus numNodes topology algorithm model rate`
  * Direct Erlang invocation: `erl -noshell -pa ebin -s project2 main numNodes topology algorithm`

---

## Largest Network Sizes Handled

| Topology | Algorithm | Max Network Size | Convergence Time | Convergence Status |
| :--- | :--- | :--- | :--- | :--- |
| **Full (`full`)** | Gossip | **10,000 nodes** | 70.51 ms | 100% Converged |
| **Full (`full`)** | Push-Sum | **10,000 nodes** | 1,072.15 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Gossip | **4,900 nodes** | 66.17 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Push-Sum | **2,500 nodes** | 606.31 ms | 100% Converged |
| **2D Grid (`2D`)** | Gossip | **2,500 nodes** | 84.10 ms | 100% Converged |
| **2D Grid (`2D`)** | Push-Sum | **1,600 nodes** | 11,598.95 ms | 100% Converged |
| **Line (`line`)** | Gossip | **300 nodes** | 763.26 ms | 100% Converged |
| **Line (`line`)** | Push-Sum | **200 nodes** | 1,190.15 ms | 100% Converged |

---

## Quick Start

### 1. Core Project (`project2`)
```bash
cd project2
make

# Run Gossip:
./project2 1000 full gossip

# Run Push-Sum:
./project2 1000 imp2D push-sum
```

### 2. Bonus Project (`project2-bonus`)
```bash
cd project2-bonus
make

# Run with 20% node crash failure:
./project2_bonus 1000 full gossip node_crash 0.2
```
