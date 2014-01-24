# Logging proxy...

require 'log4r'

module Paynearme
  module Callbacks

    class Logger
      include Log4r

      def initialize (name='Paynearme::Callbacks::Logger')
        @name = name

        if defined? Rails
          @logger = Rails.logger
        else
          @logger = Log4r::Logger.new(name)
          @logger.outputters = [
              Log4r::StdoutOutputter.new('console'),
              Log4r::FileOutputter.new('log_file', filename: 'paynearme_api.log')
          ]
          @logger.outputters.each do |o|
            o.formatter = Log4r::PatternFormatter.new(pattern: '[%d] %x %l - %M')
          end
        end
      end

      def method_missing (method, *args)
        NDC.push(@name) if Log4r::Logger === @logger
        @logger.send(method.to_sym, *args)
        NDC.pop if Log4r::Logger === @logger
      end
    end
  end
end