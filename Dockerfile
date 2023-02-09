# Debian bookworm (testing) ships Clang-13, Clang-14 and Clang-15
FROM docker.io/debian:bookworm-20230202-slim

# Install Git
RUN apt-get update && apt-get install -y --no-install-recommends git

# Kernel version: v5.18.19, v6.1.10 ...
ARG vLinux=v6.1.10 

# Clone Linux repo
RUN git clone -b $vLinux --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

# LLVM version: 13, 14 or 15
ARG v=15

# Install the dependencies to build the Linux kernel with LLVM (clang + lld)
RUN apt-get install -y --no-install-recommends \
      bc \
      bison \
      clang-$v \
      flex \
      libelf-dev \
      lld-$v \
      llvm-$v \
      make

# Configure the Linux kernel with LLVM/Clang
RUN cd linux && \
    make defconfig prepare LLVM=-$v && \
    grep ^CONFIG_BLOCK=y .config

# Install the dependencies to build ZFS with Clang
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

WORKDIR /zfs

COPY . .

RUN ./autogen.sh

RUN set -x && \
    d=$(cd ../linux && pwd) && \
    export CC=clang-$v && \
    export LD=lld-$v && \
    export LLVM=-$v && \
    KERNEL_CC=$CC KERNEL_LD=$LD KERNEL_LLVM=$LLVM \
      ./configure -v \
      --enable-linux-builtin=yes \
      --includedir=$d/include \
      --with-linux=$d \
      --with-linux-obj=$d

RUN make check

# OUTPUT:

# Making check in include
# make[1]: Entering directory '/zfs/include'
# Making check in sys
# make[2]: Entering directory '/zfs/include/sys'
# Making check in fm
# make[3]: Entering directory '/zfs/include/sys/fm'
# Making check in fs
# make[4]: Entering directory '/zfs/include/sys/fm/fs'
# make[4]: Nothing to be done for 'check'.
# make[4]: Leaving directory '/zfs/include/sys/fm/fs'
# make[4]: Entering directory '/zfs/include/sys/fm'
# make[4]: Nothing to be done for 'check-am'.
# make[4]: Leaving directory '/zfs/include/sys/fm'
# make[3]: Leaving directory '/zfs/include/sys/fm'
# Making check in fs
# make[3]: Entering directory '/zfs/include/sys/fs'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/include/sys/fs'
# Making check in crypto
# make[3]: Entering directory '/zfs/include/sys/crypto'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/include/sys/crypto'
# Making check in lua
# make[3]: Entering directory '/zfs/include/sys/lua'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/include/sys/lua'
# Making check in sysevent
# make[3]: Entering directory '/zfs/include/sys/sysevent'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/include/sys/sysevent'
# Making check in zstd
# make[3]: Entering directory '/zfs/include/sys/zstd'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/include/sys/zstd'
# make[3]: Entering directory '/zfs/include/sys'
# make[3]: Nothing to be done for 'check-am'.
# make[3]: Leaving directory '/zfs/include/sys'
# make[2]: Leaving directory '/zfs/include/sys'
# Making check in os
# make[2]: Entering directory '/zfs/include/os'
# Making check in linux
# make[3]: Entering directory '/zfs/include/os/linux'
# Making check in kernel
# make[4]: Entering directory '/zfs/include/os/linux/kernel'
# Making check in linux
# make[5]: Entering directory '/zfs/include/os/linux/kernel/linux'
# make[5]: Nothing to be done for 'check'.
# make[5]: Leaving directory '/zfs/include/os/linux/kernel/linux'
# make[5]: Entering directory '/zfs/include/os/linux/kernel'
# make[5]: Nothing to be done for 'check-am'.
# make[5]: Leaving directory '/zfs/include/os/linux/kernel'
# make[4]: Leaving directory '/zfs/include/os/linux/kernel'
# Making check in spl
# make[4]: Entering directory '/zfs/include/os/linux/spl'
# Making check in rpc
# make[5]: Entering directory '/zfs/include/os/linux/spl/rpc'
# make[5]: Nothing to be done for 'check'.
# make[5]: Leaving directory '/zfs/include/os/linux/spl/rpc'
# Making check in sys
# make[5]: Entering directory '/zfs/include/os/linux/spl/sys'
# make[5]: Nothing to be done for 'check'.
# make[5]: Leaving directory '/zfs/include/os/linux/spl/sys'
# make[5]: Entering directory '/zfs/include/os/linux/spl'
# make[5]: Nothing to be done for 'check-am'.
# make[5]: Leaving directory '/zfs/include/os/linux/spl'
# make[4]: Leaving directory '/zfs/include/os/linux/spl'
# Making check in zfs
# make[4]: Entering directory '/zfs/include/os/linux/zfs'
# Making check in sys
# make[5]: Entering directory '/zfs/include/os/linux/zfs/sys'
# make[5]: Nothing to be done for 'check'.
# make[5]: Leaving directory '/zfs/include/os/linux/zfs/sys'
# make[5]: Entering directory '/zfs/include/os/linux/zfs'
# make[5]: Nothing to be done for 'check-am'.
# make[5]: Leaving directory '/zfs/include/os/linux/zfs'
# make[4]: Leaving directory '/zfs/include/os/linux/zfs'
# make[4]: Entering directory '/zfs/include/os/linux'
# make[4]: Nothing to be done for 'check-am'.
# make[4]: Leaving directory '/zfs/include/os/linux'
# make[3]: Leaving directory '/zfs/include/os/linux'
# make[3]: Entering directory '/zfs/include/os'
# make[3]: Nothing to be done for 'check-am'.
# make[3]: Leaving directory '/zfs/include/os'
# make[2]: Leaving directory '/zfs/include/os'
# make[2]: Entering directory '/zfs/include'
# make[2]: Nothing to be done for 'check-am'.
# make[2]: Leaving directory '/zfs/include'
# make[1]: Leaving directory '/zfs/include'
# Making check in rpm
# make[1]: Entering directory '/zfs/rpm'
# Making check in generic
# make[2]: Entering directory '/zfs/rpm/generic'
# make[2]: Nothing to be done for 'check'.
# make[2]: Leaving directory '/zfs/rpm/generic'
# Making check in redhat
# make[2]: Entering directory '/zfs/rpm/redhat'
# make[2]: Nothing to be done for 'check'.
# make[2]: Leaving directory '/zfs/rpm/redhat'
# make[2]: Entering directory '/zfs/rpm'
# make[2]: Nothing to be done for 'check-am'.
# make[2]: Leaving directory '/zfs/rpm'
# make[1]: Leaving directory '/zfs/rpm'
# Making check in man
# make[1]: Entering directory '/zfs/man'
#   GEN      man8/zed.8
#   GEN      man8/zfs-mount-generator.8
# make[1]: Leaving directory '/zfs/man'
# Making check in scripts
# make[1]: Entering directory '/zfs/scripts'
# /usr/bin/sed -e '\|^export BIN_DIR=|s|$|/zfs/bin|' \
#         -e '\|^export SBIN_DIR=|s|$|/zfs/bin|' \
#         -e '\|^export LIBEXEC_DIR=|s|$|/zfs/bin|' \
#         -e '\|^export ZTS_DIR=|s|$|/zfs/tests|' \
#         -e '\|^export SCRIPT_DIR=|s|$|/zfs/scripts|' \
#         /zfs/scripts/common.sh.in >common.sh
# echo "$EXTRA_ENVIRONMENT" >>common.sh
# make[1]: Leaving directory '/zfs/scripts'
# Making check in lib
# make[1]: Entering directory '/zfs/lib'
# Making check in libavl
# make[2]: Entering directory '/zfs/lib/libavl'
#   CC       avl.lo
#   CCLD     libavl.la
# make[2]: Leaving directory '/zfs/lib/libavl'
# Making check in libicp
# make[2]: Entering directory '/zfs/lib/libicp'
#   CC       spi/kcf_spi.lo
#   CC       api/kcf_ctxops.lo
#   CC       api/kcf_digest.lo
#   CC       api/kcf_cipher.lo
#   CC       api/kcf_miscapi.lo
#   CC       api/kcf_mac.lo
#   CC       algs/aes/aes_impl_aesni.lo
#   CC       algs/aes/aes_impl_generic.lo
#   CC       algs/aes/aes_impl_x86-64.lo
#   CC       algs/aes/aes_impl.lo
#   CC       algs/aes/aes_modes.lo
#   CC       algs/edonr/edonr.lo
#   CC       algs/modes/modes.lo
#   CC       algs/modes/cbc.lo
#   CC       algs/modes/gcm_generic.lo
#   CC       algs/modes/gcm_pclmulqdq.lo
#   CC       algs/modes/gcm.lo
#   CC       algs/modes/ctr.lo
#   CC       algs/modes/ccm.lo
#   CC       algs/modes/ecb.lo
#   CC       algs/sha2/sha2.lo
#   CC       algs/skein/skein.lo
#   CC       algs/skein/skein_block.lo
#   CC       algs/skein/skein_iv.lo
#   CC       illumos-crypto.lo
#   CC       io/aes.lo
#   CC       io/edonr_mod.lo
#   CC       io/sha2_mod.lo
#   CC       io/skein_mod.lo
#   CC       os/modhash.lo
#   CC       os/modconf.lo
#   CC       core/kcf_sched.lo
#   CC       core/kcf_prov_lib.lo
#   CC       core/kcf_callprov.lo
#   CC       core/kcf_mech_tabs.lo
#   CC       core/kcf_prov_tabs.lo
#   CC       asm-x86_64/aes/aeskey.lo
#   CPPAS    asm-x86_64/aes/aes_amd64.lo
#   CPPAS    asm-x86_64/aes/aes_aesni.lo
#   CPPAS    asm-x86_64/modes/gcm_pclmulqdq.lo
#   CPPAS    asm-x86_64/modes/aesni-gcm-x86_64.lo
#   CPPAS    asm-x86_64/modes/ghash-x86_64.lo
#   CPPAS    asm-x86_64/sha2/sha256_impl.lo
#   CPPAS    asm-x86_64/sha2/sha512_impl.lo
#   CCLD     libicp.la
# copying selected object files to avoid basename conflicts...
# make[2]: Leaving directory '/zfs/lib/libicp'
# Making check in libshare
# make[2]: Entering directory '/zfs/lib/libshare'
#   CC       libshare.lo
#   CC       os/linux/nfs.lo
#   CC       os/linux/smb.lo
#   CCLD     libshare.la
# make[2]: Leaving directory '/zfs/lib/libshare'
# Making check in libspl
# make[2]: Entering directory '/zfs/lib/libspl'
# Making check in include
# make[3]: Entering directory '/zfs/lib/libspl/include'
# Making check in ia32
# make[4]: Entering directory '/zfs/lib/libspl/include/ia32'
# Making check in sys
# make[5]: Entering directory '/zfs/lib/libspl/include/ia32/sys'
# make[5]: Nothing to be done for 'check'.
# make[5]: Leaving directory '/zfs/lib/libspl/include/ia32/sys'
# make[5]: Entering directory '/zfs/lib/libspl/include/ia32'
# make[5]: Nothing to be done for 'check-am'.
# make[5]: Leaving directory '/zfs/lib/libspl/include/ia32'
# make[4]: Leaving directory '/zfs/lib/libspl/include/ia32'
# Making check in rpc
# make[4]: Entering directory '/zfs/lib/libspl/include/rpc'
# make[4]: Nothing to be done for 'check'.
# make[4]: Leaving directory '/zfs/lib/libspl/include/rpc'
# Making check in sys
# make[4]: Entering directory '/zfs/lib/libspl/include/sys'
# Making check in dktp
# make[5]: Entering directory '/zfs/lib/libspl/include/sys/dktp'
# make[5]: Nothing to be done for 'check'.
# make[5]: Leaving directory '/zfs/lib/libspl/include/sys/dktp'
# make[5]: Entering directory '/zfs/lib/libspl/include/sys'
# make[5]: Nothing to be done for 'check-am'.
# make[5]: Leaving directory '/zfs/lib/libspl/include/sys'
# make[4]: Leaving directory '/zfs/lib/libspl/include/sys'
# Making check in util
# make[4]: Entering directory '/zfs/lib/libspl/include/util'
# make[4]: Nothing to be done for 'check'.
# make[4]: Leaving directory '/zfs/lib/libspl/include/util'
# Making check in os
# make[4]: Entering directory '/zfs/lib/libspl/include/os'
# Making check in linux
# make[5]: Entering directory '/zfs/lib/libspl/include/os/linux'
# Making check in sys
# make[6]: Entering directory '/zfs/lib/libspl/include/os/linux/sys'
# make[6]: Nothing to be done for 'check'.
# make[6]: Leaving directory '/zfs/lib/libspl/include/os/linux/sys'
# make[6]: Entering directory '/zfs/lib/libspl/include/os/linux'
# make[6]: Nothing to be done for 'check-am'.
# make[6]: Leaving directory '/zfs/lib/libspl/include/os/linux'
# make[5]: Leaving directory '/zfs/lib/libspl/include/os/linux'
# make[5]: Entering directory '/zfs/lib/libspl/include/os'
# make[5]: Nothing to be done for 'check-am'.
# make[5]: Leaving directory '/zfs/lib/libspl/include/os'
# make[4]: Leaving directory '/zfs/lib/libspl/include/os'
# make[4]: Entering directory '/zfs/lib/libspl/include'
# make[4]: Nothing to be done for 'check-am'.
# make[4]: Leaving directory '/zfs/lib/libspl/include'
# make[3]: Leaving directory '/zfs/lib/libspl/include'
# make[3]: Entering directory '/zfs/lib/libspl'
#   CC       assert.lo
#   CCLD     libspl_assert.la
#   CC       atomic.lo
#   CC       list.lo
#   CC       mkdirp.lo
#   CC       page.lo
#   CC       strlcat.lo
#   CC       strlcpy.lo
#   CC       timestamp.lo
#   CC       os/linux/getexecname.lo
#   CC       os/linux/gethostid.lo
#   CC       os/linux/getmntany.lo
#   CC       os/linux/zone.lo
#   CCLD     libspl.la
# make[3]: Leaving directory '/zfs/lib/libspl'
# make[2]: Leaving directory '/zfs/lib/libspl'
# Making check in libtpool
# make[2]: Entering directory '/zfs/lib/libtpool'
#   CC       thread_pool.lo
#   CCLD     libtpool.la
# make[2]: Leaving directory '/zfs/lib/libtpool'
# Making check in libzstd
# make[2]: Entering directory '/zfs/lib/libzstd'
#   CC       lib/zstd.lo
#   CC       zfs_zstd.lo
#   CCLD     libzstd.la
# make[2]: Leaving directory '/zfs/lib/libzstd'
# Making check in libefi
# make[2]: Entering directory '/zfs/lib/libefi'
#   CC       rdwr_efi.lo
#   CCLD     libefi.la
# make[2]: Leaving directory '/zfs/lib/libefi'
# Making check in libnvpair
# make[2]: Entering directory '/zfs/lib/libnvpair'
#   CC       libnvpair.lo
#   CC       libnvpair_json.lo
#   CC       nvpair_alloc_system.lo
#   CC       nvpair_alloc_fixed.lo
#   CC       nvpair.lo
#   CC       fnvpair.lo
#   CCLD     libnvpair.la
# make[2]: Leaving directory '/zfs/lib/libnvpair'
# Making check in libzutil
# make[2]: Entering directory '/zfs/lib/libzutil'
#   CC       zutil_device_path.lo
#   CC       zutil_import.lo
#   CC       zutil_nicenum.lo
#   CC       zutil_pool.lo
#   CC       os/linux/zutil_device_path_os.lo
#   CC       os/linux/zutil_import_os.lo
#   CC       os/linux/zutil_compat.lo
#   CCLD     libzutil.la
# make[2]: Leaving directory '/zfs/lib/libzutil'
# Making check in libunicode
# make[2]: Entering directory '/zfs/lib/libunicode'
#   CC       u8_textprep.lo
#   CC       uconv.lo
#   CCLD     libunicode.la
# make[2]: Leaving directory '/zfs/lib/libunicode'
# Making check in libuutil
# make[2]: Entering directory '/zfs/lib/libuutil'
#   CC       uu_alloc.lo
#   CC       uu_avl.lo
#   CC       uu_dprintf.lo
#   CC       uu_ident.lo
#   CC       uu_list.lo
#   CC       uu_misc.lo
#   CC       uu_open.lo
#   CC       uu_pname.lo
#   CC       uu_string.lo
#   CCLD     libuutil.la
# make[2]: Leaving directory '/zfs/lib/libuutil'
# Making check in libzfs_core
# make[2]: Entering directory '/zfs/lib/libzfs_core'
#   CC       libzfs_core.lo
#   CCLD     libzfs_core.la
# make[2]: Leaving directory '/zfs/lib/libzfs_core'
# Making check in libzfs
# make[2]: Entering directory '/zfs/lib/libzfs'
#   CC       libzfs_changelist.lo
#   CC       libzfs_config.lo
#   CC       libzfs_crypto.lo
#   CC       libzfs_dataset.lo
#   CC       libzfs_diff.lo
#   CC       libzfs_import.lo
#   CC       libzfs_iter.lo
#   CC       libzfs_mount.lo
#   CC       libzfs_pool.lo
#   CC       libzfs_sendrecv.lo
#   CC       libzfs_status.lo
#   CC       libzfs_util.lo
#   CC       os/linux/libzfs_mount_os.lo
#   CC       os/linux/libzfs_pool_os.lo
#   CC       os/linux/libzfs_sendrecv_os.lo
#   CC       os/linux/libzfs_util_os.lo
#   CC       algs/sha2/sha2.lo
#   CC       cityhash.lo
#   CC       zfeature_common.lo
#   CC       zfs_comutil.lo
#   CC       zfs_deleg.lo
#   CC       zfs_fletcher.lo
#   CC       zfs_fletcher_aarch64_neon.lo
#   CC       zfs_fletcher_avx512.lo
#   CC       zfs_fletcher_intel.lo
#   CC       zfs_fletcher_sse.lo
#   CC       zfs_fletcher_superscalar.lo
#   CC       zfs_fletcher_superscalar4.lo
#   CC       zfs_namecheck.lo
#   CC       zfs_prop.lo
#   CC       zpool_prop.lo
#   CC       zprop_common.lo
#   CCLD     libzfs.la
# make[2]: Leaving directory '/zfs/lib/libzfs'
# Making check in libzpool
# make[2]: Entering directory '/zfs/lib/libzpool'
#   CC       kernel.lo
#   CC       taskq.lo
#   CC       util.lo
#   CC       zfeature_common.lo
#   CC       zfs_comutil.lo
#   CC       zfs_deleg.lo
#   CC       zfs_fletcher.lo
#   CC       zfs_fletcher_aarch64_neon.lo
#   CC       zfs_fletcher_avx512.lo
#   CC       zfs_fletcher_intel.lo
#   CC       zfs_fletcher_sse.lo
#   CC       zfs_fletcher_superscalar.lo
#   CC       zfs_fletcher_superscalar4.lo
#   CC       zfs_namecheck.lo
#   CC       zfs_prop.lo
#   CC       zpool_prop.lo
#   CC       zprop_common.lo
#   CC       abd.lo
#   CC       abd_os.lo
#   CC       aggsum.lo
#   CC       arc.lo
#   CC       arc_os.lo
#   CC       blkptr.lo
#   CC       bplist.lo
#   CC       bpobj.lo
#   CC       bptree.lo
#   CC       btree.lo
#   CC       bqueue.lo
#   CC       cityhash.lo
#   CC       dbuf.lo
#   CC       dbuf_stats.lo
#   CC       ddt.lo
#   CC       ddt_zap.lo
#   CC       dmu.lo
#   CC       dmu_diff.lo
#   CC       dmu_object.lo
#   CC       dmu_objset.lo
#   CC       dmu_recv.lo
#   CC       dmu_redact.lo
#   CC       dmu_send.lo
#   CC       dmu_traverse.lo
#   CC       dmu_tx.lo
#   CC       dmu_zfetch.lo
#   CC       dnode.lo
#   CC       dnode_sync.lo
#   CC       dsl_bookmark.lo
#   CC       dsl_dataset.lo
#   CC       dsl_deadlist.lo
#   CC       dsl_deleg.lo
#   CC       dsl_dir.lo
#   CC       dsl_crypt.lo
#   CC       dsl_pool.lo
#   CC       dsl_prop.lo
#   CC       dsl_scan.lo
#   CC       dsl_synctask.lo
#   CC       dsl_destroy.lo
#   CC       dsl_userhold.lo
#   CC       edonr_zfs.lo
#   CC       hkdf.lo
#   CC       fm.lo
#   CC       gzip.lo
#   CC       lzjb.lo
#   CC       lz4.lo
#   CC       metaslab.lo
#   CC       mmp.lo
#   CC       multilist.lo
#   CC       objlist.lo
#   CC       pathname.lo
#   CC       range_tree.lo
#   CC       refcount.lo
#   CC       rrwlock.lo
#   CC       sa.lo
#   CC       sha256.lo
#   CC       skein_zfs.lo
#   CC       spa.lo
#   CC       spa_boot.lo
#   CC       spa_checkpoint.lo
#   CC       spa_config.lo
#   CC       spa_errlog.lo
#   CC       spa_history.lo
#   CC       spa_log_spacemap.lo
#   CC       spa_misc.lo
#   CC       spa_stats.lo
#   CC       space_map.lo
#   CC       space_reftree.lo
#   CC       txg.lo
#   CC       trace.lo
#   CC       uberblock.lo
#   CC       unique.lo
#   CC       vdev.lo
#   CC       vdev_cache.lo
#   CC       vdev_draid.lo
#   CC       vdev_draid_rand.lo
#   CC       vdev_file.lo
#   CC       vdev_indirect_births.lo
#   CC       vdev_indirect.lo
#   CC       vdev_indirect_mapping.lo
#   CC       vdev_initialize.lo
#   CC       vdev_label.lo
#   CC       vdev_mirror.lo
#   CC       vdev_missing.lo
#   CC       vdev_queue.lo
#   CC       vdev_raidz.lo
#   CC       vdev_raidz_math_aarch64_neon.lo
#   CC       vdev_raidz_math_aarch64_neonx2.lo
#   CC       vdev_raidz_math_avx2.lo
#   CC       vdev_raidz_math_avx512bw.lo
#   CC       vdev_raidz_math_avx512f.lo
#   CC       vdev_raidz_math.lo
#   CC       vdev_raidz_math_scalar.lo
#   CC       vdev_raidz_math_sse2.lo
#   CC       vdev_raidz_math_ssse3.lo
#   CC       vdev_raidz_math_powerpc_altivec.lo
#   CC       vdev_rebuild.lo
#   CC       vdev_removal.lo
#   CC       vdev_root.lo
#   CC       vdev_trim.lo
#   CC       zap.lo
#   CC       zap_leaf.lo
#   CC       zap_micro.lo
#   CC       zcp.lo
#   CC       zcp_get.lo
#   CC       zcp_global.lo
#   CC       zcp_iter.lo
#   CC       zcp_set.lo
#   CC       zcp_synctask.lo
#   CC       zfeature.lo
#   CC       zfs_byteswap.lo
#   CC       zfs_debug.lo
#   CC       zfs_fm.lo
#   CC       zfs_fuid.lo
#   CC       zfs_racct.lo
#   CC       zfs_sa.lo
#   CC       zfs_znode.lo
#   CC       zfs_ratelimit.lo
#   CC       zfs_rlock.lo
#   CC       zil.lo
#   CC       zio.lo
#   CC       zio_checksum.lo
#   CC       zio_compress.lo
#   CC       zio_crypt.lo
#   CC       zio_inject.lo
#   CC       zle.lo
#   CC       zrlock.lo
#   CC       zthr.lo
#   CC       lapi.lo
#   CC       lauxlib.lo
#   CC       lbaselib.lo
#   CC       lcode.lo
#   CC       lcompat.lo
#   CC       lcorolib.lo
#   CC       lctype.lo
#   CC       ldebug.lo
#   CC       ldo.lo
#   CC       lfunc.lo
#   CC       lgc.lo
#   CC       llex.lo
#   CC       lmem.lo
#   CC       lobject.lo
#   CC       lopcodes.lo
#   CC       lparser.lo
#   CC       lstate.lo
#   CC       lstring.lo
#   CC       lstrlib.lo
#   CC       ltable.lo
#   CC       ltablib.lo
#   CC       ltm.lo
#   CC       lvm.lo
#   CC       lzio.lo
#   CCLD     libzpool.la
# make[2]: Leaving directory '/zfs/lib/libzpool'
# Making check in libzfsbootenv
# make[2]: Entering directory '/zfs/lib/libzfsbootenv'
#   CC       lzbe_device.lo
#   CC       lzbe_pair.lo
#   CC       lzbe_util.lo
#   CCLD     libzfsbootenv.la
# make[2]: Leaving directory '/zfs/lib/libzfsbootenv'
# Making check in libnvpair
# make[2]: Entering directory '/zfs/lib/libnvpair'
# make[2]: Nothing to be done for 'check'.
# make[2]: Leaving directory '/zfs/lib/libnvpair'
# make[2]: Entering directory '/zfs/lib'
# make[2]: Nothing to be done for 'check-am'.
# make[2]: Leaving directory '/zfs/lib'
# make[1]: Leaving directory '/zfs/lib'
# Making check in tests
# make[1]: Entering directory '/zfs/tests'
# Making check in runfiles
# make[2]: Entering directory '/zfs/tests/runfiles'
# make[2]: Nothing to be done for 'check'.
# make[2]: Leaving directory '/zfs/tests/runfiles'
# Making check in test-runner
# make[2]: Entering directory '/zfs/tests/test-runner'
# Making check in bin
# make[3]: Entering directory '/zfs/tests/test-runner/bin'
#   GEN      test-runner.py
#   GEN      zts-report.py
# make[3]: Leaving directory '/zfs/tests/test-runner/bin'
# Making check in include
# make[3]: Entering directory '/zfs/tests/test-runner/include'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/tests/test-runner/include'
# Making check in man
# make[3]: Entering directory '/zfs/tests/test-runner/man'
# make[3]: Nothing to be done for 'check'.
# make[3]: Leaving directory '/zfs/tests/test-runner/man'
# make[3]: Entering directory '/zfs/tests/test-runner'
# make[3]: Nothing to be done for 'check-am'.
# make[3]: Leaving directory '/zfs/tests/test-runner'
# make[2]: Leaving directory '/zfs/tests/test-runner'
# Making check in zfs-tests
# make[2]: Entering directory '/zfs/tests/zfs-tests'
# Making check in cmd
# make[3]: Entering directory '/zfs/tests/zfs-tests/cmd'
# Making check in badsend
# make[4]: Entering directory '/zfs/tests/zfs-tests/cmd/badsend'
#   CC       badsend.o
#   CCLD     badsend
# clang: error: no such file or directory: '/zfs/lib/libzfs_core/.libs/libzfs_core.so'
# clang: error: no such file or directory: '/zfs/lib/libzfs/.libs/libzfs.so'
# clang: error: no such file or directory: '/zfs/lib/libnvpair/.libs/libnvpair.so'·
# make[4]: *** [Makefile:781: badsend] Error 1
# make[4]: Leaving directory '/zfs/tests/zfs-tests/cmd/badsend'
# make[3]: *** [Makefile:718: check-recursive] Error 1
# make[3]: Leaving directory '/zfs/tests/zfs-tests/cmd'
# make[2]: *** [Makefile:701: check-recursive] Error 1
# make[2]: Leaving directory '/zfs/tests/zfs-tests'
# make[1]: *** [Makefile:705: check-recursive] Error 1
# make[1]: Leaving directory '/zfs/tests'
# make: *** [Makefile:933: check-recursive] Error 1
