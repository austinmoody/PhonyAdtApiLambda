# Phony ADT API - AWS Lambda

AWS Lambda function to generate phony HL7v2 ADT messages using the Healthcare Phony library.

## Deploying

*Assumes you have terraform and aws cli configured.*

1. Edit terraform/terraform.tfvars and set things as you want.
1. Run ```rake lambda:build``` which _should_ bundle gems into vendor/bundle and create a zip file used to deploy to AWS Lambda.
1. ```cd terraform```
1. ```terraform plan```
1. ```terraform apply```

## Using

This really is just a simple example that I was playing around with.  

If all goes well with the deploy, there should be an API Gateway instance spun up in AWS.  The terraform as is only spins up a _development_ stage that will be listening at an address similar to: https://whateveritis.execute-api.us-east-1.amazonaws.com/development 

You'll need that URL, but also the API Key that the terraform also setup since that is required.

First you'll need to authorize to use the api by getting a token.  That call will look something like this example using curl:

```text
curl --request GET \
  --url 'https://whateveritis.execute-api.us-east-1.amazonaws.com/development/authorize?access_token=this-comes-from-tfvars-valid-key' \
  --header 'x-api-key: get-this-from-aws'
```

* The access_token is the value that you gave to valid_key in terraform.tfvars
* The x-api-key is the API Key setup in AWS

This will return a token:

```json
{
  "token":"eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MTMxNzk3MzUsImlhdCI6MTYxMzE3NjEzNSwiaXNzIjoiaHR0cHM6Ly9naXRodWIuY29tL2F1c3Rpbm1vb2R5L1Bob255QWR0QXBpTGFtYmRhIiwic2NvcGVzIjpbImFkdCJdLCJzZWNyZXQiOnsia2V5IjoiNDU3MjRmMDktYjVmZi00ZTUxLTk0YjEtNzZlZTI4OGY3N2ZkIn19.edfdsdClCv3CeNsgVVkoc6L7DH7u3wghRuJ57Vk6O8w"
}
```

This will be passed in subsequent calls as the bearer token.  

Now if you want to get an ADT you would make this call:

```text
curl --request GET \
  --url 'https://whateveritis.execute-api.us-east-1.amazonaws.com/development/adt' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MTMxNzk3MzUsImlhdCI6MTYxMzE3NjEzNSwiaXNzIjoiaHR0cHM6Ly9naXRodWIuY29tL2F1c3Rpbm1vb2R5L1Bob255QWR0QXBpTGFtYmRhIiwic2NvcGVzIjpbImFkdCJdLCJzZWNyZXQiOnsia2V5IjoiNDU3MjRmMDktYjVmZi00ZTUxLTk0YjEtNzZlZTI4OGY3N2ZkIn19.edfdsdClCv3CeNsgVVkoc6L7DH7u3wghRuJ57Vk6O8w' \
  --header 'x-api-key: get-this-from-aws'
```

This will return to you an ADT HL7v2 message:

```text
MSH|^~\&|||||20210213003648||ADT^A19|PHONY9489317476|P|2.5.1
EVN|A19|20210213003648
PID|||3131817081||Gorczany^Jaime^Daugherty^||20130214|U||2054-5|3781 Thomasine Locks^Suite 586^Kleinmouth^IN^46355||(913)863-0693~(601)561-1761|(813)518-0364||||2598879161|460-48-1165
PV1||E
```