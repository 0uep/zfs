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
      build-essential:native \
      clang-$v \
      cpio \
      flex \
      kmod \
      libelf-dev \
      libssl-dev:native \
      lld-$v \
      llvm-$v \
      make \
      rsync

# Configure the Linux kernel with LLVM/Clang
RUN cd linux && \
      make -j $(nproc --all) defconfig prepare bindeb-pkg CC=clang-$v LLVM=-$v && \
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
# make[1]: Nothing to be done for 'check'.
# make[1]: Leaving directory '/zfs/include'
# Making check in tests/zfs-tests/tests
# make[1]: Entering directory '/zfs/tests/zfs-tests/tests'
#   GEN      functional/pyzfs/pyzfs_unittest.ksh
#   GEN      functional/pam/utilities.kshlib
# make[1]: Leaving directory '/zfs/tests/zfs-tests/tests'
# make[1]: Entering directory '/zfs'
#   CC       cmd/raidz_test/raidz_test-raidz_bench.o
#   CC       cmd/raidz_test/raidz_test-raidz_test.o
#   CC       lib/libzpool/libzpool_la-kernel.lo
#   CC       lib/libzpool/libzpool_la-taskq.lo
#   CC       lib/libzpool/libzpool_la-util.lo
#   CC       module/lua/libzpool_la-lapi.lo
#   CC       module/lua/libzpool_la-lauxlib.lo
#   CC       module/lua/libzpool_la-lbaselib.lo
#   CC       module/lua/libzpool_la-lcode.lo
#   CC       module/lua/libzpool_la-lcompat.lo
#   CC       module/lua/libzpool_la-lcorolib.lo
#   CC       module/lua/libzpool_la-lctype.lo
#   CC       module/lua/libzpool_la-ldebug.lo
#   CC       module/lua/libzpool_la-ldo.lo
#   CC       module/lua/libzpool_la-lfunc.lo
#   CC       module/lua/libzpool_la-lgc.lo
#   CC       module/lua/libzpool_la-llex.lo
#   CC       module/lua/libzpool_la-lmem.lo
#   CC       module/lua/libzpool_la-lobject.lo
#   CC       module/lua/libzpool_la-lopcodes.lo
#   CC       module/lua/libzpool_la-lparser.lo
#   CC       module/lua/libzpool_la-lstate.lo
#   CC       module/lua/libzpool_la-lstring.lo
#   CC       module/lua/libzpool_la-lstrlib.lo
#   CC       module/lua/libzpool_la-ltable.lo
#   CC       module/lua/libzpool_la-ltablib.lo
#   CC       module/lua/libzpool_la-ltm.lo
#   CC       module/lua/libzpool_la-lvm.lo
#   CC       module/lua/libzpool_la-lzio.lo
#   CC       module/os/linux/zfs/libzpool_la-abd_os.lo
#   CC       module/os/linux/zfs/libzpool_la-arc_os.lo
#   CC       module/os/linux/zfs/libzpool_la-trace.lo
#   CC       module/os/linux/zfs/libzpool_la-vdev_file.lo
#   CC       module/os/linux/zfs/libzpool_la-zfs_debug.lo
#   CC       module/os/linux/zfs/libzpool_la-zfs_racct.lo
#   CC       module/os/linux/zfs/libzpool_la-zfs_znode.lo
#   CC       module/os/linux/zfs/libzpool_la-zio_crypt.lo
#   CC       module/zcommon/libzpool_la-cityhash.lo
#   CC       module/zcommon/libzpool_la-zfeature_common.lo
#   CC       module/zcommon/libzpool_la-zfs_comutil.lo
#   CC       module/zcommon/libzpool_la-zfs_deleg.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher_aarch64_neon.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher_avx512.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher_intel.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher_sse.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher_superscalar.lo
#   CC       module/zcommon/libzpool_la-zfs_fletcher_superscalar4.lo
#   CC       module/zcommon/libzpool_la-zfs_namecheck.lo
#   CC       module/zcommon/libzpool_la-zfs_prop.lo
#   CC       module/zcommon/libzpool_la-zpool_prop.lo
#   CC       module/zcommon/libzpool_la-zprop_common.lo
#   CC       module/zfs/libzpool_la-abd.lo
#   CC       module/zfs/libzpool_la-aggsum.lo
#   CC       module/zfs/libzpool_la-arc.lo
#   CC       module/zfs/libzpool_la-blake3_zfs.lo
#   CC       module/zfs/libzpool_la-blkptr.lo
#   CC       module/zfs/libzpool_la-bplist.lo
#   CC       module/zfs/libzpool_la-bpobj.lo
#   CC       module/zfs/libzpool_la-bptree.lo
#   CC       module/zfs/libzpool_la-bqueue.lo
#   CC       module/zfs/libzpool_la-btree.lo
#   CC       module/zfs/libzpool_la-dbuf.lo
#   CC       module/zfs/libzpool_la-dbuf_stats.lo
#   CC       module/zfs/libzpool_la-ddt.lo
#   CC       module/zfs/libzpool_la-ddt_zap.lo
#   CC       module/zfs/libzpool_la-dmu.lo
#   CC       module/zfs/libzpool_la-dmu_diff.lo
#   CC       module/zfs/libzpool_la-dmu_object.lo
#   CC       module/zfs/libzpool_la-dmu_objset.lo
#   CC       module/zfs/libzpool_la-dmu_recv.lo
#   CC       module/zfs/libzpool_la-dmu_redact.lo
#   CC       module/zfs/libzpool_la-dmu_send.lo
#   CC       module/zfs/libzpool_la-dmu_traverse.lo
#   CC       module/zfs/libzpool_la-dmu_tx.lo
#   CC       module/zfs/libzpool_la-dmu_zfetch.lo
#   CC       module/zfs/libzpool_la-dnode.lo
#   CC       module/zfs/libzpool_la-dnode_sync.lo
#   CC       module/zfs/libzpool_la-dsl_bookmark.lo
#   CC       module/zfs/libzpool_la-dsl_crypt.lo
#   CC       module/zfs/libzpool_la-dsl_dataset.lo
#   CC       module/zfs/libzpool_la-dsl_deadlist.lo
#   CC       module/zfs/libzpool_la-dsl_deleg.lo
#   CC       module/zfs/libzpool_la-dsl_destroy.lo
#   CC       module/zfs/libzpool_la-dsl_dir.lo
#   CC       module/zfs/libzpool_la-dsl_pool.lo
#   CC       module/zfs/libzpool_la-dsl_prop.lo
#   CC       module/zfs/libzpool_la-dsl_scan.lo
#   CC       module/zfs/libzpool_la-dsl_synctask.lo
#   CC       module/zfs/libzpool_la-dsl_userhold.lo
#   CC       module/zfs/libzpool_la-edonr_zfs.lo
#   CC       module/zfs/libzpool_la-fm.lo
#   CC       module/zfs/libzpool_la-gzip.lo
#   CC       module/zfs/libzpool_la-hkdf.lo
#   CC       module/zfs/libzpool_la-lz4.lo
#   CC       module/zfs/libzpool_la-lz4_zfs.lo
#   CC       module/zfs/libzpool_la-lzjb.lo
#   CC       module/zfs/libzpool_la-metaslab.lo
#   CC       module/zfs/libzpool_la-mmp.lo
#   CC       module/zfs/libzpool_la-multilist.lo
#   CC       module/zfs/libzpool_la-objlist.lo
#   CC       module/zfs/libzpool_la-pathname.lo
#   CC       module/zfs/libzpool_la-range_tree.lo
#   CC       module/zfs/libzpool_la-refcount.lo
#   CC       module/zfs/libzpool_la-rrwlock.lo
#   CC       module/zfs/libzpool_la-sa.lo
#   CC       module/zfs/libzpool_la-sha256.lo
#   CC       module/zfs/libzpool_la-skein_zfs.lo
#   CC       module/zfs/libzpool_la-spa.lo
#   CC       module/zfs/libzpool_la-spa_checkpoint.lo
#   CC       module/zfs/libzpool_la-spa_config.lo
#   CC       module/zfs/libzpool_la-spa_errlog.lo
#   CC       module/zfs/libzpool_la-spa_history.lo
#   CC       module/zfs/libzpool_la-spa_log_spacemap.lo
#   CC       module/zfs/libzpool_la-spa_misc.lo
#   CC       module/zfs/libzpool_la-spa_stats.lo
#   CC       module/zfs/libzpool_la-space_map.lo
#   CC       module/zfs/libzpool_la-space_reftree.lo
#   CC       module/zfs/libzpool_la-txg.lo
#   CC       module/zfs/libzpool_la-uberblock.lo
#   CC       module/zfs/libzpool_la-unique.lo
#   CC       module/zfs/libzpool_la-vdev.lo
#   CC       module/zfs/libzpool_la-vdev_cache.lo
#   CC       module/zfs/libzpool_la-vdev_draid.lo
#   CC       module/zfs/libzpool_la-vdev_draid_rand.lo
#   CC       module/zfs/libzpool_la-vdev_indirect.lo
#   CC       module/zfs/libzpool_la-vdev_indirect_births.lo
#   CC       module/zfs/libzpool_la-vdev_indirect_mapping.lo
#   CC       module/zfs/libzpool_la-vdev_initialize.lo
#   CC       module/zfs/libzpool_la-vdev_label.lo
#   CC       module/zfs/libzpool_la-vdev_mirror.lo
#   CC       module/zfs/libzpool_la-vdev_missing.lo
#   CC       module/zfs/libzpool_la-vdev_queue.lo
#   CC       module/zfs/libzpool_la-vdev_raidz.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_aarch64_neon.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_aarch64_neonx2.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_avx2.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_avx512bw.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_avx512f.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_powerpc_altivec.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_scalar.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_sse2.lo
#   CC       module/zfs/libzpool_la-vdev_raidz_math_ssse3.lo
#   CC       module/zfs/libzpool_la-vdev_rebuild.lo
#   CC       module/zfs/libzpool_la-vdev_removal.lo
#   CC       module/zfs/libzpool_la-vdev_root.lo
#   CC       module/zfs/libzpool_la-vdev_trim.lo
#   CC       module/zfs/libzpool_la-zap.lo
#   CC       module/zfs/libzpool_la-zap_leaf.lo
#   CC       module/zfs/libzpool_la-zap_micro.lo
#   CC       module/zfs/libzpool_la-zcp.lo
#   CC       module/zfs/libzpool_la-zcp_get.lo
#   CC       module/zfs/libzpool_la-zcp_global.lo
#   CC       module/zfs/libzpool_la-zcp_iter.lo
#   CC       module/zfs/libzpool_la-zcp_set.lo
#   CC       module/zfs/libzpool_la-zcp_synctask.lo
#   CC       module/zfs/libzpool_la-zfeature.lo
#   CC       module/zfs/libzpool_la-zfs_byteswap.lo
#   CC       module/zfs/libzpool_la-zfs_chksum.lo
#   CC       module/zfs/libzpool_la-zfs_fm.lo
#   CC       module/zfs/libzpool_la-zfs_fuid.lo
#   CC       module/zfs/libzpool_la-zfs_ratelimit.lo
#   CC       module/zfs/libzpool_la-zfs_rlock.lo
#   CC       module/zfs/libzpool_la-zfs_sa.lo
#   CC       module/zfs/libzpool_la-zil.lo
#   CC       module/zfs/libzpool_la-zio.lo
#   CC       module/zfs/libzpool_la-zio_checksum.lo
#   CC       module/zfs/libzpool_la-zio_compress.lo
#   CC       module/zfs/libzpool_la-zio_inject.lo
#   CC       module/zfs/libzpool_la-zle.lo
#   CC       module/zfs/libzpool_la-zrlock.lo
#   CC       module/zfs/libzpool_la-zthr.lo
#   CC       module/icp/spi/libicp_la-kcf_spi.lo
#   CC       module/icp/api/libicp_la-kcf_ctxops.lo
#   CC       module/icp/api/libicp_la-kcf_cipher.lo
#   CC       module/icp/api/libicp_la-kcf_mac.lo
#   CC       module/icp/algs/aes/libicp_la-aes_impl_aesni.lo
#   CC       module/icp/algs/aes/libicp_la-aes_impl_generic.lo
#   CC       module/icp/algs/aes/libicp_la-aes_impl_x86-64.lo
#   CC       module/icp/algs/aes/libicp_la-aes_impl.lo
#   CC       module/icp/algs/aes/libicp_la-aes_modes.lo
#   CC       module/icp/algs/blake3/libicp_la-blake3.lo
#   CC       module/icp/algs/blake3/libicp_la-blake3_generic.lo
#   CC       module/icp/algs/blake3/libicp_la-blake3_impl.lo
#   CC       module/icp/algs/blake3/libicp_la-blake3_x86-64.lo
#   CC       module/icp/algs/edonr/libicp_la-edonr.lo
#   CC       module/icp/algs/modes/libicp_la-modes.lo
#   CC       module/icp/algs/modes/libicp_la-cbc.lo
#   CC       module/icp/algs/modes/libicp_la-gcm_generic.lo
#   CC       module/icp/algs/modes/libicp_la-gcm_pclmulqdq.lo
#   CC       module/icp/algs/modes/libicp_la-gcm.lo
#   CC       module/icp/algs/modes/libicp_la-ctr.lo
#   CC       module/icp/algs/modes/libicp_la-ccm.lo
#   CC       module/icp/algs/modes/libicp_la-ecb.lo
#   CC       module/icp/algs/sha2/libicp_la-sha2.lo
#   CC       module/icp/algs/skein/libicp_la-skein.lo
#   CC       module/icp/algs/skein/libicp_la-skein_block.lo
#   CC       module/icp/algs/skein/libicp_la-skein_iv.lo
#   CC       module/icp/libicp_la-illumos-crypto.lo
#   CC       module/icp/io/libicp_la-aes.lo
#   CC       module/icp/io/libicp_la-sha2_mod.lo
#   CC       module/icp/io/libicp_la-skein_mod.lo
#   CC       module/icp/core/libicp_la-kcf_sched.lo
#   CC       module/icp/core/libicp_la-kcf_prov_lib.lo
#   CC       module/icp/core/libicp_la-kcf_callprov.lo
#   CC       module/icp/core/libicp_la-kcf_mech_tabs.lo
#   CC       module/icp/core/libicp_la-kcf_prov_tabs.lo
#   CC       module/icp/asm-x86_64/aes/libicp_la-aeskey.lo
#   CPPAS    module/icp/asm-x86_64/aes/libicp_la-aes_amd64.lo
#   CPPAS    module/icp/asm-x86_64/aes/libicp_la-aes_aesni.lo
#   CPPAS    module/icp/asm-x86_64/modes/libicp_la-gcm_pclmulqdq.lo
#   CPPAS    module/icp/asm-x86_64/modes/libicp_la-aesni-gcm-x86_64.lo
#   CPPAS    module/icp/asm-x86_64/modes/libicp_la-ghash-x86_64.lo
#   CPPAS    module/icp/asm-x86_64/sha2/libicp_la-sha256_impl.lo
#   CPPAS    module/icp/asm-x86_64/sha2/libicp_la-sha512_impl.lo
#   CPPAS    module/icp/asm-x86_64/blake3/libicp_la-blake3_avx2.lo
#   CPPAS    module/icp/asm-x86_64/blake3/libicp_la-blake3_avx512.lo
#   CPPAS    module/icp/asm-x86_64/blake3/libicp_la-blake3_sse2.lo
#   CPPAS    module/icp/asm-x86_64/blake3/libicp_la-blake3_sse41.lo
#   CCLD     libicp.la
# copying selected object files to avoid basename conflicts...
#   CC       module/unicode/libunicode_la-u8_textprep.lo
#   CC       module/unicode/libunicode_la-uconv.lo
#   CCLD     libunicode.la
#   CC       lib/libnvpair/libnvpair_la-libnvpair.lo
#   CC       lib/libnvpair/libnvpair_la-libnvpair_json.lo
#   CC       lib/libnvpair/libnvpair_la-nvpair_alloc_system.lo
#   CC       module/nvpair/libnvpair_la-nvpair_alloc_fixed.lo
#   CC       module/nvpair/libnvpair_la-nvpair.lo
#   CC       module/nvpair/libnvpair_la-fnvpair.lo
#   CC       lib/libspl/libspl_assert_la-assert.lo
#   CCLD     libspl_assert.la
#   CCLD     libnvpair.la
#   CC       module/zstd/lib/common/libzstd_la-entropy_common.lo
#   CC       module/zstd/lib/common/libzstd_la-error_private.lo
#   CC       module/zstd/lib/common/libzstd_la-fse_decompress.lo
#   CC       module/zstd/lib/common/libzstd_la-pool.lo
#   CC       module/zstd/lib/common/libzstd_la-zstd_common.lo
#   CC       module/zstd/lib/compress/libzstd_la-fse_compress.lo
#   CC       module/zstd/lib/compress/libzstd_la-hist.lo
#   CC       module/zstd/lib/compress/libzstd_la-huf_compress.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_compress_literals.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_compress_sequences.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_compress_superblock.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_compress.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_double_fast.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_fast.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_lazy.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_ldm.lo
#   CC       module/zstd/lib/compress/libzstd_la-zstd_opt.lo
#   CC       module/zstd/lib/decompress/libzstd_la-huf_decompress.lo
#   CC       module/zstd/lib/decompress/libzstd_la-zstd_ddict.lo
#   CC       module/zstd/lib/decompress/libzstd_la-zstd_decompress.lo
#   CC       module/zstd/lib/decompress/libzstd_la-zstd_decompress_block.lo
#   CC       module/zstd/libzstd_la-zfs_zstd.lo
#   CCLD     libzstd.la
#   CC       lib/libzutil/libzutil_la-zutil_device_path.lo
#   CC       lib/libzutil/libzutil_la-zutil_import.lo
#   CC       lib/libzutil/libzutil_la-zutil_nicenum.lo
#   CC       lib/libzutil/libzutil_la-zutil_pool.lo
#   CC       lib/libzutil/os/linux/libzutil_la-zutil_setproctitle.lo
#   CC       lib/libzutil/os/linux/libzutil_la-zutil_device_path_os.lo
#   CC       lib/libzutil/os/linux/libzutil_la-zutil_import_os.lo
#   CC       module/avl/libavl_la-avl.lo
#   CCLD     libavl.la
#   CC       lib/libtpool/libtpool_la-thread_pool.lo
#   CCLD     libtpool.la
#   CC       lib/libspl/libspl_la-atomic.lo
#   CC       lib/libspl/libspl_la-getexecname.lo
#   CC       lib/libspl/libspl_la-list.lo
#   CC       lib/libspl/libspl_la-mkdirp.lo
#   CC       lib/libspl/libspl_la-page.lo
#   CC       lib/libspl/libspl_la-strlcat.lo
#   CC       lib/libspl/libspl_la-strlcpy.lo
#   CC       lib/libspl/libspl_la-timestamp.lo
#   CC       lib/libspl/os/linux/libspl_la-getexecname.lo
#   CC       lib/libspl/os/linux/libspl_la-gethostid.lo
#   CC       lib/libspl/os/linux/libspl_la-getmntany.lo
#   CC       lib/libspl/os/linux/libspl_la-zone.lo
#   CCLD     libspl.la
# copying selected object files to avoid basename conflicts...
#   CC       lib/libefi/libefi_la-rdwr_efi.lo
#   CCLD     libefi.la
#   CCLD     libzutil.la
#   CCLD     libzpool.la
#   CC       lib/libzfs_core/libzfs_core_la-libzfs_core.lo
#   CC       lib/libzfs_core/os/linux/libzfs_core_la-libzfs_core_ioctl.lo
#   CCLD     libzfs_core.la
#   CCLD     raidz_test
# clang: error: no such file or directory: './.libs/libzpool.so'
# clang: error: no such file or directory: './.libs/libzfs_core.so'
# make[1]: *** [Makefile:6423: raidz_test] Error 1
# make[1]: Leaving directory '/zfs'
# make: *** [Makefile:11899: check-recursive] Error 1