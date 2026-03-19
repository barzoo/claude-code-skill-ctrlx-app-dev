cmake_minimum_required(VERSION 3.16)
project(ctrlx-{company}-{app} VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Find ctrlX Data Layer SDK ─────────────────────────────────────────────────
# In App Build Environment: sudo apt install libctrlx-datalayer-dev
find_package(comm.datalayer REQUIRED)
find_package(Flatbuffers REQUIRED)

# ── Executable ────────────────────────────────────────────────────────────────
add_executable(${PROJECT_NAME}
    src/main.cpp
    # Add more source files here
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        comm::datalayer
        flatbuffers::flatbuffers
)

# ── Cross-compilation support ─────────────────────────────────────────────────
# For ARM64 (physical ctrlX CORE):
#   cmake -DCMAKE_TOOLCHAIN_FILE=arm64-toolchain.cmake ..
# Toolchain file sets:
#   CMAKE_SYSTEM_PROCESSOR = aarch64
#   CMAKE_C_COMPILER = aarch64-linux-gnu-gcc
#   CMAKE_CXX_COMPILER = aarch64-linux-gnu-g++

# ── Install ───────────────────────────────────────────────────────────────────
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION usr/local/bin
)
