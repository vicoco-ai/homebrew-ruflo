class Ruflo < Formula
  desc "Enterprise AI orchestration platform for Claude"
  homepage "https://github.com/ruvnet/ruflo"
  url "https://registry.npmjs.org/ruflo/-/ruflo-3.80.0.tgz"
  sha256 "2c52c9d1c2d8ed101710d2eff3cf368e997ee69c6a26afe4583f1141fde04242"
  license "MIT"

  depends_on "node@24"

  # Pre-built native addon has insufficient header padding for dylib ID rewrite
  skip_clean "libexec"

  def install
    system "npm", "install", *std_npm_args

    # node@24 is keg-only, so create a wrapper that puts it on PATH
    # instead of symlinking (which would use #!/usr/bin/env node and fail).
    libexec.glob("bin/*").each do |f|
      (bin/f.basename).write_env_script f, PATH: "#{formula_opt_bin("node@24")}:$PATH"
    end

    # Remove pre-built binaries for non-native architectures.
    # The npm tarball ships multi-arch prebuilds; keeping only the native
    # ones avoids brew-audit warnings and reduces install size.
    foreign_arch = Hardware::CPU.arm? ? "x64" : "arm64"
    nm = libexec/"lib/node_modules/ruflo/node_modules"
    # Matches both prebuilds/darwin-<arch> dirs and per-platform npm
    # packages like @agntcy/slim-bindings-darwin-<arch>.
    system "find", nm, "-type", "d", "-name",
           "*darwin-#{foreign_arch}*",
           "-exec", "rm", "-rf", "{}", "+"
    # Arch-first layout, e.g. claude-agent-sdk/vendor/ripgrep/<arch>-darwin.
    system "find", nm, "-type", "d", "-name",
           "#{foreign_arch}-darwin",
           "-exec", "rm", "-rf", "{}", "+"
    system "find", nm, "-type", "d", "-name", "ios-*",
           "-path", "*/prebuilds/*",
           "-exec", "rm", "-rf", "{}", "+"
    system "find", nm, "-type", "d", "-path",
           "*/onnxruntime-node/bin/napi-v3/darwin/#{foreign_arch}",
           "-exec", "rm", "-rf", "{}", "+"
    system "find", nm, "-type", "f",
           "-name", "*.darwin-#{foreign_arch}.node", "-delete"
  end

  def caveats
    <<~EOS
      ruflo requires Claude Code. If you don't have it installed:
        brew install --cask claude-code
      or see https://docs.anthropic.com/en/docs/claude-code
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ruflo --version")
  end
end
