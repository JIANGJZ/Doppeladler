#include <immintrin.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

// 定义测试矩阵的维度
int M_DIM = 1024;
int N_DIM = 1024;
int K_DIM = 1024;

// 定义测试矩阵的数据类型
typedef float matrix_t;

// 矩阵乘法 GEMM
void matmul_avx2(const matrix_t *A, const matrix_t *B, matrix_t *C, int m,
                 int n, int k) {
#pragma omp parallel for
  for (int i = 0; i < m; ++i) {
    for (int j = 0; j < n; ++j) {
      __m256 sum = _mm256_setzero_ps();
      for (int l = 0; l < k; l += 8) { // 使用 float，每次加载 8 个元素
        __m256 a = _mm256_loadu_ps(&A[i * k + l]);
        __m256 b = _mm256_loadu_ps(&B[l * n + j]);
        sum = _mm256_fmadd_ps(a, b, sum); // 使用 FMA 指令
      }
      C[i * n + j] = ((matrix_t *)&sum)[0] + ((matrix_t *)&sum)[1] +
                     ((matrix_t *)&sum)[2] + ((matrix_t *)&sum)[3] +
                     ((matrix_t *)&sum)[4] + ((matrix_t *)&sum)[5] +
                     ((matrix_t *)&sum)[6] + ((matrix_t *)&sum)[7];
    }
  }
}

// 矩阵向量乘法 GEMV
void matvecmul_avx2(const matrix_t *A, const matrix_t *x, matrix_t *y, int m,
                    int n) {
#pragma omp parallel for
  for (int i = 0; i < m; ++i) {
    __m256 sum = _mm256_setzero_ps();
    for (int j = 0; j < n; j += 8) { // 使用 float，每次加载 8 个元素
      __m256 a = _mm256_loadu_ps(&A[i * n + j]);
      __m256 b = _mm256_loadu_ps(&x[j]);
      sum = _mm256_fmadd_ps(a, b, sum); // 使用 FMA 指令
    }
    y[i] = ((matrix_t *)&sum)[0] + ((matrix_t *)&sum)[1] +
           ((matrix_t *)&sum)[2] + ((matrix_t *)&sum)[3] +
           ((matrix_t *)&sum)[4] + ((matrix_t *)&sum)[5] +
           ((matrix_t *)&sum)[6] + ((matrix_t *)&sum)[7];
  }
}
int main(int argc, char *argv[]) {
  // 解析命令行参数
  if (argc >= 4) {
    M_DIM = atoi(argv[1]);
    N_DIM = atoi(argv[2]);
    K_DIM = atoi(argv[3]);
  }

  int num_threads = 1;
  if (argc >= 5) {
    num_threads = atoi(argv[4]);
  }

  // 设置线程数量
  omp_set_num_threads(num_threads);

  // 分配内存并初始化测试矩阵 A, B, C
  matrix_t *A = (matrix_t *)malloc(M_DIM * K_DIM * sizeof(matrix_t));
  matrix_t *B = (matrix_t *)malloc(K_DIM * N_DIM * sizeof(matrix_t));
  matrix_t *C = (matrix_t *)malloc(M_DIM * N_DIM * sizeof(matrix_t));
  matrix_t *x = (matrix_t *)malloc(N_DIM * sizeof(matrix_t));
  matrix_t *y = (matrix_t *)malloc(M_DIM * sizeof(matrix_t));

  // 初始化矩阵 A, B，向量 x，这里简单起见，你可以根据需求更改初始化方法
  for (int i = 0; i < M_DIM * K_DIM; ++i)
    A[i] = rand() % 10;

  for (int i = 0; i < K_DIM * N_DIM; ++i)
    B[i] = rand() % 10;

  for (int i = 0; i < N_DIM; ++i)
    x[i] = rand() % 10;

  // 计算 GEMM 运算
  double gemm_total_time = 0.0;
  int num_iterations = argc >= 6 ? atoi(argv[5]) : 5;
  double gemm_start = omp_get_wtime();
  for (int iter = 0; iter < num_iterations; ++iter) {
    matmul_avx2(A, B, C, M_DIM, N_DIM, K_DIM);
  }
  double gemm_end = omp_get_wtime();
  gemm_total_time += (gemm_end - gemm_start);

  // 计算 GEMV 运算
  double gemv_total_time = 0.0;
  double gemv_start = omp_get_wtime();
  for (int iter = 0; iter < num_iterations; ++iter) {
    matvecmul_avx2(A, x, y, M_DIM, N_DIM);
  }
  double gemv_end = omp_get_wtime();
  gemv_total_time += (gemv_end - gemv_start);

  // 计算 GFLOPS
  double gemm_gflops = (double)num_iterations * (2.0 * M_DIM * N_DIM * K_DIM) /
                       gemm_total_time / 1e9;
  double gemv_gflops =
      (double)num_iterations * (2.0 * M_DIM * N_DIM) / gemv_total_time / 1e9;

  // 内存带宽计算假设每个矩阵和向量都被访问两次 (read + write)
  double gemm_memory_bandwidth =
      (double)num_iterations *
      (3.0 * M_DIM * N_DIM * K_DIM * sizeof(matrix_t)) / gemm_total_time;
  double gemv_memory_bandwidth =
      (double)num_iterations *
      (2.0 * M_DIM * N_DIM * sizeof(matrix_t) + N_DIM * sizeof(matrix_t)) /
      gemv_total_time;

  // 输出结果
  printf("Average GEMM Time: %lf seconds\n", gemm_total_time / num_iterations);
  printf("Average GEMV Time: %lf seconds\n", gemv_total_time / num_iterations);
  printf("\nGFLOPS (GEMM): %lf\n", gemm_gflops);
  printf("GFLOPS (GEMV): %lf\n", gemv_gflops);
  printf("Average GEMM Memory Bandwidth: %lf GB/s\n",
         gemm_memory_bandwidth / 1e9);
  printf("Average GEMV Memory Bandwidth: %lf GB/s\n",
         gemv_memory_bandwidth / 1e9);

  // 释放内存
  free(A);
  free(B);
  free(C);
  free(x);
  free(y);

  return 0;
}
