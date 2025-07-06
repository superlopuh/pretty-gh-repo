
rule avatar:
    output: "avatars/{username}.png"
    shell:
        "curl -L https://github.com/{wildcards.username}.png -o {output}"
