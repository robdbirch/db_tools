require 'logger'
require 'awesome_print'

module DbTools

  module Logging

    def self.create_logger(out=STDOUT, level=::Logger::INFO)
      @logger = ::Logger.new(out)
      @logger.level = level
      @logger
    end

    def self.logger
      @logger ||= self.create_logger
    end

    def logger
      DbTools::Logging.logger
    end

  end

end