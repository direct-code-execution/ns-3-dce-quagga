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

QUAGGA_FILE_TGZ=quagga-0.99.20.tar.gz
IPUTILS_FILE_TBZ=iputils-s20101006.tar.bz2

# build quagga
if [ ! -f  $QUAGGA_FILE_TGZ ] ; then
    wget http://www.quagga.net/download/$QUAGGA_FILE_TGZ \
	|| { echo "[Error] wget $QUAGGA_FILE_TGZ" ; exit 1 ; }
fi
tar xfz $QUAGGA_FILE_TGZ
cd quagga-0.99.20/
CFLAGS="-fPIC -g" LDFLAGS=-pie ./configure --disable-shared --enable-static --disable-user --disable-group --disable-capabilities \
    || { echo "[Error] quagga configure" ; exit 1 ; }
grep -v HAVE_CLOCK_MONOTONIC config.h >a
mv a config.h
grep -v HAVE_RUSAGE config.h >a
mv a config.h
make || { echo "[Error] quagga make" ; exit 1 ; }
mkdir -p ../ns-3-dce/build/bin_dce
/bin/cp -f zebra/zebra ../ns-3-dce/build/bin_dce
/bin/cp -f ripd/ripd ../ns-3-dce/build/bin_dce
/bin/cp -f ripngd/ripngd ../ns-3-dce/build/bin_dce
/bin/cp -f ospfd/ospfd ../ns-3-dce/build/bin_dce
/bin/cp -f ospf6d/ospf6d ../ns-3-dce/build/bin_dce
/bin/cp -f bgpd/bgpd ../ns-3-dce/build/bin_dce
cd ../

# build ping
if [ ! -f  $IPUTILS_FILE_TBZ ] ; then
    wget http://www.skbuff.net/iputils/$IPUTILS_FILE_TBZ \
	|| { echo "[Error] wget $IPUTILS_FILE_TBZ" ; exit 1 ; }
fi
tar xfj $IPUTILS_FILE_TBZ
cd iputils-s20101006

sed "s/CFLAGS+=/CFLAGS=/" Makefile > a
mv a Makefile
sed "s/__u32 flowlabel;/struct in6_pktinfo { \n struct in6_addr ipi6_addr;\n int             ipi6_ifindex;\n};\n__u32 flowlabel;/" ping6.c > a
mv a ping6.c
make CFLAGS="-fPIC -g" LDFLAGS=-pie \
	|| { echo "[Error] ping/ping6 make" ; exit 1 ; }
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
ARCH=`uname -m`/ make \
	|| { echo "[Error] elf-loader make" ; exit 1 ; }
cp ldso ../build/lib
cp libvdl.so ../build/lib
cd ..

# build ns-3-dce-quagga
cd ns-3-dce-quagga
if [ "YES" == "$USE_KERNEL" ]
then
    WAF_KERNEL=--enable-kernel-stack=`pwd`/../ns-3-linux
fi

. ../ns-3-dce/utils/setenv.sh
cd ../ns-3-dce-quagga
./waf configure --prefix=`pwd`/../build $WAF_KERNEL \
	|| { echo "[Error] ns-3-dce-quagga waf configure" ; exit 1 ; }
./waf \
	|| { echo "[Error] ns-3-dce-quagga waf make" ; exit 1 ; }
./waf install
echo Launch NS3QUAGGATEST-DCE
./build/bin/ns3test-dce-quagga --verbose


