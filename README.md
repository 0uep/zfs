# Build OpenZFS as an internal Linux module with LTO

This project has been created to document and test
OpenZFS as a Linux kernel built-in module
compiled with Clang to use LTO (Link Time Optimization).

## Generate a Debian package with LLVM-15

If you use a recent official `docker`:

    docker build -t linux-with-zfs-builtin -f Dockerfile.ccache .

Otherwise:

    docker build -t linux-with-zfs-builtin .

or if you use `podman`:

    podman build -t linux-with-zfs-builtin .

The container image contains the debian package
to install a Linux kernel including the built-in ZFS.

## Build arguments

The `Dockerfile` use the following build arguments with default values.

* `vDebian=testing-slim` (can also be `10.13-slim` or `sid-slim`, see <https://hub.docker.com/_/debian/>)
* `vLinux=linux-rolling-stable` (can also be `v6.1.12`)
* `vZFS=master` (can also be `zfs-2.1.10-staging` or `zfs-2.1.9`, see <https://github.com/openzfs/zfs/tags>)
* `LLVM=-15`
* `CC=clang-15`
* `LD=ld.lld-15`
* `ldPkg=lld-15`
* `llvmPkg=llvm-15`
* `CFLAGS="-march=native -O3 -falign-functions=64 -fno-semantic-interposition"`
* `LDFLAGS="-Wl,-O2 -Wl,--as-needed"`

Pass the arguments with the `--build-arg` flag:

    docker build -t linux-with-zfs-builtin . --build-arg LLVM=-14

## Docker Compose

The provided [`compose.yml`](compose.yml) builds six images:

1. `CC=clang-13` + `LD=ld.lld-13`
1. `CC=clang-14` + `LD=ld.lld-14`
1. `CC=clang-15` + `LD=ld.lld-15`
1. `CC=gcc-10` + `LD=ld.lld-15`
1. `CC=gcc-11` + `LD=ld.lld-15`
1. `CC=gcc-12` + `LD=ld.lld-15`

If you use a recent official `docker`:

    docker compose -f compose-ccache.yml build
    # ERROR: Could not get lock /var/cache/apt/archives/lock.

else:

    docker-compose build

## Retrieve the debian package

    mkdir -pv linzfs
    id=$(docker create linux-with-zfs-builtin "")
    docker cp $id:/ linzfs
    docker rm $id
    ls -lh linzfs/*deb

## Install

    sudo dpkg -i linzfs/linux-[hi]*.deb

## Uninstall

    # List installed Linux images
    apt list --installed --all-versions "linux-*"

    # Uninstall
    sudo apt purge "linux-*-6.1.12*"    # <-- Replace 

## Licence Warning

OpenZFS cannot be legally delivered with the Linux kernel
because of licences incompatibility.

Please do not provide OpenZFS in source code or binary format
within the same release containing Linux source code or binary.

## Loadable module

To build OpenZFS as a loadable Linux kernel module
enable loadable module support by setting
`CONFIG_MODULES=y` in the kernel configuration and run
`make modules_prepare` in the Linux source tree.

## Kernel built-in

Here we don't intend to load OpenZFS as a kernel module.
So we compile OpenZFS as a Linux kernel built-in.
The following simple steps achieve this goal:

    dir=/absolute/path/to/linux

    # Prepare the Linux source tree
    make -C $dir prepare
    
    # Configure OpenZFS with --enable-linux-builtin
    cd /path/to/zfs
    ./autogen.sh
    ./configure --enable-linux-builtin --with-linux=$dir

    # Copy the OpenZFS sources into the Linux source tree
    ./copy-builtin $dir

    # Enable ZFS if the Linux configuration 
    echo "CONFIG_ZFS=y" >> $dir/.config

    # Build Linux kernel including OpenZFS
    make -C $dir bzImage modules

## Debian package

I am using Debian testing
and want to build a Debian package
to easily install and uninstall my attempts.

    # Build a Debian binary package
    make -C $dir bindeb-pkg

## Optimizations

Let's take the opportunity to
try to improve the Kernel performance. :-)

I am trying the following optimisations:

* `-march=native`
* `-O3`
* `-falign-functions=64`
* `-fno-semantic-interposition`
* LTO (Link Time Optimisation requires LLVM/Clang)

## Inspiration

This project has been inspired by:

* <https://github.com/openzfs/zfs/issues/11238>
* <https://forum.level1techs.com/t/building-custom-kernel-with-zfs-built-in/117464/3>

## TODO

Use a local virtual machine to test the kernel images:
<https://planeta.github.io/programming/kernel-development-setup-with-vagrant/>

## Public Domain Dedication - CC0 1.0 Universal

[Creative Commons Zero] &emsp; *No Rights Reserved* &emsp; ![(CC) ZERO] &nbsp; ![(0) PUBLIC DOMAIN]

[Creative Commons Zero]: https://creativecommons.org/publicdomain/zero/1.0/deed "CC0 summary for non-lawyers"
[(CC) ZERO]:             https://licensebuttons.net/l/zero/1.0/80x15.png "Logo Creative Commons Zero (CC0) 1.0"
[(0) PUBLIC DOMAIN]:     https://licensebuttons.net/p/zero/1.0/80x15.png "Logo CC0 1.0 Public Domain"

To the extent possible under law, I have waived all copyright
and related or neighboring rights to these container related files.
This work is published from France since 2023.
Refer to [CC0 Legal Code] or a copy in file [`COPYING`].

[CC0 Legal Code]: https://creativecommons.org/publicdomain/zero/1.0/legalcode "CC0 full legal text for lawyers"
[`COPYING`]:      ./COPYING
