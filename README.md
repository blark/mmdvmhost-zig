# MMDVMHost-Zig

## Description

This project is a Zig build system setup for MMDVMHost, a widely-used software for ham radio enthusiasts that interfaces with Multi-Mode Digital Voice Modem (MMDVM) hardware, commonly used in amateur radio digital voice systems like DMR, D-STAR, and System Fusion.

I made this because I thought it would be a good opportunity to learn about Zig and it's features, particularly how it can be used for cross-platform builds.

## Project Structure

```
MMDVMHost-Zig/
├── build.zig
├── README.md
├── src/
│   └── [MMDVMHost source as a Git submodule]
└── vendor/
    ├── include/
    │   ├── [header files for libraries]
    └── lib/
        ├── aarch64-linux-gnu/
        │   └── [compiled library files for aarch64 architecture]
        └── ...
            └── [compiled library files for other architectures go here]
```

## Building MMDVMHost with Zig

### Prerequisites

- Zig (version 0.11.0): The project requires Zig version 0.11.0 for the build process. Ensure you have this specific version of Zig installed or it won't work.
- Thankfully dependencies are simple. The only library needed is [samplerate](https://github.com/libsndfile/libsamplerate.git). I've included the aarch64-linux-gnu shared object files (see project structure above). If you want to compile for a different target, just add the files to the `/vendor` directory.

### Building

Clone the repository and initialize the submodule:

```bash
git clone https://github.com/blark/mmdvmhost-zig.git
cd mmdvmhost-zig
git submodule update --init --recursive
```

and then you can build with `zig build` or to build for aarch64 `zig build -Dtarget=aarch64-linux-gnu`
