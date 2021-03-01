FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update ;  apt-get -y upgrade
RUN apt-get -y install git libboost1.71-all-dev build-essential cmake rtl-sdr
RUN git clone https://github.com/baol/waving-z
RUN cd waving-z/ ; mkdir build ; cd build ; cmake .. -DCMAKE_BUILD_TYPE=Release ; cmake --build .

ENTRYPOINT ["/entrypoint/entrypoint.sh"]
