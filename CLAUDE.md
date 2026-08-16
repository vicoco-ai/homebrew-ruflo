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
`main` directly). A separate Claude job then verifies the bump and posts a
`Verdict: PASS`/`Verdict: FAIL` comment on the PR. A correct bump changes:

1. the version inside `url`
2. `sha256` — must match the actual tarball (`curl -sL <url> | sha256sum`)
3. `depends_on "node@X"` and every `Formula["node@X"]` reference — only if
   `engines.node` changed; all node@ references must agree on the same major

Nothing else in the formula should change during a routine bump.

## Testing

`.github/workflows/test.yml` (macOS) symlinks the repo as a tap, then runs
`brew install`, `ruflo --version`, `brew test`, and
`brew audit --strict --formula vicoco-ai/ruflo/ruflo`. The install step
tolerates a non-zero exit from Homebrew's linkage fixer (see `skip_clean`
note above) and verifies the binary directly instead.

## Conventions

- Commit messages for bumps: `Update ruflo to <version>`.
- Do not edit `Formula/ruflo.rb` styling by hand; it must stay
  `brew audit --strict` clean.
