* cpu_avx2_test.cpp：测试单精度浮点运算性能
```
#编译
clang -O3 -march=native -mavx2 -fopenmp -o cpu_avx2_test cpu_avx2_test.cpp
```

