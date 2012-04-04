#!/bin/bash

cd `dirname $BASH_SOURCE`/../..

# build quagga
wget http://www.quagga.net/download/quagga-0.99.20.tar.gz
tar xvf quagga-0.99.20.tar.gz
cd quagga-0.99.20/
CFLAGS="-fPIC -g" LDFLAGS=-pie ./configure --disable-shared --enable-static --disable-user --disable-group --disable-capabilities 
grep -v HAVE_CLOCK_MONOTONIC config.h >a
mv a config.h
grep -v HAVE_RUSAGE config.h >a
mv a config.h
make
mkdir -p ../build/sbin
/bin/cp -f zebra/zebra ../build/sbin/
/bin/cp -f ripd/ripd ../build/sbin/
/bin/cp -f ripngd/ripngd ../build/sbin/
/bin/cp -f ospfd/ospfd ../build/sbin/
/bin/cp -f ospf6d/ospf6d ../build/sbin/
/bin/cp -f bgpd/bgpd ../build/sbin/
cd ../

# build ping
wget http://www.skbuff.net/iputils/iputils-s20101006.tar.bz2
tar xfj iputils-s20101006.tar.bz2
cd iputils-s20101006
sed "s/CFLAGS+=/CFLAGS=/" Makefile > a
mv a Makefile

sed "s/__u32 flowlabel;/struct in6_pktinfo { \n struct in6_addr ipi6_addr;\n int             ipi6_ifindex;\n};\n__u32 flowlabel;/" ping6.c > a
mv a ping6.c

make CFLAGS="-fPIC -g" LDFLAGS=-pie
/bin/cp -f ping ../build/bin/
/bin/cp -f ping6 ../build/bin/
cd ..

# build elf-loader
hg clone http://code.nsnam.org/mathieu/elf-loader/
cd elf-loader
sed "s/'\/usr\/lib\/debug\/lib\/ld-2.10.1.so'/'\/usr\/lib\/debug\/lib\/ld-2.10.1.so',\n'\/usr\/lib\/debug\/lib\/ld-2.11.1.so'/" extract-system-config.py >a
mv a extract-system-config.py
chmod +x extract-system-config.py
ARCH=`uname -m`/ make clean
ARCH=`uname -m`/ make vdl-config.h
ARCH=`uname -m`/ make
cp ldso ../build/lib
cp libvdl.so ../build/lib
cd ..

# mod ns-3-dce (FIXME)
cd ns-3-dce
grep -v dce-zebra wscript > a
mv a wscript
grep -v point-layout wscript > a
mv a wscript
grep -v quagga-helper wscript > a
mv a wscript
./waf
./waf install
cd ..

# build ns-3-dce-quagga
cd ns-3-dce-quagga
cd ../
BASE=$PWD
LD_LIBRARY_PATH="$BASE/ns-3-dce-quagga/build/lib:$BASE/build/lib:$BASE/ns-3-dce/build/lib:$BASE/build/bin:$BASE/ns-3-dce/build/bin:."
PKG_CONFIG_PATH="$BASE/build/lib/pkgconfig"
PATH="$BASE/build/bin:$BASE/build/sbin:$BASE/ns-3-dce/build/bin_dce:$PATH"
DCE_PATH=$PATH
PYTHONPATH=$BASE/ns-3-dev/build/debug/bindings/python:$BASE/ns-3-dev/src/visualizer:$BASE/pybindgen-0.15.0.795:$BASE/build/lib/python2.6/site-packages/:$BASE/ns-3-dce
export LD_LIBRARY_PATH PKG_CONFIG_PATH PATH PYTHONPATH DCE_PATH
cd $BASE/ns-3-dce-quagga
rm -f ../build/include/ns3/quagga-helper.h 
cp ../ns-3-dce/helper/ipv4-dce-routing-helper.h  ../build/include/ns3/
grep -v quagga-helper.h ../build/include/ns3/dce-module.h > a
mv a ../build/include/ns3/dce-module.h 
echo "#include \"ipv4-dce-routing-helper.h\"" >> ../build/include/ns3/dce-module.h 
./waf configure --prefix=`pwd`/../build --verbose --enable-kernel-stack=`pwd`/../ns-3-linux
./waf
./waf install
echo Launch NS3TEST-DCE
./build/bin/ns3test-dce-quagga --verbose


