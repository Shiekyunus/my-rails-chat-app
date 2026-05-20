# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @conversation = Conversation.find(params[:conversation_id])

    @conversation.messages.create!(
      body: params[:message][:body],
      user: current_user
    )

    redirect_to conversation_path(@conversation)
  end
end
