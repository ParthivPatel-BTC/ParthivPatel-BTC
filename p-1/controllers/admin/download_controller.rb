class Admin::DownloadController < Admin::AdminController
  def create
    if params[:study_ids].blank? || params[:study_ids].keys.blank?
      redirect_to admin_studies_path,  :flash => { error: "Please select at least one study" }
      return
    end
    @downloaded_study_ids = params[:study_ids].keys
    @download_type = params[:download_type]
    @download_instance = Download.new(study_ids: @downloaded_study_ids, download_type: @download_type)

    authorize! :read, StudyCompletion
    if @download_instance.save
      puts "arf!"
      redirect_to admin_download_path(@download_instance)#, :format => :csv)
      # respond_to do |format|
      #   format.html { render text: @download_instance.to_csv }
      #   format.csv { send_data @download_instance.to_csv, filename: "data.csv"}
      # end
    else
      redirect_to admin_studies_path, notice: "Please select a result type"
    end
  end

  def show
    @download = Download.find(params[:id])
    send_data @download.to_csv, filename: "data.csv"
  end
end
