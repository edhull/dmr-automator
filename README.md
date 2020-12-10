# Data Movement Request (DMR) Automator

A Data Movement Request (DMR) is a request submitted, usually to a security team, for the movement of data between the outside and inside of an organisation. 

This Terraform utilises AWS Lambda and SQS to automate the retrieval of files from the internet by safely scanning them (with VirusTotal and ClamAV) and bringing them into AWS.

The result of the DMR will be optionally sent to an SQS queue which will comment on a JIRA ticket with the result and location of the imported file.

![dmr-flow](dmr-flow.png)

## Prerequisites

- You must have a VirusTotal.com API key
- Terraform >=0.13
- An AWS Account

Optionally a Jira Server / ticket request for the file.

## Running

```
./init.sh
export TF_VAR_vt_api_key=<Virus Total API Key>
export TF_VAR_jira_user=<Jira user>
export TF_VAR_jira_apikey=<Jira password/API key>
export TF_VAR_jira_server=<Jira Server URL>
terraform plan
terraform apply
```
Submit a request to the SQS dmr-queue with the attributes of
`requestor`, `jira`, and `url`, where the URL is the external URL of the file to be retrieved, jira is the JIRA ticket which this request was made under, and requestor is the JIRA username of the individual who requested the DMR.

The dmr-initiator will trigger the file to be scanned on VirusTotal. If the file is clean, it will retrieve the file to the dmr-staging S3 bucket.

The object creation in the dmr-staging S3 bucket will trigger the dmr-clamav-scanner lambda to scan the object. If it is clean, it will be tagged and moved to the dmr-delivery bucket for a user to retrieve.

Optionally, the dmr-clamav-scanner will then send a comment to Jira to notify a user that their DMR has been delivered.


