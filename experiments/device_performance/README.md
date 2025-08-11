# 多设备GEMM GEMV性能测试
1. 设备
    1. AMD 5700G
    2. Intel Core Ultra 5

2. 框架
使用CLBLAST作为算子库测试FP32下的GEMM和GEMV性能

3. 算子
    * 由于CLBLAST的CPU不支持FP16，所以建议用FP32进行对比
    1. GEMM: 包含多种形状，如(4096, 4096)@(4096, 4096)，以及多种数据类型（）
    2. GEMV: 包含多种形状，如(1, 4096)@(4096, 4096)，以及多种数据类型（由于CLBLAST的CPU不支持FP16，所以建议用FP32进行对比）

4. 数据
    result文件夹中的json文件，其中m, n, k为算子的形状参数，GFLOPS为当前精度下的性能