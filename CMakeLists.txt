cmake_minimum_required(VERSION 3.8.0)

project(LatticeBoltzmannCuda VERSION 0.1.0 LANGUAGES C CXX CUDA)

find_package(CUDA REQUIRED)
include_directories(${CUDA_INCLUDE_DIRS})

find_package(CGAL REQUIRED COMPONENTS Core)

if(CGAL_FOUND)
    include_directories(${CGAL_INCLUDE_DIRS})
else()
    message(FATAL_ERROR "CGAL not found")
endif()

enable_testing()

add_subdirectory(simulation)
add_subdirectory(test)

add_executable(LatticeBoltzmannCuda LatticeBoltzmannCuda.cpp)

target_link_libraries(LatticeBoltzmannCuda PRIVATE GTest::gtest_main SimulationLib CGAL::CGAL CGAL)