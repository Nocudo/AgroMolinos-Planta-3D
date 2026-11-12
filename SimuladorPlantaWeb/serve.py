import http.server
import os
import sys
import webbrowser
import threading

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

    def log_message(self, format, *args):
        # Filtrar peticiones normales para mantener la consola limpia
        if '200' not in args[1]:
            super().log_message(format, *args)

def open_browser(port):
    url = f'http://localhost:{port}'
    print(f'[*] Abriendo navegador automáticamente en: {url}')
    sys.stdout.flush()
    try:
        webbrowser.open(url)
    except Exception as e:
        print(f'[*] Por favor, abra manualmente en su navegador: {url}')

if __name__ == '__main__':
    web_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(web_dir)

    server = None
    selected_port = 8085

    # Búsqueda de puerto disponible entre 8085 y 8095
    for port in range(8085, 8096):
        try:
            server = http.server.ThreadingHTTPServer(('0.0.0.0', port), IndustrialHTTPRequestHandler)
            selected_port = port
            break
        except OSError:
            continue

    if not server:
        print('[ERROR] No se encontro un puerto libre entre 8085 y 8095.')
        sys.exit(1)

    print('======================================================================')
    print('   AGROMOLINOS DEL VALLE S.A. - SIMULADOR 3D DE PLANTA INDUSTRIAL')
    print('   Proyecto Final de Máquinas Eléctricas (Universidad de los Llanos)')
    print('======================================================================')
    print(f' [>] Servidor multihilo activo en: http://localhost:{selected_port}')
    print(f' [>] Directorio raíz: {web_dir}')
    print(' [>] Presiona Ctrl+C para detener el servidor.')
    print('======================================================================')
    sys.stdout.flush()

    # Abrir navegador automáticamente tras 0.8 segundos
    threading.Timer(0.8, open_browser, args=(selected_port,)).start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\n[!] Servidor detenido correctamente.')
        server.server_close()
