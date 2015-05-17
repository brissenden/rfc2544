# The latency test measures the time required for a frame to travel from the originating device through the network to the destination device
# (also known as end-to-end testing). This test can also be configured to measure the round-trip time; i.e., the time required for a frame
# to travel from the originating device to the destination device and then back to the originating device.
# When the latency time varies from frame to frame, it causes issues with real-time services. For example, latency variation in VoIP
# applications would degrade the voice quality and create pops or clicks on the line. Long latency can also degrade Ethernet service
# quality. In client-server applications, the server might time out or poor application performance can occur. For VoIP, this would translate
# into long delays in the conversation, producing a “satellite call feeling”.
# The test procedure begins by measuring and benchmarking the throughput for each frame size to ensure the frames are transmitted
# without being discarded (i.e., the throughout test). This fills all device buffers, therefore measuring latency in the worst conditions.
# The second step is for the test instrument to send traffic for 120 seconds. At mid-point in the transmission, a frame must be tagged with
# a time-stamp and when it is received back at the test instrument, the latency is measured. The transmission should continue for the rest
# of the time period. This measurement must be taken 20 times for each frame size, and the results should be reported as an average.

require_relative 'udp_client'

host = 'localhost'
frame_sizes = [64, 128, 256, 512, 1024, 1280, 1518]

latency = ->(frame_rate, frame_size) {
  Latency::UdpClient.new(host, 9999).(frame_rate, frame_size)
}

latency.(5, 64)