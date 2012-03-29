#!/bin/zsh
#set -x
# Set environnement for ns3 dce
cd `dirname ${BASH_SOURCE:-$0}`/../..
BASE=$PWD
#LD_LIBRARY_PATH="$BASE/ns-3-dce-quagga/build/lib:$BASE/ns-3-dce/build/lib:$BASE/build/bin:$BASE/ns-3-dce/build/bin"
LD_LIBRARY_PATH="$BASE/ns-3-dce-quagga/build/lib:$BASE/build/lib:$$BASE/ns-3-dce/build/lib:$BASE/build/bin:$BASE/ns-3-dce/build/bin:.:/usr/local/mpi/gcc/openmpi-1.4.3/lib/"
PKG_CONFIG_PATH="$BASE/build/lib/pkgconfig"
PATH="$BASE/build/bin:$BASE/build/sbin:/home/tazaki/hgworks/ns-3-dce-thehajime/build/bin:/home/tazaki/hgworks/ns-3-dce-thehajime/build/sbin:$PATH"
DCE_PATH="$BASE/ns-3-dce/build/bin_dce"
PYTHONPATH=$BASE/ns-3-dev/build/debug/bindings/python:$BASE/ns-3-dev/src/visualizer:$BASE/pybindgen-0.15.0.795:$BASE/build/lib/python2.6/site-packages/:$BASE/ns-3-dce
export LD_LIBRARY_PATH PKG_CONFIG_PATH PATH PYTHONPATH DCE_PATH
cd $BASE/ns-3-dce-quagga
