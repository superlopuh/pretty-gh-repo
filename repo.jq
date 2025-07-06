{
    full_name: .[1].full_name,
    authors: .[0] | map(.author.login) | map(select(. != "renovate[bot]")) | group_by(.) | map({a: .[0], c: length}) | sort_by(.c) | map(.a) | reverse,
    commit_count: .[0] | length,
    stars: .[1].stargazers_count
}
