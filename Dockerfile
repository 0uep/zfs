# Version of LLVM, can "-13", "-14", "-15" or "" (empty for GCC)
ARG LLVM=-15

# Compiler, can be: gcc-10 gcc-11 gcc-12 clang-13 clang-14 clang-15
ARG CC=clang$LLVM

# Linker, can be: lld-13 lld-14 lld-15 or empty
ARG ldPkg=lld$LLVM
ARG LD=ld.$ldPkg

ARG CFLAGS="-march=native -O3 -falign-functions=64 -fno-semantic-interposition"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed"

##################################################

# vDebian = version of the Debian image
# See https://hub.docker.com/_/debian/
# can be vDebian=testing-20230208-slim
# (testing-20230208-slim ships Clang-13, Clang-14 and Clang-15)
ARG vDebian=testing-slim

FROM docker.io/debian:$vDebian AS base

RUN set -ex                                              ;\
    apt-get update                                       ;\
    echo "Install Git"                                   ;\
    apt-get install -y --no-install-recommends            \
      git                                                 \
      ca-certificates                                    ;\
    echo "Dependencies to configure the Linux kernel"    ;\
    apt-get install -y --no-install-recommends            \
      bc                                                  \
      bison                                               \
      cpio                                                \
      flex                                                \
      kmod                                                \
      libelf-dev                                          \
      libssl-dev:native                                   \
      make                                               ;\
    echo "Dependencies to build a Debian package"        ;\
    apt-get install -y --no-install-recommends            \
      build-essential:native                              \
      rsync                                              ;\
    echo "Dependencies to build ZFS"                     ;\
    apt-get install -y --no-install-recommends            \
      alien                                               \
      autoconf                                            \
      automake                                            \
      dkms                                                \
      fakeroot                                            \
      gawk                                                \
      libaio-dev                                          \
      libattr1-dev                                        \
      libblkid-dev                                        \
      libcurl4-openssl-dev                                \
      libffi-dev                                          \
      libssl-dev                                          \
      libtool                                             \
      python3                                             \
      python3-dev                                         \
      python3-packaging                                   \
      uuid-dev                                            \
      zlib1g-dev

# RUN echo "Optional: CCache to speedup the next attempts" ;\
#     apt-get install -y --no-install-recommends            \
#       ccache                                             ;\
#     ccache --max-files 0 --max-size 0 --show-config
# 
# ENV PATH=/usr/lib/ccache:$PATH

##################################################

FROM base AS compiler

ARG CC
ARG ldPkg
ARG LLVM
ARG llvmPkg=llvm$LLVM

# Install the build chain: compiler, linker...
RUN apt-get install -y --no-install-recommends  \
      "$CC"                                     \
      "$ldPkg"                                  \
      $llvmPkg

##################################################

FROM base AS linux-code

# Kernel version: v5.18.19, v6.1.10 ...
ARG vLinux=linux-rolling-stable

# Clone Linux repo
RUN git clone -b $vLinux --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

##################################################

FROM base AS zfs-code

ARG vZFS=master

# Clone OpenZFS repo
RUN git clone -b "$vZFS" --depth 1 https://github.com/openzfs/zfs

RUN /zfs/autogen.sh

##################################################

FROM compiler AS builder

COPY --from=linux-code /linux /linux

ARG CC
ARG LD
ARG LLVM
ARG CFLAGS
ARG LDFLAGS

RUN make -C linux defconfig CC="$CC" LD="$LD" LLVM="$LLVM"

# Disable -Werror because Clang fires warnings in OpenZFS source code
RUN echo "CONFIG_WERROR=n"                       >>linux/.config
# Enable additional dependencies
RUN echo "CONFIG_CRYPTO_DEFLATE=y"               >>linux/.config
RUN echo "CONFIG_ZLIB_DEFLATE=y"                 >>linux/.config
RUN echo "CONFIG_KALLSYMS=y"                     >>linux/.config
RUN echo "CONFIG_EFI_PARTITION=y"                >>linux/.config
# LTO
RUN echo "CONFIG_LTO=y"                          >>linux/.config
RUN echo "CONFIG_LTO_CLANG=y"                    >>linux/.config
RUN echo "CONFIG_ARCH_SUPPORTS_LTO_CLANG=y"      >>linux/.config
RUN echo "CONFIG_ARCH_SUPPORTS_LTO_CLANG_THIN=y" >>linux/.config
RUN echo "CONFIG_HAS_LTO_CLANG=y"                >>linux/.config
RUN echo "CONFIG_LTO_CLANG_FULL=y"               >>linux/.config

RUN make -C linux mod2yesconfig CC="$CC" LD="$LD" LLVM="$LLVM"

RUN set -x                                 ;\
    echo "PATH=$PATH"                      ;\
    command -V "$CC"                       ;\
    command -V "$LC"                       ;\
    make -C linux prepare                   \
        CC="$CC" LD="$LD" LLVM="$LLVM"      \
        KCFLAGS="$CFLAGS"                   \                    
        KLDFLAGS+="$LDFLAGS"' $(KCFLAGS)'

COPY --from=zfs-code /zfs /zfs

RUN set -ex                         ;\
    cd /zfs                         ;\
    export CC="$CC"                 ;\
    export LD="$LD"                 ;\
    export LLVM="$LLVM"             ;\
    ./configure -v                   \
        KERNEL_CC="$CC"              \
        KERNEL_LD="$LD"              \
        KERNEL_LLVM="$LLVM"          \
        CFLAGS="$CFLAGS $LDFLAGS"    \
        --disable-debug              \
        --disable-debuginfo          \
        --enable-linux-builtin=yes   \
        --with-linux=/linux         ;\
    ./copy-builtin /linux

# Enable built-in ZFS
RUN echo "CONFIG_ZFS=y" >>linux/.config

RUN make -C /linux bzImage modules -j $(nproc --all) -l $(nproc --all)   || \
    make -C /linux bzImage modules V=1

# Extra: Provide a Debian package
RUN make -C /linux bindeb-pkg -j $(nproc --all) -l $(nproc --all)        || \
    make -C /linux bindeb-pkg V=1

##################################################

FROM scratch AS final

COPY --from=builder /linux-* .
