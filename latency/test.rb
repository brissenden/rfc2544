# Objective:  To determine the latency as defined in RFC 1242.
#
# Procedure:  First determine the throughput for DUT at each of the
# listed frame sizes. Send a stream of frames at a particular frame
# size through the DUT at the determined throughput rate to a specific
# destination.  The stream SHOULD be at least 120 seconds in duration.
# An identifying tag SHOULD be included in one frame after 60 seconds
# with the type of tag being implementation dependent. The time at
# which this frame is fully transmitted is recorded (timestamp A).  The
# receiver logic in the test equipment MUST recognize the tag
# information in the frame stream and record the time at which the
# tagged frame was received (timestamp B).
#
# The latency is timestamp B minus timestamp A as per the relevant
# definition frm RFC 1242, namely latency as defined for store and
# forward devices or latency as defined for bit forwarding devices.
#
# The test MUST be repeated at least 20 times with the reported value
# being the average of the recorded values.

require_relative 'udp_client'

# host = 'kozel.hung.p2.tiktalik.io'
host = 'localhost'

test_time   = 120
frame_rate  = 5  # frames per sec
frame_sizes = [64, 128, 256, 512, 1024, 1280, 1518]

latency = ->(frame_size) {
  Latency::UdpClient.new(host, 9999, test_time, frame_rate).(frame_size)
}

frame_sizes.each do |frame_size|
  result = latency.(frame_size)
  puts "Frame size: #{frame_size} Latency: #{result}\n"
end