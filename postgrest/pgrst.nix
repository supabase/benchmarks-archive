{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "postgrest";
  src = fetchurl {
      url = "https://github.com/PostgREST/postgrest/releases/download/v9.0.0.20220531/postgrest-v9.0.0.20220531-linux-static-x64.tar.xz";
      sha256 = "sha256-7Lmm4+SqoQ743qh+rUn5wM+1lqZ8R6DAhg654Lmb/nc=";
    };
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    tar xJvf $src
    cp postgrest $out/bin/postgrest
    chmod +x $out/bin/postgrest
  '';
}
