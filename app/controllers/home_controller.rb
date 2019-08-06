class HomeController < ApplicationController
  def index
    @result = {}
    flash[:error] = ''
    request_url = params[:request_url]

    @result = FetchOembedData.call(request_url) if request_url.present?
  rescue => e
    flash[:error] = e.message
  end
end
