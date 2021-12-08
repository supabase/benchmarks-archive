{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "postgrest";
  src = fetchurl {
      url = "https://github.com/PostgREST/postgrest/releases/download/v9.0.0/postgrest-v9.0.0-linux-static-x64.tar.xz";
      sha256 = "0gngjj7bc93v9dzyxxlmqiza2p3dm8w5vp6wf26vlmwm2zm22j7a";
    };
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    tar xJvf $src
    cp postgrest $out/bin/postgrest
    chmod +x $out/bin/postgrest
  '';
}
