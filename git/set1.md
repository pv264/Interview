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
