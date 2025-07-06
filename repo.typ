#let config = yaml("default.yaml")

#let show_authors(repo) = {
  if repo.authors.len() > 5 {
    // The icons + names don't all fit, drop names and tile space with circles
    let item_count = repo.authors.len()
    let container_width = 8cm
    let container_height = 10cm
    for cols in range(1, 100) {
      let avatar_size = container_width / cols
      let rows = calc.floor(container_height / avatar_size)
      if item_count <= cols * rows {
        // This number of columns fits

        for row in range(rows) {
          for col in range(cols) {
            let x_pos = col * avatar_size
            let y_pos = row * avatar_size

            if item_count <= row * cols + col {
              break
            }

            let author = repo.authors.at(row * cols + col)

            box(clip: true, radius: avatar_size / 2, width: avatar_size, height: avatar_size, image(
              "avatars/" + author,
            ))
          }
          "\n"
        }
        break
      }
    }

    // Calculate optimal grid dimensions
    let aspect_ratio = container_width / container_height
    let cols = calc.ceil(calc.sqrt(item_count * aspect_ratio))
    let rows = calc.ceil(item_count / cols)

    // Calculate individual item size to fit the container
    let item_width = container_width / cols
    let item_height = container_height / rows
    let item_size = calc.min(item_width, item_height)

    // Ensure we don't exceed container bounds
    let actual_cols = calc.min(cols, calc.ceil(container_width / item_size))
    let actual_rows = calc.ceil(item_count / actual_cols)
    let final_item_size = calc.min(container_width / actual_cols, container_height / actual_rows)
  } else {
    for author in repo.authors {
      stack(dir: ltr, box(clip: true, radius: 1cm, width: 2cm, height: 2cm, image("avatars/" + author)), align(
        horizon,
      )[#text(
          "   @" + author,
          font: "Mona Sans",
        )])
    }
  }
}

#let show_repo(repo_path) = {
  let repo = json("repos/" + repo_path + "/repo.json")

  set text(font: "Mona Sans", size: 33pt)
  pad[
    *#repo.full_name * #h(1fr) #repo.stars ⭐️
  ]

  set text(font: "Mona Sans", size: 20pt)

  grid(
    columns: 2,
    column-gutter: 1fr,
  )[
    _#repo.description _

    In the last 6 months:

    - #repo.commit_count commits
  ][
    #show_authors(repo)
  ]
}
