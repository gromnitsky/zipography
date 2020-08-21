#!/usr/bin/env ruby

def size file; [File.stat(file).size].pack 'l<'; end

if ARGV.size < 2
  abort <<E
Usage: ./append.rb orig.zip blob > new.zip
'blob' cannot be a zip file!
E
end

$stdout.write File.read ARGV[0]
$stdout.write File.read ARGV[1]
$stdout.write size ARGV[1]
