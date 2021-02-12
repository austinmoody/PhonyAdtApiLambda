class Authorize

  def initialize(valid_key, iss, scopes)
    @valid_key = valid_key
    @iss = iss
    @scopes = scopes
  end

  def is_authorized?(access_token)
    if @valid_key == access_token
      true
    else
      false
    end
  end

  def create_token(access_token)
    JWT.encode(create_payload(access_token), ENV['JWT_SECRET'], 'HS256')
  end

  private

  def create_payload(token)
    {
      exp: Time.now.to_i + 60 * 60,
      iat: Time.now.to_i,
      iss: @iss,
      scopes: @scopes,
      secret: {
        key: token
      }
    }
  end
end
