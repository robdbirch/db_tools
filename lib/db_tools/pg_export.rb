module DbTools

  class PgExport

    # pg_dump -h localhost -port  -U username --data-only leadtrack_development > dump/pg_dump_data_20140613

    def initialize(config)
      @config = config
    end

    def get_command
      host = @config[:postgres][:host] || 'localhost'
      port = @config[:postgres][:port] || 5432
      'pg_dump -h ' + host + ' --port ' + port.to_s + ' --username ' + @config[:postgres][:user] + ' --data-only ' + ' --dbname ' + @config[:postgres][:database]
    end

    def execute_command(cmd)
      DbTools.logger.info "Command: #{cmd}"
      if @config[:export_file].nil?
        system cmd
      else
        system cmd + ' >' + @config[:export_file]
      end
    end

    def export
      execute_command get_command
    end

  end

end