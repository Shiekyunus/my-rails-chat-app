# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def create
    receiver = User.find(params[:receiver_id])

    conversation = Conversation.joins(:conversation_participants)
                               .where(conversation_participants: {
                                        user_id: [current_user.id, receiver.id]
                                      })
                               .group('conversations.id')
                               .having('COUNT(conversations.id) = 2')
                               .first

    unless conversation

      conversation = Conversation.create!

      conversation.conversation_participants.create!(
        user: current_user
      )

      conversation.conversation_participants.create!(
        user: receiver
      )

    end

    redirect_to conversation_path(conversation)
  end

  def show
    @conversation = Conversation.find(params[:id])

    @messages = @conversation.messages.includes(:user)

    @message = @conversation.messages.new
  end
end
