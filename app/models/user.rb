# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :conversation_participants
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy
  has_one_attached :profile_image

  after_create :send_welcome_email

  private

  def send_welcome_email
    UserMailer.welcome_email(self)
              .deliver_later
  end
end
