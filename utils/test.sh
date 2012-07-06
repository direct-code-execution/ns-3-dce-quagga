#!/bin/bash

cd `dirname $BASH_SOURCE`/..
. ../ns-3-dce/utils/setenv.sh
cd ../ns-3-dce-quagga
echo Launch NS3-QUAGGA-TEST-DCE
./build/bin/ns3test-dce-quagga --verbose

