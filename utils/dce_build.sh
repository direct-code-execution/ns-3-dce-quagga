#!/bin/bash

USE_KERNEL=NO
args=("$@")
NB=$#
for (( i=0;i<$NB;i++)); do
    if [ ${args[${i}]} = '-k' ]
    then
       USE_KERNEL=YES
       WGET=wget
    fi
done

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
mkdir -p ../ns-3-dce/build/bin_dce
/bin/cp -f zebra/zebra ../ns-3-dce/build/bin_dce
/bin/cp -f ripd/ripd ../ns-3-dce/build/bin_dce
/bin/cp -f ripngd/ripngd ../ns-3-dce/build/bin_dce
/bin/cp -f ospfd/ospfd ../ns-3-dce/build/bin_dce
/bin/cp -f ospf6d/ospf6d ../ns-3-dce/build/bin_dce
/bin/cp -f bgpd/bgpd ../ns-3-dce/build/bin_dce
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
hg clone http://202.249.37.8/ical/ns-3-dce-patches/
cd ns-3-dce
patch -p1 < ../ns-3-dce-patches/120406-dce-quagga-support.patch
./waf
./waf install
cd ..

# mod ns-3-linux (FIXME)
if [ "YES" == "$USE_KERNEL" ]
then

     hg clone http://202.249.37.8/ical/ns-3-linux-patches/
     cd ns-3-linux
     patch -p1 < ../ns-3-linux-patches/120406-linux-quagga-support.patch
     make clean
     rm -f config
     make config
     
     make
     cd ..
fi

# build ns-3-dce-quagga
cd ns-3-dce-quagga
if [ "YES" == "$USE_KERNEL" ]
then
    WAF_KERNEL=--enable-kernel-stack=`pwd`/../ns-3-linux
fi

. ../ns-3-dce/utils/setenv.sh
cd ../ns-3-dce-quagga
./waf configure --prefix=`pwd`/../build --verbose $WAF_KERNEL
./waf
./waf install
echo Launch NS3QUAGGATEST-DCE
./build/bin/ns3test-dce-quagga --verbose


