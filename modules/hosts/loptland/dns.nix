{
  flake.modules.nixos."hosts/loptland" =
    { config, ... }:
    let
      tailscaleIp = "100.86.250.97";
    in
    {
      local.unbound = {
        interfaces = [
          "127.0.0.1"
          "::1"
          tailscaleIp
        ];
        allowedNetworks = [
          "127.0.0.0/8"
          "::1/128"
          "100.64.0.0/10"
        ];
        ipv6 = true;
        threatFeed = true;
      };

      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [ config.local.unbound.port ];
        allowedUDPPorts = [ config.local.unbound.port ];
      };

      services.resolved.settings.Resolve.DNS = [ "127.0.0.1" ];
      networking.dhcpcd.extraConfig = "nooption domain_name_servers";
    };
}
