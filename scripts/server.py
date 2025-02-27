from http import server


class MyServer(server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()

        _headers = self.headers.as_string()
        self.wfile.write(bytes(_headers, "utf8"))


s = server.HTTPServer(("localhost", 9099), MyServer)
s.serve_forever()

