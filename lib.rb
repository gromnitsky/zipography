require 'zlib'

module Zipography

  HEADER_SIZE = 8               # bytes

  def self.checksum str         # 32bit, little-endian
    [Zlib.adler32(str)].pack 'l<'
  end

  class MyZip
    def initialize file
      @buf = File.read file
      @first_cdh = first_central_dir_header
      @eocd = end_of_central_dir
    end
    attr_reader :buf, :first_cdh, :eocd

    def first_central_dir_header
      pos = @buf.index [0x02014b50].pack('V')
      fail 'not a suitable zip file' if pos == -1
      pos
    end

    def end_of_central_dir
      @buf.rindex [0x06054b50].pack('V')
    end

    def before
      @buf.slice(0, @first_cdh)
    end
  end

  module Blob
    def self.size file          # 32bit, little-endian
      [File.stat(file).size].pack 'l<'
    end

    def self.xor_cipher str, password
      msg = str.unpack 'c*'
      pw = password.unpack 'c*'
      pw *= msg.length/pw.length + 1
      msg.zip(pw).map {|c1,c2| c1^c2}.pack 'c*'
    end

#    def self.encrypt data; xor_cipher(data, "passw0rd"); end
    def self.encrypt data; data; end
  end

  class Alien
    def initialize file; @io = File.open file; end

    def size
      @io.seek(-4, IO::SEEK_END)
      (@io.read 4).unpack('l<').first
    end

    def checksum
      @io.seek(-8, IO::SEEK_END)
      (@io.read 4).unpack('l<').first
    end

    def blob
      len = size
      @io.seek(-(HEADER_SIZE+len), IO::SEEK_END)
      Blob.encrypt(@io.read len)
    end

    def valid
      checksum == Zipography.checksum(blob).unpack('l<').first
    end
  end

end
