#!/usr/bin/env bash
# Puts the help on the homepage (../inboxclassic.com/help/<language>/<platform>/): the same topics the apps show, made
# by pe-html's help export for each platform, and help/index.html, which sends a visitor to their language and
# platform. scripts/release.sh runs it with each release; run it by hand after changing the help. Does not commit.
#
#   scripts/homepage-help.sh
set -euo pipefail
cd "$(dirname "$0")/.."
HOMEPAGE=${HOMEPAGE:-../inboxclassic.com}
[ -d "$HOMEPAGE" ] || { echo "No homepage checkout at $HOMEPAGE" >&2; exit 1; }

out=$(mktemp -d)
for platform in windows mac linux; do
    (cd core && cargo run -q --release -p pe-html --example help-export -- "$platform" web "$out/$platform")
done
rm -rf "$HOMEPAGE/help"
mkdir -p "$HOMEPAGE/help"
# the export writes <platform>/<language>/; the site has <language>/<platform>/
for platform in windows mac linux; do
    for language_dir in "$out/$platform"/*/; do
        language=$(basename "$language_dir")
        mkdir -p "$HOMEPAGE/help/$language"
        cp -R "$language_dir" "$HOMEPAGE/help/$language/$platform"
    done
done
rm -rf "$out"

# the visitor's language (of the ones there is help in) and platform, as the homepage picks the download
cat >"$HOMEPAGE/help/index.html" <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inbox Classic Help</title>
<link rel="canonical" href="https://inboxclassic.com/help/en/windows/index.html">
<script>
(function () {
    var languages = ['en', 'de', 'es', 'et', 'fr'];
    var language = 'en';
    var wanted = navigator.languages || [navigator.language || 'en'];
    for (var i = 0; i < wanted.length; i++) {
        var code = String(wanted[i]).slice(0, 2).toLowerCase();
        if (languages.indexOf(code) >= 0) { language = code; break; }
    }
    var platform = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || '';
    var name = /mac/i.test(platform) ? 'mac' : /linux/i.test(platform) && !/android/i.test(navigator.userAgent) ? 'linux' : 'windows';
    location.replace(language + '/' + name + '/index.html' + location.hash);
})();
</script>
</head>
<body>
<p><a href="en/windows/index.html">Inbox Classic Help</a>: <a href="en/windows/index.html">Windows</a>, <a href="en/mac/index.html">Mac</a>, <a href="en/linux/index.html">Linux</a></p>
</body>
</html>
EOF
# every page, for the search engines (robots.txt names this sitemap)
today=$(date -u +%Y-%m-%d)
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    (cd "$HOMEPAGE" && find help -name '*.html' ! -path help/index.html | sort) | while read -r page; do
        echo "    <url><loc>https://inboxclassic.com/$page</loc><lastmod>$today</lastmod></url>"
    done
    echo '</urlset>'
} >"$HOMEPAGE/help/sitemap.xml"
echo "The help is in $HOMEPAGE/help"
