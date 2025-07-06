configfile: "default.yaml"

rule all:
    input:
        "repos/xdslproject/inconspiquous/avatars.done",
        "repos/xdslproject/xdsl/avatars.done",
        "repos/xdslproject/xdsl-torch/avatars.done"

rule avatar:
    output: "avatars/{username}"
    shell:
        "gh api users/{wildcards.username} --jq '.avatar_url' | xargs curl -L -o {output}"

rule all_commits:
    output: "repos/{org}/{name}/all_commits.json"
    shell:
        "gh api repos/{wildcards.org}/{wildcards.name}/commits --paginate --slurp | jq > {output}"

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
        min_date=config["min_date"]
    shell:
        "jq '[.[] | .[] | select(.commit.author.date > {params.min_date})]' {input} > {output}"

rule repo:
    input:
        recent_commits="repos/{org}/{name}/recent_commits.json",
        info="repos/{org}/{name}/info.json",
        jq_script="repo.jq"
    output: "repos/{org}/{name}/repo.json"
    shell:
        "jq -f repo.jq --slurp {input.recent_commits} {input.info} > {output}"

rule author_avatars:
    input: "repos/{org}/{name}/repo.json"
    output: "repos/{org}/{name}/avatars.done"
    shell:
        "snakemake --cores all $(jq -r '.authors | .[] | \"avatars/\" + .' {input} | tr '\\n' ' ') && touch {output}"
