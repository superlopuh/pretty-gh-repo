# Pretty GitHub Repo

Generates slides for GitHub repos using `uv`, `Snakemake`, `jq`, and `Typst`.

## Prerequisites

- [uv](https://docs.astral.sh/uv/)
- [Typst](https://typst.app/) (with the "Mona Sans" font installed)
- [GitHub CLI](https://cli.github.com/) (`gh`), authenticated
- `jq`

## Adding a New Repository

1. Add the slide output to the `rule all` input list in `Snakefile`:

```python
rule all:
    input:
        "slides/{org}_{name}.png",
```

   Replace `{org}` and `{name}` with the GitHub org and repo name (e.g. `"slides/xdslproject_xdsl.png"`).

2. Run the pipeline:

```bash
uv run snakemake --cores all
```

   Snakemake will automatically fetch commits, PRs, repo info, and contributor avatars via the GitHub API, then compile a Typst slide to PNG.
   Use the `--forceall` flag to force re-download of all jsons, recommended when changing the date of generation.

3. The generated slide will be at `slides/{org}_{name}.png`.

## Configuration

Edit `default.yaml` to change:

- `generation_date` — set to today's date when regenerating slides.
