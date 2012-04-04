#!/bin/bash

cd `dirname $BASH_SOURCE`/../..

# build quagga
wget http://www.quagga.net/download/quagga-0.99.20.tar.gz
tar xvf quagga-0.99.20.tar.gz
cd quagga-0.99.20/
CFLAGS="-fPIC -g" LDFLAGS=-pie ./configure --disable-shared --enable-static --disable-user --disable-group --disable-capabilities 
sed "s/HAVE_CLOCK_MONOTONIC/\/\/HAVE_CLOCK_MONOTONIC/ config.h >a
mv a config.h
sed "s/HAVE_RUSAGE/\/\/HAVE_RUSAGE/ config.h >a
mv a config.h
make
/bin/cp -f zebra/zebra ../build/sbin/
/bin/cp -f ripd/ripd ../build/sbin/
/bin/cp -f ripngd/ripngd ../build/sbin/
/bin/cp -f ospfd/ospfd ../build/sbin/
/bin/cp -f ospf6d/ospf6d ../build/sbin/
/bin/cp -f bgpd/bgpd ../build/sbin/
cd ../

# build ping
wget http://www.skbuff.net/iputils/iputils-s20101006.tar.bz2
cd iputils-s20101006
sed "s/CFLAGS+=/CFLAGS=/" Makefile > a
mv a Makefile
make CFLAGS="-fPIC -g" LDFLAGS=-pie
/bin/cp -f ping ../build/bin/
/bin/cp -f ping6 ../build/bin/
cd ..

# build ns-3-dce-quagga
cd ns-3-dce-quagga
./waf configure --prefix=`pwd`/../build --verbose --enable-kernel-stack=`pwd`/../ns-3-linux
./waf
./waf install
export LD_LIBRARY_PATH=$SAVE_LDLP:`pwd`/build/lib:`pwd`/build/bin:`pwd`/../build/lib
. utils/setenv.sh
echo Launch NS3TEST-DCE
./build/bin/ns3test-dce-quagga --verbose


