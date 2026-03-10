import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";

const [rootArg, hostArg, portArg] = process.argv.slice(2);

const rootDir = resolve(rootArg || "/opt/penpot-mcp/plugin");
const host = hostArg || "0.0.0.0";
const port = Number.parseInt(portArg || "4400", 10);

const mimeTypes = new Map([
    [".css", "text/css; charset=utf-8"],
    [".html", "text/html; charset=utf-8"],
    [".ico", "image/x-icon"],
    [".js", "application/javascript; charset=utf-8"],
    [".json", "application/json; charset=utf-8"],
    [".map", "application/json; charset=utf-8"],
    [".png", "image/png"],
    [".svg", "image/svg+xml"],
]);

function resolveRequestPath(urlPath) {
    const decodedPath = decodeURIComponent(urlPath.split("?")[0]);
    const requestPath = decodedPath === "/" ? "/index.html" : decodedPath;
    const normalizedPath = normalize(requestPath)
        .replace(/^([.][.][/\\])+/, "")
        .replace(/^[/\\]+/, "");
    return resolve(rootDir, normalizedPath);
}

const server = createServer(async (request, response) => {
    try {
        const filePath = resolveRequestPath(request.url || "/");

        if (!filePath.startsWith(rootDir)) {
            response.writeHead(403, { "content-type": "text/plain; charset=utf-8" });
            response.end("Forbidden");
            return;
        }

        const body = await readFile(filePath);
        const contentType = mimeTypes.get(extname(filePath)) || "application/octet-stream";

        response.writeHead(200, {
            "cache-control": "no-store",
            "content-type": contentType,
        });
        response.end(body);
    } catch (error) {
        response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
        response.end("Not found");
    }
});

server.listen(port, host, () => {
    console.log(`Plugin server listening on http://${host}:${port}`);
});