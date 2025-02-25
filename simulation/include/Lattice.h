#pragma once

#include <cuda_runtime.h>
#include <cuda.h>

#include <string>
#include <vector>

class LatticePoint;
class Model;

struct LatticeData
{
    cudaPitchedPtr latticePtr;
    dim3 latticeDimensions;

    LatticeData(cudaPitchedPtr ptr, dim3 dims) : latticePtr(ptr), latticeDimensions(dims) {};
    LatticeData() : latticePtr(cudaPitchedPtr()), latticeDimensions(dim3()) {};
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
    Lattice(int x, int y, int z, dim3 blocks, dim3 threads, FluidData fluid, double spacing);
    ~Lattice();

    void load_data(LatticePoint* lattice_array);
    LatticePoint* retrieve_data();

    dim3 getDimensions() { return dim3(m_xResolution, m_yResolution, m_zResolution); };
    cudaPitchedPtr getCudaDataPointer() { return latticePtr; };

    void simulateStreaming();
    void simulateCollision();

    void simulateLattice();

    void insertModel(std::string filename);

private:
    void createExtent();
    void allocateLatticeArray();

    cudaPitchedPtr latticePtr;
    cudaExtent latticeExtent;

    FluidData m_fluid;

    LatticeData m_dataPackage;

    unsigned short m_xResolution;
    unsigned short m_yResolution;
    unsigned short m_zResolution;

    double m_latticeSpacing;

    Model* m_simModel;

    dim3 m_threads;
    dim3 m_blocks;
};