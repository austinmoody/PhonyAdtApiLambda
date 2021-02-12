require 'jwt'

class JwtVerify
  attr_reader :valid, :scopes, :secret, :jwt_error

  def initialize(iss, jwt_secret, algo, bearer, valid_key)
    begin
      options = { algorithm: algo, iss: iss }
      bearer_token = bearer.nil? ? "" : bearer.strip.slice(7..-1)
      payload, header = JWT.decode bearer_token, jwt_secret, true, options

      @scopes = payload['scopes']
      @secret = payload['secret']

      @valid = (@secret['key'] == valid_key)

    rescue JWT::DecodeError
      @valid = false
      @jwt_error = { statusCode: 401, body: { "error":"A token must be passed." }.to_json }
    rescue JWT::ExpiredSignature
      @valid = false
      @jwt_error = { statusCode: 403, body: { "error":"The token has expired." }.to_json }
    rescue JWT::InvalidIssuerError
      @valid = false
      @jwt_error = { statusCode: 403, body: { "error":"The token does not have a valid issuer." }.to_json }
    rescue JWT::InvalidIatError
      @valid = false
      @jwt_error = { statusCode: 403, body: { "error":"The token does not have a valid 'issued at' time." }.to_json }
    end
  end

end