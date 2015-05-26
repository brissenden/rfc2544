require 'bindata'

module Core
  class CustomProtocol < BinData::Record
    endian  :big
    stringz :command
    stringz :data
  end
end