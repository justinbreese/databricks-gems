# Databricks Gems
While working at Databricks, I have found many tips and tricks that customers have found valuable. So, I put them out on here so that everyone can benefit from. Welcome to Databricks Gems! There are helpful gems for the UI, API, etc.

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
* Quick and dirty calculator that helps you figure out the optimal configurations for your `spark.sql.files.maxPartitionBytes` and `spark.sql.shuffle.partitions`
* Also included some JavaScript and HTML for the accompanying page on my personal website
* If you want to use a prebuilt calculator on my website, go to: [Spark Shuffle Partition Calculator](http://justinbreese.com/shuffle-partition-calculator/)

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
``` spark.conf.set("spark.sql.files.maxPartitionBytes", 134217728)
spark.conf.set("spark.sql.shuffle.partitions", 4292)```

# TODO
* Passing variables from job params to a notebook
* Moving local files via DBFS