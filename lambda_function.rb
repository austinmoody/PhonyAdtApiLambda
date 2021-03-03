# frozen_string_literal: true

require 'base64'
require 'healthcare_phony'
require 'json'
require 'jwt'
require_relative 'authorize'
require_relative 'jwt_verify'
require_relative 'hash'

def lambda_handler(event:, context:)
  lambda_event = event.symbol_keys
  if (lambda_event[:httpMethod] == 'GET') && (lambda_event[:path] == '/authorize')
    authorize(lambda_event)
  elsif (lambda_event[:httpMethod] == 'GET') && (lambda_event[:path] == '/adt')
    get_adt_text(lambda_event)
  else
    { statusCode: 200, body: event }
  end
end

def authorize(lambda_event)
  auth = Authorize.new(ENV['VALID_KEY'], ENV['JWT_ISSUER'], %w[adt])
  response = { statusCode: 401, body: { 'error': 'invalid token' }.to_json }

  if auth.is_authorized?(lambda_event[:queryStringParameters][:access_token])
    response = { statusCode: 200, body: { 'token': "#{auth.create_token(lambda_event[:queryStringParameters][:access_token])}"}.to_json }
  end

  response
end

def get_adt_text(lambda_event)
  jwt_verify = JwtVerify.new(ENV['JWT_ISSUER'],ENV['JWT_SECRET'],'HS256', lambda_event[:headers][:Authorization], ENV['VALID_KEY'])

  if (jwt_verify.valid)
    a = HealthcarePhony::Adt.new(lambda_event[:queryStringParameters])
    { statusCode: 200, body: a.to_s }
  else
    jwt_verify.jwt_error
  end
end