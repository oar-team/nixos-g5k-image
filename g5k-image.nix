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

  # Set and select root system by label (nixos) 
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.e2fsprogs}/bin/e2label
  '';

  boot.initrd.postDeviceCommands = ''
    for o in $(cat /proc/cmdline); do
    case $o in
            root=*)
                set -- $(IFS==; echo $o)
                e2label $2 nixos
                ;;
        esac
    done
  '';
  
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda3";
  
  boot.initrd.availableKernelModules = [ "ahci" "ehci_pci" "megaraid_sas" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
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
    extraCommands = "mkdir -p etc/ssh root tmp var/log";
    storeContents = [
      { object = config.system.build.toplevel; symlink = "/run/current-system"; }
    ];

    contents = [
      { source = config.system.build.initialRamdisk + "/" + config.system.boot.loader.initrdFile;
        target = "/boot/" + config.system.boot.loader.initrdFile;
      }
      { source = config.boot.kernelPackages.kernel + "/" + config.system.boot.loader.kernelFile;
        target = "/boot/" + config.system.boot.loader.kernelFile;
      }
      { source = "${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init";
        target = "/boot/init";
      }
    ];

  };

  system.build.g5k-image-info = pkgs.writeText "g5k-imag-info.json" (builtins.toJSON {
    kernel=config.boot.kernelPackages.kernel + "/" + config.system.boot.loader.kernelFile;
    initrd=config.system.build.initialRamdisk + "/" + config.system.boot.loader.initrdFile;
    init="${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init";
    image = config.system.build.g5k-image;
  });
    
  # system.build.g5k-image-all = pkgs.stdenv.mkDerivation {
  #     name = "g5k-image-all";
  #     dontUnpack = true;
  #     doCheck = false;

  #     installPhase =''
  #       mkdir -p $out
  #       cp ${kexec_qemu_script} $out/bin/kexec-qemu
  #       cp ${kexec_info} $out/kexec-info.json
  #     '';
  #   };

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
  
    #formatAttr = "g5k-image";
    formatAttr = "g5k-image-info";
  filename = "*.img";
}
