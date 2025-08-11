* CPU: AMD 6800H
* DRAM: DDR5 4800

1. cpu test

| model                          |       size |     params | backend    |    threads | test       |              t/s |
| ------------------------------ | ---------: | ---------: | ---------- | ---------: | ---------- | ---------------: |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          1 | pp 512     |      5.48 ± 0.06 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          1 | tg 128     |      4.34 ± 0.08 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          2 | pp 512     |     10.63 ± 0.08 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          2 | tg 128     |      7.71 ± 0.01 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          4 | pp 512     |     18.22 ± 0.11 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          4 | tg 128     |     10.65 ± 0.21 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          8 | pp 512     |     28.49 ± 0.05 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          8 | tg 128     |     10.85 ± 0.03 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |         12 | pp 512     |     23.08 ± 0.08 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |         12 | tg 128     |     10.16 ± 0.38 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |         16 | pp 512     |     27.51 ± 0.08 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |         16 | tg 128     |      8.83 ± 0.80 |



CPU: Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz
1. CPU test


 model                          |       size |     params | backend    |    threads | test       |              t/s |
| ------------------------------ | ---------: | ---------: | ---------- | ---------: | ---------- | ---------------: |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          1 | pp 512     |      4.41 ± 0.00 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          1 | tg 128     |      3.11 ± 0.00 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          2 | pp 512     |      8.52 ± 0.08 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          2 | tg 128     |      5.40 ± 0.07 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          4 | pp 512     |     15.38 ± 0.08 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          4 | tg 128     |      6.97 ± 0.02 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          6 | pp 512     |     19.83 ± 0.07 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          6 | tg 128     |      7.25 ± 0.02 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          8 | pp 512     |     13.38 ± 0.39 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |          8 | tg 128     |      7.39 ± 0.01 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |         12 | pp 512     |     18.86 ± 0.17 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | CPU        |         12 | tg 128     |      7.75 ± 0.02 |


| model                          |       size |     params | backend    |    threads | test       |              t/s |
| ------------------------------ | ---------: | ---------: | ---------- | ---------: | ---------- | ---------------: |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          1 | pp 512     |      3.67 ± 0.00 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          1 | tg 128     |      2.29 ± 0.00 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          2 | pp 512     |      7.13 ± 0.01 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          2 | tg 128     |      3.64 ± 0.00 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          4 | pp 512     |     12.94 ± 0.10 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          4 | tg 128     |      4.24 ± 0.00 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          6 | pp 512     |     16.66 ± 0.08 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          6 | tg 128     |      4.47 ± 0.01 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          8 | pp 512     |     11.78 ± 0.46 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |          8 | tg 128     |      4.57 ± 0.00 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |         12 | pp 512     |     17.49 ± 0.03 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | CPU        |         12 | tg 128     |      4.69 ± 0.01 |



GPU:Intel(R) UHD Graphics 630

2. GPU test


| model                          |       size |     params | backend    | ngl | test       |              t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | ---------- | ---------------: |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | OpenCL     | 1000 | pp 512     |      9.65 ± 0.02 |
| llama 7B mostly Q4_K - Medium  |   3.80 GiB |     6.74 B | OpenCL     | 1000 | tg 128     |      2.06 ± 0.00 |

| model                          |       size |     params | backend    | ngl | test       |              t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | ---------- | ---------------: |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | OpenCL     |  99 | pp 512     |      9.51 ± 0.03 |
| llama 7B mostly Q8_0           |   6.67 GiB |     6.74 B | OpenCL     |  99 | tg 128     |      1.77 ± 0.00 |