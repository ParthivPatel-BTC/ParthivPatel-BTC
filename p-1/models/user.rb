# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :text             default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :text
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  provider               :string
#  uid                    :string
#  consent                :boolean
#  study_completion_id    :integer
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  role                   :text
#  user_session_id        :string
#  token                  :text
#  device_id              :text
#

class User < ApplicationRecord
  acts_as_tagger

  crypt_keeper :email, :reset_password_token, :role, :token, :device_id,
               encryptor: :active_support,
               key: ENV['USER_ENCRYPTION_KEY'], salt: ENV['USER_ENCRYPTION_SALT']

  before_create :set_default_role
  after_create :set_study_completions_with_user_id, :update_user_session_data
  # enum role: [:user, :superadmin, :admin]
  has_one :demographic
  has_many :study_completions
  has_many :user_studies
  has_many :user_sensor_details
  has_many :user_device_syncs, dependent: :destroy
  has_many :studies, through: :study_completions
  has_many :user_notifications, dependent: :destroy
  has_one :study, class_name: 'Study', foreign_key: :created_by
  has_many :user_study_pre_registrations, dependent: :destroy

  validates_presence_of :email, on: :update
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
  validate :unique_email

  devise :database_authenticatable, :registerable, :confirmable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook]

  scope :admins, -> { where(admin: true) }
  scope :users,  -> { where(admin: false).or(User.where(admin: nil)) }

  accepts_nested_attributes_for :demographic

  def timeout_in
    return 1.day if superadmin? || admin?
  end

  def delete_all_associated_results(deletion_type_hash)
    UserStudy.where(user_id: self.id).destroy_all

    self.study_completions.destroy_all

    feedback = Feedback.create(user_id: self.id, email: self.email, feedback_type: deletion_type_hash[:key], content: deletion_type_hash[:content])
    return feedback
  end

  def set_nil_for_all_associated_results(deletion_type_hash)
    feedback = Feedback.create(user_id: self.id, email: self.email, feedback_type: deletion_type_hash[:key], content: deletion_type_hash[:content])
    if self.demographic
      self.demographic.update_attributes(feedback_id: feedback.id, user_id: nil)
    end

    UserStudy.where(user_id: self.id).update_all(user_id: nil, feedback_id: feedback.id)

    StudyCompletion.where(user_id: self.id).update_all(user_id: nil, feedback_id: feedback.id)
    return feedback
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
    end
  end

  def is_admin?
    self.admin?
  end

  def is_superadmin?
    self.superadmin?
  end

  def set_consent
    self.update(consent: true)
  end

  def set_study_completions_with_user_id
    if self.study_completion_id
      study_completion = StudyCompletion.find_by(id: self.study_completion_id)
      if study_completion
        study_completion.update(user_id: self.id)

        if study_completion.demographic
          study_completion.demographic.update(user_id: self.id)
        end
      end
    end
    true
  end

  def start_study study_id
    user_study = UserStudy.where(user_id: self.id, study_id: study_id).first
    if user_study
      user_study.update(started_at: Time.zone.now, start_count: user_study.start_count + 1)
    else
      UserStudy.create(user_id: self.id, study_id: study_id, started_at: Time.zone.now)
    end
  end

  def set_default_role
    self.role = 0 if read_attribute(:role).blank?
  end

  def role
    read_attribute(:role).to_i
  end

  def user?
    role == 0
  end

  def superadmin?
    role == 1
  end

  def admin?
    role == 2
  end

  def unique_email
    user = User.search_by_plaintext(:email, email)&.first
    if user.present? && user != self
      errors.add(:email, 'has already been taken.')
    end
  end

  # <:user_id>
  # If current_user exists,
  #   Recommended studies are calculated based on current_user's completed studies
  # <:current_user_session_id>
  # If user hasn't signed in and results are saved based on :current_user_session_id
  #   Recommended studies are calculated based on :user_session_id in study_completion
  # <:study_taken>
  # Recommendation of studies based on study taken
  def self.recommended_studies(user_id: nil, current_user_session_id: nil, study_taken: [])
    completed_studies = current_completed_studies(user_id: user_id, current_user_session_id: current_user_session_id).distinct.pluck(:study_id)
    same_tagged_studies = Study.is_published.tagged_with(study_taken&.tag_list, any: true).pluck(:id) - completed_studies

    random_studies = []
    if same_tagged_studies.count < 4
      random_studies = (Study.is_published.ids.sample(10) - same_tagged_studies - completed_studies)
    end

    Study.is_published.where(id: (same_tagged_studies + random_studies).first(4))
  end

  # If current_user exists,
  #   Completed studies are calculated based on current_user's completed studies
  # If user hasn't signed in and results are saved based on :current_user_session_id
  #   Completed studies are calculated based on :user_session_id in study_completion
  def self.current_completed_studies(user_id: nil, current_user_session_id: nil)
    if user_id
      StudyCompletion.where(user_id: user_id)
    elsif current_user_session_id
      StudyCompletion.where(user_session_id: current_user_session_id)
    else # In some cases, user_id as well as
      []
    end
  end

  def update_user_session_data
    if user_session_id.present?
      current_session_id, study_id = user_session_id.split(':').map(&:to_i)
      # Associate demographics
      Demographic.where(user_session_id: user_session_id).update_all(user_id: self.id, user_session_id: -1)

      # Associate user_study
      UserStudy.where('user_id IS NULL AND user_session_id iLIKE ?', "#{current_session_id}%").update_all(user_id: self.id, user_session_id: -1)

      # Associate study_completions
      StudyCompletion.where('user_id IS NULL AND user_session_id iLIKE ?', "#{current_session_id}%").update_all(user_id: self.id, user_session_id: -1)
    end
  end
end
