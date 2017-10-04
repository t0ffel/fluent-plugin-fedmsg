require 'fluent/input'

module Fluent

  class ZmqSubInput < Fluent::Input
    Fluent::Plugin.register_input('fedmsg', self)

    config_param :subkey, :string, :default => ""
    config_param :publisher, :string, :default => "tcp://127.0.0.1:5556"
    config_param :tag_prefix, :string, :default => ""
    config_param :drop_fields, :string, :default => "username,certificate,i,crypto,signature"

    attr_reader :subkeys

    def initialize
      super
      require 'ffi-rzmq'
    end

    def configure(conf)
      super
      @subkeys = @subkey.split(",")
      @drop_fields_arr = @drop_fields.split(",")
    end

    def start
      super
      @context =ZMQ::Context.new()
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      Thread.kill(@thread)
      @thread.join
      @context.terminate
      super
    end

    def run
      begin
        @subscriber = @context.socket(ZMQ::SUB)
        @subscriber.connect(@publisher)
        @subscriber.setsockopt(ZMQ::SNDHWM, 100)
        @subscriber.setsockopt(ZMQ::RCVHWM, 100)
        if @subkeys.size > 0
          @subkeys.each do |k|
            @subscriber.setsockopt(ZMQ::SUBSCRIBE,k)
          end
        else
          @subscriber.setsockopt(ZMQ::SUBSCRIBE,'')
        end
        loop do
          msg = ''
          while @subscriber.recv_string(msg,ZMQ::DONTWAIT) && msg.size > 0
            begin
              record = JSON.parse(msg)
            rescue JSON::ParserError => e
              log.trace "Ignoring non-JSON message '#{msg}'"
              next
            rescue => e
              log.warn "Unknown error parsing JSON message.",:error_class => e.class, :error => e
              log.warn_backtrace
            end
            begin
              tag = @tag_prefix + "." + record['topic']
              time = record['timestamp']
              record.delete_if { |key, value| @drop_fields_arr.include? key}
              Engine.emit(tag, time, record)
            rescue => e
              log.warn "Error in processing message.",:error_class => e.class, :error => e
              log.warn_backtrace
            end
            msg = ''
          end
          sleep(0.1)
        end
      rescue => e
        log.error "error occurred while executing plugin.", :error_class => e.class, :error => e
        log.warn_backtrace
      ensure
        if @subscriber
          @subscriber.close
        end
      end
    end

  end

end
