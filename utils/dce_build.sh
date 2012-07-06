#!/bin/bash

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
sed "s/arping: arping.o -lsysfs/arping: arping.o\narping: LDLIBS = -lsysfs/" Makefile > a
mv a Makefile
if ! grep -qs in6_pktinfo /usr/include/netinet/in.h ; then
  sed "s/__u32 flowlabel;/struct in6_pktinfo { \n struct in6_addr ipi6_addr;\n int             ipi6_ifindex;\n};\n__u32 flowlabel;/" ping6.c > a
  mv a ping6.c
fi
make CFLAGS="-fPIC -g -D_GNU_SOURCE -Wstrict-prototypes -Wall" LDFLAGS=-pie \
	|| { echo "[Error] ping/ping6 make" ; exit 1 ; }
/bin/cp -f ping ../build/bin/
/bin/cp -f ping6 ../build/bin/
cd ..

# build ns-3-dce-quagga
cd ns-3-dce-quagga
. ../ns-3-dce/utils/setenv.sh
cd ../ns-3-dce-quagga
./waf configure --prefix=`pwd`/../build \
	|| { echo "[Error] ns-3-dce-quagga waf configure" ; exit 1 ; }
./waf \
	|| { echo "[Error] ns-3-dce-quagga waf make" ; exit 1 ; }
./waf install
echo Launch NS3-QUAGGA-TEST-DCE
./build/bin/ns3test-dce-quagga --verbose


