#include <cuda_runtime.h>
#include <cuda.h>
#include <stdio.h>

#include "Lattice.h"
#include "LatticePoint.h"
#include "device_launch_parameters.h"
#include "SimCalcFuncs.cuh"

namespace CudaFunctions
{
    __device__ LatticePoint* get_lattice_at_coords(LatticeData lattice, int x, int y, int z)
    {
        cudaPitchedPtr latticePtr = lattice.latticePtr;
        dim3 resolution = lattice.latticeDimensions;

        if(x < 0 || y < 0 || z < 0 || x > resolution.x || y > resolution.y || z > resolution.z)
        {
            return nullptr;
        }

        size_t pitch = latticePtr.pitch;
        size_t slicePitch = pitch * latticePtr.ysize;

        char* curr_slice = (char*)latticePtr.ptr + z * slicePitch;

        LatticePoint* lattice_points = (LatticePoint*)(curr_slice + y * pitch);

        return &lattice_points[x];
    }

    __device__ LatticePoint* get_lattice_point(LatticeData lattice)
    {
        int z = blockDim.z * blockIdx.z + threadIdx.z;
        int y = blockDim.y * blockIdx.y + threadIdx.y;
        int x = blockDim.x * blockIdx.x + threadIdx.x;

        return get_lattice_at_coords(lattice, x, y, z);
    }

    __global__ void prime_points(LatticeData lattice)
    {
        LatticePoint* current_point = get_lattice_point(lattice);

        current_point->x = blockDim.x * blockIdx.x + threadIdx.x;
        current_point->y = blockDim.y * blockIdx.y + threadIdx.y;
        current_point->z = blockDim.z * blockIdx.z + threadIdx.z;
    }

    __global__ void calculate_equilibrium(LatticeData lattice)
    {
        LatticePoint* current_point = get_lattice_point(lattice);

        double density = 0;
        double ux = 0;
        double uy = 0;
        double uz = 0;

        constexpr int directions[27][3] = {{0, 0, 0}, {-1, 0, 0}, {0, -1, 0}, {0, 0, -1}, {0, 0, 1}, {0, 1, 0}, {1, 0, 0}, {-1, -1, 0}, {-1, 0, -1}, {-1, 0, 1}, {-1, 1, 0}, {0, -1, -1}, {0, -1, 1}, {0, 1, -1}, {0, 1, 1}, {1, -1, 0}, {1, 0, -1}, {1, 0, 1}, {1, 1, 0}, {-1, -1, -1}, {-1, -1, 1}, {-1, 1, -1}, {-1, 1, 1}, {1, -1, -1}, {1, -1, 1}, {1, 1, -1}, {1, 1, 1}};

        for(int i = 0; i < 27; ++i)
        {
            density += current_point->particle_distribution[i];
            ux += current_point->particle_distribution[i] * directions[i][0];
            uy += current_point->particle_distribution[i] * directions[i][1];
            uz += current_point->particle_distribution[i] * directions[i][2];
        }

        {   
            double common_term = ((directions[0][0] * ux) + (directions[0][1] * uy) + (directions[0][2] * uz));
            current_point->equilibrium[0] = (8.0/27.0) * density * (1 + (3.0 * common_term) + (4.5 * common_term * common_term) - (1.5 * (ux * ux) * (uy * uy) * (uz * uz)));
        }

        for(int i = 1; i < 7; ++i)
        {
            double common_term = ((directions[i][0] * ux) + (directions[i][1] * uy) + (directions[i][2] * uz));

            current_point->equilibrium[i] = (2.0/27.0) * density * (1 + (3.0 * common_term) + (4.5 * common_term * common_term) - (1.5 * (ux * ux) * (uy * uy) * (uz * uz)));
        }

        for(int i = 7; i < 19; ++i)
        {
            double common_term = ((directions[i][0] * ux) + (directions[i][1] * uy) + (directions[i][2] * uz));

            current_point->equilibrium[i] = (1.0/54.0) * density * (1 + (3.0 * common_term) + (4.5 * common_term * common_term) - (1.5 * (ux * ux) * (uy * uy) * (uz * uz)));
        }

        for(int i = 19; i < 27; ++i)
        {
            double common_term = ((directions[i][0] * ux) + (directions[i][1] * uy) + (directions[i][2] * uz));

            current_point->equilibrium[i] = (1.0/216.0) * density * (1 + (3.0 * common_term) + (4.5 * common_term * common_term) - (1.5 * (ux * ux) * (uy * uy) * (uz * uz)));
        }
    }

    __global__ void calculate_streaming(LatticeData lattice, LatticeData templattice)
    {
        LatticePoint* current_point = get_lattice_point(lattice);

        constexpr int directions[27][3] = {{0, 0, 0}, {-1, 0, 0}, {0, -1, 0}, {0, 0, -1}, {0, 0, 1}, {0, 1, 0}, {1, 0, 0}, {-1, -1, 0}, {-1, 0, -1}, {-1, 0, 1}, {-1, 1, 0}, {0, -1, -1}, {0, -1, 1}, {0, 1, -1}, {0, 1, 1}, {1, -1, 0}, {1, 0, -1}, {1, 0, 1}, {1, 1, 0}, {-1, -1, -1}, {-1, -1, 1}, {-1, 1, -1}, {-1, 1, 1}, {1, -1, -1}, {1, -1, 1}, {1, 1, -1}, {1, 1, 1}};

        for(int i = 1; i < 27; ++i)
        {
            LatticePoint* neighbour = get_lattice_at_coords(templattice, current_point->x + directions[i][0], current_point->y + directions[i][1], current_point->z + directions[i][2]);

            if(neighbour != nullptr)
            {
                neighbour->particle_distribution[i] = current_point->particle_distribution[i];
            }
        }
    }

    __global__ void calculate_collision(LatticeData lattice, double timescale)
    {
        LatticePoint* current_point = get_lattice_point(lattice);

        for(int i = 0; i < 27; ++i)
        {
            current_point->particle_distribution[i] += (current_point->equilibrium[i] - current_point->particle_distribution[i])/timescale;
        }
    }
}

namespace RunCudaFunctions
{
    void run_calculate_streaming(dim3 blocks, dim3 threads, LatticeData lattice, LatticeData templattice)
    {
        CudaFunctions::calculate_streaming<<<blocks, threads>>>(lattice, templattice);
    }

    void run_calculate_collision(dim3 blocks, dim3 threads, LatticeData lattice, double timescale)
    {
        CudaFunctions::calculate_equilibrium<<<blocks, threads>>>(lattice);

        CudaFunctions::calculate_collision<<<blocks, threads>>>(lattice, timescale);
    }
}