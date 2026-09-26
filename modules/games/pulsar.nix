{
  flake.modules.nixos.games =
    { lib, pkgs, ... }:
    let
      url = "https://bbb.pulsar.gg";

      # Skips the WebHID chooser when exactly one granted device is connected.
      # Chromium ignores extensions whose files are symlinks, so copy them in.
      autoSelect =
        pkgs.runCommand "pulsar-autoselect"
          {
            manifest = builtins.toJSON {
              manifest_version = 3;
              name = "Pulsar auto-select";
              version = "1.0";
              content_scripts = [
                {
                  matches = [ "${url}/*" ];
                  js = [ "inject.js" ];
                  run_at = "document_start";
                  world = "MAIN";
                }
              ];
            };
            inject = ''
              const requestDevice = navigator.hid.requestDevice.bind(navigator.hid);
              navigator.hid.requestDevice = async (options) => {
                const granted = await navigator.hid.getDevices();
                const ids = new Set(granted.map((d) => d.vendorId + ":" + d.productId));
                return ids.size === 1 ? granted : requestDevice(options);
              };
            '';
            passAsFile = [
              "manifest"
              "inject"
            ];
          }
          ''
            mkdir $out
            cp $manifestPath $out/manifest.json
            cp $injectPath $out/inject.js
          '';
    in
    {
      services.udev.packages = [
        (pkgs.writeTextDir "lib/udev/rules.d/70-pulsar.rules" ''
          KERNEL=="hidraw*", ATTRS{idVendor}=="3710", TAG+="uaccess"
        '')
      ];

      environment.etc."chromium/policies/managed/pulsar.json".text = builtins.toJSON {
        WebHidAllowDevicesForUrls = [
          {
            devices = [ { vendor_id = 14096; } ];
            urls = [ url ];
          }
        ];
      };

      environment.systemPackages = [
        (pkgs.makeDesktopItem {
          name = "pulsar-configurator";
          desktopName = "Pulsar Configurator";
          exec = "${lib.getExe pkgs.chromium} --load-extension=${autoSelect} --app=${url}/";
          icon = pkgs.fetchurl {
            url = "${url}/img/icon.png";
            hash = "sha256-9YRlPnH63mPZFEExmyyezJiCLrMEqG+8wiflS1YMwMY=";
          };
          categories = [
            "Settings"
            "HardwareSettings"
          ];
        })
      ];
    };
}
