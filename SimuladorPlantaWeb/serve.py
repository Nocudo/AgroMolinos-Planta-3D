import http.server
import os
import sys

class IndustrialHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def guess_type(self, path):
        if path.endswith('.glb'):
            return 'model/gltf-binary'
        if path.endswith('.gltf'):
            return 'model/gltf+json'
        if path.endswith('.js'):
            return 'application/javascript'
        if path.endswith('.css'):
            return 'text/css'
        return super().guess_type(path)

if __name__ == '__main__':
    port = 8085
    web_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(web_dir)
    server = http.server.ThreadingHTTPServer(('0.0.0.0', port), IndustrialHTTPRequestHandler)
    print(f'Industrial Server active at http://localhost:{port}')
    sys.stdout.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
