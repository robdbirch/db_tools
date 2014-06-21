module DbTools

  class LispToJson

    def self.get_exe
      dir = File.expand_path '../../../lib/sbcl', __FILE__
      if RbConfig::CONFIG['host_os'].include? 'linux'
        dir + '/linux/model2json'
      else
        dir + '/osx/model2json'
      end
    end

    def self.as_json(model)
      exe = LispToJson.get_exe
      IO.popen exe, mode='r+' do |pipe|
        pipe.write model
        pipe.close_write
        model = pipe.read
        pipe.close_read
      end
      model
    end

  end

end