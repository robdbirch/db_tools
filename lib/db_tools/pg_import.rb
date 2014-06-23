module DbTools


  class PgImport

    def initialize(config)
      @config = config
    end

    def get_command
      host = 'localhost' || @config[:postgres][:host]
      port = 5432 || @config[:postgres][:port]
      'psql -h ' + host + ' --port ' + port.to_s + ' --username ' + @config[:postgres][:user] + ' --dbname ' + @config[:postgres][:database]
    end

    def execute_command(cmd)
      if @config[:import_file].nil?
          system cmd + ' < '
        else
          system cmd + ' < ' + @config[:import_file]
      end
    end

    def import
      cmd = get_command
      DbTools.logger.info "Command: #{cmd}"
      execute_command cmd
    end

  end

end