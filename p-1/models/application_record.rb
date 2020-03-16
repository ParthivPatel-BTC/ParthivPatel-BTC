# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def validate_file(file, messages, extension)
    return if send(file).blank?

    return if send(file).file.extension.downcase == extension

    errors.add file.to_sym, "^please upload #{extension} file in #{messages}"
  end
end
