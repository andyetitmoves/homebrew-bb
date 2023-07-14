class TinyproxyLibproxy < Formula
  desc "HTTP/HTTPS proxy for POSIX systems (with libproxy support)"
  homepage "https://www.banu.com/tinyproxy/"
  url "https://github.com/andyetitmoves/tinyproxy", :using => :git, :revision => "9e4463c56495718523c809b34d4692773a35ecd3"
  version "1.8.3+libproxy-0.1"

  head "https://github.com/andyetitmoves/tinyproxy", :using => :git, :branch => "libproxy-upstream"

  depends_on "asciidoc" => :build
  depends_on "libproxy"

  # Since we build from git
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  conflicts_with "tinyproxy", :because => "because tinyproxy and tinyproxy-libproxy install the same thing from different sources"

  option "with-reverse", "Enable reverse proxying"
  option "with-transparent", "Enable transparent proxying"

  deprecated_option "reverse" => "with-reverse"

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --localstatedir=#{var}
      --sysconfdir=#{etc}
      --disable-regexcheck
    ]

    args << "--enable-reverse" if build.with? "reverse"
    args << "--enable-transparent" if build.with? "transparent"

    system "./autogen.sh", *args

    system "make", "install"
  end

  def post_install
    (var/"log/tinyproxy").mkpath
    (var/"run/tinyproxy").mkpath
  end

  test do
    pid = fork do
      exec "#{sbin}/tinyproxy"
    end
    sleep 2

    begin
      assert_match /tinyproxy/, shell_output("curl localhost:8888")
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end

  service do
    run [opt_sbin/"tinyproxy"]
    require_root true
    keep_alive true
    working_dir HOMEBREW_PREFIX
  end
end
