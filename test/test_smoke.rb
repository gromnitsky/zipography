require 'minitest/autorun'

require 'securerandom'
require 'yaml'
require_relative '../lib'
include Zipography

class Smoke < Minitest::Test
  def setup
    @zip_new = SecureRandom.hex
    `./zipography-append test/orig.zip test/blob1.png > #{@zip_new}`
    assert_equal 0, $?.exitstatus
  end

  def teardown
    File.unlink @zip_new
  end

  def test_info_and_extract
    info = `./zipography-info < #{@zip_new}`
    assert_equal 0, $?.exitstatus
    assert_equal({
                   "Blob size" => 18313,
                   "Checksum" => 109129119,
                   "Valid" => true
                 }, YAML.load(info))

    blob = SecureRandom.hex
    `./zipography-extract < #{@zip_new} > #{blob}`
    assert_equal 0, $?.exitstatus
    `cmp test/blob1.png #{blob}`
    assert_equal 0, $?.exitstatus

    File.unlink blob
  end

  def test_checksum
    # change some bytes in the payload
    zip = File.read @zip_new
    zip[zip.size-100] = 'L'
    zip[zip.size-101] = 'O'
    zip[zip.size-102] = 'L'
    File.open(@zip_new, 'w') { |f| f.write zip }

    info = `./zipography-info < #{@zip_new}`
    assert_equal 0, $?.exitstatus
    assert_equal({
                   "Blob size" => 18313,
                   "Checksum" => 109129119,
                   "Valid" => false # yup
                 }, YAML.load(info))
  end
end
