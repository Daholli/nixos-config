{
  flake.modules = {
    homeManager.dev =
      { pkgs, ... }:
      {
        programs = {
          gh-dash = {
            enable = true;
            settings = {
              prSections = [
                {
                  title = "My PRs";
                  filters = "is:open author:@me";
                }
                {
                  title = "Needs my review";
                  filters = "is:open review-requested:@me";
                }
                {
                  title = "To review";
                  filters = "repo:NixOS/nixpkgs is:open draft:false status:success";
                }
                {
                  title = "1st contribution";
                  filters = ''repo:NixOS/nixpkgs is:open draft:false label:"12. first-time contribution"'';
                }
                {
                  title = "Involved";
                  filters = "is:open involves:@me -author:@me";
                }
              ];
              defaults = {
                prsLimit = 25;
                issuesLimit = 10;
                view = "prs";
                preview = {
                  open = false;
                  width = 100;
                };
                refetchIntervalMinutes = 10;
              };
              repoPaths = {
                "NixOS/*" = "~/projects/NixOS/*";
                "nix-community/*" = "~/projects/nix-community/*";
                "sodiboo/niri-flake" = "~/projects/niri/niri-flake/";
              };
              theme.ui.table.showSeparator = false;
            };
          };

          gh = {
            enable = true;
            extensions = [
              pkgs.gh-dash
              pkgs.gh-copilot
            ];
          };
        };
      };
  };
}
