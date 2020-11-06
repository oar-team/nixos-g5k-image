{ config, lib, pkgs, ... }:
{  
  environment.systemPackages = with pkgs; [ vim exa bat];
  
  services.sshd.enable = true;
  
  networking.firewall.enable = false;
  
  users.users.root.password = "nixos";
  services.openssh.permitRootLogin = lib.mkDefault "yes";
  services.mingetty.autologinUser = lib.mkDefault "root";
}
