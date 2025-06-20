#pragma once

#include <cuda_runtime.h>
#include <cuda.h>
#include <string>
#include <vector>
#include <array>
#include <utility>

#include "Geometry.h"
#include "FlowSurface.h"

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

struct ReflectionData
{
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

class Lattice
{
public:
    Lattice(int x, int y, int z, dim3 blocks, dim3 threads, FluidData fluid, double spacing);
    ~Lattice();

    void load_data(LatticePoint* lattice_array);
    LatticePoint* retrieve_data();
    ReflectionData* retrieve_reflection_data();

    dim3 getDimensions() { return dim3(m_xResolution, m_yResolution, m_zResolution); };
    cudaPitchedPtr getCudaDataPointer() { return latticePtr; };

    void simulateStreaming();
    void simulateCollision();
    void simulateReflections();
    void simulateFlow();

    void simulateLattice();

    void insertModel(std::string filename);

    std::array<std::pair<double, int>, 27> distributeVector(Point_3 vector);

    void preProcessModel();

    void setFlowData(FlowData* flowData);

    void setReflectionData(ReflectionData* reflection);

private:
    void createExtent();
    void allocateLatticeArray();
    void allocateReflectionData();

    inline LatticePoint* getElementAtDirection(int& x, int& y, int& z, int& dir_index, LatticePoint* data_array);

    cudaPitchedPtr latticePtr;
    cudaExtent latticeExtent;

    FluidData m_fluid;

    FlowData* m_flowData;
    FlowData* d_flowData;

    LatticeData m_dataPackage;

    unsigned short m_xResolution;
    unsigned short m_yResolution;
    unsigned short m_zResolution;

    double m_latticeSpacing;

    Model* m_simModel;

    dim3 m_threads;
    dim3 m_blocks;

    ReflectionData* m_reflectionData = nullptr;
    ReflectionData* d_reflectionData;
};