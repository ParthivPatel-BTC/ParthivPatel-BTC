# frozen_string_literal: true

class BaseSerializer
  include FastJsonapi::ObjectSerializer

  def serializable_hash
    data = super
    case data[:data]
    when Hash
      data[:data][:attributes]
    when Array
      data[:data].map { |x| x[:attributes] }
    when nil
      nil
    else
      data
    end
  end

  # https://github.com/getsentry/raven-ruby/issues/725;
  # we have to convert our sting to utf-8 to ignore error on encodeing to json
  def self.url_to_file_in_utf_format(study_file)
    open(study_file) { |file| file&.read }.force_encoding('UTF-8')
  rescue Exception => e
    Rollbar.error(e, "Problem with s3 file for encoding to UTF-8 #{study_file}")
    nil
  end

  def self.convert_to_base64(file_path, object)
    Base64.encode64(open(file_path) { |io| io&.read }).gsub(/\n/, '')
  rescue Exception => e
    Rollbar.error(e, "Problem with on s3 study_id: #{object.id} file name: #{object.mobile_preview_image&.url}")
    nil
  end
end
