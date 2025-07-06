
rule avatar:
    output: "avatars/{username}.png"
    shell:
        "curl -L https://github.com/{wildcards.username}.png -o {output}"

rule all_commits:
    output: "repos/{org}/{name}/all_commits.json"
    shell:
        "gh api repos/{wildcards.org}/{wildcards.name}/commits --paginate --slurp | jq > {output}"

# Six months ago, update this value when re-generating
MIN_DATE = "2025-01-04"

rule recent_commits:
    input: "repos/{org}/{name}/all_commits.json"
    output: "repos/{org}/{name}/recent_commits.json"
    shell:
        "jq '[.[] | .[] | select(.commit.author.date > {MIN_DATE})]' {input} > {output}"

rule repo:
    input:
        recent_commits="repos/{org}/{name}/recent_commits.json",
        jq_script="repo.jq"
    output: "repos/{org}/{name}/repo.json"
    shell:
        "jq -f repo.jq {input.recent_commits} > {output}"

rule author_avatars:
    input: "repos/{org}/{name}/repo.json"
    output: "repos/{org}/{name}/avatars.done"
    shell:
        "snakemake --cores all $(jq -r '.authors | .[] | \"avatars/\" + . + \".png\"' {input} | tr '\\n' ' ') && touch {output}"
