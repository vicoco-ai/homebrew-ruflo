# homebrew-ruflo

Homebrew tap for `ruflo` (an npm package). The only product of this repo is
`Formula/ruflo.rb`, which installs the `ruflo` npm tarball via Homebrew.

## How the formula works

- `url`/`sha256` point at the exact npm tarball for the pinned version
  (`https://registry.npmjs.org/ruflo/-/ruflo-<version>.tgz`).
- `depends_on "node@<major>"` must satisfy the `engines.node` field of that
  ruflo version's `package.json`. The node formula is keg-only, so `install`
  writes wrapper scripts (`write_env_script`) instead of symlinking bins.
- `install` deletes pre-built binaries for foreign architectures
  (darwin-x64 vs darwin-arm64, ios-*) to keep the install lean and quiet
  `brew audit`.
- `skip_clean "libexec"` is required: a transitive native addon has too little
  Mach-O header padding for Homebrew's dylib ID rewrite.

## Version bumps

`.github/workflows/auto-update.yml` runs daily: it compares the formula
version against the npm registry, rewrites `url`, `sha256`, and the `node@`
references with sed, and opens a `bump-ruflo-<version>` PR (never pushes to
`main` directly). The same workflow then gates the PR on two jobs that both
run against the exact bump commit:

- `test` — calls `test.yml` (see Testing) on the bump commit.
- `verify-bump` — Claude independently verifies the bump, posts a
  `Verdict: PASS`/`Verdict: FAIL` comment on the PR, and returns the same
  verdict as structured output; anything but `PASS` fails the job.

If both succeed, the `merge` job squash-merges the PR (pinned to the tested
commit) and closes older `bump-ruflo-*` PRs as superseded. If either fails,
the PR stays open for a human and the workflow run is red.

A correct bump changes:

1. the version inside `url`
2. `sha256` — must match the actual tarball (`curl -sL <url> | sha256sum`)
3. `depends_on "node@X"` and every `formula_opt_bin("node@X")` reference — only if
   the `engines.node` minimum rose above the pinned major; all node@
   references must agree on the same major

The node pin is chosen by hand, not derived from `engines.node`: it should be
a Homebrew `node@X` that satisfies `engines.node` and is not deprecated
(`brew info node@X`). Homebrew disables each `node@X` about a year after its
end-of-life, at which point the formula can no longer be installed.

Nothing else in the formula should change during a routine bump.

## Testing

`.github/workflows/test.yml` (macOS) symlinks the repo as a tap, then runs
`brew install`, `ruflo --version`, `brew test`, and
`brew audit --strict --formula vicoco-ai/ruflo/ruflo`. The install step
tolerates a non-zero exit from Homebrew's linkage fixer (see `skip_clean`
note above) and verifies the binary directly instead. A final headless
Claude gate (`claude -p`, JSON output) re-audits the formula and fails the
job unless it returns `"verdict":"PASS"`.

## Conventions

- Commit messages for bumps: `Update ruflo to <version>`.
- Do not edit `Formula/ruflo.rb` styling by hand; it must stay
  `brew audit --strict` clean.
