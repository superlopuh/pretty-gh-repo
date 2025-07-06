{
    authors: .[0] | map(.author.login) | map(select(. != "renovate[bot]")) | group_by(.) | map({a: .[0], c: length}) | sort_by(.c) | map(.a) | reverse,
    stars: .[1].stargazers_count
}
