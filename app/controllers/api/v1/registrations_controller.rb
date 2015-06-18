class Api::V1::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_authenticity_token, if: :json_request?
  skip_before_filter :authenticate_scope!, only: [:update]
  before_filter :validate_auth_token, except: :create
  include ApiHelper

  def create
    build_resource sign_up_params

    if resource.save

      expire_session_data_after_sign_in! unless resource.active_for_authentication?
      render json: resource, status: :created
    else
      clean_up_passwords resource
      render json: resource.errors, status: :unprocessable_entity
    end
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
    logger.debug(params[:user])
    if resource.update_with_password(account_update_params)
      if is_navigational_format?
        update_needs_confirmation?(resource, prev_unconfirmed_email)
      end
      sign_in resource_name, resource
      return render json: {success: true}
    else
      clean_up_passwords resource
      return render status: 401, json: {errors: resource.errors}
    end
  end

  private

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password)
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
