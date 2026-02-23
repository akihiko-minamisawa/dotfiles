---
name: review-diff
description: Review code differences between two branches before creating a PR.
argument-hint: "[base-branch] [compare-branch]"
disable-model-invocation: true
---

# Code Review: Branch Diff

If either `$0` or `$1` is empty or missing, do NOT proceed with the review.
Instead, display the following usage message and stop:

```
Usage: /review-diff [base-branch] [compare-branch]

Example:
  /review-diff develop feature/my-feature
  /review-diff main feature/add-login
```

Otherwise, review the diff between the base branch `$0` and the compare branch `$1`.

## Steps

1. Get the diff using the following commands:

   ```bash
   git diff $0..$1 --stat
   git log $0..$1 --oneline
   git diff $0..$1
   ```

2. Review the changes from these perspectives:
   - **Bugs**: Logic errors, unhandled edge cases
   - **Security**: Injection, XSS, and other vulnerabilities
   - **Performance**: Unnecessary loops, expensive operations
   - **Code quality**: Readability, naming, duplication
   - **Tests**: Coverage and adequacy of tests

3. Provide the output in the following format:
   - **Summary**: What changed
   - **Issues**: Problems that should be fixed
   - **Suggestions**: Improvements to consider
   - **Verdict**: Ready to merge / Needs changes
