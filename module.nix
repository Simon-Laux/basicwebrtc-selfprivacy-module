{basicwebrtc}:{ config, lib, pkgs, ... }:
let
  # Just for convinience, this module's config values
  sp = config.selfprivacy;
  cfg = sp.modules.service_id;
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
    location = (lib.mkOption {
      type = lib.types.str;
      description = "basicWebRTC location";
    }) // {
      meta = {
        type = "location";
      };
    };


  config = lib.mkIf cfg.enable {

    # Your service configuration, varies heavily.
    # Refer to NixOS Options search.
    # You can use defined options here.
    services.service = {
      enable = true;
      domain = "${cfg.subdomain}.${sp.domain}";
      config = {
        theme = cfg.defaultTheme;
        appName = cfg.appName;
        signupsAllowed = cfg.signupsAllowed;
      };
    }; # bin/basicwebrtc
    systemd = {
      services.basicwebrtc = {
        description = "Basicwebrtc signaling server and webserver";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${basicwebrtc}/bin/basicwebrtc";
          Restart = "always";
          Type = "simple";
          Slice = "basicwebrtc.slice";
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
          proxyPass = "http://localhost:2283";
          proxyWebsockets = true;
        };
      };
    };
  };
 };
}
