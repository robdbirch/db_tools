require 'pg'
require 'mongo'
require 'json'
require 'awesome_print'

module DbTools

  class MongoExport

    SQL_SCOUTS = 'SELECT id, name, enterprise_id FROM SCOUTS'
    SQL_QUERY  = 'SELECT DISTINCT(name), ss.query FROM scouts s, scout_services ss WHERE s.id = ss.scout_id;'

    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def get_sql_conn
      host = @config[:postgres][:host] || 'localhost'
      port = @config[:postgres][:port] ||  5432
      DbTools.logger.info "Connecting to host: #{host} on port: #{port} database #{@config[:postgres][:database]} user: #{@config[:postgres][:user]} password: #{@config[:postgres][:password]}"
      PG.connect host: host, port: port, dbname: @config[:postgres][:database], user: @config[:postgres][:user], password: @config[:postgres][:password]
    end

    def get_sql_query
      SQL_SCOUTS
    end

    def execute_query(conn)
      query = get_sql_query
      conn.exec query
    end

    def names_to_array(results)
      names = []
      results.each do |scout|
        names <<  scout['name']
      end
      names
    end

    def get_sql_model_names
      names = []
      begin
        conn = get_sql_conn
        results = execute_query conn
        names = names_to_array results
      rescue => e
        DbTools.logger.error e.message
        DbTools.logger.error e.backtrace
        raise e
      ensure
        conn.close unless conn.nil?
      end
      names
    end

    def get_model_names
      if @config[:models].nil?
        get_sql_model_names
      else
        @config[:models]
      end
    end

    def get_mongo_query(names)
      raise ArgumentError.new 'No model names to export from mongo' if names.size == 0
      if @config[:query].nil?
        @config[:query] = "\'{ modelid: { $in : %s } }\'" % names.to_json
      end
      DbTools.logger.debug @config[:query]
      @config[:query]
    end

    def get_command(query)
      outfile = @config[:export_file].nil? ? nil : '--out ' +  @config[:export_file]
      cmd = "mongoexport --db #{@config[:db]} --collection #{@config[:collection]} --query #{query} #{outfile}"
      DbTools.logger.info cmd
      cmd
    end

    def get_query
      names = get_model_names
      get_mongo_query names
    end

    def export
      command = get_command get_query
      system command
    end

    def get_json
      mdb = MongoDB.new @config
      names = get_model_names
      mdb.get_collection_data names
    end

    def output_json(models)
      if @config[:export_file].nil?
        puts models
      else
        File.write(@config[:export_file], models)
        if @config[:gzip]

        end
      end
    end

    def export_json
      models = get_json
      models.each do |model|
        model['store'] << LispToJson.as_json(model['store'])
      end
      output_json models
    end

    def build_pretty_store(store)
      fc = store['featureCounts']
      pfc = [ ]
      fc.each do |feature, probs|
        f = feature + ': '
        probs.each do |label, prob|
          f = "#{f}#{label}: #{prob}, "
        end
        f[-1] = ''
        f[-1] = ''
        pfc << f
      end
      store['featureCounts'] = pfc
      store
    end

    def export_pretty
      j_models = []
      models = get_json
      models.each do |model|
        store = LispToJson.as_json model['store']
        j_store = JSON.parse store
        j_model = JSON.parse model.to_json
        j_model.delete 'store'
        p_store = build_pretty_store j_store
        j_model['store'] = p_store
        j_models << JSON.pretty_generate(j_model)
      end
      output_json j_models
    end
  end
end