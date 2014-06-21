require 'spec_helper'
require 'yaml'
require 'mongo'
include Mongo

describe 'mongo' do

  context 'import' do

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
      options
    end

    def get_mongo_connection(options)
      host = options[:mongo][:host] || 'localhost'
      port = options[:mongo][:port] || 27017
      @m_conn = MongoClient.new host, port
    end

    def load_mongo(options)
      @documents = []
      get_mongo_connection options
      @m_db = @m_conn.db('aicore-test')
      col = @m_db['models']
      File.new(File.expand_path('../support/mongo-models-export-20140613011004778.json', __FILE__)).each_line do |line|
        jl = JSON.parse(line)
        @documents << jl
        oid = jl['_id']['$oid']
        jl.delete '_id'
        jl['oid'] = BSON::ObjectId(oid)
        col.insert(jl)
      end
    end

    def clean_mongo
      @m_db['models'].drop
      @m_conn.close
    end

    before(:each) do
      options = get_config
      load_mongo options
      @mi = DbTools::MongoExport.new options
      conn = @mi.get_sql_conn
      conn.exec('DELETE FROM scouts WHERE name = \'keywest2\'')
      conn.exec('INSERT INTO scouts (name, enterprise_id, enabled) VALUES (\'keywest2\', 1, true)')
      conn.close
    end

    after(:each) do
      clean_mongo
      @m_conn.close
      conn = @mi.get_sql_conn
      conn.exec('DELETE FROM scouts WHERE name = \'keywest2\'')
      conn.close
    end

    it 'gets sql connection' do
      conn = nil
      expect { conn = @mi.get_sql_conn }.not_to throw_symbol
      expect { conn.close }.not_to throw_symbol
    end

    it 'executes scout sql query' do
      conn = @mi.get_sql_conn
      results = @mi.execute_query conn
      expect(results.num_tuples).to eq 1
      conn.close
    end

    it 'gets the scout names' do
      conn = @mi.get_sql_conn
      results = @mi.execute_query conn
      expect(results[0]['name']).to eq 'keywest2'
      names = @mi.names_to_array results
      expect(names[0]).to eq 'keywest2'
      conn.close
    end

    it 'get model names' do
      names = @mi.get_sql_model_names
      expect(names[0]).to eq 'keywest2'
    end

    it 'get mongo query' do
      names = @mi.get_sql_model_names
      expect(names[0]).to eq 'keywest2'
      mq = @mi.get_mongo_query names
      expect(mq).to include 'modelid'
      expect(mq).to include 'keywest2'
    end

    it 'mongo export' do
      @mi.config[:export_file] = File.expand_path '../../tmp/test_mongo_export_2.json', __FILE__
      @mi.config[:models] = %w[ keywest2 neuro-issue ]
      @mi.export
      expect(File.exist?(@mi.config[:export_file])).to be true
      exp = File.readlines @mi.config[:export_file]
      expect(exp.size).to eq 2
      File.delete @mi.config[:export_file]
    end

    it 'mongo json export' do
      @mi.config[:export_file] = File.expand_path '../../tmp/test_mongo_export_2.json', __FILE__
      @mi.config[:models] = %w[ keywest2 neuro-issue ]
      @mi.export_json
      expect(File.exist?(@mi.config[:export_file])).to be true
      exp = File.readlines @mi.config[:export_file]
      expect(exp.size).to eq 1
      File.delete @mi.config[:export_file]
    end

    it 'mongo pretty json export', :skip do
      @mi.config[:export_file] = nil
      @mi.config[:models] = %w[ keywest2 neuro-issue ]
      @mi.export_pretty
    end

    it 'zips export' do
      file = @mi.config[:export_file] = File.expand_path '../../tmp/test_mongo_export_2.json', __FILE__
      @mi.config[:models] = %w[ keywest2 neuro-issue ]
      @mi.export_json
      expect(File.exist?(file)).to be true
      exp = File.readlines file
      expect(exp.size).to eq 1
      Tools.zip_it file
      expect(File.exist?(file + '.gz')).to be true
      File.delete file
      File.delete file + '.gz'
    end

  end

end