class Api::V1::SessionsController < Devise::SessionsController
  prepend_before_filter :require_no_authentication, only: [:create]
  skip_before_filter :verify_authenticity_token, if: :json_request?
  skip_before_filter :verify_signed_out_user, if: :json_request?
  before_filter :validate_auth_token, except: :create
  include Devise::Controllers::Helpers
  include ApiHelper

  def create
    resource = User.find_for_database_authentication email: sign_in_params[:email]

    if resource && resource.valid_password?(sign_in_params[:password])
      sign_in :user, resource
      resource.ensure_authentication_token!
      render json: resource, status: :created
    else
      render json: { errors: [t('api.v1.sessions.invalid_login')] }, status: :unauthorized
    end
  end

  def destroy
    resource.reset_authentication_token!
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    render json: { success: true }, status: :accepted
  end

  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end
