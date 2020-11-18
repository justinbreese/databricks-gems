# Databricks Gems
While working at Databricks, I have found many tips and tricks that customers have found valuable. So, I put them out on here so that everyone can benefit from. Welcome to Databricks Gems! There are helpful gems for the UI, API, etc.

## Table of contents
* [Deploy Multiple Workspaces](../master#deploy-multiple-workspaces)
* [perfTestAutomation.py](../master#perftestautomationpy)
* [uploadNotebook.py](../master#uploadNotebookpy)
* [getPort.py](../master#getPortpy)
* [sparkShufflePartitionCalculator.py](../master#sparkShufflePartitionCalculatorpy)

# [Deploy Multiple Workspaces](../master/deployMws/deploy.sh)
Multiple workspaces allows for customers to setup many workspaces. The Account API lets you programmatically create multiple new Databricks workspaces associated with a single Databricks account. Each workspace you create can have different configuration settings. To learn more, go to [this](https://docs.databricks.com/getting-started/overview.html) link.

## What the code does
Goes into the existing AWS account:
* Creates S3 bucket and bucket policy
* IAM role and role policy
* Leverages the existing VPC, subnets, and security groups
* Adds a NACL for RDS (TCP 3306)
* Creates VPC endpoints for STS and Kinesis
* Creates a CMK

In the Databricks MWS API, it creates the following:
* Credential configuration
* Storage configuration
* Configures the network
* Configures the CMK

Finally, the code returns the URL of the newly created workspace

## Prerequisites
* AWS CLI setup on your laptop; configured with a role that has full EC2, S3, and IAM perms
* Databricks MWS `accountId`, username, and password - go [here](https://docs.databricks.com/administration-guide/multiworkspace/new-workspace-aws.html) if you need more information.
* jq is installed - `brew install jq` 

## Sample command
`cd deployMws`

`./deploy.sh deploymentName databricksAccountId some@email.com databricksPassword us-west-2 true true awsAccountId`

Explain the args that are being passed (in order):
* Name of the deployment that you want to create (e.g. the cname)
* Databricks MWS accountId
* Email/username for the Databricks account
* Password for the Databricks account
* AWS region
* BYO VPC functionality (boolean)
* BYO CMK functionality (boolean)
* AWS AccountId

# [perfTestAutomation.py](../master/perfTestAutomation.py)
Automate your performance testing with Databricks notebooks! Leveraging Databricks Widgets, Jobs API, Delta Table for analysis, etc.

Performance testing is usually hard: you have to keep track of a lot of different items, store your results in a notebook, etc. It does not have to be that hard. 

This notebook/code goes through a merge on read architecture: there are three ways to show the correct view so we want to test out each of them to see which performs better. This is simple to use and can be completely automated.

## Prerequsites
* Databricks User Access Token (UAT)

## How to use it
* Download  `/artifacts/perfTestNotebook.dbc` - in this is a Databricks Notebook - this works fine in Community Edition
* Import the notebook into Databricks
* Go through each cell; I have lot of comments and explanation in there
* Once you have the notebook working, then get your UAT and run the below sample command
* If you did it successfully, then you will see something like 
![Image of successful api call](../master/artifacts/perfTestSuccess_1.png)

## Sample command
`python .\perfTestAutomation.py --token <yourTokenHere> --start 0 --json_spec /artifacts/perfTest.json`

Explain the args that are being passed (in order):
* Databricks User Access Token (UAT)
* Starting number. If you have already done 5 runs (and they are saved in your table), then start with 6 so you do not have duplicate runs
* Point to the json spec file. There is a sample file in `/artifacts/perfTest.json`

# [uploadNotebook.py](../master/uploadNotebook.py)
Brief demo on how to use the Databricks REST API to upload a given file (python in this case) to your Databricks workspace

## Prerequisites
* You have a [user access token](https://docs.databricks.com/dev-tools/api/latest/authentication.html) for your Databricks workspace 

## Sample command
`python3 uploadNotebook.py https://demo.cloud.databricks.com <insert-your-token-here> artifacts/sample.py /Users/justin.breese@databricks.com/temp/sample`

Explain the args being passed in order:
* URL of your Databricks environment (note: no trailing `/`)
* Your user access token (from the prereqs)
* The file that you want to move from your laptop to your workspace
* The path where you want the file uploaded

# [getPort.py](../master/getPort.py)
Showing you how to get the port of a given `clusterId` via the API

## Prerequisites
* You have a [user access token](https://docs.databricks.com/dev-tools/api/latest/authentication.html) for your Databricks workspace
* You have a given `clusterId`

## Sample command
`python3 .\getPort.py https://demo.cloud.databricks.com <insert-your-token-here> 0318-151752-abed99`

Explain the args being passed in order:
* URL of your Databricks environment (note: no trailing `/`)
* Your user access token (from the prereqs)
* `clusterId` of the specific cluster

## Important things to understand
* In the Databricks World, a cluster uses a single `applicationId`
* The port is dynamic; meaning it is a different value each time it starts up or restarts - so you may have to periodically re-run this command to get the latest port

# [sparkShufflePartitionCalculator.py](../master/shufflePartitionCalculator/sparkShufflePartitionCalculator.py)
* Quick and dirty calculator that helps you figure out the optimal configurations for the `spark.sql.files.maxPartitionBytes` and `spark.sql.shuffle.partitions` settings
* If you want to use a pre-built calculator on my website, go to: [Spark Shuffle Partition Calculator](http://justinbreese.com/spark-shuffle-partition-calculator/)
* Also, included the JavaScript, CSS, and HTML for the accompanying page on my website ^^

## Prerequisites
* You know your `shuffleRead` amount for a given Spark job

## Sample command
`python3 .\shufflePartitionCalculator\sparkShufflePartitionCalculator.py 550 116 128`

Explain the args being passed in order:
* The size of the `shuffleRead` for a given Spark job
* The amount of cores available in your cluster
* The `partitionSize` that you would like to consider for this job (128MB is the default)

## Output
The command will output something like this:
```
Total Spark Partitions: 4400.0
Cluster core cycles: 37.93103448275862
Suggested Shuffle Partitions: 4292

--Settings to use--
spark.conf.set("spark.sql.files.maxPartitionBytes", 134217728)
spark.conf.set("spark.sql.shuffle.partitions", 4292)
```

Description of the output:
* Total Spark Partitions is the total amount of Spark partitions that will need to be processed for this job
* Cluster core cycles is the amount of times a given core will have to do work (Total Spark Partitions / amount of cores in your cluster)
* Suggested shuffle partitions is what this calculator recommends for your `spark.sql.shuffle.partitions`
* Finally, the output provides you with the actual Spark configs that you can use: 
``` 
spark.conf.set("spark.sql.files.maxPartitionBytes", 134217728)
spark.conf.set("spark.sql.shuffle.partitions", 4292)
```

# TODO
* Passing variables from job params to a notebook
* Moving local files via DBFS