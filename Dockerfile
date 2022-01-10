# Inspired by https://github.com/OSGeo/gdal/blob/master/docker/ubuntu-small/Dockerfile

FROM quay.io/pypa/manylinux_2_24_x86_64:latest as build_base

ARG GDAL_VERSION=3.4.1
ARG PROJ_VERSION=8.2.1
ARG GEOS_VERSION=3.10.1
ARG SQLITE_VERSION=3370200
ARG SQLITE_YEAR=2022
ARG EXPAT_VERSION=2.4.1
ARG EXPAT_VERSION_=2_4_1
# proj 8.2.0 seems to have problems with Openssl 3.0.0
ARG OPENSSL_VERSION=1.1.1m
ARG CURL_VERSION=7.80.0
ARG NGHTTP2_VERSION=1.46.0
ARG JSONC_VERSION=0.15
ARG JPEG_VERSION=9d
ARG OPENJPEG_VERSION=2.4.0
ARG ZSTD_VERSION=1.5.1
ARG TIFF_VERSION=4.3.0
ARG ZLIB_VERSION=1.2.11
ARG LCMS2_VERSION=2.12
ARG LIBWEBP_VERSION=1.2.1
ARG LIBPNG_VERSION=1.6.37
ARG LIBACE_VERSION=1.0.6
# HDF5 1.13.0 has issues with gdal 3.4.1: https://github.com/OSGeo/gdal/issues/5061 
ARG HDF5_VERSION=1.12.1
ARG NETCDF_VERSION=4.8.1

ARG BUILD_PREFIX=/extralibs
ARG CPU=16

ENV PATH="${BUILD_PREFIX}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${BUILD_PREFIX}/lib:${LD_LIBRARY_PATH}"
ENV LD_RUN_PAT="${BUILD_PREFIX}/lib:${LD_RUN_PATH}"
ENV CFLAGS="${CFLAGS} -g -O3"
ENV CXXFLAGS="$CXXFLAGS -g -O3"

# Install required apt packages
RUN apt-get update -y && apt-get install -y wget build-essential pkg-config cmake && apt-get remove -y libcurl4-openssl-dev curl openssl

# Install zlib
RUN wget -q https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
    && tar -xzf zlib-${ZLIB_VERSION}.tar.gz \
    && cd zlib-${ZLIB_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf zlib-${ZLIB_VERSION}*


# Install openssl
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -xzf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./config --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf openssl-${OPENSSL_VERSION}*

# Install nghttp2
RUN wget -q https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz \
    && tar -xzf nghttp2-${NGHTTP2_VERSION}.tar.gz \
    && cd nghttp2-${NGHTTP2_VERSION} \
    && ./configure --enable-lib-only --disable-examples --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf nghttp2-${NGHTTP2_VERSION}*

# Install curl
RUN wget -q https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz \
    && tar -xzf curl-${CURL_VERSION}.tar.gz \
    && cd curl-${CURL_VERSION} \
    && ./configure --with-nghttp2=${BUILD_PREFIX} --with-openssl=${BUILD_PREFIX} --disable-ldap --disable-ldaps --disable-manual --enable-ipv6 --enable-versioned-symbols --enable-threaded-resolver --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf curl-${CURL_VERSION}*

# Install jsonc
RUN wget -q https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSONC_VERSION}.tar.gz \
    && tar -xzf json-c-${JSONC_VERSION}.tar.gz \
    && mkdir json-c-build \
    && cd json-c-build \
    && cmake -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} ../json-c-${JSONC_VERSION} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf json-c*

# Install expat
RUN wget -q https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION_}/expat-${EXPAT_VERSION}.tar.gz \
    && tar -xzf expat-${EXPAT_VERSION}.tar.gz \
    && cd expat-${EXPAT_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf expat-${EXPAT_VERSION}*

# Install SQLite3
RUN wget -q https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && tar -xzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && cd sqlite-autoconf-${SQLITE_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} --enable-rtree --disable-static \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf sqlite-autoconf-${SQLITE_VERSION}*

# Install zstd
# GDAL 3.4.1 requires -DZSTD_LEGACY_SUPPORT=ON
# TODO What does SED_ERE_OPT do?
RUN wget -q https://github.com/facebook/zstd/archive/v${ZSTD_VERSION}.tar.gz \
    && tar -xzf v${ZSTD_VERSION}.tar.gz \
    && mkdir zstd-build \
    && cd zstd-build \
    && cmake -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} -DZSTD_LEGACY_SUPPORT=0 ../zstd-${ZSTD_VERSION}/build/cmake \
    && make -s -j ${CPU} \
    && make install SED_ERE_OPT="-r" \
    && cd .. && rm -rf zstd* && rm v${ZSTD_VERSION}.tar.gz

# Install lcms2
RUN wget -q https://sourceforge.net/projects/lcms/files/lcms/${LCMS2_VERSION}/lcms2-${LCMS2_VERSION}.tar.gz \
    && tar -xzf lcms2-${LCMS2_VERSION}.tar.gz \
    && cd lcms2-${LCMS2_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf lcms2-${LCMS2_VERSION}*

# Install libtiff
RUN wget -q http://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz \
    && tar -xzf tiff-${TIFF_VERSION}.tar.gz \
    && cd tiff-${TIFF_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf tiff-${TIFF_VERSION}*

# Install libpng
# requires zlib
RUN wget -q http://prdownloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz \
    && tar -xzf libpng-${LIBPNG_VERSION}.tar.gz \
    && cd libpng-${LIBPNG_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf libpng-${LIBPNG_VERSION}*

# Install libwebp
# Requires libjpeg, libtiff, libgif
RUN wget -q https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${LIBWEBP_VERSION}.tar.gz \
    && tar -xzf libwebp-${LIBWEBP_VERSION}.tar.gz \
    && cd libwebp-${LIBWEBP_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf libwebp-${LIBWEBP_VERSION}*

# Install jpeg
RUN wget -q http://ijg.org/files/jpegsrc.v${JPEG_VERSION}.tar.gz \
    && tar -xzf jpegsrc.v${JPEG_VERSION}.tar.gz \
    && cd jpeg-${JPEG_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf jpeg*

# Install openjpeg
RUN wget -q https://github.com/uclouvain/openjpeg/archive/refs/tags/v${OPENJPEG_VERSION}.tar.gz \
    && tar -xzf v${OPENJPEG_VERSION}.tar.gz \
    && mkdir openjpeg-build \
    && cd openjpeg-build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF -DBUILD_DOC=off ../openjpeg-${OPENJPEG_VERSION} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf openjpeg* && rm v${OPENJPEG_VERSION}.tar.gz

# Install libace
RUN wget -q https://gitlab.dkrz.de/k202009/libaec/-/archive/v${LIBACE_VERSION}/libaec-v${LIBACE_VERSION}.tar.gz \
    && tar -xzf libaec-v${LIBACE_VERSION}.tar.gz \
    && mkdir libaec-build \
    && cd libaec-build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} ../libaec-v${LIBACE_VERSION} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf libaec*

# Install hdf5
RUN wget -q https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(echo $HDF5_VERSION | awk -F "." '{printf "%d.%d", $1, $2}')/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz \
    && tar -xzf hdf5-${HDF5_VERSION}.tar.gz \
    && cd hdf5-${HDF5_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} --with-szlib=${BUILD_PREFIX} --enable-shared --enable-build-mode=production \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf hdf5*

# Install netcdf
# Requires hdf5, curl
RUN wget -q https://github.com/Unidata/netcdf-c/archive/v${NETCDF_VERSION}.tar.gz \
    && tar -xzf v${NETCDF_VERSION}.tar.gz \
    && mkdir netcdf-build \
    && cd netcdf-build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} ../netcdf-c-${NETCDF_VERSION} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf netcdf* && rm v${NETCDF_VERSION}.tar.gz

# Install geos
RUN wget -q http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 \
    && tar xfj geos-${GEOS_VERSION}.tar.bz2 \
    && mkdir geos-build \
    && cd geos-build \
    && cmake -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} -DCMAKE_BUILD_TYPE=Release -DBUILD_DOCUMENTATION=OFF ../geos-${GEOS_VERSION} \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf geos-*

# # Install proj-datumgrid
# RUN wget -q http://download.osgeo.org/proj/proj-datumgrid-latest.zip \
#     && mkdir -p {BUILD_PREFIX}/share/proj \
#     && unzip -q -j -u -o proj-datumgrid-latest.zip -d {BUILD_PREFIX}/share/proj

# Install PROJ
# 
# TODO GDAL Dockerfile
# export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2 -g"
# export CXXFLAGS="-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -g"

RUN wget -q https://github.com/OSGeo/PROJ/releases/download/${PROJ_VERSION}/proj-${PROJ_VERSION}.tar.gz \
    && tar -xzf proj-${PROJ_VERSION}.tar.gz \
    && cd proj-${PROJ_VERSION} \
    && cmake . -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF\
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf proj-${PROJ_VERSION}*

# Install gdal
RUN wget -q http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
    && tar -xzf gdal-${GDAL_VERSION}.tar.gz \
    && cd gdal-${GDAL_VERSION} \ 
    && ./configure \
    --with-crypto=yes \
    --with-hide-internal-symbols \
    --with-webp=${BUILD_PREFIX} \
    --disable-debug \
    --disable-static \
    --disable-driver-elastic \
    --prefix=${BUILD_PREFIX} \
    --with-curl=curl-config \
    --with-expat=${BUILD_PREFIX} \
    --with-geos=${BUILD_PREFIX}/bin/geos-config \
    --with-geotiff=internal --with-rename-internal-libgeotiff-symbols \
    --with-gif \
    # --with-grib \
    --with-jpeg \
    --with-libiconv-prefix=/usr \
    --with-libjson-c=${BUILD_PREFIX} \
    --with-libtiff=${BUILD_PREFIX} \
    --with-libz=/usr \
    --with-netcdf=${BUILD_PREFIX} \
    --with-openjpeg \
    --with-pam \
    --with-png \
    --with-proj=${BUILD_PREFIX} \
    --with-sqlite3=${BUILD_PREFIX} \
    --with-zstd=${BUILD_PREFIX} \
    --with-threads \
    # --without-bsb \
    --without-cfitsio \
    # --without-dwgdirect \
    --without-ecw \
    --without-fme \
    --without-freexl \
    --without-gnm \
    --without-grass \
    --without-ingres \
    --without-jasper \
    --without-jp2mrsid \
    --without-jpeg12 \
    --without-kakadu \
    --without-libgrass \
    --without-libkml \
    # --without-mrf \
    --without-mrsid \
    --with-spatialite \
    --without-mysql \
    --without-odbc \
    --without-ogdi \
    --without-pcidsk \
    --without-pcraster \
    --without-perl \
    --without-pg \
    # --without-php \
    --without-python \
    --without-qhull \
    # --without-sde \
    --without-sfcgal \
    --without-xerces \
    --without-xml2 \
    && make -s -j ${CPU} \
    && make install \
    && cd .. && rm -rf gdal-${GDAL_VERSION}*

RUN strip -v --strip-unneeded ${BUILD_PREFIX}/lib/*.so.*

FROM quay.io/pypa/manylinux_2_24_x86_64:latest
COPY --from=build_base /extralibs /extralibs
