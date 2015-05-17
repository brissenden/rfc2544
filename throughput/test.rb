require_relative 'udp_client'

# host        = 'kozel.hung.p2.tiktalik.io'
host        = '85.14.98.130'
# host = 'localhost'
frame_sizes = [64, 128, 256, 512, 1024, 1280, 1518]

throughput = ->(frame_size) {
  Throughput::UdpClient.new(host, 9999).(frame_size)[:throughput].to_s
}

frame_sizes.each do |frame_size|
  puts "Throughput: #{throughput.(frame_size)} Mb/s Frame size: #{frame_size}"
end