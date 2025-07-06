
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
    input: "repos/{org}/{name}/recent_commits.json"
    output: "repos/{org}/{name}/repo.json"
    shell:
        "jq -f repo.jq {input} > {output}"
