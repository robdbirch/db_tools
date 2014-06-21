require 'google/api_client'
require 'date'
require 'awesome_print'

module DbTools

  class GoogleDrive
    ## Email of the Service Account #
    SERVICE_ACCOUNT_EMAIL = '385200327222-argpunek5eei944ku9mtl58f8ra272u7@developer.gserviceaccount.com'

    ## Path to the Service Account's Private Key file #
    SERVICE_ACCOUNT_PKCS12_FILE = '/Users/rbirch/Downloads/Google Keys/Sandbox App/google-app-sandbox-privatekey.p12'

    API_VERSION = 'v2'
    TMP_DIR = File.expand_path '../../../tmp', __FILE__
    CACHED_API_FILE = "#{TMP_DIR}/drive-#{API_VERSION}.cache"

    def initialize(config)
      set_config config
      init_google
    end

    def set_config(config)
      @config = config
      @config[:google][:service][:email]           = config[:google][:service][:email]           ||  SERVICE_ACCOUNT_EMAIL
      @config[:google][:service][:pkey_file]       = config[:google][:service][:pkey_file]       ||  SERVICE_ACCOUNT_PKCS12_FILE
      @config[:google][:drive][:auth_user]         = config[:google][:drive][:auth_user]         ||  'robert.birch@noxaos.com'
      @config[:google][:drive][:app_name]          = config[:google][:drive][:app_name]          ||  'Sandbox'
      @config[:google][:drive][:app_version]       = config[:google][:drive][:app_version]       ||  '0.0.1'
      @config[:google][:drive][:folder]            = config[:google][:drive][:folder]            ||  'Mongo'
      @config[:google][:drive][:tmp_dir]           = config[:google][:drive][:tmp_dir]           ||  TMP_DIR
      @config[:google][:drive][:cached_api]        = config[:google][:drive][:cached_api]        ||  CACHED_API_FILE
      @config[:google][:drive][:share][:users]     = config[:google][:drive][:share][:users]     ||  [ 'steve.weagraff@noxaos.com' ]
      @config[:google][:drive][:share][:perm_type] = config[:google][:drive][:share][:perm_type] ||  'user'
      @config[:google][:drive][:share][:role]      = config[:google][:drive][:share][:role]      ||  'writer'
    end

    def init_google
      build_client
      set_drive_api
    end

    def build_client
      key      = Google::APIClient::PKCS12.load_key(@config[:google][:service][:pkey_file], 'notasecret')
      asserter = Google::APIClient::JWTAsserter.new(@config[:google][:service][:email],
                                                    'https://www.googleapis.com/auth/drive',
                                                    key)
      @client   = Google::APIClient.new application_name: 'Sandbox', application_version: '0.0.1'
      @client.authorization = asserter.authorize(@config[:google][:drive][:auth_user] )
    end

    def set_drive_api
      # Load cached discovered API, if it exists. This prevents retrieving the
      # discovery document on every run, saving a round-trip to API servers.
      if File.exist? CACHED_API_FILE
        File.open(CACHED_API_FILE) do |file|
          @drive = Marshal.load(file)
        end
      else
        @drive = @client.discovered_api('drive', API_VERSION)
        File.open(CACHED_API_FILE, 'w') do |file|
          Marshal.dump(@drive, file)
        end
      end
    end

    def delete_file(file, parent='root')
      fid = get_drive_item_id file, parent
      delete_file_id fid
    end

    def delete_file_id(file_id)
      result = @client.execute(
          :api_method => @drive.files.delete,
          :parameters => { 'fileId' => file_id }
      )
    end

    def get_drive_item(query, folderId='root')
      result = @client.execute(
          :api_method => @drive.children.list,
          :parameters => {
              'folderId' => folderId,
              'q' => query
          }
      )
      DbTools.logger.debug result.data.to_hash
      raise DbToolsError.new "An error occurred: #{result.data['error']['message']}" if result.status != 200
      result.data.to_hash
    end

    def get_drive_item_id(title, parent='root')
      result = get_drive_item "title = \"#{title}\"", parent
      if result['items'].size > 0
        result['items'][0]['id']
      else
        {}
      end
    end

    def insert_file(file, parent_id=nil)
      schema = @drive.files.insert.request_schema.new ({
          'title' => "#{File.basename(file)}",
          'description' => "Model from #{DateTime.now.iso8601}",
          'mimeType' => 'text/plain'
      })
      schema.parents = [ { 'id' => parent_id } ] unless parent_id.nil?

      media = Google::APIClient::UploadIO.new(file, 'text/plain')
      result = @client.execute(
          api_method: @drive.files.insert,
          body_object: schema,
          media: media,
          parameters: {
              'uploadType' => 'multipart',
              'alt' => 'json'
          }
      )
      DbTools.logger.debug result.data.to_hash
      raise DbToolsError.new "An error occurred: #{result.data['error']['message']}" if result.status != 200
      result.data.to_hash
    end

    def share(file_id, user, perm_type='user', role='writer')
      new_permission = @drive.permissions.insert.request_schema.new(
          {
              'value' => user,
              'type' => perm_type,
              'role' => role
          }
      )
      result = @client.execute(
          :api_method => @drive.permissions.insert,
          :body_object => new_permission,
          :parameters => {
              'fileId' => file_id,
              'sendNotificationEmails' => false
          }
      )
      DbTools.logger.debug result.data.to_hash
      raise DbToolsError.new("An error occurred: #{result.data['error']['message']}") if result.status != 200
      result.data.to_hash
    end

    def upload_file(file_name, parent_folder=nil)
      folder = parent_folder || @config[:google][:drive][:folder]
      folder_id = get_drive_item_id folder
      file_info = insert_file file_name, folder_id
      @config[:google][:drive][:share][:users].each do |user|
        share(
            file_info['id'],
            user,
            @config[:google][:drive][:share][:perm_type],
            @config[:google][:drive][:share][:role]
        )
      end
    end

  end
end