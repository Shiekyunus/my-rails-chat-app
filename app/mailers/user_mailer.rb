# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: 'chatapp@example.com'

  def welcome_email(user)
    @user = user

    mail(
      to: @user.email,
      subject: 'Welcome to Chat Application'
    )
  end
end
