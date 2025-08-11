#!/usr/bin/env python3
# config first!!!
CPU_PLATFORM = 0
CPU_DEVICE = 0

IGPU_PLATFORM = 1
IGPU_DEVICE = 1

Mgemm = {
    "benchmarks": [
        {
            "name": "gemm", "num_steps": 20, "num_runs": 20,
            "title": "cpu normal gemm",
            "x_label": "device(m=n=k)", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 128, "n": 128, "k": 128, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 128,"n": 128,"k": 128},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemm", "num_steps": 20, "num_runs": 20,
            "title": "cpu gemm flat@thin",
            "x_label": "device(m,10000,k)", "x_keys": ["m","k"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 12, "n": 10000, "k": 12, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 24,"n": 0,"k": 24},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemm", "num_steps": 20, "num_runs": 20,
            "title": "igpu normal gemm",
            "x_label": "device(m=n=k)", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "igpu",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 128, "n": 128, "k": 128, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 128,"n": 128,"k": 128},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemm", "num_steps": 20, "num_runs": 20,
            "title": "igpu gemm flat@thin",
            "x_label": "device(m,10000,k)", "x_keys": ["m","k"],
            
            "devices": [
                {
                    "name": "igpu",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 12, "n": 10000, "k": 12, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 24,"n": 0,"k": 24},
                }
            ],
            "precisions": [32],
        },
    ]
}

CPU_IGPU_CORUN = {
    "benchmarks": [
        {
            "name": "gemm", "num_steps": 30, "num_runs": 20,
            "title": "cpu igpu normal gemm",
            "x_label": "device(m=n=k)", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 128, "n": 128, "k": 128, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 128,"n": 128,"k": 128},
                },
                {
                    "name": "iGPU",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 128, "n": 128, "k": 128, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 128,"n": 128,"k": 128},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemm", "num_steps": 30, "num_runs": 20,
            "title": "cpu igpu gemm flat@thin",
            "x_label": "device(m,10000,k) m=k", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 12, "n": 10000, "k": 12, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 36,"n": 0,"k": 36},
                },
                {
                    "name": "iGPU",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 12, "n": 10000, "k": 12, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 36,"n": 0,"k": 36},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemv", "num_steps": 30, "num_runs": 200,
            "title": "cpu igpu normal gemv",
            "x_label": "device(m=n,1)", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 256, "n": 256, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 256,"n": 256},
                },
                {
                    "name": "iGPU",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 256, "n": 256, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 256,"n": 256},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemv", "num_steps": 30, "num_runs": 200,
            "title": "cpu igpu gemv flat matrix",
            "x_label": "device(m,10000,1)", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 12, "n": 10000, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 36,"n": 0},
                },
                {
                    "name": "iGPU",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 12, "n": 10000, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 36,"n": 0},
                }
            ],
            "precisions": [32],
        },
        {
            "name": "gemv", "num_steps": 20, "num_runs": 200,
            "title": "cpu igpu normal gemv 1024step",
            "x_label": "device(m=n,1)", "x_keys": ["m"],
            
            "devices": [
                {
                    "name": "cpu",
                    "platform": CPU_PLATFORM,
                    "device": CPU_DEVICE,
                    "args": {"m": 1024, "n": 1024, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 1024,"n": 1024},
                },
                {
                    "name": "iGPU",
                    "platform": IGPU_PLATFORM,
                    "device": IGPU_DEVICE,
                    "args": {"m": 1024, "n": 1024, "layout": 102,
                            "transA": 111, "transB": 111},
                    "custom_step": {"m": 1024,"n": 1024},
                }
            ],
            "precisions": [32],
        },
    ]
}