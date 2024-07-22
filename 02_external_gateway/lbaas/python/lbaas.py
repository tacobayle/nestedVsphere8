from flask import Flask
import subprocess
import json
from flask_restful import Api, Resource, reqparse, abort

# curl -X POST http://127.0.0.1:5000/api/createlbaas -d '{"vs_name":"python-vs", "operation":"apply", "app_profile":"private","count":2, "cert": "self-signed"}' -H "Content-Type: application/json"
# curl -X DELETE http://127.0.0.1:5000/api/deletelbaas -d '{"vs_name":"python-vs"}' -H "Content-Type: application/json"

# Creating a Flask app
app = Flask(__name__)

@app.route('/api/createlbaas', methods=['POST'])
def createlbaas():
    args_parser_createlbaas = reqparse.RequestParser()
    args_parser_createlbaas.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_createlbaas.add_argument("operation", type=str, help="apply or destroy", required=True)
    args_parser_createlbaas.add_argument("app_profile", type=str, help="public or private", required=True)
    args_parser_createlbaas.add_argument("count", type=int, help="Number of backend", required=True)
    args_parser_createlbaas.add_argument("cert", type=str, help="self-signed or new-cert", required=True)
    args_parser_createlbaas = args_parser_createlbaas.parse_args()
    a_dict = {}
    a_dict['operation'] = args_parser_createlbaas['operation']
    a_dict['vs_name'] = args_parser_createlbaas['vs_name']
    a_dict['app_profile'] = args_parser_createlbaas['app_profile']
    a_dict['count'] = args_parser_createlbaas['count']
    a_dict['cert'] = args_parser_createlbaas['cert']
    json_file='/tmp/create.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas"
    # subprocess.run will wait for the bash script to finish
    # subprocess.Popen will not wait for the bash script to finish
    subprocess.Popen(['/bin/bash', 'lbaas.sh', json_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    return "operation-on-going", 201

@app.route('/api/deletelbaas', methods=['DELETE'])
def deletelbaas():
    args_parser_createlbaas = reqparse.RequestParser()
    args_parser_createlbaas.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_createlbaas = args_parser_createlbaas.parse_args()
    json_file='/tmp/destroy.json'
    a_dict = {}
    a_dict['vs_name'] = args_parser_createlbaas['vs_name']
    a_dict['operation'] = "destroy"
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas"
    subprocess.Popen(['/bin/bash', 'lbaas.sh', json_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    return "operation-on-going", 201

# Start the server
if __name__ == '__main__':
    app.run(debug=True)  # Run the app in debug mode