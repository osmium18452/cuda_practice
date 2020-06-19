#include <cstdio>
#include <cstdlib>
#include <iostream>

using std::cout;
using std::endl;

#define BLOCKSIZE 50
#define RADIUS 10
#define maxn 2000
#define size maxn*sizeof(int)

__global__ void add(const int *a, const int *b, int *c) {
    c[threadIdx.x + blockIdx.x * blockDim.x] =
            a[threadIdx.x + blockIdx.x * blockDim.x] + b[threadIdx.x + blockIdx.x * blockDim.x];
}

__global__ void stential(const int *in, int *out) {
    __shared__ int tmp[BLOCKSIZE + RADIUS * 2];
    auto gindex = threadIdx.x + blockIdx.x * blockDim.x;
    auto lindex = threadIdx.x + RADIUS;

    tmp[lindex] = in[gindex];
    if (threadIdx.x < RADIUS) {
        tmp[lindex - RADIUS] = (gindex < RADIUS ) ? 0 : in[gindex - RADIUS];
        tmp[lindex + BLOCKSIZE] = (gindex + BLOCKSIZE > maxn) ? 0 : in[gindex + BLOCKSIZE];
    }

    __syncthreads();

    int result = 0;
    for (int i = -RADIUS; i < RADIUS; i++) {
        result += tmp[i + lindex];
    }
    out[gindex] = result;
}

int main() {
    int *in, *out;
    int *inc, *outc;
    in = (int *) malloc(size);
    out = (int *) malloc(size);
    for (int i = 0; i < maxn; i++) {
        in[i] = i;
        out[i] = 233;
    }
    cudaMalloc((void **) &inc, size);
    cudaMalloc((void **) &outc, size);

    cudaMemcpy(inc, in, size, cudaMemcpyHostToDevice);
    stential<<<(maxn+BLOCKSIZE-1)/BLOCKSIZE, BLOCKSIZE>>>(inc, outc);
    cudaError error;
    cout<<size<<" "<<sizeof(out)<<" "<<sizeof(outc)<<endl;
    error = cudaMemcpy(out, outc, size, cudaMemcpyDeviceToHost);//why i can't copy the memory?
    std::cout << "error: " << cudaGetErrorString(error) << std::endl;

    for (int i = 0; i < maxn; i++) {
        std::cout << in[i] << " " << out[i] << std::endl;
    }
    cudaFree(inc);
    cudaFree(outc);
    return 0;
}