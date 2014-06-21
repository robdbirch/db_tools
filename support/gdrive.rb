#!/usr/bin/env ruby
require 'google/api_client'
require 'date'
require 'awesome_print'

## Email of the Service Account #
SERVICE_ACCOUNT_EMAIL = '385200327222-argpunek5eei944ku9mtl58f8ra272u7@developer.gserviceaccount.com'

## Path to the Service Account's Private Key file #
SERVICE_ACCOUNT_PKCS12_FILE_PATH = '/Users/rbirch/Downloads/Google Keys/Sandbox App/google-app-sandbox-privatekey.p12'

API_VERSION = 'v2'
TMP_DIR = File.expand_path '../../tmp', __FILE__
CACHED_API_FILE = "#{TMP_DIR}/drive-#{API_VERSION}.cache"
CREDENTIAL_STORE_FILE = "#{TMP_DIR}/#{$0}-oauth2.json"

##
# Build a Drive client instance authorized with the service account
# that acts on behalf of the given user.
#
# @param [String] user_email
#   The email of the user.
# @return [Google::APIClient]
#   Client instance
def build_client(user_email = 'robert.birch@noxaos.com')
  key = Google::APIClient::PKCS12.load_key(SERVICE_ACCOUNT_PKCS12_FILE_PATH, 'notasecret')
  asserter = Google::APIClient::JWTAsserter.new(SERVICE_ACCOUNT_EMAIL,
                                                'https://www.googleapis.com/auth/drive', key)
  client = Google::APIClient.new application_name: 'Sandbox', application_version: '0.0.1'
  client.authorization = asserter.authorize(user_email)
  client
end

def get_drive(client)
  drive = nil
  # Load cached discovered API, if it exists. This prevents retrieving the
  # discovery document on every run, saving a round-trip to API servers.
  if File.exists? CACHED_API_FILE
    File.open(CACHED_API_FILE) do |file|
      drive = Marshal.load(file)
    end
  else
    drive = client.discovered_api('drive', API_VERSION)
    # File.open(CACHED_API_FILE, 'w') do |file|
    #   Marshal.dump(drive, file)
    # end
  end
  drive
end

def insert_file(client, drive, parent_id=nil)
  file = drive.files.insert.request_schema.new ({
      'title' => 'mongo-models-export-20140613011004778.json',
      'description' => "Model from #{DateTime.now.iso8601}",
      'mimeType' => 'text/plain'
  })
  file.parents = [ { 'id' => parent_id } ] unless parent_id.nil?
  backup = File.expand_path '../../tmp/mongo-models-export-20140613011004778.json', __FILE__
  media = Google::APIClient::UploadIO.new(backup, 'text/plain')
  result = client.execute(
      api_method: drive.files.insert,
      body_object: file,
      media: media,
      parameters: {
          'uploadType' => 'multipart',
          'alt' => 'json'
      }
  )
  result.data.to_hash
end

def get_mongo_folder(client, drive)
  result = client.execute(
      :api_method => drive.children.list,
      :parameters => {
          'folderId' => 'root',
          'q' => 'title = "Mongo"'
      }
  )
  if result.status != 200
    puts "An error occurred: #{result.data['error']['message']}"
  end
  result.data.to_hash
end

def share(client, drive, file_id, perm_type='user', user='steve.weagraff@noxaos.com', role='writer')
  new_permission = drive.permissions.insert.request_schema.new(
      {
           'value' => user,
           'type' => perm_type,
           'role' => role
      }
  )
  result = client.execute(
      :api_method => drive.permissions.insert,
      :body_object => new_permission,
      :parameters => {
          'fileId' => file_id,
          'sendNotificationEmails' => false
      }
  )
  if result.status != 200
    puts "An error occurred: #{result.data['error']['message']}"
  end
  result.data.to_hash
end

client = build_client
drive = get_drive client
folder = get_mongo_folder(client, drive)
ap folder
ap folder['items'][0]['id']
file = insert_file client, drive, folder['items'][0]['id']
ap file['id']
shared = share client, drive, file['id']
ap shared







