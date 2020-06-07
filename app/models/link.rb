class Link < ApplicationRecord
  self.primary_key = 'link_id'

  has_secure_password :password, validations: false

  before_save :generate_secret

  def generate_secret
    secret ? secret : generate_secret!
  end

  def generate_secret!
    # Hint at password status for debuggability
    self.secret = protected? ? 's' : 'p'
    self.secret += SecureRandom.urlsafe_base64(8)
  end

  def protected?
    !password_digest.nil?
  end
end
