{ pkgs, ... }:
{
  # add vim editor
  environment.systemPackages = with pkgs; [ vim ];

  users.users.root.password = "nixos";
  # note: ssh server is enable  and firewall is disable
}
