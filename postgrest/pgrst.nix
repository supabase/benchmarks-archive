{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "postgrest";
  src = fetchurl {
    url = "https://github.com/PostgREST/postgrest/releases/download/v7.0.1/postgrest-v7.0.1-linux-x64-static.tar.xz";
    sha256 = "0h5zlpz7f7x220pklp28pggkpai7vfv06dpdal4xpq8bc56gf27p";
  };
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    tar xJvf $src
    cp postgrest $out/bin/postgrest
    chmod +x $out/bin/postgrest
  '';
}
