from __future__ import annotations

import argparse
import os
import re
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class RangeRequestHandler(SimpleHTTPRequestHandler):
    """Serve static files with byte ranges so browsers can stream local video."""

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def send_head(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            return super().send_head()

        try:
            file = open(path, "rb")
        except OSError:
            self.send_error(404, "File not found")
            return None

        stat = os.fstat(file.fileno())
        content_type = self.guess_type(path)
        start = 0
        end = stat.st_size - 1
        range_header = self.headers.get("Range")

        if range_header:
            match = re.fullmatch(r"bytes=(\d*)-(\d*)", range_header.strip())
            if not match:
                file.close()
                self.send_error(416, "Requested range not satisfiable")
                return None

            first, last = match.groups()
            if first:
                start = int(first)
                end = int(last) if last else end
            elif last:
                suffix_length = int(last)
                start = max(0, stat.st_size - suffix_length)

            if start > end or start >= stat.st_size:
                file.close()
                self.send_response(416)
                self.send_header("Content-Range", f"bytes */{stat.st_size}")
                self.end_headers()
                return None

            end = min(end, stat.st_size - 1)
            self.send_response(206)
            self.send_header("Content-Range", f"bytes {start}-{end}/{stat.st_size}")
        else:
            self.send_response(200)

        self.send_header("Content-type", content_type)
        self.send_header("Content-Length", str(end - start + 1))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Last-Modified", self.date_time_string(stat.st_mtime))
        if content_type.startswith("text/html"):
            self.send_header("Cache-Control", "no-store, max-age=0")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
        self.end_headers()
        file.seek(start)
        self.range = (start, end)
        return file

    def copyfile(self, source, outputfile):
        if not hasattr(self, "range"):
            return super().copyfile(source, outputfile)

        start, end = self.range
        remaining = end - start + 1
        while remaining:
            chunk = source.read(min(64 * 1024, remaining))
            if not chunk:
                break
            outputfile.write(chunk)
            remaining -= len(chunk)


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve the portfolio locally.")
    parser.add_argument("--port", type=int, default=4173)
    parser.add_argument("--bind", default="127.0.0.1")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent
    os.chdir(root)
    server = ThreadingHTTPServer((args.bind, args.port), RangeRequestHandler)
    print(f"Serving {root} at http://{args.bind}:{args.port}/")
    server.serve_forever()


if __name__ == "__main__":
    main()
