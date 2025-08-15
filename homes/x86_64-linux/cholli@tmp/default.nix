{
  lib,
  pkgs,
  config,
  namespace,
  osConfig ? { },
  format ? "unknown",
  ...
}:
with lib.${namespace};
{
  wyrdgard = {
    apps = {
      kitty = enabled;
    };

    tools = {
      direnv = enabled;
    };
  };

  services.easyeffects = {
    enable = true;
    preset = "jtrv-preset";
    extraPresets = {
      jtrv-preset = {
        input = {
          blocklist = [

          ];
          "compressor#0" = {
            attack = 5;
            boost-amount = 6;
            boost-threshold = -72;
            bypass = false;
            dry = -100;
            hpf-frequency = 10;
            hpf-mode = "off";
            input-gain = 0;
            knee = -6;
            lpf-frequency = 20000;
            lpf-mode = "off";
            makeup = 0;
            mode = "Downward";
            output-gain = 0;
            ratio = 4;
            release = 75;
            release-threshold = -40;
            sidechain = {
              lookahead = 0;
              mode = "RMS";
              preamp = 0;
              reactivity = 10;
              source = "Middle";
              stereo-split-source = "Left/Right";
              type = "Feed-forward";
            };
            stereo-split = false;
            threshold = -20;
            wet = 0;
          };
          "deesser#0" = {
            bypass = false;
            detection = "RMS";
            f1-freq = 3000.0;
            f1-level = -6.0;
            f2-freq = 5000.0;
            f2-level = -6.0;
            f2-q = 1.5000000000000004;
            input-gain = 0.0;
            laxity = 15;
            makeup = 0;
            mode = "Wide";
            output-gain = 0;
            ratio = 5;
            sc-listen = false;
            threshold = -20;
          };
          "equalizer#0" = {
            balance = 0;
            bypass = false;
            input-gain = 0;
            left = {
              band0 = {
                frequency = 50;
                gain = 3;
                mode = "RLC (BT)";
                mute = false;
                q = 0.7;
                slope = "x1";
                solo = false;
                type = "Hi-pass";
                width = 4;
              };
              band1 = {
                frequency = 90;
                gain = 3;
                mode = "RLC (MT)";
                mute = false;
                q = 0.7;
                slope = "x1";
                solo = false;
                type = "Lo-shelf";
                width = 4;
              };
              band2 = {
                frequency = 425;
                gain = -2;
                mode = "BWC (MT)";
                mute = false;
                q = 0.9999999999999998;
                slope = "x2";
                solo = false;
                type = "Bell";
                width = 4;
              };
              band3 = {
                frequency = 3500;
                gain = 3;
                mode = "BWC (BT)";
                mute = false;
                q = 0.7;
                slope = "x2";
                solo = false;
                type = "Bell";
                width = 4;
              };
              band4 = {
                frequency = 9000;
                gain = 2;
                mode = "LRX (MT)";
                mute = false;
                q = 0.7;
                slope = "x1";
                solo = false;
                type = "Hi-shelf";
                width = 4;
              };
            };
            mode = "IIR";
            num-bands = 5;
            output-gain = 0;
            pitch-left = 0;
            pitch-right = 0;
            right = {
              band0 = {
                frequency = 50;
                gain = 3;
                mode = "RLC (BT)";
                mute = false;
                q = 0.7;
                slope = "x1";
                solo = false;
                type = "Hi-pass";
                width = 4;
              };
              band1 = {
                frequency = 90;
                gain = 3;
                mode = "RLC (MT)";
                mute = false;
                q = 0.9999999999999998;
                slope = "x1";
                solo = false;
                type = "Lo-shelf";
                width = 4;
              };
              band2 = {
                frequency = 425;
                gain = -2;
                mode = "BWC (MT)";
                mute = false;
                q = 0.7;
                slope = "x2";
                solo = false;
                type = "Bell";
                width = 4;
              };
              band3 = {
                frequency = 3500;
                gain = 3;
                mode = "BWC (BT)";
                mute = false;
                q = 0.7;
                slope = "x2";
                solo = false;
                type = "Bell";
                width = 4;
              };
              band4 = {
                frequency = 9000;
                gain = 2;
                mode = "LRX (MT)";
                mute = false;
                q = 0.7;
                slope = "x1";
                solo = false;
                type = "Hi-shelf";
                width = 4;
              };
            };
            split-channels = false;
          };
          "gate#0" = {
            attack = 1;
            bypass = false;
            curve-threshold = -50;
            curve-zone = -2;
            dry = -100;
            hpf-frequency = 10;
            hpf-mode = "off";
            hysteresis = true;
            hysteresis-threshold = -3;
            hysteresis-zone = -1;
            input-gain = 0;
            lpf-frequency = 20000;
            lpf-mode = "off";
            makeup = 1;
            output-gain = 0;
            reduction = -15;
            release = 200;
            sidechain = {
              input = "Internal";
              lookahead = 0;
              mode = "RMS";
              preamp = 0;
              reactivity = 10;
              source = "Middle";
              stereo-split-source = "Left/Right";
            };
            stereo-split = false;
            wet = -1;
          };
          "limiter#0" = {
            alr = false;
            alr-attack = 5;
            alr-knee = 0;
            alr-release = 50;
            attack = 1;
            bypass = false;
            dithering = "16bit";
            external-sidechain = false;
            gain-boost = true;
            input-gain = 0;
            lookahead = 5;
            mode = "Herm Wide";
            output-gain = 0;
            oversampling = "Half x2(2L)";
            release = 5;
            sidechain-preamp = 0;
            stereo-link = 100;
            threshold = -1;
          };
          plugins_order = [
            "rnnoise#0"
            "gate#0"
            "deesser#0"
            "compressor#0"
            "equalizer#0"
            "speex#0"
            "limiter#0"
          ];
          "rnnoise#0" = {
            bypass = false;
            enable-vad = false;
            input-gain = 0;
            model-path = "";
            output-gain = 0;
            release = 20;
            vad-thres = 50;
            wet = 0;
          };
          "speex#0" = {
            bypass = false;
            enable-agc = false;
            enable-denoise = false;
            enable-dereverb = false;
            input-gain = 0;
            noise-suppression = -70;
            output-gain = 0;
            vad = {
              enable = true;
              probability-continue = 90;
              probability-start = 95;
            };
          };
        };
      };
    };
  };
}
