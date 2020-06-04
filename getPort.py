import requests
import sys
import time

# upload files, leverage the encode64 function to send as the payload
def request(endpoint, payload):
    response = requests.post(
        '%s/api/1.2/%s' % (host, endpoint),
        headers={'Authorization': 'Bearer %s' % token},
        json = payload
    )

    if response.status_code == 200:
        return response.json()
    else:
        print("There was an error.")

def getResult(endpoint):
    response = requests.get(
        '%s/api/1.2/%s' % (host, endpoint),
        headers={'Authorization': 'Bearer %s' % token},
    )
    return response.json()

if __name__ == '__main__':
    host = sys.argv[1]
    token = sys.argv[2]
    clusterId = sys.argv[3]

    contextId = request("contexts/create", {"language": "scala", "clusterId": "%s" % clusterId})["id"]
    commandId = request("commands/execute", {"language": "scala", "clusterId": "%s" % clusterId,"contextId": "%s" % (contextId), "command": "spark.conf.get(\"spark.ui.port\")  + \" -- \" + spark.conf.get(\"spark.app.id\")"})["id"]
    # wait 2 seconds so the command can register and finish
    print("the job has started")
    time.sleep(5)
    portIdAppId = getResult("commands/status?clusterId=%s&contextId=%s&commandId=%s" % (clusterId, contextId, commandId))["results"]["data"]
    print("contextId: " + contextId)
    print("commandId: " + commandId)
    print("portId and appId: " + portIdAppId)
 
