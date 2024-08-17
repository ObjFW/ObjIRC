project('ObjIRC', 'objc',
  version: '0.1',
  meson_version: '>= 1.5.0',
  default_options: {
    'warning_level': '3',
  })

objfw_dep = dependency('objfw')

incdir = include_directories('src')

subdir('src')
subdir('tests')

objfwconfig = find_program('objfw-config')
packages_dir = run_command(
  [objfwconfig, '--packages-dir'],
  check: true).stdout().strip()

configure_file(
  input: 'ObjIRC.oc.in',
  output: 'ObjIRC.oc',
  configuration: {
    'includedir': get_option('prefix') / get_option('includedir'),
    'libdir': get_option('prefix') / get_option('libdir'),
  },
  install: true,
  install_dir: packages_dir)
