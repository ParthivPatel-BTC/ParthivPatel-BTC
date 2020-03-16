# frozen_string_literal: true

class AboutUs < ActiveModelSerializers::Model
  attributes :version, :static_data, :team

  def version
    GlobalConstants::STATIC_PAGE_CONTENT_VERSION
  end

  def static_data
    static_data = []
    Rails.cache.fetch("#{GlobalConstants::STATIC_PAGE_CONTENT_VERSION}about_us") do
      GlobalConstants::ABOUT_US_HEADER.each do |key, value|
        static_data << { 'title': value, 'disc': GlobalConstants::ABOUT_US_HEADER_CONTENT[key] }
      end
      static_data
    end
  end

  def team
    Rails.cache.fetch("#{GlobalConstants::STATIC_PAGE_CONTENT_VERSION}about_us_team") do
      team_with_base64_image
    end
  end

  def team_with_base64_image
    team_with_base64_image = []
    GlobalConstants::TEAM.each do |hash|
      hash[:base64] = Base64.encode64(open(hash[:img_url]) { |io| io&.read }).gsub(/\n/, '')
      team_with_base64_image << hash
    end
  end
end
