require "language/node"

class DashlaneCli < Formula
  desc "Command-line interface for Dashlane"
  homepage "https://dashlane.com"
  url "https://github.com/Dashlane/dashlane-cli/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "541b1780efe3a94ab85179972302df17134062eba5543dda9d124a25f6de78cc"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "node@16" => :build
  depends_on "yarn" => :build

  on_macos do
    # macos requires binaries to do codesign
    depends_on xcode: :build
    # macos 12+ only
    depends_on macos: :monterey
  end

  def install
    Language::Node.setup_npm_environment
    platform = OS.linux? ? "linux" : "macos"
    system "yarn", "set", "version", "berry"
    system "yarn"
    system "yarn", "run", "build"
    system "yarn", "workspaces", "focus", "--production"
    system "yarn", "dlx", "pkg", ".",
      "-t", "node16-#{platform}-#{Hardware::CPU.arch}", "-o", "bin/dcli",
      "--no-bytecode", "--public", "--public-packages", "tslib,thirty-two"
    bin.install "bin/dcli"
  end

  test do
    # Test cli version
    assert_equal version.to_s, shell_output("#{bin}/dcli --version").chomp

    # Test cli reset storage
    expected_stdout = "? Do you really want to delete all local data from this app? (Use arrow keys)\n" \
                      "❯ Yes \n  No \e[5D\e[5C\e[2K\e[1A\e[2K\e[1A\e[2K\e[G? " \
                      "Do you really want to delete all local data from this " \
                      "app? Yes\e[64D\e[64C\nThe local Dashlane local storage has been reset"
    assert_equal expected_stdout, pipe_output("#{bin}/dcli reset", "\n", 0).chomp
  end
end
