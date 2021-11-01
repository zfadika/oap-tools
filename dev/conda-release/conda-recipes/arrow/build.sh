#!/bin/bash

set -e
set -x
mkdir cpp/build
pushd cpp/build
export http_proxy=http://child-prc.intel.com:913
export https_proxy=http://child-prc.intel.com:913
EXTRA_CMAKE_ARGS=""

# Include g++'s system headers
if [ "$(uname)" == "Linux" ]; then
  SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
  EXTRA_CMAKE_ARGS=" -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"
fi

cmake \
    -DARROW_COMPUTE=ON \
    -DARROW_S3=ON \
    -DARROW_GANDIVA_JAVA=ON \
    -DARROW_GANDIVA=ON \
    -DARROW_PARQUET=ON \
    -DARROW_HDFS=ON \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_JNI=ON \
    -DARROW_DATASET=ON \
    -DARROW_WITH_PROTOBUF=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_ZSTD=OFF \
    -DARROW_WITH_BROTLI=OFF \
    -DARROW_WITH_ZLIB=OFF \
    -DARROW_WITH_FASTPFOR=ON \
    -DARROW_FILESYSTEM=ON \
    -DARROW_JSON=ON \
    -DARROW_CSV=ON \
    -DARROW_FLIGHT=OFF \
    -DARROW_JEMALLOC=ON \
    -DARROW_SIMD_LEVEL=AVX2 \
    -DARROW_RUNTIME_SIMD_LEVEL=MAX \
    -DARROW_PACKAGE_PREFIX=$PREFIX \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_RANLIB=${RANLIB} \
    -DLLVM_TOOLS_BINARY_DIR=$PREFIX/bin \
    -GNinja \
    ${EXTRA_CMAKE_ARGS} \
    ..
ninja install
popd
cd $PREFIX/lib/
ln -snf libarrow_dataset_jni.so.400 libarrow_dataset_jni.so
ln -snf libarrow_dataset.so.400 libarrow_dataset.so
ln -snf libarrow.so.400 libarrow.so