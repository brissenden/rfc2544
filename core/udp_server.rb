require 'socket'
require_relative 'protocol'

module Core
  class UdpServer
    UnknownCommand = Class.new(StandardError)
  
    attr_accessor :rcv_frames, :rcv_bytes
  
    def initialize
      @port       = 9999
      @rcv_frames = 0
      @timestamp  = nil
    end

    def listen
      Socket.udp_server_loop(@port) do |body, source|
        proto = CustomProtocol.new
        proto.read(body)
      
        case proto.command
          when "CMD_DATA"         then data_handler
          when "CMD_SETUP_SYN"    then setup_syn_handler(source)
          when "CMD_FINISH_SYN"   then finish_syn_handler(source)  
          when "CMD_LATENCY"      then latency_handler
          when "CMD_LATENCY_SYN"  then latency_syn_handler(source)
          else
            raise UnknownCommand.new
        end
      end
    end
  
    private
  
    def data_handler
    	@rcv_frames += 1
    end
  
    def setup_syn_handler(source)
      clear
      source.reply(CustomProtocol.new(command: 'CMD_SETUP_ACK').to_binary_s)
    end
  
    def finish_syn_handler(source)
      source.reply(CustomProtocol.new(command: 'CMD_FINISH_ACK', data: @rcv_frames.to_s).to_binary_s)
      clear
    end
  
    def latency_handler
      @timestamp = Time.now.to_f
    end
  
    def latency_syn_handler(source)
      source.reply(CustomProtocol.new(command: 'CMD_LATENCY_ACK', data: @timestamp.to_s).to_binary_s)
      @timestamp = nil
    end

    def clear
    	@rcv_frames = 0
    end
  end
end
  
Core::UdpServer.new.listen
