# Databricks notebook source
# MAGIC %md # Overview
# MAGIC * Import a repo: https://github.com/justinbreese/databricks-gems.git
# MAGIC * Browse the repo directory structure
# MAGIC * Call some helper functions
# MAGIC * Add a library
# MAGIC * Go to the IDE
# MAGIC * Build my docker container
# MAGIC * Run it locally
# MAGIC * Profit.

# COMMAND ----------

# MAGIC %md ## Look at the directory structure
# MAGIC * You will see that it shows the contents of the current directory of the repo that you are in

# COMMAND ----------

# MAGIC %sh ls

# COMMAND ----------

# MAGIC %md ### Go up a level...

# COMMAND ----------

# MAGIC %sh ls ../

# COMMAND ----------

# MAGIC %md ## Helper functions
# MAGIC * I have already created a file called `helpers.py` that has a `meaingOfLife` function in it
# MAGIC * Let's just import it!

# COMMAND ----------

# omg there is auto completion?!
from helpers import meaningOfLife

# COMMAND ----------

# and call it
print('What is the meaning of life?')
print()
print(meaningOfLife())

# COMMAND ----------

# MAGIC %md ## Create a Flask app
# MAGIC * The library does not exist, we we will have to add it

# COMMAND ----------

from flask import Flask

# COMMAND ----------

# MAGIC %md ## Add a library
# MAGIC * Instead of just `pip install Flask`, let's add them to a text file in the repo called `requirements.txt`; this will help when we go to our laptop/IDE

# COMMAND ----------

pip install -r requirements.txt

# COMMAND ----------

# MAGIC %md ## Now let's just go to IDE land...
# MAGIC * Do a commit first
# MAGIC * Then in your IDE, do a `git pull`

# COMMAND ----------

# MAGIC %md # Of course, random Spark things here

# COMMAND ----------

from pyspark.sql.functions import col 

df = spark.range(1000).withColumn("number", col("id") % 20)

display(df)

# COMMAND ----------

# MAGIC %sql select * from foo

# COMMAND ----------

# MAGIC %r pi

# COMMAND ----------

# MAGIC %scala val df = spark.range(1000)
