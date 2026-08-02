# Build and Install llama.cpp

These instructions target Ubuntu or Debian Linux and use Ninja with Vulkan support.

## Install Dependencies

```shell
sudo apt update
sudo apt install build-essential cmake ninja-build git wget ccache \
  libcurl4-openssl-dev libopenblas-dev libvulkan-dev vulkan-tools spirv-tools

wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc \
  | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-noble.list \
  http://packages.lunarg.com/vulkan/lunarg-vulkan-noble.list
sudo apt update
sudo apt install vulkan-sdk
```

## Clone and Configure

```shell
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp

export LLAMA_CPP_HOME=$(realpath $PWD/../llama_cpp_rl)
mkdir -p "$LLAMA_CPP_HOME"
```

Use `-DLLAMA_CUDA=ON` for NVIDIA GPUs, `-DGGML_CLBLAST=ON` for AMD OpenCL, or `-DGGML_VULKAN=ON` for Vulkan support.

```shell
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$LLAMA_CPP_HOME" \
  -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=ON \
  -DLLAMA_BUILD_SERVER=ON -DGGML_CLBLAST=ON -DGGML_VULKAN=ON

cmake --build build --config Release -j $(nproc)
cmake --install build --config Release

export PATH="$LLAMA_CPP_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$LLAMA_CPP_HOME/lib:$LD_LIBRARY_PATH"
llama-cli --list-devices
```

## Build with Make

The repository Makefile provides backend-specific builds after the source tree is available:

```shell
make llama-clone
make llama-build-amd-vulkan
```

Use the target that matches the installed backend:

```shell
make llama-build-nvidia
make llama-build-amd-vulkan
make llama-build-amd-rocm
```

Override the source directory, build type, or install location when needed:

```shell
make llama-build-amd-vulkan \
  LLAMA_DIR=llama.cpp \
  LLAMA_BUILD_TYPE=Release \
  LLAMA_INSTALL_PREFIX="$PWD/llama_cpp_rl"
```

## Further Reading

- [Vulkan setup for Ubuntu](https://vulkan.lunarg.com/doc/view/latest/linux/getting_started_ubuntu.html)
