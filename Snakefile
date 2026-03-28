configfile: "default.yaml"

from datetime import date, timedelta
GENERATION_DATE = date.fromisoformat(config["generation_date"])
MIN_DATE = (GENERATION_DATE - timedelta(days=config["lookback_days"])).isoformat()

rule all:
    input:
        "slides/xdslproject_inconspiquous.png",
        "slides/xdslproject_tenstorrent.png",
        "slides/xdslproject_xdsl-asl.png",
        "slides/xdslproject_xdsl-torch.png",
        "slides/xdslproject_xdsl.png",
        "slides/xdslproject_xdsl-jax.png",

rule avatar:
    output: "avatars/{username}"
    shell:
        "gh api users/{wildcards.username} --jq '.avatar_url' | xargs curl -L -o {output}"

rule all_commits:
    output: "repos/{org}/{name}/all_commits.json"
    shell:
        "gh api repos/{wildcards.org}/{wildcards.name}/commits --paginate --slurp | jq > {output}"

rule all_prs:
    output: "repos/{org}/{name}/all_prs.json"
    shell:
        "gh api 'repos/{wildcards.org}/{wildcards.name}/pulls?state=all' --paginate --slurp | jq > {output}"

rule stars:
    output: "repos/{org}/{name}/info.json"
    shell:
        "gh api repos/{wildcards.org}/{wildcards.name} | jq > {output}"

rule releases:
    output: "repos/{org}/{name}/releases.json"
    shell:
        "gh api repos/{wildcards.org}/{wildcards.name}/releases | jq > {output}"

rule recent_commits:
    input: "repos/{org}/{name}/all_commits.json"
    output: "repos/{org}/{name}/recent_commits.json"
    params:
        min_date=MIN_DATE
    shell:
        "jq '[.[] | .[] | select(.commit.author.date > \"{params.min_date}\")]' {input} > {output}"

rule recent_prs:
    input: "repos/{org}/{name}/all_prs.json"
    output: "repos/{org}/{name}/recent_prs.json"
    params:
        min_date=MIN_DATE
    shell:
        "jq '[.[] | .[] | select(.created_at > \"{params.min_date}\")]' {input} > {output}"

rule recent_pr_start_end_times:
    input: "repos/{org}/{name}/recent_prs.json"
    output: "repos/{org}/{name}/recent_pr_start_end_times.jsonl"
    shell:
        (
            "jq -c '.[] | {{start: .created_at, end: .closed_at}}' {input} > {output}"
        )

rule pr_median_time:
    input:
        "repos/{org}/{name}/recent_prs.json"
    output:
        "repos/{org}/{name}/pr_median_time.json"
    run:
        import pandas as pd

        df = pd.read_json(input[0], convert_dates=["created_at", "closed_at"])
        num_closed = int(df["closed_at"].notna().sum())
        df["closed_at"] = df["closed_at"].fillna(pd.Timestamp.now("UTC"))
        df["close_time_hours"] = (df["closed_at"] - df["created_at"]).dt.total_seconds() / 3600

        res = {
            "median_close_time_hours": round(df["close_time_hours"].median(), 2),
            "num_closed": num_closed,
            "num_total": len(df),
        }
        pd.Series(res).to_json(output[0], indent=2)

rule repo:
    input:
        recent_commits="repos/{org}/{name}/recent_commits.json",
        info="repos/{org}/{name}/info.json",
        all_commits="repos/{org}/{name}/all_commits.json",
        jq_script="repo.jq"
    output: "repos/{org}/{name}/repo.json"
    shell:
        "jq -f repo.jq --slurp {input.recent_commits} {input.info} {input.all_commits} > {output}"

rule author_avatars:
    input: "repos/{org}/{name}/repo.json"
    output: "repos/{org}/{name}/avatars.done"
    shell:
        "snakemake --cores all $(jq -r '.all_contributors | .[] | \"avatars/\" + .' {input} | tr '\\n' ' ') && touch {output}"

rule slide_typ:
    input: "repos/{org}/{name}/avatars.done"
    output: "repos/{org}/{name}/slide.typ"
    shell:
        """cat > {output} << EOL
#import "../../../repo.typ": show_repo

#set page(
width: 13.33in,
height: 7.5in,
margin: 0.5in,
)

#set text(font: "Mona Sans", size: 20pt)

#show_repo("{wildcards.org}/{wildcards.name}")
EOL
"""

rule slide_png:
    input:
        slide="repos/{org}/{name}/slide.typ",
        repo="repo.typ",
        pr_median_time="repos/{org}/{name}/pr_median_time.json",
    output: "repos/{org}/{name}/slide.png"
    shell: "typst compile {input.slide} --root . --format png"

rule moved_slide:
    input: "repos/{org}/{name}/slide.png"
    output: "slides/{org}_{name}.png"
    shell: "cp {input} {output}"
