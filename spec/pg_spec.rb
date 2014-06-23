require 'spec_helper'
require 'yaml'
require 'pg'
require 'fileutils'

describe 'postgres' do

  def get_config
    options = {}
    options[:config] = File.expand_path '../../config/db_tools.yml', __FILE__
    options[:db]='aicore'
    options[:collection]='models'
    options[:export_file]=nil
    options[:direction] = 'import'
    options[:data_dir]=nil
    options[:models]=nil
    options[:json]=false
    options[:pretty_json] = false
    config = YAML.load(File.read (options[:config]))
    options.merge! config.symbolize_keys
    options[:postgres][:database] = 'leadtrack_test'
    options
  end

  def get_conn(config)
    host = config[:postgres][:host] || 'localhost'
    port = config[:postgres][:port] ||  5432
    DbTools.logger.info "Connecting to host: #{host} on port: #{port} database #{config[:postgres][:database]} user: #{config[:postgres][:user]} password: #{config[:postgres][:password]}"
    PG.connect host: host, port: port, dbname: config[:postgres][:database], user: config[:postgres][:user], password: config[:postgres][:password]
  end

  def get_scouts
   [
      [6,	"FrankensteinAlert",	"Doctor Runs a Muck",	66,	false],
      [274,	"blt2",	"blt2",	1,	true],
      [3,	"keywestbob1",	"The Inn At Key West Scout",	2,	false]
   ]
  end

  def get_insert
      'INSERT INTO scouts (id, name, description, enterprise_id, enabled) VALUES ($1, $2, $3, $4, $5)'
  end

  context 'export/import' do

    def delete_scouts
      @conn.exec 'DELETE FROM scouts;'
    end

    def clean_up
      File.delete @exp1_file unless @exp1_file.nil?
      delete_scouts
    end

    before(:each) do
      @config = get_config
      @conn = get_conn @config
      clean_up
      @conn.prepare('st', get_insert)
      get_scouts.each do |s|
        @conn.exec_prepared('st', s)
      end
      @exp1_file = File.expand_path '../../tmp/pg_test.export', __FILE__
    end

    after(:each) do
      clean_up
      @conn.close unless @conn.nil?
    end

    it 'export' do
      @config[:postgres][:database] = 'leadtrack_test'
      @config[:export_file] = @exp1_file
      pex = PgExport.new @config
      cmd = pex.get_command
      puts "#{cmd}"
      expect(cmd).to include 'localhost'
      expect(cmd).to include '--data-only'
      pex.execute_command cmd
      expect(File.exist? @config[:export_file]).to be true
    end

    it 'import', :focus do
      @config[:postgres][:database] = 'leadtrack_test'
      @config[:export_file] = @exp1_file
      pex1 = PgExport.new @config
      pex1.export
      expect(File.exist? @exp1_file).to be true
      delete_scouts
      select_scouts = 'SELECT * FROM scouts;'
      r = @conn.exec select_scouts
      expect(r.num_tuples).to eq 0
      @config[:import_file] = @exp1_file
      pimp = PgImport.new @config
      pimp.import
      r = @conn.exec select_scouts
      expect(r.num_tuples).to eq 3
    end


  end

end