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
    CACHED_API_FILE = "drive-#{API_VERSION}.cache"

    def initialize(config)
      set_config config
      init_google
    end

    def set_config(config)
      @config = config
      set_drive_service_params @config[:google][:service],config[:google][:service]
      set_drive_params @config[:google][:drive], config[:google][:drive]
    end

    def set_drive_service_params(service, config)
      service[:email]     = config[:email]     ||  SERVICE_ACCOUNT_EMAIL
      service[:pkey_file] = config[:pkey_file] ||  SERVICE_ACCOUNT_PKCS12_FILE
    end

    def set_drive_params(drive, config)
      drive[:auth_user]         = config[:auth_user]         ||  'robert.birch@noxaos.com'
      drive[:app_name]          = config[:app_name]          ||  'Sandbox'
      drive[:app_version]       = config[:app_version]       ||  '0.0.1'
      drive[:folder]            = config[:folder]            ||  'Mongo'
      drive[:tmp_dir]           = config[:tmp_dir]           ||  TMP_DIR
      drive[:cached_api]        = config[:cached_api]        ||  "#{@config[:google][:drive][:tmp_dir]}/#{CACHED_API_FILE}"
      drive[:share][:users]     = config[:share][:users]     ||  [ 'steve.weagraff@noxaos.com' ]
      drive[:share][:perm_type] = config[:share][:perm_type] ||  'user'
      drive[:share][:role]      = config[:share][:role]      ||  'writer'
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
      if File.exist? @config[:google][:drive][:cached_api]
        File.open(@config[:google][:drive][:cached_api]) do |file|
          @drive = Marshal.load(file)
        end
      else
        @drive = @client.discovered_api('drive', API_VERSION)
        File.open(@config[:google][:drive][:cached_api], 'w') do |file|
          Marshal.dump(@drive, file)
        end
      end
    end

    def delete_file(file, parent='root')
      fid = get_drive_item_id file, parent
      delete_file_id fid
    end

    def delete_file_id(file_id)
      @client.execute(
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
      schema = build_file_schema file, parent_id
      media  = Google::APIClient::UploadIO.new(file, 'text/plain')
      result = do_upload schema, media
      DbTools.logger.debug result.data.to_hash
      raise DbToolsError.new "An error occurred: #{result.data['error']['message']}" if result.status != 200
      result.data.to_hash
    end

    def build_file_schema(file, parent_id)
      schema = @drive.files.insert.request_schema.new ({
          'title' => "#{File.basename(file)}",
          'description' => "Model from #{DateTime.now.iso8601}",
          'mimeType' => 'text/plain'
      })
      schema.parents = [ { 'id' => parent_id } ] unless parent_id.nil?
      schema
    end

    def do_upload(schema, media)
      @client.execute(
          api_method: @drive.files.insert,
          body_object: schema,
          media: media,
          parameters: {
              'uploadType' => 'multipart',
              'alt' => 'json'
          }
      )
    end

    def share(file_id, user, perm_type='user', role='writer')
      new_permission = get_permission user, perm_type, role
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

    def get_permission(user, perm_type, role)
      @drive.permissions.insert.request_schema.new(
          {
              'value' => user,
              'type' => perm_type,
              'role' => role
          }
      )
    end

    def upload_file(file_name, parent_folder=nil)
      folder = parent_folder || @config[:google][:drive][:folder]
      folder_id = get_drive_item_id folder
      file_info = insert_file file_name, folder_id
      share_files @config[:google][:drive][:share][:users], file_info
    end

    def share_files(users, file_info)
      users.each do |user|
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