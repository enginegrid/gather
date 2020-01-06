# frozen_string_literal: true

class SingleSignOnController < ApplicationController
  # sso requests will always be to the apex domain. Requiring a subdomain would add unnecessary complexity.
  skip_before_action :ensure_subdomain, only: :sign_on

  def sign_on
    authorize(:single_sign_on)
    # Expects client to specify return URL.
    handler = DiscourseSingleSignOn.new(payload: params[:sso], signature: params[:sig],
                                        secret: Settings.single_sign_on.secret)
    handler.email = current_user.email
    handler.external_id = current_user.id
    handler.name = current_user.decorate.full_name
    handler.username = handler.name
    handler.custom_fields[:first_name] = current_user.first_name
    handler.custom_fields[:last_name] = current_user.last_name

    redirect_to(handler.to_url)
  rescue Pundit::NotAuthorizedError
    render_forbidden
  rescue DiscourseSingleSignOn::ParseError => e
    render(plain: e, status: :unprocessable_entity)
  end
end
