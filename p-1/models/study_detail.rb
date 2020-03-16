# frozen_string_literal: true

# == Schema Information
#
# Table name: study_details
#
#  id                      :bigint           not null, primary key
#  study_id                :bigint
#  embed_code              :string
#  mobile_embed_code       :string
#  css_url                 :string
#  end_date                :datetime
#  number_of_notifications :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

# study group model
class StudyDetail < ApplicationRecord
  default_scope { order(:created_at) }
  belongs_to :study
  after_save :update_study

  mount_uploader :embed_code, StudyJavascriptUploader
  mount_uploader :mobile_embed_code, StudyJavascriptUploader
  mount_uploader :css_url, StudyCssUploader

  has_many :study_group_notifications, dependent: :destroy
  accepts_nested_attributes_for :study_group_notifications,
                                allow_destroy: true
  validates :embed_code, presence: { message: '^Upload Web Js file' }, if: :study_active?
  validates :css_url, presence: { message: '^Upload css file' }, if: :study_active?
  validates :mobile_embed_code, presence: { message: '^Upload mobile js file' }, if: :study_active?
  validate :file_extension, if: :study_active?

  validates_associated :study_group_notifications, message: proc { |_p, meta| study_group_notifications_message(meta) }

  def self.study_group_notifications_message(meta)
    e = []
    meta[:value].each do |notification|
      e << notification.errors.full_messages
    end
    e.flatten.uniq
  end

  def update_study
    study.touch
  end

  def study_active?
    study.active?
  end

  def file_extension
    validate_file('embed_code', 'Web Js', 'js')
    validate_file('mobile_embed_code', 'Mobile Js', 'js')
    validate_file('css_url', 'Stylesheet(.css file)', 'css')
  end
end
