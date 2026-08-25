## How I Enforce Branch Protection Rules

I enforce branch protection rules on the `main` branch using GitHub repository settings.

- Prevent developers from pushing directly to `main` and require all changes to go through a **Pull Request (PR)**.
- Configure **mandatory code reviews**, typically requiring one or two approvals before merging.
- Configure **required CI status checks**, such as:
  - Build
  - Unit tests
  - Security scans
- Allow a PR to be merged only when all required checks pass and the required approvals are received.
- **Disable force pushes** to `main` to prevent anyone from rewriting the branch history.

This ensures that only **reviewed, tested, and approved code** is merged into the `main` branch.


# Git Merge vs Rebase

Git **merge** and **rebase** are both used to bring changes from one branch into another, but they handle the Git history differently.

## Merge

**Merge** combines the two branches and preserves their existing history. It may create a merge commit.

For example:

```text
main:     A---B---C
               \
feature:        D---E
```

If I merge `main` into `feature`, the history becomes:

```text
A---B---C
     \   \
      D---E---M
```

I would use **merge** when working with shared branches or when I want to preserve the complete history of how the branches were developed.

## Rebase

**Rebase** takes the commits from my feature branch and replays them on top of the latest `main` branch. This gives a cleaner, linear history.

For example:

```text
main:     A---B---C
               \
feature:        D---E
```

After rebasing the feature branch:

```text
A---B---C---D'---E'
```

Here, `D'` and `E'` are recreated commits based on the latest `main`.

I generally use **rebase on my own feature branch** to bring in the latest changes from `main` and keep the history clean. I use **merge for shared branches** when preserving the existing history is more important.

