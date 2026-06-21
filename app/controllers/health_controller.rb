class HealthController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  def show
    render plain: "OK", status: 200
  end
end
