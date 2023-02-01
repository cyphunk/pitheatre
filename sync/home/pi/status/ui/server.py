
import os
import subprocess

try:
    from http.server import BaseHTTPRequestHandler, HTTPServer
except ImportError:
    from BaseHTTPServer import HTTPServer
    from SimpleHTTPServer import SimpleHTTPRequestHandler as BaseHTTPRequestHandler
    
# NOTE: This script is not secure, at all. 
#       Arguments passed directly to scripts
#       could lead to total compromise or unintentional errors.
#
# Server functions:
# 1. Allow other html UI pages to poll and run permitted status bash scripts
#    Other pre-existing html UI pages can use the script.js file functions to
#    facillitate polling.
# 2. Server an example html UI
#
# Valid example URI's to poll status: 
#  /blahblah/status/power.sh
#  /status/power.sh
# Example with argument:
#  /status/serial.sh#/dev/ttyUSB0
#  /status/serial.sh#process1,process2*.whatever

port = 8000
ip = '0.0.0.0'

status_scripts_poll_uri_prefix = "status" 

# scripts found in the parent directory next to this python script:
server_directory = os.path.dirname(os.path.realpath(__file__))
status_scripts_directory = server_directory+'/../'
status_scripts = [fn for fn in os.listdir(status_scripts_directory) if fn.endswith('.sh')]

print("Available status_scripts:", status_scripts)

# public files (htmls, css, js) found in current directory
included_extensions = ['html','htm','js','css','jpg','jpeg','png','gif']
public_files = [fn for fn in os.listdir(server_directory) if any(fn.endswith(ext) for ext in included_extensions)]
print("Available public_files:", public_files)

os.chdir(status_scripts_directory)

class Server(BaseHTTPRequestHandler):
    def do_GET(self):
        # print("GET - path:",self.path)
        
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        if '?' in self.path:
            elems = self.path.split('?')
            paths = elems[0].split('/')
            args  = elems[1].split(',') # args unnamed so we split args on , and not &+=
        else:
            paths = self.path.split('/')
            args  = None

        # print('paths:',paths)
        # print('args:',args)

        # Valid example URI's to poll status: 
        #  /blahblah/status/power.sh
        #  /status/power.sh
        #  /status/process.sh?process1,process1

        if paths[-2] == status_scripts_poll_uri_prefix and \
           paths[-1] in status_scripts:
            #
            # Script path
            #
            if args:
                command = ['./'+paths[-1]] + args
            else:
                command = ['./'+paths[-1]]
            # print('command:', command)
            #result=os.popen(command).read()
            result=subprocess.Popen(command, shell=False, stdout=subprocess.PIPE).stdout.read()
            # print('Result:',result)
            self.wfile.write(result)

        elif paths[-1] in public_files:
            #
            # file path
            # e.g. /script.js /style.css
            #
            with open(server_directory+'/'+paths[-1], "rb") as fh:
                content = fh.read()
            self.wfile.write(content)
        
        elif self.path == '/':
            # redirect to index.html or example.html if index.html does not exist
            if "index.html" in public_files:
                self.wfile.write(b'<meta http-equiv="refresh" content="1; URL=/index.html" />')
            else:
                self.wfile.write(b'<meta http-equiv="refresh" content="1; URL=/example.html" />')


        else:
            #
            # Error path
            # file not exist
            #
            print('Error path:',paths)
            self.wfile.write(b'ERROR')


if __name__ == "__main__":
    httpd = HTTPServer((ip, port),Server)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()