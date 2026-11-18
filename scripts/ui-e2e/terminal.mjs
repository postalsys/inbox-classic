// A terminal of the UI end-to-end test on Windows: the test runs it from a copy of the Node.js binary under a
// terminal's name (WindowsTerminal.exe), so the relay it starts as its child (`<app> --mcp --store <store>`) is found
// to be started from a terminal, as an agent run by hand there would be. It sends the agent's first request, which
// brings the question, and ends with the relay once its own input closes. The relay's errors go to ERR.
//   APP=<executable> STORE=<store> ERR=<file> WindowsTerminal terminal.mjs
import { spawn } from 'node:child_process';
import { openSync } from 'node:fs';

const { APP, STORE, ERR } = process.env;
const relay = spawn(APP, ['--mcp', '--store', STORE], { stdio: ['pipe', 'ignore', openSync(ERR, 'w')] });
relay.stdin.on('error', () => {});
relay.stdin.write(
    JSON.stringify({
        jsonrpc: '2.0',
        id: 1,
        method: 'initialize',
        params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'ui-test', version: '1' } }
    }) + '\n'
);
relay.on('exit', code => process.exit(code ?? 1));
process.stdin.on('end', () => {
    relay.kill();
    process.exit(0);
});
process.stdin.resume();
