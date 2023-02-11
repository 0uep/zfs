# Debian bookworm (testing) ships Clang-13, Clang-14 and Clang-15
FROM docker.io/debian:bookworm-20230202-slim

# Install Git
RUN apt-get update && \
    apt-get install -y --no-install-recommends git

# Install the dependencies to configure the Linux kernel (except the compiler and linker)
RUN apt-get install -y --no-install-recommends \
      bc \
      bison \
      cpio \
      flex \
      kmod \
      libelf-dev \
      libssl-dev:native \
      make

# Optional: Install the dependencies to build the Linux kernel as a Debian package
RUN apt-get install -y --no-install-recommends \
      build-essential:native \
      rsync

# Install the dependencies to build ZFS
RUN apt-get install -y --no-install-recommends \
      alien \
      autoconf \
      automake \
      dkms \
      fakeroot \
      gawk \
      libaio-dev \
      libattr1-dev \
      libblkid-dev \
      libcurl4-openssl-dev \
      libffi-dev \
      libssl-dev \
      libtool \
      python3 \
      python3-dev \
      python3-packaging \
      uuid-dev \
      zlib1g-dev

# Kernel version: v5.18.19, v6.1.10 ...
ARG vLinux=v6.1.10 

# Clone Linux repo
RUN git clone -b $vLinux --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

# Version of LLVM, can "-13", "-14", "-15" or "" (empty for GCC)
ARG LLVM=-15

# if LLVM is set, use llvmPkg=llvm$LLVM
ARG llvmPkg=llvm$LLVM

# Compiler, can be: gcc-10 gcc-11 gcc-12 clang-13 clang-14 clang-15
ARG CC=clang-15

# Linker, can be: lld-13 lld-14 lld-15 or empty
ARG ldPkg=lld-15
ARG LD=ld.$ldPkg

# Install the build chain: compiler, linker...
RUN apt-get install -y --no-install-recommends \
      $CC \
      $ldPkg \
      $llvmPkg

# Configure the Linux kernel
RUN cd linux && \
    make defconfig prepare CC=$CC LD=$LD LLVM=$LLVM && \
    grep ^CONFIG_BLOCK=y .config

# Optional: Build the Linux kernel as a Debian package
RUN cd linux && \
    make -j $(nproc --all) bindeb-pkg CC=$CC LD=$LD LLVM=$LLVM

WORKDIR /zfs

COPY . .

RUN ./autogen.sh

RUN set -x && \
    d=$(cd ../linux && pwd) && \
    export CC=$CC && \
    export LD=$LD && \
    export LLVM=$LLVM && \
    KERNEL_CC=$CC KERNEL_LD=$LD KERNEL_LLVM=$LLVM \
          ./configure -v \
          --enable-linux-builtin=yes \
          --includedir=$d/include \
          --with-linux=$d \
          --with-linux-obj=$d

RUN make check -j $(nproc --all)
