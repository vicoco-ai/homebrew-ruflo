class Ruflo < Formula
  desc "Enterprise AI orchestration platform for Claude"
  homepage "https://github.com/ruvnet/ruflo"
  url "https://registry.npmjs.org/ruflo/-/ruflo-3.7.0-alpha.11.tgz"
  sha256 "1b58221fef3fee46f2f821aa0add96bbcb0fdb095b8282cb71bbb31de8f435eb"
  license "MIT"

  depends_on "node@20"

  # Pre-built native addon has insufficient header padding for dylib ID rewrite
  skip_clean "libexec"

  def install
    system "npm", "install", *std_npm_args

    # node@22 is keg-only, so create a wrapper that puts it on PATH
    # instead of symlinking (which would use #!/usr/bin/env node and fail).
    libexec.glob("bin/*").each do |f|
      (bin/f.basename).write_env_script f, PATH: "#{Formula["node@20"].opt_bin}:$PATH"
    end

    # Remove pre-built binaries for non-native architectures.
    # The npm tarball ships multi-arch prebuilds; keeping only the native
    # ones avoids brew-audit warnings and reduces install size.
    foreign_arch = Hardware::CPU.arm? ? "x64" : "arm64"
    nm = libexec/"lib/node_modules/ruflo/node_modules"
    system "find", nm, "-type", "d", "-name",
           "darwin-#{foreign_arch}", "-path", "*/prebuilds/*",
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
