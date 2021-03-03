namespace :lambda do
  desc 'Build For AWS Deploy'
  task build: %w(bundle package)

  desc 'Bundle Install'
  task :bundle do
    sh %{ bundle install --deployment }
  end

  desc 'Create AWS Zip Package'
  task :package do
    sh %{ zip -r phony_adt_api_lambda.zip hash.rb authorize.rb jwt_verify.rb lambda_function.rb vendor/* }
  end
end