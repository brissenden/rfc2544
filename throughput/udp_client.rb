require 'json'
require 'socket'
require_relative 'protocol'

module Throughput
  class UdpClient
    IP_HEADER     = 20
    UDP_HEADER    = 8
    ETHER_HEADER  = 18
    HEADERS       = IP_HEADER + UDP_HEADER + ETHER_HEADER
    
    attr_accessor :host, :port, :socket, :running, :udelay, :bytes
    
    def initialize(host, port)
      @host   = host
      @port   = port
      @socket = UDPSocket.new
      
      @send_frames = 0
      @send_bytes  = 0
      
      @udelay      = 0.1
      @running     = true
    end
    
    def call(frame_size)
      @bytes = frame_size
      @bytes -= HEADERS
      
      #while running
        send_and_wait_to_ack build_request('CMD_SETUP_SYN') do
          send_data_packets
          send_and_wait_to_ack build_request('CMD_FINISH_SYN') do |response|
            if response.data.to_i == @send_frames
              increment_rate
            else
              decrement_rate
            end
            reset
          end
        end
        #end
    end
    
    def send_data_packets
      rate = 1.0/udelay
      
      puts "Rate: #{rate} bytes: #{bytes}"
      rate.to_i.times.each do |i|
        send_request build_request('CMD_DATA', 0)
        @send_frames += 1
        @send_bytes  += bytes
        
        sleep udelay
      end
    end
    
    def increment_rate
      @udelay = udelay / 2
    end
    
    def decrement_rate
      @udelay = udelay * 2
    end
    
    def reset
      @send_frames = 0
    end
    
    private
    
    def send_and_wait_to_ack(request, &block)
      send_request(request)
      msg, _   = socket.recvfrom(1024)
      
      response = CustomProtocol.new
      response.read(msg)      
      expected_command = request.command.gsub('SYN', 'ACK')
      if response.command == expected_command
        yield(response)
      end
    end
    
    def build_request(command, data = nil)
      CustomProtocol.new.tap do |request|
        request.command = command
        request.data    = data
      end
    end
    
    def send_request(request)
      socket.send(request.to_binary_s, 0, host, port)
    end
  end
end

Throughput::UdpClient.new('localhost', 9999).(128)