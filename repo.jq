{
    authors: map(.author.login) | map(select(. != "renovate[bot]")) | group_by(.) | map({a: .[0], c: length}) | sort_by(.c) | map(.a) | reverse
}
