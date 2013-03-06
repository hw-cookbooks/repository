module RepositoryHelper
  class << self
    def generate_checksums(base_directory)
      require 'digest/sha1'
      require 'digest/sha2'
      require 'digest/md5'
      result = {'MD5Sum' => [], 'SHA1' => [], 'SHA256' => []}
      Dir.glob("#{base_directory}/**/*").map do |file|
        next if File.directory?(file)
        end_path = file.sub(%r{^#{Regexp.escape(base_directory)}/?}, '')
        size = File.size(file)
        # TODO: Update this to use #<< so we don't read entire file at once
        contents = File.read(file)
        {'SHA1' => Digest::SHA1, 'SHA256' => Digest::SHA256, 'MD5Sum' => Digest::MD5}.each do |key, klass|
          d = klass.new
          d.update(contents)
          result[key] << "#{d.hexdigest} #{size} #{end_path}"
        end
      end
      result
    end
  end
end
