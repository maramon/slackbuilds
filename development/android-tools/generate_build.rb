#!/usr/bin/ruby

# Android build system is complicated and does not allow to build
# separate parts easily.
# This script tries to mimic Android build rules.

def expand(dir, files)
  files.map{|f| File.join(dir,f)}
end

# Compiles sources to *.o files.
# Returns array of output *.o filenames
def compile(sources, cflags)
  outputs = []
  for s in sources
    ext = File.extname(s)
    
    case ext
    when '.c'
        cc = 'clang'
    	lang_flags = '-std=gnu11 $CFLAGS $CPPFLAGS'
    when '.cpp', '.cc'
        cc = 'clang++'
    	lang_flags = '-std=gnu++14 $CXXFLAGS $CPPFLAGS'
    else
        raise "Unknown extension #{ext}"
    end

    output = s + '.o'
    outputs << output
    puts "echo Compiling #{output}\n"
    puts "#{cc} -o #{output} #{lang_flags} #{cflags} -c #{s}\n"
  end

  return outputs
end

# Links object files
def link(output, objects, ldflags)
  puts "echo Linking #{output}\n"
  puts "g++ -o #{output} #{ldflags} $LDFLAGS #{objects.join(' ')}"
end


adbdfiles = %w(
  adb.cpp
  adb_auth.cpp
  adb_io.cpp
  adb_listeners.cpp
  adb_trace.cpp
  adb_utils.cpp
  line_printer.cpp
  sockets.cpp
  transport.cpp
  transport_local.cpp
  transport_usb.cpp
  sysdeps_unix.cpp

  fdevent.cpp
  get_my_path_linux.cpp
  usb_linux.cpp

  adb_auth_host.cpp
  shell_service_protocol.cpp
)
libadbd = compile(expand('core/adb', adbdfiles), '-DADB_REVISION=\"$PKGVER\" -DADB_HOST=1 -fpermissive -Icore/include -Icore/base/include -Icore/adb')

adbfiles = %w(
  bugreport.cpp
  console.cpp
  commandline.cpp
  adb_client.cpp
  services.cpp
  file_sync_client.cpp
  client/main.cpp
)
libadb = compile(expand('core/adb', adbfiles), '-D_GNU_SOURCE -DADB_HOST=1 -DWORKAROUND_BUG6558362 -fpermissive -Icore/include -Icore/base/include -Icore/adb')

basefiles = %w(
  file.cpp
  logging.cpp
  parsenetaddress.cpp
  stringprintf.cpp
  strings.cpp
  errors_unix.cpp
)
libbase = compile(expand('core/base', basefiles), '-DADB_HOST=1 -Icore/base/include -Icore/include')

logfiles = %w(
  log_event_write.c
  fake_log_device.c
  log_event_list.c
  logger_write.c
  config_write.c
  logger_lock.c
  fake_writer.c
  logger_name.c
)
liblog = compile(expand('core/liblog', logfiles), '-DLIBLOG_LOG_TAG=1005 -DFAKE_LOG_DEVICE=1 -D_GNU_SOURCE -Icore/log/include -Icore/include')

cutilsfiles = %w(
  load_file.c
  socket_local_client_unix.c
  socket_loopback_client_unix.c
  socket_network_client_unix.c
  socket_loopback_server_unix.c
  socket_local_server_unix.c
  sockets_unix.cpp
  socket_inaddr_any_server_unix.c
  sockets.cpp
)
libcutils = compile(expand('core/libcutils', cutilsfiles), '-D_GNU_SOURCE -Icore/include')

diagnoseusbfiles = %w(
  diagnose_usb.cpp
)
libdiagnoseusb = compile(expand('core/adb', diagnoseusbfiles), '-Icore/include -Icore/base/include')

link('adb', libbase + liblog + libcutils + libadbd + libadb + libdiagnoseusb, '-lpthread -lcrypto')


fastbootfiles = %w(
  protocol.cpp
  engine.cpp
  bootimg_utils.cpp
  fastboot.cpp
  util.cpp
  fs.cpp
  usb_linux.cpp
  util_linux.cpp
  socket.cpp
  tcp.cpp
  udp.cpp
)
libfastboot = compile(expand('core/fastboot', fastbootfiles), '-DFASTBOOT_REVISION=\"$PKGVER\" -D_GNU_SOURCE -Icore/base/include -Icore/include -Icore/adb -Icore/libsparse/include -Icore/mkbootimg -Iextras/ext4_utils -Iextras/f2fs_utils')

sparsefiles = %w(
  backed_block.c
  output_file.c
  sparse.c
  sparse_crc32.c
  sparse_err.c
  sparse_read.c
)
libsparse = compile(expand('core/libsparse', sparsefiles), '-Icore/libsparse/include')

zipfiles = %w(
  zip_archive.cc
)
libzip = compile(expand('core/libziparchive', zipfiles), '-Icore/base/include -Icore/include')

utilfiles = %w(
  FileMap.cpp
)
libutil = compile(expand('core/libutils', utilfiles), '-Icore/include')

ext4files = %w(
  make_ext4fs.c
  ext4fixup.c
  ext4_utils.c
  allocate.c
  contents.c
  extent.c
  indirect.c
  sha1.c
  wipe.c
  crc16.c
  ext4_sb.c
)
libext4 = compile(expand('extras/ext4_utils', ext4files), '-Icore/libsparse/include -Icore/include -Ilibselinux/include')

selinuxfiles = %w(
  src/callbacks.c
  src/check_context.c
  src/freecon.c
  src/init.c
  src/label.c
  src/label_file.c
  src/label_android_property.c
  src/label_support.c
)
libselinux = compile(expand('libselinux', selinuxfiles), '-DAUDITD_LOG_TAG=1003 -D_GNU_SOURCE -DHOST -Ilibselinux/include')

link('fastboot', libsparse + libzip + libcutils + liblog + libutil + libbase + libext4 + libselinux + libfastboot + libdiagnoseusb, '-lz -lpcre -lpthread')
