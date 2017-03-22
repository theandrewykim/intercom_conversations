class ConversationsController < BaseController
before_action :set_request_params, only: [:create]

  def index
    #check google authorization
    begin

      if authorization_code == nil
        credentials = Google::Auth::UserRefreshCredentials.new(client_id: ENV['GOOGLE_CLIENT_EMAIL'], client_secret: ENV['GOOGLE_CLIENT_SECRET'], scope: ["https://www.googleapis.com/auth/drive", "https://spreadsheets.google.com/feeds/"], redirect_uri: "/")
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