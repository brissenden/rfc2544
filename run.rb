require_relative 'throughput/test'
require_relative 'latency/test'
require_relative 'frame_loss_rate/test'

host = ENV['HOST']

Throughput::Test.new.(host)
FrameLossRate::Test.new.(host)
Latency::Test.new.(host)