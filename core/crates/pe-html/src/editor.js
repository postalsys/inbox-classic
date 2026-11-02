// The editor of the compose window. The only script PostalExpress runs: the page allows it by a nonce, nothing else
// can run (the CSP has no other script source, and the quoted message sits in a sandboxed frame without scripts).
// The host calls window.pe; the page answers with plain strings over postMessage, which the host never parses
// beyond their prefix:
//   "html:<the body>"   the HTML of what was written, after pe.send()
//   "state:<flags>"     one 0 or 1 per command of STATE, for the format bar
//   "dirty"             the first change, so closing can ask before throwing the text away
(() => {
    'use strict';
    // the order of the flags of "state:", which kStateButtons in app/src/compose.cpp follows
    const STATE = ['bold', 'italic', 'underline', 'insertOrderedList', 'insertUnorderedList', 'justifyLeft', 'justifyCenter', 'justifyRight'];
    const body = document.getElementById('body');
    const quote = document.getElementById('quote');
    const more = document.getElementById('more');
    const post = message => {
        if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(message);
        }
    };

    // <b>, <i>, <font> rather than spans with styles: what other mail programs show the same way
    document.execCommand('styleWithCSS', false, false);
    document.execCommand('defaultParagraphSeparator', false, 'div');

    let last = '';
    const report = () => {
        const flags = STATE.map(command => (document.queryCommandState(command) ? '1' : '0')).join('');
        if (flags !== last) {
            last = flags;
            post('state:' + flags);
        }
    };
    document.addEventListener('selectionchange', report);

    let dirty = false;
    body.addEventListener('input', () => {
        if (!dirty) {
            dirty = true;
            post('dirty');
        }
    });

    // the quoted message: folded behind "..." in a reply, shown in a forward; its frame grows with its content
    const fit = () => {
        if (quote && !quote.hidden && quote.contentDocument) {
            quote.style.height = quote.contentDocument.documentElement.scrollHeight + 'px';
        }
    };
    const fold = folded => {
        quote.hidden = folded;
        more.setAttribute('aria-expanded', String(!folded));
        more.title = folded ? 'Show the quoted message' : 'Hide the quoted message';
        fit();
    };
    if (quote) {
        quote.addEventListener('load', () => {
            fit();
            // pictures in the quote change its height as they load
            for (const image of quote.contentDocument.images) {
                image.addEventListener('load', fit);
            }
        });
        more.addEventListener('click', () => fold(!quote.hidden));
        window.addEventListener('resize', fit);
        fold(quote.dataset.folded === '1');
    }

    window.pe = {
        // a formatting command of the format bar: bold, fontName, foreColor, insertImage, ...
        exec(command, value) {
            body.focus();
            document.execCommand(command, false, value === undefined ? null : value);
            report();
        },
        // a link around the selection, or the address itself as the link when nothing is selected
        link(url) {
            body.focus();
            const selection = window.getSelection();
            if (selection && !selection.isCollapsed) {
                document.execCommand('createLink', false, url);
            } else {
                const a = document.createElement('a');
                a.href = url;
                a.textContent = url;
                document.execCommand('insertHTML', false, a.outerHTML);
            }
        },
        send() {
            post('html:' + body.innerHTML);
        },
        focus() {
            body.focus();
        }
    };

    // a click in the empty space below the text puts the cursor at its end, as in a text box
    document.addEventListener('mousedown', event => {
        if (event.target === document.documentElement || event.target === document.body) {
            event.preventDefault();
            body.focus();
            const range = document.createRange();
            range.selectNodeContents(body);
            range.collapse(false);
            const selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
        }
    });
    // the page is at least the window's height, so that space is the page's
    document.body.style.minHeight = '100vh';

    // the cursor where the user writes
    body.focus();
    report();
})();
