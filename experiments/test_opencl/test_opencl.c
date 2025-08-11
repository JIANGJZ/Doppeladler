#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <omp.h>
#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

const char *kernelSource = 
    "__kernel void vector_add(__global const float* A, __global const float* B, __global float* C, const unsigned int N) {\n"
    "   int id = get_global_id(0);\n"
    "   if (id < N) {\n"
    "       C[id] = A[id] + B[id];\n"
    "   }\n"
    "}\n";

void vector_add_cpu(const float* A, const float* B, float* C, const unsigned int N) {
    #pragma omp parallel for
    for (unsigned int i = 0; i < N; i++) {
        C[i] = A[i] + B[i];
    }
}

int main() {
    unsigned int N = 4048576;
    size_t bytes = N * sizeof(float);

    // Allocate memory for each vector on host
    float *h_A = (float*)malloc(bytes);
    float *h_B = (float*)malloc(bytes);
    float *h_C = (float*)malloc(bytes);
    float *h_C_CPU = (float*)malloc(bytes);

    // Initialize vectors on host
    for(int i = 0; i < N; i++) {
        h_A[i] = sinf(i) * sinf(i);
        h_B[i] = cosf(i) * cosf(i);
    }

    // Start timer for CPU
    clock_t cpu_startTime = clock();

    // Add vectors on host
    vector_add_cpu(h_A, h_B, h_C_CPU, N);

    // Stop timer for CPU
    clock_t cpu_endTime = clock();
    double cpu_duration = (double)(cpu_endTime - cpu_startTime) / CLOCKS_PER_SEC;

    printf("CPU execution time: %f seconds\n", cpu_duration);

    size_t globalSize, localSize;
    cl_int err;
    cl_device_id device_id;
    cl_context context;
    cl_command_queue queue;
    cl_program program;
    cl_kernel kernel;
    cl_mem d_A, d_B, d_C;

    // Number of work items in each local work group
    localSize = 64;

    // Number of total work items - localSize must be devisor
    globalSize = ceil(N/(float)localSize)*localSize;

    // Bind to platform
    cl_platform_id cpPlatform;
    clGetPlatformIDs(1, &cpPlatform, NULL);

    // Get ID for the device
    err = clGetDeviceIDs(cpPlatform, CL_DEVICE_TYPE_GPU, 1, &device_id, NULL);

    // Create a context 
    context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);

    // Create a command queue
    queue = clCreateCommandQueue(context, device_id, CL_QUEUE_PROFILING_ENABLE, &err);

    // Create the compute program from the source buffer
    program = clCreateProgramWithSource(context, 1, &kernelSource, NULL, &err);

    // Build the program executable
    clBuildProgram(program, 0, NULL, NULL, NULL, NULL);

    // Create the compute kernel in the program we wish to run
    kernel = clCreateKernel(program, "vector_add", &err);

    // Create the input and output arrays in device memory for our calculation
    d_A = clCreateBuffer(context, CL_MEM_READ_ONLY, bytes, NULL, NULL);
    d_B = clCreateBuffer(context, CL_MEM_READ_ONLY, bytes, NULL, NULL);
    d_C = clCreateBuffer(context, CL_MEM_WRITE_ONLY, bytes, NULL, NULL);

    // Write our data set into the input array in device memory 
    err = clEnqueueWriteBuffer(queue, d_A, CL_TRUE, 0, bytes, h_A, 0, NULL, NULL);
    err |= clEnqueueWriteBuffer(queue, d_B, CL_TRUE, 0, bytes, h_B, 0, NULL, NULL);

    // Set the arguments to our compute kernel
    err  = clSetKernelArg(kernel, 0, sizeof(cl_mem), &d_A);
    err |= clSetKernelArg(kernel, 1, sizeof(cl_mem), &d_B);
    err |= clSetKernelArg(kernel, 2, sizeof(cl_mem), &d_C);
    err |= clSetKernelArg(kernel, 3, sizeof(unsigned int), &N);

    // Execute the kernel over the entire range of our 1d input data set
    // using the maximum number of work group items for this device

    cl_event event;
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, &localSize, 0, NULL, &event);

    // Wait for the command queue to get serviced before reading back results
    clFinish(queue);

    // Read the results from the device
    clEnqueueReadBuffer(queue, d_C, CL_TRUE, 0, bytes, h_C, 0, NULL, NULL );

    // Calculate time taken by event
    cl_ulong time_start;
    cl_ulong time_end;

    // Wait for event and calculate time
    clWaitForEvents(1, &event);
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(time_start), &time_start, NULL);
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END, sizeof(time_end), &time_end, NULL);
    double gpu_duration = (double)(time_end - time_start)/1000000.0;

    printf("OpenCL execution time: %f milliseconds \n", gpu_duration);

    // Verify that the GPU results match the CPU results
    int correct = 1;
    for(int i = 0; i < N; i++) {
        if(fabs(h_C[i] - h_C_CPU[i]) > 1e-5){
            printf("Result verification failed at element %d!\n", i);
            printf("CPU %f != GPU %f\n", h_C_CPU[i], h_C[i]);
            correct = 0;
            break;
        }
    }

    if(correct) {
        printf("Results are correct!\n");
    } else {
        printf("Results are incorrect!\n");
    }

    // Shutdown and cleanup
    clReleaseMemObject(d_A);
    clReleaseMemObject(d_B);
    clReleaseMemObject(d_C);
    clReleaseProgram(program);
    clReleaseKernel(kernel);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    free(h_A);
    free(h_B);
    free(h_C);
    free(h_C_CPU);

    return 0;
}
