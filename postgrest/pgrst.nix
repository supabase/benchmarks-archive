{ stdenv, fetchurl, isNightly }:

stdenv.mkDerivation {
  name = "postgrest";
  src = if isNightly
    then fetchurl {
      url = "https://github.com/PostgREST/postgrest/releases/download/nightly/postgrest-nightly-2020-12-09-14-20-ebd474a-linux-x64-static.tar.xz";
      sha256 = "17si275mjc0mzz7zr9pl05bzg8h7xkrpvnfsf563bkwngyla7cqk";
    }
    else fetchurl {
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
