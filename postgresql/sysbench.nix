{ stdenv, fetchFromGitHub, autoreconfHook, pkg-config, libaio, postgresql }:

stdenv.mkDerivation rec {
  pname = "sysbench";
  version = "1.0.20";

  nativeBuildInputs = [ autoreconfHook pkg-config postgresql ];
  buildInputs = [ libaio postgresql ];
  configureFlags = [ "--with-pgsql" "--without-mysql" ];

  src = fetchFromGitHub {
    owner = "akopytov";
    repo = pname;
    rev = version;
    sha256 = "1sanvl2a52ff4shj62nw395zzgdgywplqvwip74ky8q7s6qjf5qy";
  };

  enableParallelBuilding = true;

  meta = {
    description = "Modular, cross-platform and multi-threaded benchmark tool";
    homepage = "https://github.com/akopytov/sysbench";
  };
}
