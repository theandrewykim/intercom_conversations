class ConversationsController < BaseController
before_action :set_request_params, only: [:create]

  def index
    #check google authorization
    begin

      if defined?(authorization_code) == nil
        credentials = Google::Auth::UserRefreshCredentials.new(client_id: "662603162232-7fr0jjm7a0lda0easvj8l7le77qp3u00.apps.googleusercontent.com", client_secret: "kGb3PoV4TU5gbwswIfSe3HqK", scope: ["https://www.googleapis.com/auth/drive", "https://spreadsheets.google.com/feeds/"], redirect_uri: "/")
        session = GoogleDrive::Session.from_credentials(credentials)
        redirect_to root_path
      else
        credentials.code = authorization_code
        credentials.fetch_access_token!
        session = GoogleDrive.login_with_oauth(credentials)
        @google_auth = 1
      end
      begin
        ws = session.spreadsheet_by_key(ENV['GOOGLE_SPREADSHEET_KEY']).worksheets[0]
        @google_auth = 2
      rescue Google::Apis::ClientError
      end
    rescue RuntimeError
      @google_auth = 0
    end
    #check intercom authorization
    begin
      intercom = Intercom::Client.new(token: ENV['INTERCOM_KEY'])
      intercom.admins.all.first
      @intercom_auth = true
    rescue
      @intercom_auth = false
    end
  end

  def create
    # To record this asynchronously:
    # Sidekiq::Client.enqueue(RecordConversation, @request_params["data"]["item"]["id"])
    RecordConversation.new.perform(@request_params["data"]["item"]["id"])
    head :ok
  end

end 