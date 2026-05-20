# frozen_string_literal: true

class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :users, through: :conversation_participants
end
