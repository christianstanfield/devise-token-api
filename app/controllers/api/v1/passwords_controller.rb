class Api::V1::PasswordsController < Devise::SessionsController
  skip_before_filter :verify_authenticity_token, if: :json_request?
  include ApiHelper

  def create
    @user = User.send_reset_password_instructions params[:user]

    if successfully_sent? @user
      render json: { success: true }, status: :accepted
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end
end
