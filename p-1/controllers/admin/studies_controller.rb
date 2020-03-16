# frozen_string_literal: true

class Admin::StudiesController < Admin::AdminController
  before_action :set_study, only: %i[show edit update destroy
                                     delete_js_presentation_file
                                     delete_mobile_js_presentation_file
                                     delete_json_results_schema_file
                                     delete_study_css_file
                                     update_study_status]

  before_action :set_study_detail, only: %i[delete_study_detail_css_file
                                            delete_study_detail_embed_code_file
                                            delete_study_detail_mobile_embed_code_file]
  before_action :set_tag_list, :set_estimated_time, only: %i[create update]

  # GET /studies
  # GET /studies.json
  def index
    @studies = Study.find_studies_with_details(current_user.superadmin? ? nil : current_user&.id)
    @study_statistics_by_id = Study.get_study_statistics(studies: @studies)
    authorize! :read, StudyCompletion
  end

  # GET /studies/1
  # GET /studies/1.json
  def show
    redirect_to edit_admin_study_path(@study)
  end

  # GET /studies/new
  def new
    @study = Study.new(type: params.dig(:study_type, :type))
    build_related_entities
    @form_button_text = 'Add New Study'
  end

  # GET /studies/1/edit
  def edit
    @form_button_text = 'Update Study'
    add_notification_if_needed
  end

  # POST /studies
  # POST /studies.json
  def create
    @study = Study.new(study_params)
    @study.created_by = current_user.id
    respond_to do |format|
      if @study.save
        format.html { redirect_to edit_admin_study_path(@study), notice: 'Study was successfully created.' }
        format.json { render :show, status: :created, location: admin_dashboard_index_path }
      else
        params[:study_type] = JSON.parse(params[:study_type])
        format.html { render :edit }
        format.json { render json: @study.errors, status: :unprocessable_entity }
      end
    rescue Exception => e
      @error = true
      flash[:error] = I18n.t('failure.something_went_wrong')
      format.js
      Rollbar.error(e.message,
                    object_info: @study)
    end
  end

  # PATCH/PUT /studies/1
  # PATCH/PUT /studies/1.json
  def update
    @form_path = admin_study_path(@study)
    respond_to do |format|
      if @study.update(study_params)
        @study.active? ? @study.update(published: true) : @study.update(published: false)
        format.html { redirect_to edit_admin_study_path(@study), notice: 'Study was successfully updated.' }
        format.json { render :show, status: :ok, location: admin_dashboard_index_path }
      else
        add_notification_if_needed
        format.html { render :edit }
        format.js { render :edit }
        format.json { render json: @study.errors, status: :unprocessable_entity }
      end
    rescue Exception => e
      format.html { render :edit }
      flash[:error] = I18n.t('failure.something_went_wrong')
      Rollbar.error(e.message,
                    object_info: @study)
    end
  end

  def update_study_order
    @studies = params['studies']
    @studies.each.with_index(1) do |study, index|
      study_to_update = Study.find(study[:id])
      study_to_update.update(study_order: index)
    end
  end

  def update_study_status
    @study.active? ? @study.deactivated : @study.activated
    if @study.update(published: !@study.published)
      render json: { success: true, message: 'Study status successfully updated.' }
    else
      render json: {
        success: false,
        message: 'There are some errors. Please go to edit page and update.',
        id: @study.id,
        status: @study.published
      }
    end
  end
  def delete_js_presentation_file
    @study.remove_js_presentation_url!
    update_study_and_redirect(@study, 'Js Presentation')
  end

  def delete_mobile_js_presentation_file
    @study.remove_mobile_js_presentation_url!
    update_study_and_redirect(@study, 'Mobile Js Presentation')
  end

  def delete_json_results_schema_file
    @study.remove_json_results_schema!
    update_study_and_redirect(@study, 'Json Results Schema')
  end

  def delete_study_css_file
    @study.remove_css_url!
    update_study_and_redirect(@study, 'Study CSS')
  end

  def delete_study_detail_embed_code_file
    @study_detail.remove_embed_code!
    update_study_detail_and_redirect(@study_detail, 'Embed Code')
  end

  def delete_study_detail_css_file
    @study_detail.remove_css_url!
    update_study_detail_and_redirect(@study_detail, 'Study Detail CSS')
  end

  def delete_study_detail_mobile_embed_code_file
    @study_detail.remove_mobile_embed_code!
    update_study_detail_and_redirect(@study_detail, 'Mobile Embed Code')
  end

  # DELETE /studies/1
  # DELETE /studies/1.json

  def destroy
    if @study.destroy
      render json: { success: true, message: 'Study was successfully destroyed.' }
    else
      render json: { success: false, message: 'Study cannot be destroyed. We will contact you soon.' }
      Rollbar.error(object_info: @study)
    end
  end

  def tags
    respond_to do |format|
      format.html
      format.json { render json: Study.search_tags(params[:q]) }
    end
  end

  def set_estimated_time
    params[find_type][:estimated_completion_time] = "#{params.dig(find_type, :estimated_completion_time)} #{params.dig(:min_or_hour)}"
  end

  private

  def remove_file_name
    @study.preview_image = nil
    @study.mobile_preview_image = nil
    @study.study_details.destroy_all
    build_related_entities
  end

  def add_notification_if_needed
    if @study.same_notification
      notifications = @study.study_details.first.study_group_notifications
      if (notifications.first.type == StudyGroupNotification::RANDOM_NOTIFICATION) && (notifications.count == 1)
        (@study.number_of_notification - 1).times do
          notification = notifications.build
          notification.type = StudyGroupNotification::RANDOM_NOTIFICATION
        end
      end
    end
  end

  def update_study_and_redirect(object, file_text)
    respond_to do |format|
      if object.save
        format.html { redirect_to edit_admin_study_path(object), notice: t('success.file_deleted', file_name: file_text) }
        format.json { render :show, status: :ok, location: edit_admin_study_path(object) }
      else
        format.html { render :edit }
        format.json { render json: object.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_study_detail_and_redirect(object, file_text)
    respond_to do |format|
      if object.save
        format.html { redirect_to edit_admin_study_path(object.study), notice: t('success.file_deleted', file_name: file_text) }
        format.json { render :show, status: :ok, location: edit_admin_study_path(object.study) }
      else
        format.html { render :edit }
        format.json { render json: object.errors, status: :unprocessable_entity }
      end
    end
  end

  def build_related_entities
    case params.dig(:study_type, :type)
    when Study::GENERAL_TYPE
      @study.build_related_entities
    else
      @study.build_related_entities(
        number_of_days: params.dig(:study_type, :number_of_days),
        notifications_per_day: params.dig(:study_type, :number_of_notification),
        same_study_material: params.dig(:study_type, :same_study_material),
        same_notification_schedule: params.dig(:study_type, :same_notification_schedule)
      )
    end
  end

  def set_tag_list
    return unless params[find_type][:tag_list]&.include?('New')

    params[find_type][:tag_list].gsub!(/New:\s/, '')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_study
    if Study.find_by(id: params[:id])&.type == Study::GENERAL_TYPE
      @study = Study.includes(:study_details).find_by(id: params[:id])
    else
      @study = Study.includes(study_details: :study_group_notifications).find_by(id: params[:id])
    end
    return if @study

    redirect_to(admin_dashboard_index_url, notice: 'Study does not exists')
  end

  def set_study_detail
    @study_detail = StudyDetail.find_by(id: params[:id])
    @study = @study_detail.study
    return if @study_detail

    redirect_to(admin_dashboard_index_url, notice: 'Study detail does not exists')
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def study_params
    params.require(find_type).permit(
      :name, :description, :js_presentation_url,
      :css_url, :json_results_schema, :max_score, :preview_image,
      :estimated_completion_time, :purpose_of_study,
      :understading_the_results, :related_research, :published, :tag_list,
      :mobile_js_presentation_url, :mobile_preview_image, :split_week,
      :pre_registration_start_date, :type, :start_date, :frequency,
      :same_notification, :number_of_notification, :same_study_material,
      :pre_registration_required, :aasm_state, :registration_page_description,
      study_details_attributes: [
        :id, :embed_code, :mobile_embed_code, :css_url,
        :number_of_notifications,
        study_group_notifications_attributes: [
          :id, :start_time, :end_time, :weekly_notifications,
          :number_of_reminders, :reminder_spacing, :type,
          :participant_specified, :sun, :mon, :tue, :wed, :thu, :fri, :sat
        ]
      ]
    )
  end

  def find_type
    return Study::IST_MODEL_NAME['EmaWeekly'] if params.dig(Study::IST_MODEL_NAME['EmaWeekly']).present?

    return Study::IST_MODEL_NAME['EmaDaily'] if params.dig(Study::IST_MODEL_NAME['EmaDaily']).present?

    return Study::IST_MODEL_NAME['General'] if params.dig(Study::IST_MODEL_NAME['General']).present?
  end
end
