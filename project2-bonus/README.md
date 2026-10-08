# COP5612 – Fall 2026: Project 2 (Bonus – Failure Models)

## Team Members
* **Harsha Karimikonda** (hkarimkonda@ufl.edu, UFID: 50966091)
* **Venkata Eswar Gollepalli** (ve.gollepalli@ufl.edu, UFID: 24690032)

---

## What is Working (Bonus Features)
* **Crash-Stop Node Failure Model (`node_crash`)**:
  * Configurable failure probability $P_{fail} \in [0.0, 1.0]$.
  * Nodes crash independently during startup. Crashed actors terminate execution and cease receiving/sending messages.
  * Master tracks the number of alive/dead actors and monitors surviving node coverage.
* **Lossy Connection Model (`connection_loss`)**:
  * Simulates unreliable network links with message drop probability $P_{loss} \in [0.0, 1.0]$.
  * Messages between nodes are probabilistically dropped.
* **Comparative Resilience Findings**:
  * **Full Network**: Extreme fault tolerance. 100% surviving node coverage even with 40% node failure.
  * **Imperfect 2D**: Small-world shortcuts provide alternate bypass routes around dead clusters, maintaining 96.6% coverage at 40% failure.
  * **2D Grid**: Vulnerable to perimeter and boundary blockages; breaks down near percolation threshold (~40%).
  * **Line Topology**: Extremely fragile. A single dead node partitions the graph into disconnected components, dropping coverage to 25.5% at only 5% failure.

---

## Instructions to Run Bonus

### Compilation
From the `project2-bonus` directory:
```bash
make
# Or directly with erlc:
erlc -o ebin src/*.erl
```

### Running the Bonus Simulator
```bash
# Defaults to 10% node crash:
./project2_bonus 1000 full gossip

# Specify failure rate (e.g. 20% crash):
./project2_bonus 1000 full gossip node_crash 0.2

# Test connection loss (e.g. 15% message drop):
./project2_bonus 1000 imp2D gossip connection_loss 0.15
```
