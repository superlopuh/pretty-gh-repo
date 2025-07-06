configfile: "default.yaml"

rule all:
    input:
        "repos/xdslproject/inconspiquous/slide.png",
        "repos/xdslproject/tenstorrent/slide.png",
        "repos/xdslproject/xdsl-asl/slide.png",
        "repos/xdslproject/xdsl-torch/slide.png",
        "repos/xdslproject/xdsl/slide.png",

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
        "jq '[.[] | .[] | select(.commit.author.date > \"{params.min_date}\")]' {input} > {output}"

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
    input: "repos/{org}/{name}/slide.typ"
    output: "repos/{org}/{name}/slide.png"
    shell: "typst compile repos/{wildcards.org}/{wildcards.name}/slide.typ --root . --format png"
