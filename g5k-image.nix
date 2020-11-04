{ config, lib, pkgs, modulesPath, ... }:
{

  imports =
    
    [
     # Profiles of this basic installation.
     <nixpkgs/nixos/modules/profiles/all-hardware.nix>
     <nixpkgs/nixos/modules/profiles/base.nix>
     <nixpkgs/nixos/modules/profiles/installation-device.nix>
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda3";
  
  boot.initrd.availableKernelModules = [ "ahci" "ehci_pci" "megaraid_sas" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  
  fileSystems."/" = {
    device = "/dev/disk/by-label/System";
    autoResize = true;
    fsType = "ext4";
  };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 32;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  
  system.build.g5k-image = import "${toString modulesPath}/../lib/make-system-tarball.nix" {
    stdenv = pkgs.stdenv;
    closureInfo = pkgs.closureInfo;
    pixz = pkgs.pixz;
    storeContents = [
      { object = config.system.build.toplevel; symlink = "/run/current-system"; }
    ];

    contents =
      [ { source = config.system.build.initialRamdisk + "/" + config.system.boot.loader.initrdFile;
      target = "/boot/" + config.system.boot.loader.initrdFile;
    }
      #{ source = versionFile;
      #  target = "/nixos-version.txt";
      #}
    ];

  };


  boot.postBootCommands =
  ''
    # After booting, register the contents of the Nix store on the
    # CD in the Nix database in the tmpfs.
    if [ -f /nix-path-registration ]; then
    ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
    rm /nix-path-registration
    fi
    
    # nixos-rebuild also requires a "system" profile and an
    # /etc/NIXOS tag.
    touch /etc/NIXOS
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
  '';





  
  formatAttr = "g5k-image";
  filename = "*.img";
}
