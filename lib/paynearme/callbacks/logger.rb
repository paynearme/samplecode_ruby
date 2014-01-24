# Logging proxy...

require 'log4r'

module Paynearme
  module Callbacks

    class Logger
      include Log4r

      def initialize (options={})
        options = default_options.merge(options)
        @name = options[:name]

        if options[:allow_rails_logger] and defined? Rails
          @logger = Rails.logger
        else
          @logger = Log4r::Logger.new(@name)
          @logger.outputters = [
              Log4r::StdoutOutputter.new('console'),
              Log4r::FileOutputter.new('log_file', filename: options[:logfile])
          ]
          @logger.outputters.each do |o|
            o.formatter = Log4r::PatternFormatter.new(pattern: options[:pattern])
          end
        end
      end

      def method_missing (method, *args)
        NDC.push(@name) if Log4r::Logger === @logger
        @logger.send(method.to_sym, *args)
        NDC.pop if Log4r::Logger === @logger
      end

      private

      def default_options
        {logfile: 'paynearme_api.log',
         pattern: '[%d] %x %l - %M',
         name: 'Paynearme::Callbacks::Logger',
         allow_rails_logger: true
        }
      end
    end
  end
end