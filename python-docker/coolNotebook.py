# Databricks notebook source
# MAGIC %md # Overview
# * Import a repo: https://github.com/justinbreese/databricks-gems.git
# * Call some helper functions
# MAGIC %md # Random Spark things here

# COMMAND ----------

from pyspark.sql.functions import col 

df = spark.range(1000).withColumn("number", col("id") % 20)

display(df)

# COMMAND ----------

# MAGIC %md # Look at the files within the repo

# COMMAND ----------

# MAGIC %sh ls

# COMMAND ----------

# MAGIC %md # Install libs

# COMMAND ----------

# MAGIC %pip install -r requirements.txt
