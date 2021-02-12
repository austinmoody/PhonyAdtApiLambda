# frozen_string_literal: true

require 'base64'
require 'healthcare_phony'
require 'json'
require 'jwt'
require_relative 'authorize'
require_relative 'jwt_verify'

def lambda_handler(event:, context:)
  if (event['httpMethod'] == 'GET') && (event['path'] == '/authorize')
    authorize(event)
  elsif (event['httpMethod'] == 'GET') && (event['path'] == '/adt')
    get_adt_text(event)
  else
    { statusCode: 200, body: event }
  end
end

def authorize(event)
  auth = Authorize.new(ENV['VALID_KEY'], ENV['JWT_ISSUER'], %w[adt])
  response = { statusCode: 401, body: { 'error': 'invalid token' }.to_json }

  if auth.is_authorized?(event['queryStringParameters']['access_token'])
    response = { statusCode: 200, body: { 'token': "#{auth.create_token(event['queryStringParameters']['access_token'])}"}.to_json }
  end

  response
end

def get_adt(event)
  jwt_verify = JwtVerify.new(ENV['JWT_ISSUER'],ENV['JWT_SECRET'],'HS256', event['headers']['Authorization'], ENV['VALID_KEY'])

  if (jwt_verify.valid)
    a = HealthcarePhony::Adt.new
    { statusCode: 200, body: {'ADT_Base64':Base64.strict_encode64(a.to_s)}.to_json }
  else
    jwt_verify.jwt_error
  end
end

def get_adt_text(event)
  jwt_verify = JwtVerify.new(ENV['JWT_ISSUER'],ENV['JWT_SECRET'],'HS256', event['headers']['Authorization'], ENV['VALID_KEY'])

  if (jwt_verify.valid)
    a = HealthcarePhony::Adt.new
    # { statusCode: 200, body: {'ADT':a.to_s}.to_json }
    { statusCode: 200, body: a.to_s }
  else
    jwt_verify.jwt_error
  end
end