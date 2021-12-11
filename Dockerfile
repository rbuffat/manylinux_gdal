# Inspired by https://github.com/OSGeo/gdal/blob/master/docker/ubuntu-small/Dockerfile

FROM quay.io/pypa/manylinux_2_24_x86_64:latest

ARG GDAL_VERSION=3.4.0
ARG PROJ_VERSION=8.2.0
ARG GEOS_VERSION=3.10.1
ARG SQLITE_VERSION=3370000
ARG SQLITE_YEAR=2021
ARG EXPAT_VERSION=2.4.1
ARG EXPAT_VERSION_=2_4_1
ARG OPENSSL_VERSION=1.1.1l
ARG CURL_VERSION=7.80.0
ARG NGHTTP2_VERSION=1.46.0
ARG JSONC_VERSION=0.15
ARG OPENJPEG_VERSION=2.4.0
ARG ZSTD_VERSION=1.5.0

ARG BUILD_PREFIX=/extralibs
ARG CPU=16

ENV PATH="${BUILD_PREFIX}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${BUILD_PREFIX}/lib:${LD_LIBRARY_PATH}"
ENV LD_RUN_PAT="${BUILD_PREFIX}/lib:${LD_RUN_PATH}"
ENV CFLAGS="${CFLAGS} -g -O2"
ENV CXXFLAGS="$CXXFLAGS -g -O2"

# Install required apt packages
RUN apt-get update -y && apt-get install -y wget build-essential pkg-config libtiff5-dev libcurl4-openssl-dev cmake libpsl-dev && apt-get remove -y libcurl4-openssl-dev curl openssl

# Install openssl
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -xzf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ls -l \
    && ./config --prefix=${BUILD_PREFIX} \
    && make -j ${CPU} \
    && make install

# Install nghttp2
RUN wget -q https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz \
    && tar -xzf nghttp2-${NGHTTP2_VERSION}.tar.gz \
    && cd nghttp2-${NGHTTP2_VERSION} \
    && ./configure --enable-lib-only --prefix=${BUILD_PREFIX} \
    && make -j ${CPU} \
    && make install

# Install curl
RUN wget -q https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz \
    && tar -xzf curl-${CURL_VERSION}.tar.gz \
    && cd curl-${CURL_VERSION} \
    && ./configure --with-nghttp2=$BUILD_PREFIX --with-openssl=${BUILD_PREFIX} --prefix=${BUILD_PREFIX} \
    && make -j ${CPU} \
    && make install

# Install geos
RUN wget -q http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 \
    && tar xfj geos-${GEOS_VERSION}.tar.bz2 \
    && cd geos-${GEOS_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -j ${CPU} \
    && make install

# Install jsonc
RUN wget -q https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSONC_VERSION}.tar.gz \
    && tar -xzf json-c-${JSONC_VERSION}.tar.gz \
    && mkdir json-c-build \
    && cd json-c-build \
    && cmake -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} ../json-c-${JSONC_VERSION} \
    && make -j ${CPU} \
    && make install

# Install expat
RUN wget -q https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION_}/expat-${EXPAT_VERSION}.tar.gz \
    && tar -xzf expat-${EXPAT_VERSION}.tar.gz \
    && cd expat-${EXPAT_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -j ${CPU} \
    && make install

# Install SQLite3
RUN wget -q https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && tar -xzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && cd sqlite-autoconf-${SQLITE_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX} \
    && make -j ${CPU} \
    && make install

# # Install proj-datumgrid
# RUN wget -q http://download.osgeo.org/proj/proj-datumgrid-latest.zip \
#     && mkdir -p {BUILD_PREFIX}/share/proj \
#     && unzip -q -j -u -o proj-datumgrid-latest.zip -d {BUILD_PREFIX}/share/proj

# Install PROJ
RUN wget -q https://github.com/OSGeo/PROJ/releases/download/${PROJ_VERSION}/proj-${PROJ_VERSION}.tar.gz \
    && tar -xzf proj-${PROJ_VERSION}.tar.gz \
    && cd proj-${PROJ_VERSION} \
    && ls -l \
    && cmake . -DCMAKE_INSTALL_PREFIX=${BUILD_PREFIX} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF\
    && make -j ${CPU} \
    && make install

# Install gdal
RUN wget -q http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
    && tar -xzf gdal-${GDAL_VERSION}.tar.gz \ 
    && cd gdal-${GDAL_VERSION} \ 
    && ./configure \
    --with-crypto=yes \
    --with-hide-internal-symbols \
    --disable-debug \
    --disable-static \
    --disable-driver-elastic \
    --prefix=$BUILD_PREFIX \
    --with-curl=curl-config \
    --with-expat=${BUILD_PREFIX} \
    --with-geos=${BUILD_PREFIX}/bin/geos-config \
    --with-geotiff=internal \
    --with-gif \
    --with-jpeg \
    --with-libiconv-prefix=/usr \
    --with-libjson-c=${BUILD_PREFIX} \
    --with-libtiff=internal \
    --with-libz=/usr \
    --with-pam \
    --with-png \
    --with-proj=${BUILD_PREFIX} \
    --with-sqlite3=${BUILD_PREFIX} \
    --with-threads \
    --without-bsb \
    --without-cfitsio \
    --without-dwgdirect \
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
    --without-mrf \
    --without-mrsid \
    --without-mysql \
    --without-odbc \
    --without-ogdi \
    --without-pcidsk \
    --without-pcraster \
    --without-perl \
    --without-pg \
    --without-php \
    --without-python \
    --without-qhull \
    --without-sde \
    --without-xerces \
    --without-xml2 \
    && make -j ${CPU} \
    && make install

RUN strip -v --strip-unneeded ${BUILD_PREFIX}/lib/*.so.*