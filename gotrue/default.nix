{ callPackage
 , lib
 , stdenv
 , fetchurl
 , nixos
 , testers
 }:

 stdenv.mkDerivation (finalAttrs: {
   pname = "gotrue";
   version = "2.9.2";

   src = fetchurl {
     url = "https://github.com/supabase/gotrue/releases/download/v${finalAttrs.version}/gotrue-v${finalAttrs.version}-x86.tar.gz";
     sha256 = "G+3qddI9zyuhx//TA1i1Pt+0Nig2PgEMOXvb9HqfBtY=";
   };
   phases = ["installPhase"];
   installPhase = ''
    mkdir -p $out/bin
    tar xzvf $src
    cp gotrue $out/bin/gotrue
    chmod +x $out/bin/gotrue
    '';

 })
