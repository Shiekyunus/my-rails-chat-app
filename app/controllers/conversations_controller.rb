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

    @messages = @conversation.messages
                             .includes(:user)
                             .order(created_at: :asc)

    if params[:from_date].present? &&
       params[:to_date].present?

      from_date =
        Date.parse(params[:from_date]).beginning_of_day

      to_date =
        Date.parse(params[:to_date]).end_of_day

      @messages = @messages.where(
        created_at: from_date..to_date
      )

    end

    @message = @conversation.messages.new

    @conversation.messages
                 .where(
                   user_id: other_participant.id,
                   read: false
                 )
                 .update_all(read: true)

  end

  private

  def other_participant
    @conversation.conversation_participants
                 .where.not(user: current_user)
                 .first.user
    end
end
