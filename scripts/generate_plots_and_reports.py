import json
import os
import matplotlib.pyplot as plt
import numpy as np

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(SCRIPT_DIR, "benchmark_data.json")
ROOT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

with open(DATA_FILE, "r") as f:
    data = json.load(f)

# Set high-DPI clean styling for matplotlib
plt.rcParams.update({
    "font.size": 11,
    "axes.labelsize": 12,
    "axes.titlesize": 14,
    "xtick.labelsize": 10,
    "ytick.labelsize": 10,
    "legend.fontsize": 11,
    "figure.titlesize": 16,
    "figure.dpi": 300
})

colors_map = {
    "full": "#00529B",      # UF Blue
    "imp2D": "#E87722",     # UF Orange
    "2D": "#2E7D32",        # Green
    "line": "#D32F2F"       # Red
}

markers_map = {
    "full": "o",
    "imp2D": "s",
    "2D": "^",
    "line": "D"
}

labels_map = {
    "full": "Full Network (Degree N-1)",
    "imp2D": "Imperfect 2D (4 Grid + 1 Random)",
    "2D": "2D Grid (Degree 2-4)",
    "line": "Line (Degree 1-2)"
}

# =========================================================================
# 1. Generate Gossip Convergence Plot
# =========================================================================
plt.figure(figsize=(8, 5))
for topo in ["full", "imp2D", "2D", "line"]:
    pts = data["gossip"][topo]
    x = [p["nodes"] for p in pts]
    y = [p["ms"] for p in pts]
    plt.plot(x, y, marker=markers_map[topo], color=colors_map[topo],
             linewidth=2.2, markersize=6, label=labels_map[topo])

plt.xscale("log")
plt.yscale("log")
plt.xlabel("Network Size (Number of Nodes, N)")
plt.ylabel("Convergence Time (milliseconds, log scale)")
plt.title("Gossip Protocol: Convergence Time vs. Network Size")
plt.grid(True, which="both", ls="--", alpha=0.5)
plt.legend(loc="upper left", frameon=True)
plt.tight_layout()
gossip_img = os.path.join(SCRIPT_DIR, "gossip_convergence.png")
plt.savefig(gossip_img, dpi=300)
plt.close()

# =========================================================================
# 2. Generate Push-Sum Convergence Plot
# =========================================================================
plt.figure(figsize=(8, 5))
for topo in ["full", "imp2D", "2D", "line"]:
    pts = data["push_sum"][topo]
    x = [p["nodes"] for p in pts]
    y = [p["ms"] for p in pts]
    plt.plot(x, y, marker=markers_map[topo], color=colors_map[topo],
             linewidth=2.2, markersize=6, label=labels_map[topo])

plt.xscale("log")
plt.yscale("log")
plt.xlabel("Network Size (Number of Nodes, N)")
plt.ylabel("Convergence Time (milliseconds, log scale)")
plt.title("Push-Sum Protocol: Convergence Time vs. Network Size")
plt.grid(True, which="both", ls="--", alpha=0.5)
plt.legend(loc="upper left", frameon=True)
plt.tight_layout()
push_sum_img = os.path.join(SCRIPT_DIR, "push_sum_convergence.png")
plt.savefig(push_sum_img, dpi=300)
plt.close()

# =========================================================================
# 3. Generate Bonus Failure Plots
# =========================================================================
plt.figure(figsize=(8, 5))
for topo in ["full", "imp2D", "2D", "line"]:
    pts = data["bonus"]["node_crash"][topo]
    x = [p["rate"] * 100 for p in pts]
    y = [p["coverage_pct"] for p in pts]
    plt.plot(x, y, marker=markers_map[topo], color=colors_map[topo],
             linewidth=2.2, markersize=6, label=labels_map[topo])

plt.xlabel("Node Failure Rate (%)")
plt.ylabel("Surviving Node Coverage (%)")
plt.title("Bonus Study: Information Coverage under Node Crashes")
plt.grid(True, ls="--", alpha=0.5)
plt.ylim(-5, 105)
plt.legend(loc="lower left", frameon=True)
plt.tight_layout()
bonus_cov_img = os.path.join(SCRIPT_DIR, "bonus_coverage_vs_failure.png")
plt.savefig(bonus_cov_img, dpi=300)
plt.close()

print("Generated plots successfully!")

# =========================================================================
# 4. Generate Report.pdf
# =========================================================================
def build_report_pdf():
    pdf_path = os.path.join(ROOT_DIR, "Report.pdf")
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        leftMargin=40, rightMargin=40,
        topMargin=40, bottomMargin=40
    )
    
    styles = getSampleStyleSheet()
    normal = styles["Normal"]
    
    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#0021A5"),
        spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        "DocSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#333333"),
        spaceAfter=12
    )
    h1_style = ParagraphStyle(
        "H1",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=14,
        leading=18,
        textColor=colors.HexColor("#0021A5"),
        spaceBefore=12,
        spaceAfter=6
    )
    body_style = ParagraphStyle(
        "Body",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor("#222222"),
        spaceAfter=6
    )
    bullet_style = ParagraphStyle(
        "Bullet",
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )
    
    story = []
    
    # Header
    story.append(Paragraph("COP5612 – Distributed Operating System Principles", subtitle_style))
    story.append(Paragraph("Project 2: Asynchronous Gossip & Push-Sum Simulator in Erlang", title_style))
    story.append(Paragraph("<b>Author / Group Member:</b> Harsha Karimikonda | <b>Instructor:</b> Prof. Alin Dobra", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#FA4616"), spaceAfter=10))
    
    # 1. Executive Summary
    story.append(Paragraph("1. Executive Summary & Problem Overview", h1_style))
    story.append(Paragraph(
        "This project implements a distributed simulator in <b>Erlang/OTP</b> based strictly on concurrent actor processes. "
        "Two prominent decentralized algorithms are simulated across four canonical network topologies: "
        "<b>Gossip Information Propagation</b> and <b>Push-Sum Aggregate Computation</b>. "
        "The actor model is leveraged to maintain pure asynchrony without shared memory or centralized locks, communicating solely through message passing (!). "
        "High-precision running times were captured using <code>erlang:monotonic_time(microsecond)</code> across sizes ranging from 20 up to 10,000 actors.",
        body_style
    ))
    
    # 2. Maximum Network Sizes
    story.append(Paragraph("2. Largest Network Sizes Handled", h1_style))
    story.append(Paragraph(
        "The following table summarizes the largest stable network size successfully simulated for each topology and algorithm combination, along with its convergence duration:",
        body_style
    ))
    
    table_data = [
        ["Topology", "Algorithm", "Largest Network Size", "Convergence Time (ms)", "Status"],
        ["Full Network", "Gossip", "10,000 nodes", "209.30 ms", "100% Converged"],
        ["Full Network", "Push-Sum", "10,000 nodes", "1,833.68 ms", "100% Converged"],
        ["Imperfect 2D Grid", "Gossip", "4,900 nodes", "219.75 ms", "100% Converged"],
        ["Imperfect 2D Grid", "Push-Sum", "2,500 nodes", "936.24 ms", "100% Converged"],
        ["2D Grid", "Gossip", "2,500 nodes", "911.26 ms", "100% Converged"],
        ["2D Grid", "Push-Sum", "1,600 nodes", "25,409.13 ms", "100% Converged"],
        ["Line", "Gossip", "300 nodes", "4,754.12 ms", "100% Converged"],
        ["Line", "Push-Sum", "200 nodes", "23,600.85 ms", "100% Converged"]
    ]
    t = Table(table_data, colWidths=[1.4*inch, 1.2*inch, 1.6*inch, 1.5*inch, 1.3*inch])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0021A5")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8.5),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#F8F9FA"), colors.white]),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    story.append(Spacer(1, 10))
    
    # 3. Experimental Findings & Charts
    story.append(Paragraph("3. Empirical Convergence Analysis", h1_style))
    story.append(Paragraph(
        "Convergence times for Gossip and Push-Sum were logged across varied orders of magnitude. "
        "Due to vast topological diameter disparities, logarithmic scales are utilized to capture the scaling behavior simultaneously.",
        body_style
    ))
    
    # Images
    story.append(Image(gossip_img, width=6.8*inch, height=3.6*inch))
    story.append(Spacer(1, 8))
    story.append(Image(push_sum_img, width=6.8*inch, height=3.6*inch))
    story.append(Spacer(1, 10))
    
    # 4. In-Depth Observations
    story.append(Paragraph("4. Key Technical Findings & Architectural Observations", h1_style))
    story.append(Paragraph(
        "<b>• The Small-World Phenomenon (2D vs. Imperfect 2D):</b> "
        "One of the most remarkable results is the staggering difference between regular 2D Grid and Imperfect 2D Grid. "
        "In regular 2D, diameter scales as <i>O(√N)</i>, causing Push-Sum convergence for 1,600 nodes to take 25.4 seconds. "
        "Adding just <b>one single random shortcut per node</b> (Imperfect 2D) collapses the effective diameter to <i>O(log N)</i>, "
        "reducing convergence time to only 505 ms—an astonishing <b>50x speedup</b>!",
        bullet_style
    ))
    story.append(Paragraph(
        "<b>• Line Topology Diameter Bottleneck:</b> "
        "In the Line network, messages must traverse <i>O(N)</i> hops sequentially. In gossip, rumor propagation encounters high collision "
        "at boundaries. In push-sum, mass diffusion behaves like 1D Brownian motion, exhibiting severe quadratic slowdown as N grows.",
        bullet_style
    ))
    story.append(Paragraph(
        "<b>• Push-Sum Mass Conservation in Asynchronous Actors:</b> "
        "In asynchronous Push-Sum, nodes that converge (ratio unchanging by < 10⁻¹⁰ over 3 rounds) must continue relaying incoming (s, w) pairs. "
        "If converged nodes drop messages, total network mass (s = N(N+1)/2, w = N) is permanently lost, causing severe calculation distortion. "
        "Our implementation preserves passive message routing, achieving exact convergence of s/w → (N+1)/2 across all nodes.",
        bullet_style
    ))
    story.append(Paragraph(
        "<b>• Full Network Scaling with Persistent Memory:</b> "
        "For full networks, naive pairwise neighbor lists require <i>O(N²)</i> heap memory (exceeding memory for 10,000 actors). "
        "By utilizing Erlang's constant-time <code>persistent_term</code> registration and algorithmic uniform sampling, "
        "10,000 actors were spawned and converged in just 209 ms for Gossip and 1.83 s for Push-Sum.",
        bullet_style
    ))
    
    doc.build(story)
    print("Report.pdf generated successfully!")

# =========================================================================
# 5. Generate Report-bonus.pdf
# =========================================================================
def build_bonus_pdf():
    pdf_path = os.path.join(ROOT_DIR, "Report-bonus.pdf")
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        leftMargin=40, rightMargin=40,
        topMargin=40, bottomMargin=40
    )
    
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#0021A5"),
        spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        "DocSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#333333"),
        spaceAfter=12
    )
    h1_style = ParagraphStyle(
        "H1",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=14,
        leading=18,
        textColor=colors.HexColor("#0021A5"),
        spaceBefore=12,
        spaceAfter=6
    )
    body_style = ParagraphStyle(
        "Body",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor("#222222"),
        spaceAfter=6
    )
    bullet_style = ParagraphStyle(
        "Bullet",
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )
    
    story = []
    
    # Header
    story.append(Paragraph("COP5612 – Distributed Operating System Principles (Fall 2026)", subtitle_style))
    story.append(Paragraph("Bonus Project Report: Node & Link Failure Resilience Models", title_style))
    story.append(Paragraph("<b>Author / Group Member:</b> Harsha Karimikonda | <b>Instructor:</b> Prof. Alin Dobra", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#FA4616"), spaceAfter=10))
    
    # 1. Introduction & Failure Models
    story.append(Paragraph("1. Failure Models & Experimental Design", h1_style))
    story.append(Paragraph(
        "In production distributed networks, nodes can experience abrupt crash-stop failures, and communication channels can experience transient packet drops. "
        "To evaluate gossip robustness under adverse conditions (30% Bonus requirement), we extended the actor engine with parameter-controlled failure models: "
        "<br/><b>1. Crash-Stop Node Failure Model:</b> Each actor independently transitions to a dead state with probability <i>P<sub>fail</sub></i> (0% to 40%). "
        "Dead nodes cease message processing and drop all received transmissions."
        "<br/><b>2. Lossy Channel Model:</b> Transient link errors drop outgoing rumor messages with probability <i>P<sub>loss</sub></i>.",
        body_style
    ))
    
    # 2. Failure Plot
    story.append(Paragraph("2. Empirical Resilience Results", h1_style))
    story.append(Paragraph(
        "We systematically tested surviving node information coverage across failure rates from 0% to 40% for Full (1000 nodes), "
        "Imperfect 2D (1024 nodes), 2D Grid (1024 nodes), and Line (100 nodes).",
        body_style
    ))
    story.append(Image(bonus_cov_img, width=6.8*inch, height=3.6*inch))
    story.append(Spacer(1, 10))
    
    # 3. Data Table
    story.append(Paragraph("3. Quantitative Failure Performance Table", h1_style))
    table_data = [
        ["Failure Rate", "Full Network", "Imperfect 2D", "2D Grid", "Line Topology"],
        ["0% (Baseline)", "100.0% Coverage (210 ms)", "100.0% Coverage (240 ms)", "100.0% Coverage (588 ms)", "100.0% Coverage (1,585 ms)"],
        ["5% Failures", "100.0% Coverage (178 ms)", "100.0% Coverage (489 ms)", "100.0% Coverage (559 ms)", "25.5% Coverage (Partitioned)"],
        ["10% Failures", "100.0% Coverage (212 ms)", "100.0% Coverage (370 ms)", "100.0% Coverage (905 ms)", "5.4% Coverage (Partitioned)"],
        ["20% Failures", "100.0% Coverage (228 ms)", "99.6% Coverage (11.2 s)", "99.1% Coverage (11.9 s)", "6.4% Coverage (Partitioned)"],
        ["30% Failures", "100.0% Coverage (258 ms)", "99.5% Coverage (11.2 s)", "99.6% Coverage (12.1 s)", "2.9% Coverage (Partitioned)"],
        ["40% Failures", "100.0% Coverage (335 ms)", "96.6% Coverage (11.5 s)", "Percolation Breakdown", "3.5% Coverage (Partitioned)"]
    ]
    t = Table(table_data, colWidths=[1.2*inch, 1.7*inch, 1.7*inch, 1.6*inch, 1.4*inch])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0021A5")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#F8F9FA"), colors.white]),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
    ]))
    story.append(t)
    story.append(Spacer(1, 10))
    
    # 4. Critical Observations
    story.append(Paragraph("4. Critical Observations & Theoretical Insights", h1_style))
    story.append(Paragraph(
        "<b>• Catastrophic Fragility of Line Topology (Single Point of Failure):</b> "
        "As seen in the empirical results, the Line topology suffers complete failure under even minute failure rates. "
        "At just 5% node failure, coverage collapses from 100% to 25.5%! In a 1D graph, any dead node acts as a bridge cut, "
        "irreversibly partitioning the network. The rumor is trapped strictly within the segment containing the initiator.",
        bullet_style
    ))
    story.append(Paragraph(
        "<b>• Percolation Threshold and Grid Boundary Degradation:</b> "
        "In 2D grid networks, percolation theory dictates that when node removal exceeds the site percolation threshold (~40.7% for square lattices), "
        "the giant connected component dissolves. Below this threshold (e.g. 10-25%), 2D grids maintain high coverage (>99%) because multi-path cycles bypass isolated dead actors. "
        "However, at 40% failure, coverage drops precipitously.",
        bullet_style
    ))
    story.append(Paragraph(
        "<b>• Imperfect 2D Small-World Redundancy:</b> "
        "Imperfect 2D grid demonstrates remarkable resilience up to 40% failures, achieving 96.6% surviving coverage. "
        "The long-range random links provide alternate bypass routes around clusters of dead grid nodes, bridging otherwise disconnected components.",
        bullet_style
    ))
    story.append(Paragraph(
        "<b>• Full Network Invulnerability:</b> "
        "In the Full topology, every node maintains <i>N - 1 - F</i> living connections. Even with 40% of nodes dead, "
        "each remaining node connects to 600 active peers, ensuring 100.0% coverage with virtually zero latency degradation (210 ms → 335 ms).",
        bullet_style
    ))
    
    doc.build(story)
    print("Report-bonus.pdf generated successfully!")

if __name__ == "__main__":
    build_report_pdf()
    build_bonus_pdf()
