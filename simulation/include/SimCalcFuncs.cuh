#include <cuda_runtime.h>
#include <cuda.h>

#include "device_launch_parameters.h"

namespace CudaFunctions
{
    __global__ void calculate_streaming(LatticeData lattice, LatticeData templattice);

    __global__ void prime_points(LatticeData lattice);
}

namespace RunCudaFunctions
{
    void run_calculate_streaming(dim3 blocks, dim3 threads, LatticeData lattice, LatticeData templattice);

    void run_calculate_collision(dim3 blocks, dim3 threads, LatticeData lattice, double timescale);
}