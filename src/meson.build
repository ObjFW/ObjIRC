fs = import('fs')

sources = files(
  'IRCConnection.m',
  'IRCUser.m',
)

objirc = library('objirc',
  sources,
  include_directories: incdir,
  dependencies: [objfw_dep],
  soversion: '0.0.0',
  install: true)

headers = ['ObjIRC.h']
foreach source: sources
  headers += fs.replace_suffix(source.full_path(), '.h')
endforeach

install_headers(headers, subdir: 'ObjIRC')
