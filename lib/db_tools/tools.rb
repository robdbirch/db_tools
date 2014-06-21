require 'pg'
require 'mongo'
require 'json'
require 'zlib'

module DbTools

    class Tools

      def self.zip_it(file)
        Zlib::GzipWriter.open(file + '.gz') do |gz|
          gz.mtime = File.mtime file
          gz.orig_name = File.basename file
          gz.write IO.binread(file)
        end
      end

      def initialize(config)
        @config = config
        if @config[:db_operation] == 'mongo'
          @mongo = get_mongo
        else
          @postgres = nil
        end
      end

      def get_mongo
        if  @config[:direction] == 'export'
          MongoExport.new(@config)
        else
          MongoImport.new(@config)
        end
      end

      def mongo_import

      end

      def mongo_export
        @mongo.export
      end

      def export_json
        @mongo.export_json
      end

      def export_pretty
        @mongo.export_pretty
      end

      def mongo_delete_days_old(days)

      end
  end
end