## -*- Mode: python; py-indent-offset: 4; indent-tabs-mode: nil; coding: utf-8; -*-

import os
import Options
import os.path
import ns3waf
import sys


def options(opt):
    opt.tool_options('compiler_cc') 
    ns3waf.options(opt)
    opt.add_option('--enable-kernel-stack',
                   help=('Path to the prefix where the kernel wrapper headers are installed'),
                   default=None,
                   dest='kernel_stack', type="string")

def search_file(files):
    for f in files:
        if os.path.isfile (f):
            return f
    return None

def configure(conf):
    ns3waf.check_modules(conf, ['dce'], mandatory = True)
    ns3waf.check_modules(conf, ['core', 'network', 'internet'], mandatory = True)
    ns3waf.check_modules(conf, ['point-to-point', 'tap-bridge', 'netanim'], mandatory = False)
    ns3waf.check_modules(conf, ['wifi', 'point-to-point', 'csma', 'mobility'], mandatory = False)
    ns3waf.check_modules(conf, ['point-to-point-layout'], mandatory = False)
    ns3waf.check_modules(conf, ['topology-read', 'applications', 'visualizer'], mandatory = False)
    conf.check_tool('compiler_cc')
    conf.check(header_name='stdint.h', define_name='HAVE_STDINT_H', mandatory=False)
    conf.check(header_name='inttypes.h', define_name='HAVE_INTTYPES_H', mandatory=False)
    conf.check(header_name='sys/inttypes.h', define_name='HAVE_SYS_INT_TYPES_H', mandatory=False)
    conf.check(header_name='sys/types.h', define_name='HAVE_SYS_TYPES_H', mandatory=False)
    conf.check(header_name='sys/stat.h', define_name='HAVE_SYS_STAT_H', mandatory=False)
    conf.check(header_name='dirent.h', define_name='HAVE_DIRENT_H', mandatory=False)

    conf.env.append_value('CXXFLAGS', '-I/usr/include/python2.6')
    conf.env.append_value('LINKFLAGS', '-pthread')
    conf.env.append_value('LINKFLAGS', '-Wl,--dynamic-linker=' +
                             os.path.abspath ('../build/lib/ldso'))
    conf.check (lib='dl', mandatory = True)

    vg_h = conf.check(header_name='valgrind/valgrind.h', mandatory=False)
    vg_memcheck_h = conf.check(header_name='valgrind/memcheck.h', mandatory=False)
    if vg_h and vg_memcheck_h:
        conf.env.append_value('CXXDEFINES', 'HAVE_VALGRIND_H')

    conf.start_msg('Searching C library')
    libc = search_file ([
            '/lib64/libc.so.6',
            '/lib/libc.so.6',
            ])
    if libc is None:
        conf.fatal('not found')
    else:
        conf.end_msg(libc, True)
    conf.env['LIBC_FILE'] = libc

    conf.start_msg('Searching pthread library')
    libpthread = search_file ([
            '/lib64/libpthread.so.0',
            '/lib/libpthread.so.0',
            ])
    if libpthread is None:
        conf.fatal('not found')
    else:
        conf.end_msg(libpthread, True)
    conf.env['LIBPTHREAD_FILE'] = libpthread

    conf.start_msg('Searching rt library')
    librt = search_file ([
            '/lib64/librt.so.1',
            '/lib/librt.so.1',
            ])
    if librt is None:
        conf.fatal('not found')
    else:
        conf.end_msg(librt, True)
    conf.env['LIBRT_FILE'] = librt

    conf.find_program('readversiondef', var='READVERSIONDEF', mandatory=True)

    if Options.options.kernel_stack is not None and os.path.isdir(Options.options.kernel_stack):
        conf.check(header_name='sim.h',
                   includes=os.path.join(Options.options.kernel_stack, 'sim/include'))
      #  conf.check()
        conf.env['KERNEL_STACK'] = Options.options.kernel_stack

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

def build_dce_tests(module, kern):
    module.add_runner_test(needed=['core', 'dce-quagga', 'internet', 'csma'],
                           source=['test/dce-quagga-test.cc'])

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

    build_dce_tests(module, bld.env['KERNEL_STACK'])
    build_dce_examples(module)

    if bld.env['KERNEL_STACK']:
        build_dce_kernel_examples(module)
