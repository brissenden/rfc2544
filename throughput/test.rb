# The throughput test defines the maximum number of frames per second that can be transmitted without any error. This test
# is done to measure the rate-limiting capability of an Ethernet switch as found in carrier Ethernet services. The methodology
# involves starting at a maximum frame rate and then comparing the number of transmitted and received frames. Should frame loss
# occur, the transmission rate is divided by two and the test is restarted. If during this trial there is no frame loss, then the
# transmission rate is increased by half of the difference from the previous trial. This methodology is known as the half/doubling
# method. This trial-and-error methodology is repeated until the rate at which there is no frame loss is found.
# The throughput test must be performed for each frame size. Although the test time during which frames are transmitted can be
# short, it must be at least 60 seconds for the final validation. Each throughput test result must then be recorded in a report, using
# frames per second (f/s or fps) or bits per second (bit/s or bps) as the measurement unit.

require_relative 'udp_client'

# host = 'kozel.hung.p2.tiktalik.io'
# host = '85.14.98.130'
host = 'localhost'

max_frame_rate = 1000
frame_sizes = [64, 128, 256, 512, 1024, 1280, 1518]

throughput = ->(frame_size) {
  Throughput::UdpClient.new(host, 9999, max_frame_rate).(frame_size)
}

frame_sizes.each do |frame_size|
  result = throughput.(frame_size)
  puts "Frame size: #{frame_size} FPS: #{result[:fps]}\n"
end
