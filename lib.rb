require 'zlib'
require 'bindata'

module Zipography

  HEADER_SIZE = 9               # bytes
  class HiddenBlob < BinData::Record
    endian :little

    uint32 :checksum
    uint32 :len
    uint8 :version, initial_value: 1
  end

  def checksum s; Zlib.adler32(s); end

  def blob_make file
    payload = File.read file
    header = HiddenBlob.new len: File.stat(file).size,
                            checksum: checksum(payload)
    [payload.force_encoding('ASCII-8BIT'), header.to_binary_s].join
  end

  class MyZip
    def initialize file
      @file = file
      @buf = File.read file
      @eocd = end_of_central_dir
      @first_cdh = first_central_dir_header
    end

    def first_central_dir_header
      @buf.index [0x02014b50].pack('V')
    end

    def end_of_central_dir
      pos = @buf.rindex [0x06054b50].pack('V')
      fail 'not a zip file' unless pos
      pos
    end

    # start of central dir offset
    def offset
      @buf.slice(@eocd+16, 4).unpack('V').first
    end

    # very crude: instead of an intelligent parsing of eocd, modifying
    # an offset, replacing eocd, we just change the offset. this won't
    # fly for zip64 files
    def repack data
      [
        @buf.slice(0, @first_cdh),
        data,
        # just before the offset of start of central dir
        @buf.slice(@first_cdh, (@eocd+16) - @first_cdh),
        # inject new offset
        [offset + data.bytesize].pack('V'),
        # the rest
        @buf.slice(@eocd+16+4, @buf.size)
      ]
    end

    def blob
      payload = ''
      header = {}
      File.open(@file) do |f|
        f.seek(offset-HEADER_SIZE)
        header = HiddenBlob.read f
        f.seek(offset-HEADER_SIZE-header.len)
        payload = f.read header.len
      end
      { header: header, payload: payload }
    end

    def payload_valid? blob
      blob[:header][:checksum] == checksum(blob[:payload])
    end
  end

end
