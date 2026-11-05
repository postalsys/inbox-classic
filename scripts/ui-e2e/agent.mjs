// The AI agent of the UI end-to-end tests: starts Inbox Classic's MCP relay (`<app> --mcp --store <store>`) as an
// agent host would and runs one fixed conversation through it, writing each answer as a line of JSON to OUT, so the
// test can answer the app's questions (let it in, send the message) and check what the agent saw and changed.
// The tests run it from a copy of the Node.js binary named "My AI agent", which is what the app then calls it.
//   APP=<executable> STORE=<store> OUT=<file> "My AI agent" agent.mjs
import { spawn } from 'node:child_process';
import { appendFileSync, writeFileSync } from 'node:fs';
import { createInterface } from 'node:readline';

const { APP, STORE, OUT } = process.env;
writeFileSync(OUT, '');
const record = (step, result) => appendFileSync(OUT, JSON.stringify({ step, result }) + '\n');

const relay = spawn(APP, ['--mcp', '--store', STORE], { stdio: ['pipe', 'pipe', 'inherit'] });
const lines = createInterface({ input: relay.stdout });
const waiting = new Map();
lines.on('line', line => {
    const message = JSON.parse(line);
    waiting.get(message.id)?.(message);
    waiting.delete(message.id);
});
let next = 0;
const request = (method, params = {}) =>
    new Promise(resolve => {
        next += 1;
        waiting.set(next, resolve);
        relay.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: next, method, params }) + '\n');
    });
const call = async (name, args = {}) => {
    const answer = await request('tools/call', { name, arguments: args });
    const text = answer.result?.content?.[0]?.text ?? '';
    return answer.result?.isError ? { error: text } : JSON.parse(text);
};

try {
    // waits for the user to let it in
    record('initialize', await request('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'ui-test', version: '1' } }));
    relay.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
    const tools = await request('tools/list');
    record(
        'tools',
        tools.result.tools.map(tool => tool.name)
    );
    const accounts = await call('list_accounts');
    record('accounts', accounts);
    const account = accounts.accounts[0].account;
    const folders = await call('list_folders', { account });
    const inbox = folders.folders.find(folder => folder.special === 'inbox').folder;
    record('inbox', inbox);
    const unread = await call('list_messages', { folder: inbox, unread_only: true, limit: 2 });
    record('unread', unread);
    const uids = unread.messages.map(message => message.uid);
    // read without marking read, then marked read: the windows show it
    record('read', await call('get_message', { folder: inbox, uid: uids[0] }));
    record('marked', await call('mark_read', { folder: inbox, uids }));
    // waits for the user's yes
    record(
        'sent',
        await call('send_message', {
            account,
            to: 'Pat Example <pat@example.net>',
            subject: 'Lunch on Friday?',
            text: 'Hi Pat,\n\nWould Friday at noon work for lunch? The usual place.\n\nThanks!'
        })
    );
    record('done', true);
} catch (error) {
    record('error', String(error));
}
relay.stdin.end();
