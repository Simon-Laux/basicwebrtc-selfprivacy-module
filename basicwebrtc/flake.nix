{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    basicwebrtc = {
      url = "github:cracker0dks/basicwebrtc?ref=simon/small-ui-improvements";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, basicwebrtc} :
  let
    version = "0.1.0";
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {
            inherit system;
          };
        });
    in {
    packages = forEachSupportedSystem ({pkgs}: {
      default = pkgs.buildNpmPackage {
        pname = "basicwebrtc";
        inherit version;
        src = basicwebrtc;
        npmDepsHash = "sha256-t+tQ0LxjNC5RbENAM3BFwSIgy2oM1cPDNCLxUac5Z3o=";
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r . $out
          rm $out/Dockerfile
          rm $out/.gitignore
          rm $out/updateserver.sh

          mkdir $out/bin
          cat > $out/bin/basicwebrtc <<EOF
#!${pkgs.bash}/bin/bash
export listen_port=3900
cd $out/
exec ${pkgs.nodejs}/bin/node $out/server.js "\$@"
EOF
          chmod +x $out/bin/basicwebrtc
        '';
      };
  });
};
}
