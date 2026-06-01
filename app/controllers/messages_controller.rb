# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversation = Conversation.find(params[:conversation_id])
    @messages = @conversation.messages
    @message = Message.new
  end

  def create
    @conversation = Conversation.find(params[:conversation_id])

    @message = @conversation.messages.create!(
      body: params[:message][:body],
      user: current_user
    )

    respond_to do |format|
      format.html do
        redirect_to conversation_path(@conversation)
      end

      format.js
    end
  end
end
