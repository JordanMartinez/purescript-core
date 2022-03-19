# purescript-core

Exploring what a mono-repo for `core` libraries for PureScript would look like, how it would work, and what tradeoffs are made using this approach.

## Observations

### Merging all repos and merge conflicts

Merging all repos' code into one repo had 2 merge conflicts
  - `ordered-collections`
  - `transformers`

These both had to be fixed by hand by copying and pasting current `master` content into repo since other folders were modified in the process.

### GitHub Actions tradeoffs

There's three ways to do this. The first one is what this repo is currently doing:
1. One `ci.yml` file per repo (e.g. for `arrays` it would be `arrays.yml`).
2. One `ci.yml` for the entire repo with one job for each repo

    ```yml
    name: CI

    jobs:
      arrays:
        # array build
      filterable:
        # filterable build
      etc:
        # ...
    ```
3. A hybrid approach. A few `ci.yml` files where the name indicates which repo's build is inside that file (e.g. `a-e.yml`, which has `arrays`, `effect`, etc. builds in it; `f-l.yml`; `m-r.yml`; `s-z.yml`).

1 makes it easy to see the build for a specific repo, but spams the "All Workflows" view when changes are made to all repos at once.

2 makes spams the "run" view when changes are made to all repos at once. Moreover, we would be editing a very large file.

3 makes the best overall tradeoff by using a tree-like search.

### Notification Spam

GitHub does not allow one to subscribe to notifications based on what labels are added to an issue. One can either opt-in to the entire repo's notifications or none at all.

The best workaround I can think of is to use some GitHub Action to repost all conversation done in one issue to the corresponding PureScript repo and asking people to subscribe to that repo instead to get notified. The other alternative is to set up some service that notifies people separately. However, there entails a privacy concern.

### Issue labeling

Due to having all repos in one project, we would need repo-specific labels to indicate which project is affected by some bug. Moreover, the issue tracker could quickly become very large and discourage people from helping due to decision paralysis.
