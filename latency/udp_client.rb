require 'timeout'
require 'socket'
require_relative '../core/protocol'

module Latency
  class UdpClient
    IP_HEADER     = 20
    UDP_HEADER    = 8
    ETHER_HEADER  = 18
    CMD_HEADER    = 10 
    HEADERS       = IP_HEADER + UDP_HEADER + ETHER_HEADER
    
    attr_accessor :host, :port, :socket
    
    def initialize(host, port)
      @host   = host
      @port   = port
      @socket = UDPSocket.new
    end
    
    def call(frame_rate, frame_size)
      @fps       = frame_rate
      @test_time = 30
      
      @bytes = frame_size
      @bytes -= HEADERS
      
      send_and_wait_to_ack build_request('CMD_SETUP_SYN') do
        send_data_packets
        
        send_and_wait_to_ack build_request('CMD_LATENCY_SYN') do |response|
          latency = response.data.to_i - @timestamp
          puts "Latency: #{latency}"
        end
      end
    end
    
    def send_data_packets
      udelay = 1.0/@fps
      data   = (@bytes - CMD_HEADER).times.map{ '1' }.join()
      
      @fps.to_i.times.each do |sec|
        if sec == @fps.to_i/2
          @timestamp = Time.now.to_i
          send_request build_request('CMD_LATENCY', @timestamp.to_s)
        end
        
        @fps.to_i.times.each do |i|
          send_request build_request('CMD_DATA', data)
          sleep udelay
        end
        
        sleep 1
      end
    end
    
    def reset
      @send_frames = 0
    end
    
    private
    
    def send_and_wait_to_ack(request, &block)
      send_request(request)

      message, client_address = socket.recvfrom(1024)
  
      response = ::Core::CustomProtocol.new
      response.read(message)      
      expected_command = request.command.gsub('SYN', 'ACK')
      if response.command == expected_command
        yield(response)
      end
    end
    
    def build_request(command, data = nil)
      ::Core::CustomProtocol.new.tap do |request|
        request.command = command
        request.data    = data
      end
    end
    
    def send_request(request)
      socket.send(request.to_binary_s, 0, host, port)
    end
  end
end