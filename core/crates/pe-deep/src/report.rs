//! The page a run leaves (`report.html`) and its outcome for the release (`result.json`): the journeys with pass or
//! fail, the walk with its seed, the health over the run, and for each failure the steps before it, what the window
//! showed and its picture.

use std::fmt::Write as _;
use std::path::Path;

use serde_json::json;

use crate::run::Run;

fn escape(text: &str) -> String {
    text.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

/// What the run concluded, for scripts: passed, the seed, the commit, the counts
pub fn result_json(run: &Run<'_>, passed: bool, stopped: Option<&str>, commit: &str) -> serde_json::Value {
    json!({
        "passed": passed,
        "target": run.target.name(),
        "seed": run.world.seed,
        "profile": run.world.profile.name(),
        "world": run.world.digest(),
        "commit": commit,
        "steps": run.step_number(),
        "failures": run.failed.len(),
        "stopped": stopped,
        "seconds": run.elapsed().round(),
        "health": crate::health::judge(&run.samples),
    })
}

/// The page of the run
pub fn write(
    run: &Run<'_>,
    passed: bool,
    stopped: Option<&str>,
    health: &[String],
    path: &Path,
) -> std::io::Result<()> {
    let mut page = String::new();
    let verdict = if passed { "Passed" } else { "Failed" };
    let _ = write!(
        page,
        r#"<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Deep test: {target}</title>
<style>
:root{{--bg:#f6f7f9;--panel:#fff;--ink:#1c1f25;--muted:#5d6370;--line:#dfe2e8;--ok:#1d7a46;--bad:#a3352b;--accent:#1f5fae}}
@media (prefers-color-scheme:dark){{:root{{--bg:#15171b;--panel:#1e2127;--ink:#e7e8ec;--muted:#a1a7b3;--line:#2f333b;--ok:#6fd39b;--bad:#f0897d;--accent:#7fb0f0}}}}
body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 -apple-system,"Segoe UI",Roboto,sans-serif}}
main{{max-width:1040px;margin:0 auto;padding:28px 16px 60px}}
h1{{margin:0 0 4px}} h2{{margin:28px 0 8px}} .muted{{color:var(--muted)}}
table{{border-collapse:collapse;width:100%;background:var(--panel);border:1px solid var(--line)}}
td,th{{padding:6px 10px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}}
.ok{{color:var(--ok);font-weight:700}} .bad{{color:var(--bad);font-weight:700}}
pre{{background:var(--panel);border:1px solid var(--line);padding:10px;overflow-x:auto;font-size:12.5px}}
img{{max-width:100%;border:1px solid var(--line)}}
</style></head><body><main>
<h1>Deep test: {target} <span class="{class}">{verdict}</span></h1>
<p class="muted">Seed {seed}, profile {profile} ({messages} messages, world {digest}), {steps} steps in {seconds:.0} s{stopped}.
Play it again with <code>scripts/deep-test.sh {target} --seed {seed} --profile {profile} --until {steps}</code>.</p>
"#,
        target = escape(run.target.name()),
        class = if passed { "ok" } else { "bad" },
        seed = run.world.seed,
        profile = run.world.profile.name(),
        messages = run.world.total(),
        digest = run.world.digest(),
        steps = run.step_number(),
        seconds = run.elapsed(),
        stopped = stopped.map(|s| format!(", stopped: {}", escape(s))).unwrap_or_default(),
    );
    page.push_str(
        "<h2>Journeys</h2><table><tr><th>Journey</th><th>Outcome</th><th>Seconds</th><th>Not done here</th></tr>",
    );
    for j in &run.journeys {
        let _ = write!(
            page,
            "<tr><td>{} {}</td><td class=\"{}\">{}</td><td>{:.0}</td><td>{}</td></tr>",
            j.id,
            escape(j.name),
            if j.failures == 0 { "ok" } else { "bad" },
            if j.failures == 0 {
                "passed".to_string()
            } else {
                format!("{} failed", j.failures)
            },
            j.seconds,
            escape(&j.skipped.join("; "))
        );
    }
    page.push_str("</table>");
    page.push_str("<h2>Health</h2>");
    if health.is_empty() {
        page.push_str("<p class=\"ok\">Nothing grew out of bounds over the run.</p>");
    } else {
        for line in health {
            let _ = write!(page, "<p class=\"bad\">{}</p>", escape(line));
        }
    }
    if let (Some(first), Some(last)) = (run.samples.first(), run.samples.last()) {
        let _ = write!(
            page,
            "<table><tr><th></th><th>Memory (KiB)</th><th>Open files</th><th>IMAP sessions</th><th>Store (bytes)</th></tr>\
             <tr><td>Step {}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr><tr><td>Step {}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr></table>",
            first.step,
            first.memory_kib,
            first.open_files,
            first.sessions,
            first.store_bytes,
            last.step,
            last.memory_kib,
            last.open_files,
            last.sessions,
            last.store_bytes
        );
    }
    let _ = write!(page, "<h2>Failures ({})</h2>", run.failed.len());
    for failed in run.failed.iter().take(40) {
        let _ = write!(
            page,
            "<h3>Step {} ({}) {}: {}</h3>",
            failed.step,
            escape(&failed.part),
            failed.failure.check,
            escape(&failed.failure.detail)
        );
        let before: Vec<String> = run
            .steps
            .iter()
            .filter(|s| s.number + 30 > failed.step && s.number <= failed.step)
            .map(|s| format!("{:>6} {:>8.1}s {:<6} {}", s.number, s.at, s.part, s.what))
            .collect();
        let _ = write!(page, "<pre>{}</pre>", escape(&before.join("\n")));
        if let Some(seen) = &failed.seen {
            let _ = write!(
                page,
                "<details><summary>What the window showed</summary><pre>{}</pre></details>",
                escape(&serde_json::to_string_pretty(&seen.to_json()).unwrap_or_default())
            );
        }
        if let Some(shot) = &failed.screenshot
            && let Some(name) = shot.file_name()
        {
            let _ = write!(
                page,
                "<img src=\"{}\" alt=\"The window at step {}\">",
                escape(&name.to_string_lossy()),
                failed.step
            );
        }
    }
    page.push_str("<h2>Steps</h2><pre>");
    for s in &run.steps {
        let _ = writeln!(page, "{:>6} {:>8.1}s {:<6} {}", s.number, s.at, s.part, escape(&s.what));
    }
    page.push_str("</pre></main></body></html>\n");
    std::fs::write(path, page)
}
