# ComboLLM Evaluation (Doppeladler AE)

This repository contains the artifact to reproduce the key results of **Doppeladler: Adaptive Tensor Parallelism for Latency‑Critical LLM Deployment on CPU‑GPU Integrated End‑User Device** (PACT 2025). It provides:
- A fork of `llama.cpp` with integrated-CPU/GPU co-execution and **OpenCL (CLBlast)** support.
- The **Doppeladler runtime**: heuristic-based intra-operator tensor parallelism, contention mitigation, and zero‑copy with alternate access.
- Benchmarks, experiment scripts, and collected results to reproduce Figures in Section 4 of the paper.

> Target platforms: integrated CPU–GPU devices (e.g., AMD 5700G Vega8 iGPU, Intel Core Ultra5 Arc iGPU).  
> Primary metric: **latency per token** (ms/token).

---

## Repository Layout

```
ComboLLM-evaluation/
├── CMakeLists.txt, Makefile       # build system (CMake or GNU Make)
├── ggml-*.{c,h}, ggml-opencl.*    # ggml core and OpenCL backend
├── llama.*                        # llama.cpp front-end
├── experiments/                   # scripts and data for Section 4
│   ├── device_performance/        # GEMM/GEMV microbenchmarks (AMD/Intel)
│   ├── benchmark_llama7B/         # quick llama-bench recipes
│   └── eval/                      # end-to-end eval and CSV collection
├── scripts/                       # helpers (convert, quantize, download, etc.)
└── tools/, examples/, tests/      # additional utilities
```

---

## Requirements

### OS
- Ubuntu 22.04 LTS (tested) or similar Linux distribution

### Build Toolchain
- CMake ≥ 3.18 and a C++17 compiler (GCC ≥ 9 / Clang ≥ 10), or GNU Make
- OpenCL headers & ICD loader
- **CLBlast** (OpenCL BLAS) development package

Example (Ubuntu/Debian):
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake git pkg-config     ocl-icd-opencl-dev clinfo libclblast-dev
```

### Python (optional, for plotting/eval helpers)
```
pip install -r requirements.txt
```
Contents:
```
numpy==1.24.4
sentencepiece==0.1.98
gguf>=0.1.0
```

### Models
- We use **GGUF** models compatible with `llama.cpp`.  
- Dummy weights can be used for functional runs; for full reproduction, use GGUF weights for LLaMA2‑7B or Baichuan2‑7B in Q4/Q8/FP16.
- Convert via `scripts/convert-gg.sh` or official `llama.cpp` conversion tools if needed.

---

## Build

You can build via **CMake** (recommended) or **GNU Make**.

### CMake (Release, with OpenCL/CLBlast)
```bash
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DLLAMA_CLBLAST=ON ..
cmake --build . -j
# binaries in build/bin/, e.g., build/bin/llama-bench
```

### GNU Make (with OpenCL/CLBlast)
```bash
make LLAMA_CLBLAST=1 -j
# binaries in project root (e.g., ./llama-bench, ./main, ./server, ...)
```

> **Device selection**: choose the OpenCL device via environment variable, e.g.  
> `export GGML_OPENCL_DEVICE="'Intel(R) Arc(TM) Graphics'"`  
> Run `clinfo` to list available platforms/devices.

---

## Quick Start

Sanity run (quantized LLaMA 2 7B, example):
```bash
# Using CMake build
./build/bin/llama-bench -m /path/to/llama-2-7b.Q4_K_M.gguf -p 512 -n 128 -ngl 99 -t 1
# or use the recipe
bash experiments/benchmark_llama7B/benchmark.sh
```

Main end-to-end evaluator (collects CSV under `experiments/eval/...`):
```bash
export GGML_OPENCL_DEVICE="'Intel(R) Arc(TM) Graphics'"
python experiments/eval/eval.py     --models-dir /path/to/gguf     --out-dir experiments/eval/core_ultra5
```

Micro-benchmarks (GEMM/GEMV):
```bash
python experiments/device_performance/AMD_5700G/mbenchmark.py
python experiments/device_performance/INTEL_CoreUltra5/mbenchmark.py
```

---

## Reproducing Paper Figures (Section 4)

- **Figure 8 (Latency across seq lengths, precisions, models)**  
  Use `experiments/eval/eval.py` to generate CSVs for each (model, precision, seq length) and plot with your preferred tool.
- **Figure 9 (Decoding, KVCache)**  
  Run decoding profiles with starting sequence length 64, 32 iterations; see `eval.py` model arg presets.
- **Figure 10–11 (Heuristic decomposition & contention mitigation)**  
  Enabled by default in Doppeladler runtime; logs are captured alongside CSVs. Trigger contention by co-running CPU/iGPU loads (see Section 3.3).
- **Figure 12 (Zero-copy vs standard copy)**  
  Compare runs with and without zero-copy region swap. Use models in `experiments/eval/*/no_zero_copy_*` as references.

> Exact model/precision/sequence sets are pre-populated inside `experiments/eval/*` and `experiments/benchmark_llama7B/benchmark.sh`.

---

## Troubleshooting

- **OpenCL device not found**: check `clinfo`, install proper vendor runtime (Intel/AMD), set `GGML_OPENCL_DEVICE` exactly to the device name.
- **Linking CLBlast fails**: ensure `libclblast-dev` is installed; check `pkg-config --libs clblast OpenCL` output.
- **Performance below expectations**: verify Release build, CPU frequency governor, and background processes. For laptops, ensure adequate cooling (TDP throttling impacts iGPU).
- **Permission errors on models**: verify path and file permissions; GGUF is required.

---

## License and Citation

- Code license: see repository/license headers (derivative of `llama.cpp` and ggml components).  
- If you use this artifact, please cite the PACT 2025 paper.
