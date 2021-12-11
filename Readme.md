sudo docker build -t gdal_base:latest . 

sudo docker run -it -v "$(pwd)"/scripts:/io -v "$(pwd)"/wheelhouse:/wheelhouse -v /home/rene/dev/Fiona/:/app  gdal_base:latest /io/build-wheels.sh