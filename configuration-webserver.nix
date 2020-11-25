{ pkgs, ... }:
{
  services.nginx = {
    enable = true;
    # a minimal site with one page
    virtualHosts.default = {
      root = pkgs.runCommand "testdir" {} ''
        mkdir "$out"
        echo hello world > "$out/index.html"
      '';
    };
  };
}
