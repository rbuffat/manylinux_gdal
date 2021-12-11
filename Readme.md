# Build wheels

1. Build docker image

To build the docker image, run the following command in the directory with the Dockerfile.

`docker build -t gdal_base:latest .`


2. To build wheels using this docker image, run the following command in the same directory

`docker run -it -v "$(pwd)"/scripts:/io -v "$(pwd)"/wheelhouse:/wheelhouse -v /path/to/Fiona/:/app gdal_base:latest /io/build-wheels.sh`


# TODO:

Test created wheels
