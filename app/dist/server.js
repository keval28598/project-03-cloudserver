import express from "express";
import { hostname } from "os";
const app = express();
const PORT = Number(process.env.PORT) || 3000;
const SERVER_ID = hostname();
app.use(express.json());
// Health check - the load balancer calls this every 30 seconds
app.get("/health", (_req, res) => {
    res.status(200).json({ status: "ok", server: SERVER_ID });
});
// Home page - shows WHICH server answered
app.get("/", (_req, res) => {
    res.json({
        message: "CloudServer is running",
        servedBy: SERVER_ID,
        time: new Date().toISOString(),
    });
});
// Deliberately burns CPU - used later to trigger auto scaling
app.get("/load", (_req, res) => {
    const end = Date.now() + 5000;
    let n = 0;
    while (Date.now() < end) {
        n += Math.sqrt(n + 1);
    }
    res.json({ done: true, servedBy: SERVER_ID });
});
// Anything else 404
app.use((_req, res) => {
    res.status(404).json({ error: "Not found" });
});
app.listen(PORT, () => {
    console.log(`Listening on port \({PORT} as\){SERVER_ID}`);
});
