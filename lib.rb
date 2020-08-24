require 'zlib'
require 'bindata'

module Zipography
  class Eocd < BinData::Record
    endian :little

    uint32 :signature, asserted_value: 0x06054b50
    uint16 :disk
    uint16 :disk_cd_start
    uint16 :cd_entries_disk
    uint16 :cd_entries_total
    uint32 :cd_size
    uint32 :cd_offset_start
    uint16 :comment_len
    string :comment, :read_length => :comment_len,
           onlyif: -> { comment_len.nonzero? }
  end

  class IOReverseChunks
    include Enumerable

    def initialize io, bufsiz: 4096, debug: false
      @io = io
      @fsize = io.stat.size
      @bufsiz = bufsiz > @fsize ? (@fsize/2.0).ceil : bufsiz

      @seek = -@bufsiz
      @io.seek @seek, IO::SEEK_END

      @debug = debug
      $stderr.puts "#{@io.path}: seek=#{@seek}, bufsiz=#{@bufsiz}" if @debug
    end
    attr_reader :io, :fsize

    def each
      idx = 0
      while (chunk = @io.read(@bufsiz))
        return if chunk.size == 0

        yield chunk
        idx += 1

        return if @seek == 0

        @seek = -@bufsiz*(idx+1)
        begin
          @io.seek @seek, IO::SEEK_END
        rescue Errno::EINVAL
          @bufsiz = -(@bufsiz*(idx+1) - @fsize - @bufsiz)
          @seek = 0
          @io.seek @seek
        end

        $stderr.puts "#{@io.path}: seek=#{@seek}, bufsiz=#{@bufsiz}" if @debug
      end
    end
  end

  def file_rindex file, substring
    my_rindex = ->(s1, s2) { s1.rindex s2.dup.force_encoding('ASCII-8BIT') }

    r = nil
    File.open(file, 'rb') do |io|
      iorc = IOReverseChunks.new io
      prev_chunk = ''
      bytes_read = 0

      r = iorc.each do |chunk|
        bytes_read += chunk.size

        if (idx = my_rindex.call(chunk, substring))
          break iorc.fsize - bytes_read + idx
        end

        if my_rindex.call(chunk, substring[0])
          two_chunks = chunk + prev_chunk
          if (idx = my_rindex.call(two_chunks, substring))
            break iorc.fsize - bytes_read + idx
          end
        end

        prev_chunk = chunk
      end
    end

    r
  end

  def eocd_position file
    file_rindex(ARGV[0], [0x06054b50].pack('V')) || fail("#{file}: not a zip")
  end

  def eocd_parse file, pos
    File.open(file, 'rb') do |f|
      f.seek pos
      Eocd.read f
    end
  end

  class HiddenBlobHeader < BinData::Record
    endian :little

    uint32 :checksum
    uint32 :len
    uint8 :version, initial_value: 1
  end

  HIDDEN_BLOB_HEADER_SIZE = 9           # bytes

  def adler32_file file, bufsiz: 1 << 16
    r = nil
    File.open(file, 'rb') do |f|
      while (chunk = f.read bufsiz)
        r = Zlib.adler32 chunk, r
      end
    end
    r
  end

  def blob_write file, dest
    blob_size = File.stat(file).size

    header = HiddenBlobHeader.new len: blob_size, checksum: adler32_file(file)
    IO.copy_stream file, dest
    dest.write header.to_binary_s

    blob_size + header.num_bytes
  end

  def adler32_file_slice file, start, length, bufsiz: 1 << 16
    r = nil
    File.open(file, 'rb') do |f|
      f.seek start
      bytes_read = 0
      idx = 0
      while (chunk = f.read bufsiz)
        bytes_read += chunk.bytesize

        if bytes_read > length
          if idx == 0
            chunk = chunk.byteslice(0, length)
          else
            chunk = chunk.byteslice(0, chunk.bytesize - (bytes_read - length))
          end
        end
        r = Zlib.adler32 chunk, r
        idx += 1
      end
    end
    r
  end

  def adler2hex i; "0x" + i.to_i.to_s(16); end

end
