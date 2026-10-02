# COP5612 (Fall 2026) – Project 2: Gossip & Push-Sum Simulator

**Author / Group Member:** Harsha Karimikonda (harshakarimikonda@ufl.edu)  
**Instructor:** Prof. Alin Dobra  

---

## Deliverables Summary

* `project2/`: Core implementation containing:
  * `src/`: Erlang source code (`project2.erl`, `worker.erl`, `topology.erl`).
  * `ebin/`: Compiled `.beam` actor binaries.
  * `project2`: Executable Unix shell script.
  * `project2.bat`: Executable Windows batch script.
  * `Makefile`: Erlang build configuration.
  * `README.md`: Project-specific requirements, largest network sizes table, and instructions.
* `project2-bonus/`: 30% Bonus implementation containing:
  * `src/`: Bonus Erlang source code (`project2_bonus.erl`, `worker_bonus.erl`, `topology.erl`).
  * `ebin/`: Compiled bonus `.beam` binaries.
  * `project2_bonus`: Unix executable script.
  * `project2_bonus.bat`: Windows executable script.
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
  * `project2.zip` and `project2.tgz`
  * `project2-bonus.zip` and `project2-bonus.tgz`

---

## Largest Network Sizes Handled

| Topology | Algorithm | Max Network Size | Convergence Time | Convergence Status |
| :--- | :--- | :--- | :--- | :--- |
| **Full (`full`)** | Gossip | **10,000 nodes** | 209.31 ms | 100% Converged |
| **Full (`full`)** | Push-Sum | **10,000 nodes** | 1,833.68 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Gossip | **4,900 nodes** | 219.75 ms | 100% Converged |
| **Imperfect 2D (`imp2D`)** | Push-Sum | **2,500 nodes** | 936.24 ms | 100% Converged |
| **2D Grid (`2D`)** | Gossip | **2,500 nodes** | 911.26 ms | 100% Converged |
| **2D Grid (`2D`)** | Push-Sum | **1,600 nodes** | 25,409.13 ms | 100% Converged |
| **Line (`line`)** | Gossip | **300 nodes** | 4,754.12 ms | 100% Converged |
| **Line (`line`)** | Push-Sum | **200 nodes** | 23,600.85 ms | 100% Converged |

---

## Quick Start

### 1. Core Project (`project2`)
```bash
cd project2
make

# Run Gossip:
./project2 1000 full gossip
# Or on Windows:
project2.bat 1000 full gossip

# Run Push-Sum:
./project2 1000 imp2D push-sum
# Or on Windows:
project2.bat 1000 imp2D push-sum
```

### 2. Bonus Project (`project2-bonus`)
```bash
cd project2-bonus
make

# Run with 20% node crash failure:
./project2_bonus 1000 full gossip node_crash 0.2
# Or on Windows:
project2_bonus.bat 1000 full gossip node_crash 0.2
```
