from flask import Flask
import subprocess
import json

# Creating a Flask app
app = Flask(__name__)

@app.route('/api/create-lbaas', methods=['POST'])
def getFolders():
    folder="/nestedVsphere8/02_external_gateway"
    subprocess.call(['/bin/bash', 'getFolders.sh'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open('/nestedVsphere8/api/getFolders.json', 'r') as results_json:
        results = json.load(results_json)
    return results, 201
    subprocess.call(['rm', '/nestedVsphere8/api/getFolders.json'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)

@app.route('/api/delete-lbaas', methods=['DELETE'])
def getNetworks():
    folder="/nestedVsphere8/api"
    subprocess.call(['/bin/bash', 'getNetworks.sh'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open('/nestedVsphere8/api/getNetworks.json', 'r') as results_json:
        results = json.load(results_json)
    return results, 201
    subprocess.call(['rm', '/nestedVsphere8/api/getNetworks.json'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)

# Endpoint 2: POST request
@app.route('/endpoint2', methods=['POST'])
def endpoint2():
    return 'This is endpoint 2'

# Endpoint 3: DELETE request
@app.route('/endpoint3', methods=['DELETE'])
def endpoint3():
    return 'This is endpoint 3'

# Start the server
if __name__ == '__main__':
    app.run(debug=True)  # Run the app in debug mode