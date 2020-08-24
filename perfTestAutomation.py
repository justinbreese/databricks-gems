import requests
import json
from string import Template
import argparse
import time

# Configurable args
ap = argparse.ArgumentParser()
ap.add_argument("-t", "--token", required=True,
	help="User access token for your Databricks workspace")
ap.add_argument("-s", "--start", required=True,
	help="Starting run number (e.g. already have 4 runs stored and want to start next run at 5")

args = vars(ap.parse_args())

token = args["token"]
start = int(args["start"])

with open('artifacts/perfTest.json', 'r') as json_file:
    jsonConfigs = json.load(json_file)

testName = jsonConfigs['Name']
host = jsonConfigs['Host']
runs = jsonConfigs['Runs']
operations = jsonConfigs['Operations']
methods = jsonConfigs['Methods']
readQuery = jsonConfigs['ReadQuery']
runTemplate = Template(json.dumps(jsonConfigs))

# run-now
def runNow(runJson):
    response = requests.post(
        url='%s/api/2.0/jobs/runs/submit' % (host),
        headers={'Authorization': 'Bearer %s' % token},
        json=runJson
    )

    if response.status_code == 200:
        runId = str(response.json()['run_id'])
        print("Successfully started run_id: " + runId)
    else:
        print("Error creating the job run: %s: %s" % (response.json()["error_code"], response.json()["message"]))

# trigger all of the jobs
for run in range(start, start + runs):
    for method in methods:
        for operation in operations:
            # replace some objects within the json template
            runPayload = json.loads(runTemplate.substitute(runName=testName, method=method, operation=operation, run=run, readQuery=readQuery))['JobConfig']
            # execute the command to send the requests
            runNow(runPayload)