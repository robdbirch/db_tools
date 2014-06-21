require 'mongo'

module DbTools

  class MongoDB

    def initialize(config)
      @config = config
      @conn = nil
    end

    def get_connection
      host = @config[:mongo][:host].nil? ? 'localhost' : @config[:mongo][:host]
      port = @config[:mongo][:port].nil? ? 27017 : @config[:mongo][:port]
      Mongo::MongoClient.new host, port
    end

    def get_db_collection(conn)
      raise ArgumentError.new 'Mongo database not specified' if @config[:db].nil?
      raise ArgumentError.new 'Mongo collection not specified' if @config[:collection].nil?
      conn.db(@config[:db]).collection(@config[:collection])
    end

    def get_mongo_collection
      @conn = get_connection
      get_db_collection @conn
    end

    def query_collection(collection, names)
      collection.find('modelid' => { '$in' => names }).to_a
    end

    def get_collection_data(names)
      begin
        collection = get_mongo_collection
        query_collection collection, names
      ensure
        @conn.close unless @conn.nil?
      end
    end

  end

end