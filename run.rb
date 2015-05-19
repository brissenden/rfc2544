require_relative 'throughput/test'
require_relative 'latency/test'
require_relative 'frame_loss_rate/test'

host = ENV['host']

Throughput::Test.new.(host)
Latency::Test.new.(host)
FrameLossRate::Test.new.(host)
