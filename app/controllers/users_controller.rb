# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!
  def index
    @users = User.where.not(id: current_user.id)
  end

  def search
    @searched_user = User.find_by(email: params[:email])

    return unless @searched_user

    @conversations = @searched_user.conversations.includes(:messages, :users)
  end
end
