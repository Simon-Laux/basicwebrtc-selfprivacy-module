{basicwebrtc}:{ config, lib, pkgs, ... }:
let
  # Just for convinience, this module's config values
  sp = config.selfprivacy;
  cfg = sp.modules.basicwebrtc;
in
{
  # Here go the options you expose to the user.
  options.selfprivacy.modules.basicwebrtc = {
    # This is required and must always be named "enable"
    enable = (lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Enable the basicWebRTC";
    }) // {
      meta = {
        type = "enable";
      };
    };
    # This is required if your service stores data on disk
    subdomain = (lib.mkOption {
      default = "beep";
      type = lib.types.strMatching "[A-Za-z0-9][A-Za-z0-9\-]{0,61}[A-Za-z0-9]";
      description = "Subdomain";
    }) // {
      meta = {
        widget = "subdomain";
        type = "string";
        regex = "[A-Za-z0-9][A-Za-z0-9\-]{0,61}[A-Za-z0-9]";
        weight = 0;
      };
    };

  };

    # All your changes to the system must go to this config attrset.
    # It MUST use lib.mkIf with an enable option.
    # This makes sure your module only makes changes to the system
    # if the module is enabled.
  config = lib.mkIf cfg.enable {
    systemd = {
      services.basicwebrtc = {
        description = "Basicwebrtc signaling server and webserver";
        wantedBy = [ "multi-user.target" ];
        # Only nginx talks to it, so don't expose port 3900 on all interfaces
        environment.listen_ip = "127.0.0.1";
        serviceConfig = {
          ExecStart = "${basicwebrtc.packages.${pkgs.system}.default}/bin/basicwebrtc";
          Restart = "always";
          Type = "simple";
          Slice = "basicwebrtc.slice";

          # Sandboxing: the server is stateless, only reads from the nix store,
          # listens on localhost and makes no outbound connections.
          DynamicUser = true;
          User = "basicwebrtc";
          Group = "basicwebrtc";

          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          UMask = "0077";

          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          AmbientCapabilities = "";
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          RemoveIPC = true;
          PrivateUsers = true;

          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
          IPAddressDeny = "any";
          IPAddressAllow = [ "localhost" ];

          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
          # Node's V8 JIT needs writable+executable memory, enabling this crashes node
          MemoryDenyWriteExecute = false;
        };
      };
      # Define the slice itself
      slices.basicwebrtc = {
        description = "basicwebrtc slice";
      };
    };
    # You can define a reverse proxy for your service like this
    services.nginx.virtualHosts."${cfg.subdomain}.${sp.domain}" = {
      useACMEHost = sp.domain;
      forceSSL = true;
      extraConfig = ''
        add_header Strict-Transport-Security $hsts_header;
        add_header 'Referrer-Policy' 'origin-when-cross-origin';
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
      '';
      locations = {
        "/" = {
          proxyPass = "http://localhost:3900";
          proxyWebsockets = true;
        };
      };
    };
  };
}
