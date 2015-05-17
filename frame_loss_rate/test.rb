# Objective:  To determine the frame loss rate, as defined in RFC 1242,
# of a DUT throughout the entire range of input data rates and frame
# sizes.
#
# Procedure:  Send a specific number of frames at a specific rate
# through the DUT to be tested and count the frames that are
# transmitted by the DUT.  The frame loss rate at each point is
# calculated using the following equation:
#
#       ( ( input_count - output_count ) * 100 ) / input_count
#
#
# The first trial SHOULD be run for the frame rate that corresponds to
# 100% of the maximum rate for the frame size on the input media.
# Repeat the procedure for the rate that corresponds to 90% of the
# maximum rate used and then for 80% of this rate.  This sequence
# SHOULD be continued (at reducing 10% intervals) until there are two
# successive trials in which no frames are lost. The maximum
# granularity of the trials MUST be 10% of the maximum rate, a finer
# granularity is encouraged.
#
# Reporting format:  The results of the frame loss rate test SHOULD be
# plotted as a graph.  If this is done then the X axis MUST be the
# input frame rate as a percent of the theoretical rate for the media
# at the specific frame size. The Y axis MUST be the percent loss at
# the particular input rate.  The left end of the X axis and the bottom
# of the Y axis MUST be 0 percent; the right end of the X axis and the
# top of the Y axis MUST be 100 percent.  Multiple lines on the graph
# MAY used to report the frame loss rate for different frame sizes,
# protocols, and types of data streams.

require_relative 'udp_client'

host = 'kozel.hung.p2.tiktalik.io'
# host = 'localhost'

max_frame_rate  = 10
frame_sizes     = [64, 128, 256, 512, 1024, 1280, 1518]

frame_loss_rate = ->(frame_size) {
  FrameLossRate::UdpClient.new(host, 9999, max_frame_rate).(frame_size)
}

frame_sizes.each do |frame_size|
  result = frame_loss_rate.(frame_size)
  puts "Frame size: #{frame_size}\n"
  result.each do |row|
    puts "FPS: #{row[:fps]} Frame loss rate: #{row[:frame_loss_rate]}\n"
  end
end