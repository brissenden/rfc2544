require 'timeout'
require 'socket'
require_relative '../core/protocol'

module Throughput
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
      
      @send_frames = 0
      @send_bytes  = 0
      @stats       = []
      
      @running     = true
    end
    
    def call(max_frame_rate, frame_size)
      @fps                 = max_frame_rate
      @last_not_passed_fps = max_frame_rate
      
      @bytes = frame_size
      @bytes -= HEADERS
      
      while @running
        send_and_wait_to_ack build_request('CMD_SETUP_SYN') do
          send_data_packets
          
          send_and_wait_to_ack build_request('CMD_FINISH_SYN') do |response|
            if response.data.to_i == @send_frames
              @stats << { fps: @fps }

              increment_rate
            else
              @last_not_passed_fps = @fps
              decrement_rate
            end
            reset
          end
        end
      end
      @stats.max{ |e| e[:fps] }
    end
    
    def send_data_packets
      udelay = 1.0/@fps
      
      data = (@bytes - CMD_HEADER).times.map{ '1' }.join()
      @fps.to_i.times.each do |i|
        send_request build_request('CMD_DATA', data)
        @send_frames += 1
        @send_bytes  += data.length
        sleep udelay
      end
    rescue FloatDomainError
      puts "FloatDomainError!"
    end
    
    def increment_rate
      add = (@fps - @last_not_passed_fps).abs / 2
      @fps += add
      
      if @fps < 2 || add == 0
        @running = false
      end
    end
    
    def decrement_rate
      @fps = @fps / 2
      
      unless @fps > 1
        @running = false
      end
    end
    
    def reset
      @send_frames = 0
    end
    
    private
    
    def send_and_wait_to_ack(request, &block)
      send_request(request)
      begin 
        timeout(10) do
          message, client_address = socket.recvfrom(1024)
      
          response = ::Core::CustomProtocol.new
          response.read(message)      
          expected_command = request.command.gsub('SYN', 'ACK')
          if response.command == expected_command
            yield(response)
          end
        end
      rescue Timeout::Error
        puts "Timed out!"
        decrement_rate
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