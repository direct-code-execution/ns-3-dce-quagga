Introduction
------------

The Quagga support on DCE enables the users to reuse routing protocol
implementations of Quagga (RIPv1, RIPv2, RIPng, OSPFv2, OSPFv3, BGP,
BGP+, RAadv) as models of network simulation. It reduces the time of
re-implementation of the model, and potentially improve the result of
the simulation since it already "actively running" in the real world.

It was started as a Google Summer of Code (GSoC) 2008 by Liu Jian with
a numerous contribution especially on the netlink implementation with
quagga porting. You can look at his effort at the `link
<https://www.nsnam.org/wiki/index.php/Real_World_Application_Integration>`_.


Getting Started
---------------

Prerequisite
************
Quagga support on DCE requires several packages:
autoconf, automake, flex, git-core, wget, g++, libc-dbg, bison

You need to install the correspondent packages in advance.

::

  $ sudo apt-get install git-core (in ubuntu/debian)

or

::

  $ sudo yum install git (in fedora)


Building ns-3, DCE, and DCE-Quagga
*********************

First you need to download NS-3 DCE using mercurial:

::

  $ mkdir test_build_ns3_dce
  $ cd test_build_ns3_dce
  $ hg clone http://code.nsnam.org/furbani/ns-3-dce

then build ns-3-dce:

::

  $ ns-3-dce/utils/clone_and_compile_ns3_dce.sh -k

Note that "-k" requires the build of ns-3-linux, which supports Linux
native stack direct code execution with quagga. This is highly
recommended at this moment (2012/04/20) so that Quagga runs
successfully.

For more information about ns-3-dce core, please refer the `DCE manual
<http://www-sop.inria.fr/members/Frederic.Urbani/ns3dceccnx/getting-started.html#building-ns-3-and-dce>`_.

After DCE is installed successfully, download ns-3-dce-quagga.

::

  $ mkdir test_build_ns3_dce
  $ cd test_build_ns3_dce
  $ hg clone http://code.nsnam.org/thehajime/ns-3-dce-quagga



You can build ns-3-dce-quagga as following:

::

  $ cd ns-3-dce-quagga
  $ ./utils/dce_build.sh -k
  clone readversiondef
  ...
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  clone ns-3-dce
  ...
  2105 files updated, 0 files merged, 0 files removed, 0 files unresolved
  ...
  Launch NS3QUAGGATEST-DCE
  PASS dce-quagga 14.290ms
    PASS Check that process "radvd-kernel" completes correctly. 2.650ms
    PASS Check that process "ripd-kernel" completes correctly. 1.300ms
    PASS Check that process "ripngd-kernel" completes correctly. 1.250ms
    PASS Check that process "ospfd-kernel" completes correctly. 3.620ms
    PASS Check that process "ospf6d-kernel" completes correctly. 1.530ms
    PASS Check that process "bgpd-kernel" completes correctly. 1.940ms
    PASS Check that process "bgpd_v6-kernel" completes correctly. 2.000ms
    
You can see the above PASSed test if everything goes fine. Congrats!

Setting Environment
*********************

Call the setenv.sh script to correctly setup the environment variables (i.e., PATH, LD_LIBRARY_PATH and PKG_CONFIG_PATH)

::

  $ source ns-3-dce/utils/setenv.sh

Configuration Manual
********************
Examples
********
Basic
#####
::

  $ cd ns-3-dce-quagga
  $ ./build/bin/dce-zebra-simple

OSPF
####
::

  $ cd ns-3-dce-quagga
  $ ./build/bin/dce-quagga-ospfd

OSPF with ns-3-linux
####################
::

  $ cd ns-3-dce-quagga
  $ ./build/bin/dce-quagga-ospfd --netStack=linux


Modifying DCE Quagga
--------------------

Customizing Helper
******************

At this moment, only a limited configuration of Quagga is implemented
in the QuaggaHelper. For example, if you wanna configure the "cost"
parameter of OSPF link, you do have to extend QuaggaHelper
(quagga-helper.cc) to generate the following configuration for example. 

::

  interface sim0
    ip ospf cost 20
  !

Customizing Binary
******************

If you wanna extend the protocol by modifying the source code of
Quagga, your extended binary should be located at the directory
"ns-3-dce/build/bin_dce".

FAQ 
---


