# Summarizes the OpenPGP interoperability test suite's results.json (scripts/pgp-interop-suite.sh) for pe-pgp.
# pe-pgp's results, test by test: where the suite scores them a failure (a result other than the one it expects),
# and the count of each score (Unsupported: an option or subcommand the example does not have)
import collections, json, sys

report = json.load(open(sys.argv[1]))
ours = next(i["summary"] for i in report["implementations"] if i["summary"].startswith("pe-pgp-sop"))
scores = collections.Counter()
failed = collections.defaultdict(list)
for section in report["results"]:
    for test in section["results"]:
        for row in test["results"] or []:
            made = row["artifacts"]
            if made.get("producer") == ours and made["score"] == "Failure":
                failed[(section["section"], test["title"])].append(f"made by us: {(made.get('error') or '').strip()}")
            for cell in row["results"] or []:
                if cell is None or cell["producer"] != ours:
                    continue
                scores[cell["score"]] += 1
                if cell["score"] == "Failure":
                    error = (cell.get("error") or "opened").strip()
                    failed[(section["section"], test["title"])].append(f"{made.get('producer')}: {error}")

print(f"{ours}: " + ", ".join(f"{n} {score}" for score, n in scores.most_common()))
for (section, title), rows in failed.items():
    print(f"\n{section} / {title} ({len(rows)})")
    for line in rows[:6]:
        print(f"    {line[:160]}")
