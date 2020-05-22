import requests
import base64
import sys


# generic encoding function to read the files that need to be uploaded
def encode64(f):
    with open(f, 'rb') as binary_file:
        binary_file_data = binary_file.read()
        base64_encoded_data = base64.b64encode(binary_file_data)
        base64_message = base64_encoded_data.decode('utf-8')
        
        return base64_message

# upload files, leverage the encode64 function to send as the payload
def writeNotebookToWorkspace():
    payload = encode64(file)

    response = requests.post(
        '%s/api/2.0/workspace/import' % (host),
        headers={'Authorization': 'Bearer %s' % token},
        json = {
            "path": "%s" % (path),
            "format": "SOURCE",
            "language": "PYTHON",
            "content": "%s" % (payload),
            "overwrite": "true"
        }
    )

    if response.status_code == 200:
        print("Successfully uploaded the notebook.")
    else:
        print("Error uploading notebook: %s: %s" % (response.json()["error_code"], response.json()["message"]))


if __name__ == '__main__':
    host = sys.argv[1]
    token = sys.argv[2]
    file = sys.argv[3]
    path = sys.argv[4]

    writeNotebookToWorkspace()