from flask import Flask
import subprocess
import json
from flask_restful import Api, Resource, reqparse, abort
from flask_cors import CORS

# curl -X POST http://127.0.0.1:5000/api/createlbaas -d '{"vs_name":"python-vs", "operation":"apply", "app_profile":"private","count":2, "cert": "self-signed"}' -H "Content-Type: application/json"
# curl -X POST http://127.0.0.1:5000/api/createlbaas -d '{"vs_name":"python-vs", "operation":"apply", "app_profile":"public","count":1, "cert": "new-cert"}' -H "Content-Type: application/json"
# curl -X DELETE http://127.0.0.1:5000/api/deletelbaas -d '{"vs_name":"python-vs"}' -H "Content-Type: application/json"
# curl -X GET http://127.0.0.1:5000/api/get_sesizing -d '{"vs_name":"private-vs"}' -H "Content-Type: application/json"
# curl -X GET http://127.0.0.1:5000/api/getnsxgroup -d '{"vs_name":"test-create-vm"}' -H "Content-Type: application/json"
# curl -X GET http://127.0.0.1:5000/api/getcert -d '{"vs_name":"signed-pub"}' -H "Content-Type: application/json"


# Creating a Flask app
app = Flask(__name__)
cors = CORS(app)

@app.route('/api/createlbaas', methods=['POST'])
def createlbaas():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get.add_argument("app_profile", type=str, help="public or private", required=True)
    args_parser_get.add_argument("count", type=int, help="Number of backend", required=True)
    args_parser_get.add_argument("cert", type=str, help="self-signed or new-cert", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['operation'] = "apply"
    a_dict['vs_name'] = args_parser_get['vs_name']
    a_dict['app_profile'] = args_parser_get['app_profile']
    a_dict['count'] = args_parser_get['count']
    a_dict['cert'] = args_parser_get['cert']
    json_file='/tmp/create_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas"
    subprocess.Popen(['/bin/bash', 'lbaas.sh', json_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    output = {}
    output['vs_name'] = args_parser_get['vs_name']
    results = json.dumps(output)
    return results, 201

@app.route('/api/deletelbaas', methods=['DELETE'])
def deletelbaas():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    a_dict['operation'] = "destroy"
    json_file='/tmp/destroy_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas"
    subprocess.Popen(['/bin/bash', 'lbaas.sh', json_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    output = {}
    output['vs_name'] = args_parser_get['vs_name']
    results = json.dumps(output)
    return results, 201

@app.route('/api/getvip', methods=['GET'])
def getvip():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    json_file='/tmp/getvip_' + a_dict['vs_name'] + '.json'
    json_output_file='/tmp/getvip_output_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/avi"
    subprocess.run(['/bin/bash', 'get_vip.sh', json_file, json_output_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open(json_output_file, 'r') as results_json:
        results = json.load(results_json)
    return results, 201

@app.route('/api/getfqdn', methods=['GET'])
def getfqdn():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    json_file='/tmp/getfqdn_' + a_dict['vs_name'] + '.json'
    json_output_file='/tmp/getfqdn_output_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/avi"
    subprocess.run(['/bin/bash', 'get_fqdn.sh', json_file, json_output_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open(json_output_file, 'r') as results_json:
        results = json.load(results_json)
    return results, 201

@app.route('/api/getse', methods=['GET'])
def getse():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    json_file='/tmp/getse_' + a_dict['vs_name'] + '.json'
    json_output_file='/tmp/getse_output_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/avi"
    subprocess.run(['/bin/bash', 'get_se.sh', json_file, json_output_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open(json_output_file, 'r') as results_json:
        results = json.load(results_json)
    return results, 201

@app.route('/api/getsesizing', methods=['GET'])
def getsesizing():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    json_file='/tmp/getsesizing_' + a_dict['vs_name'] + '.json'
    json_output_file='/tmp/getsesizing_output_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/avi"
    subprocess.run(['/bin/bash', 'get_sesizing.sh', json_file, json_output_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open(json_output_file, 'r') as results_json:
        results = json.load(results_json)
    return results, 201

@app.route('/api/getcert', methods=['GET'])
def getcert():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    json_file='/tmp/getcert_' + a_dict['vs_name'] + '.json'
    json_output_file='/tmp/getcert_output_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/avi"
    subprocess.run(['/bin/bash', 'get_cert.sh', json_file, json_output_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open(json_output_file, 'r') as results_json:
        results = json.load(results_json)
    return results, 201

@app.route('/api/getnsxgroup', methods=['GET'])
def getnsxgroup():
    args_parser_get= reqparse.RequestParser()
    args_parser_get.add_argument("vs_name", type=str, help="VS Name", required=True)
    args_parser_get = args_parser_get.parse_args()
    a_dict = {}
    a_dict['vs_name'] = args_parser_get['vs_name']
    json_file='/tmp/getnsxgroup_' + a_dict['vs_name'] + '.json'
    json_output_file='/tmp/getnsxgroup_output_' + a_dict['vs_name'] + '.json'
    with open(json_file, 'w') as outfile:
        json.dump(a_dict, outfile)
    folder="/home/ubuntu/lbaas/nsx"
    subprocess.run(['/bin/bash', 'get_nsx_group.sh', json_file, json_output_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=folder)
    with open(json_output_file, 'r') as results_json:
        results = json.load(results_json)
    return results, 201

# Start the server
if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")  # Run the app in debug mode