require 'pg'
require 'mongo'
require 'json'

module DbTools

  class MongoImport

    CMD = 'mongoimport'

    def initialize(config)
      @config = config
    end

    def import

    end

  end

end