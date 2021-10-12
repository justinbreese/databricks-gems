# Databricks notebook source
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

# MAGIC %md # pip freeze the env
# MAGIC * Current limitation: we currently cannot write directly to a repo file/notebook; however we can do it for normal notebooks. 
# MAGIC * That functionality is coming in the next 3ish months. In the interim, we have to do a quick copy paste
# MAGIC * Else, we could run this below: `pip freeze > requirements.txt`

# COMMAND ----------

pip freeze
