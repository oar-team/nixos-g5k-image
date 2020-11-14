with import <nixpkgs> {};
let

  #pkgs = import <nixpkgs> {};
  nixos-generator = stdenv.mkDerivation rec {
  pname = "nixos-generators";
  version = "1.2.0";
  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nixos-generators";
    rev = version;
    sha256 = "GxEDeHRBR3S9JfYjD+2VtsN7JnOD2sV7s/7//WEajMc=";
  };
  nativeBuildInputs = [ makeWrapper ];
  installFlags = [ "PREFIX=$(out)" ];
  postFixup = ''
    wrapProgram $out/bin/nixos-generate \
      --prefix PATH : ${lib.makeBinPath [ jq coreutils findutils nix ] }
  '';
};

in
pkgs.mkShell {
  buildInputs = [ nixos-generator ];
}
