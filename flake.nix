{
  description = "Flake description";

  inputs = {
    basicwebrtc.url = "path:./basicwebrtc";
  };

  outputs = { self, basicwebrtc }: {
    nixosModules.default = import ./module.nix { inherit basicwebrtc; };
    configPathsNeeded =
      builtins.fromJSON (builtins.readFile ./config-paths-needed.json);
    meta = {lib, ...}: {
      spModuleSchemaVersion = 1;
      id = "basicwebrtc";
      name = "basicWebRTC";
      description = "Basic encrypted p2p audio and video calls over WebRTC.";
      svgIcon = builtins.readFile ./icon.svg;
      showUrl = true;
      primarySubdomain = "beep";
      isMovable = false;
      isRequired = false;
      canBeBackedUp = false;
      systemdServices = [
        "basicwebrtc.service"
      ];
      user = "basicwebrtc";
      group = "basicwebrtc";

      license = [
        lib.licenses.mit
      ];
      # homepage = "https://github.com/cracker0dks/basicwebrtc";
      sourcePage = "https://github.com/cracker0dks/basicwebrtc";
      supportLevel = "community";
    };
  };
}
