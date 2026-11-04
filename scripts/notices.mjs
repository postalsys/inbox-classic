// Writes THIRD-PARTY-NOTICES.txt into the staging folder: the license texts of everything compiled into
// InboxClassic.exe. The Rust crates the core links (from cargo metadata, for the Windows target, normal
// dependencies of pe-ffi only) with the license files each crate ships, and the WebView2 SDK loader.
// With --linux, those of the Linux app instead: the crates of linux/ (normal dependencies of inbox-classic, for the
// Linux target of the machine it runs on); GTK, libadwaita and WebKitGTK are the system's, not part of the package.
//
//   node scripts/notices.mjs <staging folder> <CMake build folder>
//   node scripts/notices.mjs --linux <staging folder>

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const linux = process.argv[2] === '--linux';
const [staging, buildDir] = process.argv.slice(linux ? 3 : 2);
if (!staging || (!linux && !buildDir)) {
    console.error('usage: node scripts/notices.mjs <staging folder> <build folder> | --linux <staging folder>');
    process.exit(1);
}
// which crate's dependencies, in which workspace, for which target
const target = linux
    ? { dir: 'linux', start: 'inbox-classic', platform: `${process.arch === 'arm64' ? 'aarch64' : 'x86_64'}-unknown-linux-gnu` }
    : { dir: 'core', start: 'pe-ffi', platform: 'x86_64-pc-windows-msvc' };

const LICENSE_FILE = /^(licen[cs]e|copying|notice|unlicense)([-._].*)?$/i;
const read = file => fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n').trim();
const section = (title, text) => `${'='.repeat(100)}\n${title}\n${'='.repeat(100)}\n\n${text}\n\n`;

// the crates compiled in: the normal dependencies of pe-ffi on Windows (of inbox-classic on Linux), not build or dev ones
function crates() {
    const metadata = JSON.parse(
        execFileSync('cargo', ['metadata', '--format-version', '1', '--locked', '--filter-platform', target.platform], {
            cwd: path.join(root, target.dir),
            maxBuffer: 64 * 1024 * 1024
        })
    );
    const nodes = new Map(metadata.resolve.nodes.map(node => [node.id, node]));
    const packages = new Map(metadata.packages.map(pkg => [pkg.id, pkg]));
    const start = metadata.packages.find(pkg => pkg.name === target.start).id;
    const seen = new Set();
    const stack = [start];
    while (stack.length) {
        const id = stack.pop();
        if (seen.has(id)) {
            continue;
        }
        seen.add(id);
        for (const dep of nodes.get(id).deps) {
            if (dep.dep_kinds.some(kind => kind.kind === null || kind.kind === 'normal')) {
                stack.push(dep.pkg);
            }
        }
    }
    return [...seen]
        .map(id => packages.get(id))
        .filter(pkg => pkg.source)
        .sort((a, b) => a.name.localeCompare(b.name) || a.version.localeCompare(b.version));
}

function crateNotice(pkg) {
    const dir = path.dirname(pkg.manifest_path);
    const files = fs
        .readdirSync(dir)
        .filter(name => LICENSE_FILE.test(name) && fs.statSync(path.join(dir, name)).isFile())
        .sort();
    const texts = files.map(name => `--- ${name} ---\n\n${read(path.join(dir, name))}`);
    const license = pkg.license || (pkg.license_file ? 'see the license file' : 'not stated');
    return section(`${pkg.name} ${pkg.version} (${license})`, texts.join('\n\n') || `Licensed under ${license}.`);
}

function webview2Notice() {
    const dir = fs.readdirSync(buildDir).find(name => name.startsWith('webview2-'));
    if (!dir) {
        throw new Error(`The WebView2 SDK is not in ${buildDir}, build the app first`);
    }
    const license = path.join(buildDir, dir, 'LICENSE.txt');
    return section(`Microsoft Edge WebView2 SDK loader (${dir}), compiled into InboxClassic.exe`, read(license));
}

const list = crates();
const notices =
    'Inbox Classic includes the software below. Each part keeps its own license, given here in full.\n\n' +
    (linux ? '' : webview2Notice()) +
    section('Fluent UI System Icons (toolbar pictures, from app/res/icons)', read(path.join(root, 'app', 'res', 'icons', 'LICENSE'))) +
    list.map(crateNotice).join('');
fs.mkdirSync(staging, { recursive: true });
// Windows line ends in the Windows installer, Linux ones in the .deb
fs.writeFileSync(path.join(staging, 'THIRD-PARTY-NOTICES.txt'), linux ? notices : notices.replace(/\n/g, '\r\n'));
console.log(`THIRD-PARTY-NOTICES.txt: ${linux ? '' : 'WebView2 and '}${list.length} crates`);
