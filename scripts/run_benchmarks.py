import subprocess
import re
import json
import os
import sys

ERL_PATH = r"C:\Users\hkarimkonda\erlang\bin\erl.exe"
PROJECT2_EBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "project2", "ebin"))
BONUS_EBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "project2-bonus", "ebin"))

def run_project2(num_nodes, topology, algorithm, timeout=90):
    cmd = [
        ERL_PATH, "-noshell",
        "-pa", PROJECT2_EBIN,
        "-s", "project2", "main",
        str(num_nodes), topology, algorithm
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        output = proc.stdout + proc.stderr
        match = re.search(r"Convergence time:\s*(\d+)\s*microseconds", output)
        if match:
            us = int(match.group(1))
            return {"nodes": num_nodes, "status": "ok", "us": us, "ms": us / 1000.0}
        else:
            print(f"Failed to match for {num_nodes} {topology} {algorithm}: {output[:200]}")
            return {"nodes": num_nodes, "status": "error", "output": output}
    except subprocess.TimeoutExpired:
        print(f"Timeout for {num_nodes} {topology} {algorithm}")
        return {"nodes": num_nodes, "status": "timeout"}

def run_bonus(num_nodes, topology, algorithm, fail_type, fail_rate, timeout=60):
    cmd = [
        ERL_PATH, "-noshell",
        "-pa", BONUS_EBIN,
        "-s", "project2_bonus", "main",
        str(num_nodes), topology, algorithm, fail_type, str(fail_rate)
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        output = proc.stdout + proc.stderr
        cov_match = re.search(r"Covered Nodes\s*:\s*(\d+)\s*\(([\d\.]+)%\s*of active nodes\)", output)
        time_match = re.search(r"Duration\s*:\s*(\d+)\s*microseconds", output)
        active_match = re.search(r"Active Nodes\s*:\s*(\d+)\s*/\s*(\d+)", output)
        
        cov_pct = float(cov_match.group(2)) if cov_match else 0.0
        duration_ms = (int(time_match.group(1)) / 1000.0) if time_match else 0.0
        active_nodes = int(active_match.group(1)) if active_match else num_nodes
        
        return {
            "rate": fail_rate,
            "coverage_pct": cov_pct,
            "duration_ms": duration_ms,
            "active_nodes": active_nodes
        }
    except subprocess.TimeoutExpired:
        return {"rate": fail_rate, "status": "timeout", "coverage_pct": 0.0, "duration_ms": timeout * 1000}

def main():
    bench_data = {"gossip": {}, "push_sum": {}, "bonus": {}}
    
    # 1. Gossip configurations
    gossip_suites = {
        "full": [50, 100, 250, 500, 1000, 2500, 5000, 10000],
        "imp2D": [49, 100, 225, 400, 900, 1600, 2500, 4900],
        "2D": [49, 100, 225, 400, 900, 1600, 2500],
        "line": [20, 50, 100, 150, 200, 300]
    }
    
    print("=== Running Gossip Benchmarks ===")
    for topo, node_list in gossip_suites.items():
        bench_data["gossip"][topo] = []
        for n in node_list:
            res = run_project2(n, topo, "gossip")
            print(f"Gossip | {topo:<6} | {n:<6} nodes -> {res.get('ms', 'ERR')} ms")
            if res.get("status") == "ok":
                bench_data["gossip"][topo].append({"nodes": n, "ms": res["ms"], "us": res["us"]})
    
    # 2. Push-Sum configurations
    push_sum_suites = {
        "full": [50, 100, 250, 500, 1000, 2500, 5000, 10000],
        "imp2D": [49, 100, 225, 400, 900, 1600, 2500],
        "2D": [49, 100, 225, 400, 900, 1600],
        "line": [20, 50, 100, 150, 200]
    }
    
    print("\n=== Running Push-Sum Benchmarks ===")
    for topo, node_list in push_sum_suites.items():
        bench_data["push_sum"][topo] = []
        for n in node_list:
            res = run_project2(n, topo, "push-sum")
            print(f"Push-Sum | {topo:<6} | {n:<6} nodes -> {res.get('ms', 'ERR')} ms")
            if res.get("status") == "ok":
                bench_data["push_sum"][topo].append({"nodes": n, "ms": res["ms"], "us": res["us"]})
                
    # 3. Bonus Failure Benchmarks
    print("\n=== Running Bonus Failure Benchmarks ===")
    fail_rates = [0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.40]
    bonus_topos = [("full", 1000), ("imp2D", 1024), ("2D", 1024), ("line", 100)]
    
    bench_data["bonus"]["node_crash"] = {}
    for topo, n in bonus_topos:
        bench_data["bonus"]["node_crash"][topo] = []
        for r in fail_rates:
            res = run_bonus(n, topo, "gossip", "node_crash", r)
            print(f"Bonus Crash | {topo:<6} | rate: {r:.2f} -> Cov: {res['coverage_pct']:.1f}%, Time: {res['duration_ms']:.1f} ms")
            bench_data["bonus"]["node_crash"][topo].append(res)
            
    out_file = os.path.join(os.path.dirname(__file__), "benchmark_data.json")
    with open(out_file, "w") as f:
        json.dump(bench_data, f, indent=2)
    print(f"\nAll benchmark results successfully saved to {out_file}")

if __name__ == "__main__":
    main()
