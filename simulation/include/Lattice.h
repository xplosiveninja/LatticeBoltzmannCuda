#pragma once

#include <cuda_runtime.h>
#include <cuda.h>

class LatticePoint;

struct LatticeData
{
    cudaPitchedPtr latticePtr;
    dim3 latticeDimensions;

    LatticeData(cudaPitchedPtr ptr, dim3 dims) : latticePtr(ptr), latticeDimensions(dims) {};
};

struct FluidData
{
    double m_fluidDensity;
    double m_characteristicTimescale;

    FluidData(double fluidDensity, double characteristicTimescale) : m_fluidDensity(fluidDensity), m_characteristicTimescale(characteristicTimescale) {};
    FluidData() : m_fluidDensity(1.0), m_characteristicTimescale(1.0) {};
};

class Lattice
{
public:
    Lattice(int x, int y, int z, dim3 blocks, dim3 threads, FluidData fluid);
    ~Lattice();

    void load_data(LatticePoint* lattice_array);
    LatticePoint* retrieve_data();

    dim3 getDimensions() { return dim3(m_xResolution, m_yResolution, m_zResolution); };
    cudaPitchedPtr getCudaDataPointer() { return latticePtr; };

    void simulateStreaming();
    void simulateCollision();

private:
    void createExtent();
    void allocateLatticeArray();

    //void simulateStreaming();
    //void simulateCollision();

    cudaPitchedPtr latticePtr;
    cudaExtent latticeExtent;

    FluidData m_fluid;

    unsigned short m_xResolution;
    unsigned short m_yResolution;
    unsigned short m_zResolution;

    dim3 m_threads;
    dim3 m_blocks;
};