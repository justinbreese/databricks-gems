import requests
import sys
import time

# upload files, leverage the encode64 function to send as the payload
def request(method, endpoint, payload):
    if method == "post":    
        response = requests.post(
            '%s/api/1.2/%s' % (host, endpoint),
            headers={'Authorization': 'Bearer %s' % token},
            json = payload
        )
    elif method == "get":
        response = requests.get(
        '%s/api/1.2/%s' % (host, endpoint),
        headers={'Authorization': 'Bearer %s' % token},
        json = payload
    )
    else:
        print("There was an error.")
        exit()

    if response.status_code == 200:
        return response.json()
    else:
        print("There was an error: " + response.json()["error"])
        # delete the context as we don't need it anymore
        request("post", "contexts/destroy", {"contextId": "%s" % contextId, "clusterId": "%s" % clusterId})
        exit()

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

    # create a context so we can run a command against it - return the contextId
    contextId = request("post", "contexts/create", {"language": "scala", "clusterId": "%s" % clusterId})["id"]

    # submit a command to the contextId from the previous step - return the commandId
    commandId = request("post", "commands/execute", {"language": "scala", "clusterId": "%s" % clusterId,"contextId": "%s" % (contextId), "command": "spark.conf.get(\"spark.ui.port\")  + \" -- \" + spark.conf.get(\"spark.app.id\")"})["id"]
    
    # wait 5 seconds so the command can register and finish
    print("Getting the port...")
    time.sleep(5)

    # retrieve the results from the command - return the port and applicationId
    # for some reason, it appears that this API only accepts args, so there is a different function written for it getResult()
    portIdAppId = getResult("commands/status?clusterId=%s&contextId=%s&commandId=%s" % (clusterId, contextId, commandId))["results"]["data"].replace("res0: String = ", "")
    
    # delete the context as we don't need it anymore
    print("Cleaning up...")
    request("post", "contexts/destroy", {"contextId": "%s" % contextId, "clusterId": "%s" % clusterId})

    # display the port and applicationId 
    print("portId and appId: " + portIdAppId)