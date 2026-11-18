// The AI agent of the UI end-to-end tests: starts Inbox Classic's MCP relay (`<app> --mcp --store <store>`) as an
// agent host would and runs one fixed conversation through it, writing each answer as a line of JSON to OUT, so the
// test can answer the app's questions (let it in, send the message) and check what the agent saw and changed.
// The tests run it from a copy of the Node.js binary named "My AI agent", which is what the app then calls it.
// After marking two messages read it flags one blue and watches the other's conversation.
// A send the user has not answered in about 20 seconds is answered `waiting`: the agent then asks get_send_status
// every second until it has the answer. After the send it saves a draft in Markdown, then waits for the file OUT.unsubscribe, which the test makes once it has looked at the Outbox and the
// AI Agents window, and then asks to unsubscribe from the two mailing lists the test added.
//   APP=<executable> STORE=<store> OUT=<file> "My AI agent" agent.mjs
import { spawn } from 'node:child_process';
import { appendFileSync, existsSync, rmSync, writeFileSync } from 'node:fs';
import { createInterface } from 'node:readline';

const { APP, STORE, OUT } = process.env;
writeFileSync(OUT, '');
rmSync(`${OUT}.unsubscribe`, { force: true });
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
    record('marked', await call('mark_messages_read', { folder: inbox, uids }));
    // a flag of a colour on the older one, and the newer one's conversation watched: the AI Agents log lists both
    record('colored', await call('set_flag_color', { folder: inbox, uids: [uids[1]], color: 'blue' }));
    record('watched', await call('set_conversation_mark', { thread: unread.messages[0].thread, mark: 'watch' }));
    // waits for the user's yes, asking again while the answer is that the user has not answered yet
    let sent = await call('send_message', {
        account,
        to: 'Pat Example <pat@example.net>',
        subject: 'Lunch on Friday?',
        text: 'Hi Pat,\n\nWould Friday at noon work for lunch? The usual place.\n\nThanks!'
    });
    for (let waited = 0; sent.status === 'waiting'; waited += 1000) {
        if (waited > 180000) throw new Error('the user never answered the send');
        await new Promise(resolve => setTimeout(resolve, 1000));
        sent = await call('get_send_status', { ask_id: sent.ask_id });
    }
    record('sent', sent);
    // a draft for the user to check, written in Markdown
    record(
        'draft',
        await call('save_draft', {
            account,
            to: 'Pat Example <pat@example.net>',
            subject: 'Agenda for Friday',
            text: 'Hi Pat,\n\n**Agenda**\n\n- lunch\n- the plan',
            format: 'markdown'
        })
    );
    // the test's go: the Outbox and the AI Agents window are checked
    for (let waited = 0; !existsSync(`${OUT}.unsubscribe`); waited += 200) {
        if (waited > 180000) throw new Error('the test never said to unsubscribe');
        await new Promise(resolve => setTimeout(resolve, 200));
    }
    // two list messages, added by the test before the agent starts, found by their subject
    const lists = await call('search_messages', { query: 'subject:"Weekly digest" OR subject:"Monthly offers"' });
    record('lists', lists);
    // downloads them: the one-click way is read from the message itself
    for (const message of lists.messages) await call('get_message', { folder: message.folder, uid: message.uid });
    // waits for the user's answer
    record('unsubscribe', await call('unsubscribe_from_list', { folder: inbox, uids: lists.messages.map(message => message.uid) }));
    record('done', true);
} catch (error) {
    record('error', String(error));
}
relay.stdin.end();
