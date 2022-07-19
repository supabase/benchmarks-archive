{ callPackage
 , lib
 , stdenv
 , fetchurl
 , nixos
 , testers
 }:

 stdenv.mkDerivation (finalAttrs: {
   pname = "gotrue";
   version = "2.8.0";

   src = fetchurl {
     url = "https://github.com/supabase/gotrue/releases/download/v${finalAttrs.version}/gotrue-v${finalAttrs.version}-arm64.tar.gz";
     sha256 = "01rsiz20wc8zvw280p7f18hl5h3nhvkd59cklfxnlccqzp924rs4";
   };
   phases = ["installPhase" "patchPhase"];
   installPhase = ''
    mkdir -p $out/bin
    tar xzvf $src
    cp gotrue $out/bin/gotrue
    chmod +x $out/bin/gotrue
    '';

   doCheck = true;

 })
