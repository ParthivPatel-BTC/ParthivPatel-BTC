# frozen_string_literal: true

class DemographicData < ActiveModelSerializers::Model
  attributes :version, :static_data
  def version
    GlobalConstants::DEMOGRAPHICS[:version]
  end

  def static_data
    static_data = []
    Rails.cache.fetch((GlobalConstants::DEMOGRAPHICS[:version]).to_s) do
      static_data << {
        countries: GlobalConstants::DEMOGRAPHICS[:countries],
        gender: GlobalConstants::DEMOGRAPHICS[:gender],
        ethnicity: GlobalConstants::DEMOGRAPHICS[:ethnicity],
        education: GlobalConstants::DEMOGRAPHICS[:education],
        political_on_social: GlobalConstants::DEMOGRAPHICS[:political_on_social],
        political_on_economic: GlobalConstants::DEMOGRAPHICS[:political_on_economic],
        language: GlobalConstants::DEMOGRAPHICS[:language]
      }
    end
  end
end
