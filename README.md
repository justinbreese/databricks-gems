# Databricks Gems
While working at Databricks, I have found many tips and tricks that customers have found valuable. So, I put them out on here so that everyone can benefit from. Welcome to Databricks Gems! There are helpful gems for the UI, API, etc.

# [uploadNotebook.py](../master/uploadNotebook.py)
This is a brief demo on how to use the Databricks REST API to upload a given file (python in this case) to your Databricks workspace

## Prerequisites
* You have a [user access token](https://docs.databricks.com/dev-tools/api/latest/authentication.html) for your Databricks workspace 

## Sample command
`python3 uploadNotebook.py https://demo.cloud.databricks.com <insert-your-token-here> artifacts/sample.py /Users/justin.breese@databricks.com/temp/sample`

Explain the args being passed in order:
* URL of your Databricks environment (note: no trailing `/`)
* Your user access token (from the prereqs)
* The file that you want to move from your laptop to your workspace
* The path where you want the file uploaded