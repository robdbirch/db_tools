require 'spec_helper'
require 'yaml'

describe 'google drive' do

  context 'upload' do

    def get_config
      options = {}
      options[:config] = File.expand_path '../../config/db_tools.yml', __FILE__
      options[:db]='aicore'
      options[:export_file]= File.expand_path '../support/mongo-models-export-20140613011004778.json', __FILE__
      options[:direction] = 'import'
      options[:data_dir]=nil
      options[:models]=nil
      options[:json]=false
      options[:pretty_json] = false
      config = YAML.load(File.read (options[:config]))
      options.merge! config.symbolize_keys
      options
    end

    before(:each) do
      @config = get_config
      @gd = GoogleDrive.new @config
      delete_file
    end

    after(:each) do
      delete_file
    end

    def delete_file
      file = File.basename @config[:export_file]
      mid = @gd.get_drive_item_id 'Mongo'
      @gd.delete_file file, mid
    end

    it 'get folder' do
      folder = @gd.get_drive_item "title =  \"#{@config[:google][:drive][:folder]}\""
      expect(folder['selfLink']).to include 'Mongo'
      expect(folder['items'].size).to eq 1
    end

    it 'get folder id' do
      fid = @gd.get_drive_item_id @config[:google][:drive][:folder]
      expect(fid).not_to be_nil
    end

    it 'insert a file'  do
      mid = @gd.get_drive_item_id 'Mongo'
      file = @config[:export_file]
      result = @gd.insert_file file, mid
      expect(result['originalFilename']).to eq File.basename @config[:export_file]
    end

    it 'delete a file'  do
      file = File.basename @config[:export_file]
      mid = @gd.get_drive_item_id 'Mongo'
      fid = @gd.get_drive_item_id file, mid
      @gd.insert_file @config[:export_file], mid if fid.size == 0
      @gd.delete_file file, mid
      fid = @gd.get_drive_item_id file, mid
      expect(fid.size).to eq 0
    end

    it 'share a file'  do
      folder = @config[:google][:drive][:folder]
      folder_id = @gd.get_drive_item_id folder
      file_name = @config[:export_file]
      file_info = @gd.insert_file file_name, folder_id
      @config[:google][:drive][:share][:users].each do |user|
        result = @gd.share(
              file_info['id'],
              user,
              @config[:google][:drive][:share][:perm_type],
              @config[:google][:drive][:share][:role]
          )
        expect(result['emailAddress']).to eq 'steve.weagraff@noxaos.com'
      end
    end

  end

end


