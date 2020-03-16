class ContactsController < ApplicationController
  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # POST /contacts
  # POST /contacts.json
  def create
    @contact = Contact.new(contact_params)

    respond_to do |format|
      if verify_recaptcha(model: @contact) && @contact.save
        mailer = ContactFormMailer.contact_response(@contact)
        mailer.deliver!
        format.html { redirect_to contact_confirmation_page_path }
        format.json { render :show, status: :created, location: @contact }
      else
        format.html { render 'pages/contact' }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end


  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def contact_params
      params.require(:contact).permit(:first_name, :last_name, :email_address, :questions_comments)
    end
end
