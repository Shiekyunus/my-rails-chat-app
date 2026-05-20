# frozen_string_literal: true

class ConversationParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :conversation
end
