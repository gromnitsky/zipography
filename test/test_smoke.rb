require 'minitest/autorun'

require 'securerandom'
require 'yaml'
require_relative '../lib'
include Zipography

class Smoke < Minitest::Test
  def setup
    @zip_new = SecureRandom.hex
    `./zipography-inject test/orig.zip test/blob1.png > #{@zip_new}`
    assert_equal 0, $?.exitstatus
  end

  def teardown
    File.unlink @zip_new
  end

  def test_info_and_extract
    info = `./zipography-info #{@zip_new}`
    assert_equal 0, $?.exitstatus
    assert_equal({
                   "Payload size" => 18313,
                   "Adler32" => 109129119,
                   "Blob version" => 1,
                 }, YAML.load(info))

    blob = SecureRandom.hex
    `./zipography-extract #{@zip_new} > #{blob}`
    assert_equal 0, $?.exitstatus
    `cmp test/blob1.png #{blob}`
    assert_equal 0, $?.exitstatus

    File.unlink blob
  end

  def test_checksum
    # change some bytes in the payload
    zip = File.read @zip_new
    zip[zip.size-300] = 'L'
    zip[zip.size-301] = 'O'
    zip[zip.size-302] = 'L'
    File.open(@zip_new, 'w') { |f| f.write zip }

    info = `./zipography-info #{@zip_new}`
    assert_equal 1, $?.exitstatus
    assert_equal({
                   "Payload size" => 18313,
                   "Adler32" => 109129119,
                   "Blob version" => 1,
                   "Error" => "invalid checksum 0xf7f72d64"
                 }, YAML.load(info))
  end

  def test_zip64
    r = assert_raises(RuntimeError) do
      eocd_parse 'test/64.zip', eocd_position('test/64.zip')
    end
    assert_equal 'no support for zip64 format', r.message
  end

  def test_not_a_zip
    r = assert_raises(RuntimeError) do
      eocd_position('test/blob1.png')
    end
    assert_match(/not a zip$/, r.message)
  end
end
