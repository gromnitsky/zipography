require 'zlib'

module Zipography

  HEADER_SIZE = 8               # byte

  def self.checksum str         # 32bit, little-endian
    [Zlib.adler32(str)].pack 'l<'
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

    def self.encrypt data; xor_cipher(data, "passw0rd"); end
  end

  class Alien
    def initialize io; @io = io; end

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
