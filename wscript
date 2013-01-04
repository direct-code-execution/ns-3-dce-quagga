## -*- Mode: python; py-indent-offset: 4; indent-tabs-mode: nil; coding: utf-8; -*-

import os
import Options
import os.path
import ns3waf
import sys


def options(opt):
    opt.tool_options('compiler_cc') 
    ns3waf.options(opt)

def configure(conf):
    ns3waf.check_modules(conf, ['dce'], mandatory = True)
    ns3waf.check_modules(conf, ['core', 'network', 'internet'], mandatory = True)
    ns3waf.check_modules(conf, ['point-to-point', 'tap-bridge', 'netanim'], mandatory = False)
    ns3waf.check_modules(conf, ['wifi', 'point-to-point', 'csma', 'mobility'], mandatory = False)
    ns3waf.check_modules(conf, ['point-to-point-layout'], mandatory = False)
    ns3waf.check_modules(conf, ['topology-read', 'applications', 'visualizer'], mandatory = False)
    conf.check_tool('compiler_cc')

    conf.env.append_value('CXXFLAGS', '-I/usr/include/python2.6')
    conf.env.append_value('LINKFLAGS', '-pthread')
    conf.check (lib='dl', mandatory = True)

    ns3waf.print_feature_summary(conf)


def dce_kw(**kw):
    d = dict(**kw)
    if os.uname()[4] == 'x86_64':
        mcmodel = ['-mcmodel=large']
    else:
        mcmodel = []
    nofortify = ['-U_FORTIFY_SOURCE']
    #debug_dl = ['-Wl,--dynamic-linker=/usr/lib/debug/ld-linux-x86-64.so.2']
    debug_dl = []
    d['cxxflags'] = d.get('cxxflags', []) + ['-fpie'] + mcmodel + nofortify
    d['cflags'] = d.get('cflags', []) + ['-fpie'] + mcmodel + nofortify
    d['linkflags'] = d.get('linkflags', []) + ['-pie'] + debug_dl
    return d

def build_dce_tests(module, bld):
    module.add_runner_test(needed=['core', 'dce-quagga', 'internet', 'csma'],
                           source=['test/dce-quagga-test.cc'])
    module.add_runner_test(needed=['core', 'dce-quagga', 'internet', 'csma'],
                           source=['test/dce-quagga-test.cc'], linkflags = ['-Wl,--dynamic-linker=' + os.path.abspath (bld.env.PREFIX + '/lib/ldso')], name='vdl')

def build_dce_examples(module):
    dce_examples = [
                   ]
    for name,lib in dce_examples:
        module.add_example(**dce_kw(target = 'bin/' + name, 
                                    source = ['example/' + name + '.cc'],
                                    lib = lib))

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point', 'point-to-point-layout'],
                       target='bin/dce-zebra-simple',
                       source=['example/dce-zebra-simple.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point', 'applications', 'topology-read', 'visualizer'],
                       target='bin/dce-quagga-ospfd-rocketfuel',
                       source=['example/dce-quagga-ospfd-rocketfuel.cc'])

def build_dce_kernel_examples(module):
    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point'],
                       target='bin/dce-quagga-radvd',
                       source=['example/dce-quagga-radvd.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point'],
                       target='bin/dce-quagga-ripd',
                       source=['example/dce-quagga-ripd.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point'],
                       target='bin/dce-quagga-ripngd',
                       source=['example/dce-quagga-ripngd.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point'],
                       target='bin/dce-quagga-ospfd',
                       source=['example/dce-quagga-ospfd.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point'],
                       target='bin/dce-quagga-ospf6d',
                       source=['example/dce-quagga-ospf6d.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point', 'visualizer', 'topology-read'],
                       target='bin/dce-quagga-bgpd-caida',
                       source=['example/dce-quagga-bgpd-caida.cc'])

    module.add_example(needed = ['core', 'internet', 'dce-quagga', 'point-to-point'],
                       target='bin/dce-quagga-bgpd',
                       source=['example/dce-quagga-bgpd.cc'])


def build(bld):
    module_source = [
        'helper/quagga-helper.cc',
        ]
    module_headers = [
        'helper/quagga-helper.h',
        ]
    module_source = module_source
    module_headers = module_headers
    uselib = ns3waf.modules_uselib(bld, ['core', 'network', 'internet', 'netlink', 'dce'])
    module = ns3waf.create_module(bld, name='dce-quagga',
                                  source=module_source,
                                  headers=module_headers,
                                  use=uselib,
                                  lib=['dl'])
#                                  lib=['dl','efence'])

    build_dce_tests(module,bld)
    bld.install_files('${PREFIX}/bin', 'build/bin/ns3test-dce-quagga', chmod=0755 )
    bld.install_files('${PREFIX}/bin', 'build/bin/ns3test-dce-quagga-vdl', chmod=0755 )
    build_dce_examples(module)
    build_dce_kernel_examples(module)
