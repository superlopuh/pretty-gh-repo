{
    full_name: .[1].full_name,
    description: .[1].description,
    recent_contributor_count: .[0] | map(.author.login) | map(select(. != "renovate[bot]" and . != "dependabot[bot]" and . != null and . != "github-actions[bot]"))| unique | length,
    all_contributors: .[2] | flatten | map(.author.login) | map(select(. != "renovate[bot]" and . != "dependabot[bot]" and . != null and . != "github-actions[bot]"))| group_by(.) | map({a: .[0], c: length}) | sort_by(.c) | map(.a) | reverse,
    commit_count: .[0] | length,
    stars: .[1].stargazers_count
}
