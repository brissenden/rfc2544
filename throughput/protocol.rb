require 'bindata'

module Throughput
  class CustomProtocol < BinData::Record
    endian  :big
    stringz :command
    stringz :data
  end
end