#!/usr/bin/env nu

def main [owner?: string, out: string = "README.md"] {
  let owner = if ($owner == null) {
    gh api user --jq '.login' | str trim
  } else {
    $owner
  }

  let generated_at = (date now | format date "%Y-%m-%d %H:%M:%SZ")
  let excluded_repos = [".github"]

  let repos = (
    gh repo list $owner --limit 1000 --json name,url,description,updatedAt,isFork
    | from json
    | where isFork == false
    | where { |repo| not ($excluded_repos | any { |name| $name == $repo.name }) }
    | sort-by updatedAt --reverse
  )

  let content = (
    [
      $"# ($owner) GitHub repositories"
      ""
      $"A list of all non-fork repositories under the `($owner)` GitHub account, sorted by recent GitHub activity. Each row shows the repo, its GitHub description, and a human-readable last updated time."
      ""
      $"Last generated: ($generated_at)"
      ""
      "## Excluded repositories"
      ""
      ...($excluded_repos | each { |name| ["- ", $name] | str join "" })
      ""
      "## Repositories"
      ""
      "| Repository | Description | Last updated |"
      "| --- | --- | --- |"
      ...($repos | each { |repo|
        let description = if ($repo.description | is-empty) { "No description" } else { $repo.description }
        let last_updated = ($repo.updatedAt | into datetime | date humanize)
        ["| [", $repo.name, "](", $repo.url, ") | ", $description, " | ", $last_updated, " |"] | str join ""
      })
    ]
    | str join (char nl)
  )

  $content | save -f $out
}
