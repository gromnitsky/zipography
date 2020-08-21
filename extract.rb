#!/usr/bin/env ruby

def size io
  io.seek(-4, IO::SEEK_END)
  (io.read 4).unpack('l<').first
end

File.open(ARGV[0]) do |f|
  len = size(f)
  f.seek(-(4+len), IO::SEEK_END)
  $stdout.write f.read len
end
