# Data Movement Request (DMR) Automator

A Data Movement Request (DMR) is a request submitted, usually to a security team, for the movement of data between the outside and inside of an organisation. 

This Terraform utilises AWS Lambda and SQS to automate the retrieval of files from the internet by safely scanning them (with VirusTotal and ClamAV) and bringing them into AWS.

The result of the DMR will be optionally sent to a lambda which will comment on a JIRA ticket with the result and location of the imported file.

![dmr-flow](dmr-flow.png)

1. User sends a request which ends up in an SQS queue
2. SQS queue item triggers the dmr-initiator lambda to scan against VirusTotal
3. File is submitted to VirusTotal
4. File is scanned
5. File is pulled down from the file provider if it is clean, otherwise a message is sent to notify the user that the file was suspicious/malicious
6. File is stored in a Staging bucket
7. Object Put event triggers the dmr-scanner lambda
8. New ClamAV definitions are retrieved from a bucket containing new ClamAV definitions
9. File is scanned by ClamAV. If it is clean it is sent to a delivery bucket, otherwise the user is notified via Jira that the DMR was not successful and the file is deleted.
10. Presigned URL is generated and sent to the user via Jira by the dmr-scanner.

## Prerequisites

- You must have a VirusTotal.com API key
- Terraform >=0.13
- An AWS Account

Optionally a Jira Server / ticket request for the file.

## Running

```
export TF_VAR_vt_api_key=<Virus Total API Key>
export TF_VAR_jira_user=<Jira user>
export TF_VAR_jira_apikey=<Jira password/API key>
export TF_VAR_jira_server=<Jira Server URL>
./init.sh
terraform plan
terraform apply
```
Submit a request to the SQS dmr-queue with the attributes of
`requestor`, `jira`, and `url`, where the URL is the external URL of the file to be retrieved, jira is the JIRA ticket which this request was made under, and requestor is the JIRA username of the individual who requested the DMR.

The dmr-initiator will trigger the file to be scanned on VirusTotal. If the file is clean, it will retrieve the file to the dmr-staging S3 bucket.

The object creation in the dmr-staging S3 bucket will trigger the dmr-clamav-scanner lambda to scan the object. If it is clean, it will be tagged and moved to the dmr-delivery bucket for a user to retrieve.

Optionally, the dmr-clamav-scanner will then send a comment to Jira to notify a user that their DMR has been delivered.

## Misc

The ClamAV scanner builds upon the work of [Upside Travel|https://github.com/upsidetravel/bucket-antivirus-function]


