from flask import Flask
import subprocess
import json
from flask_restful import Api, Resource, reqparse, abort

# Creating a Flask app
app = Flask(__name__)

args_parser_createlbaas = reqparse.RequestParser()
args_parser_createlbaas.add_argument("vs_name", type=str, help="VS Name", required=True)
args_parser_createlbaas.add_argument("operation", type=str, help="apply or destroy", required=True)
args_parser_createlbaas.add_argument("profile", type=str, help="public or private", required=True)
args_parser_createlbaas.add_argument("count", type=int, help="Number of backend", required=True)
args_parser_createlbaas.add_argument("cert", type=str, help="self-signed or new-cert", required=True)

@app.route('/api/createlbaas', methods=['POST'])
def createlbaas():
    args_parser_createlbaas = parser_create_vs_multiple_dcs.parse_args()
    a_dict = {}
    a_dict['operation'] = args_parser_createlbaas['operation']
    a_dict['vs_name'] = args_parser_createlbaas['vs_name']
    a_dict['profile'] = args_parser_createlbaas['profile']
    a_dict['count'] = args_parser_createlbaas['count']
    a_dict['cert'] = args_parser_createlbaas['cert']
    json_file='/tmp/create.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/lbaas.sh"
    subprocess.call(['/bin/bash', 'lbaas.sh', json_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    return results, 201

@app.route('/api/deletelbaas', methods=['DELETE'])
def deletelbaas():
    args_parser_createlbaas = parser_create_vs_multiple_dcs.parse_args()
    a_dict = {}
    a_dict['operation'] = args_parser_createlbaas['operation']
    a_dict['vs_name'] = args_parser_createlbaas['vs_name']
    a_dict['profile'] = args_parser_createlbaas['profile']
    a_dict['count'] = args_parser_createlbaas['count']
    a_dict['cert'] = args_parser_createlbaas['cert']
    json_file='/tmp/create.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/lbaas.sh"
    subprocess.call(['/bin/bash', 'lbaas.sh', json_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    return results, 201

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