{ config, lib, pkgs, modulesPath, ... }:
let
  image_name = if (builtins.getEnv ("KAENV_NAME") != "") then
    builtins.getEnv ("KAENV_NAME")
  else
    "nixos-${pkgs.stdenv.hostPlatform.system}";

  author = if (builtins.getEnv ("AUTHOR") != "") then
    builtins.getEnv ("AUTHOR")
  else
    builtins.getEnv ("USER");

  file_image_baseurl = if (builtins.getEnv ("FILE_IMAGE_BASEURL") != "") then
    builtins.getEnv ("FILE_IMAGE_BASEURL")
  else
    "file:~";

  postinstall = if (builtins.getEnv ("POST_INSTALL") != "") then
    builtins.getEnv ("POST_INSTALL")
  else
    "server:///grid5000/postinstalls/g5k-postinstall.tgz";

  postinstall_args = if (builtins.getEnv ("POST_INSTALL") != "") then
    builtins.getEnv ("POST_INSTALL_ARGS")
  else
    "g5k-postinstall --net none --bootloader no-grub-from-deployed-env";

in {
  imports = [
    # Profiles of this basic installation.
    <nixpkgs/nixos/modules/profiles/all-hardware.nix>
    <nixpkgs/nixos/modules/profiles/base.nix>
    <nixpkgs/nixos/modules/profiles/installation-device.nix>
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  # base configuration
  services.sshd.enable = true;
  networking.firewall.enable = false;
  services.openssh.permitRootLogin = lib.mkDefault "yes";
  services.mingetty.autologinUser = lib.mkDefault "root";

  # Set and select root system by label (nixos) 
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.e2fsprogs}/bin/e2label
  '';

  boot.initrd.postDeviceCommands = ''
    for o in $(cat /proc/cmdline); do
    case $o in
            root=*)
                set -- $(IFS==; echo $o)
                waitDevice $2
                e2label $2 nixos
                ;;
        esac
    done
  '';

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda3";

  boot.initrd.availableKernelModules =
    [ "ahci" "ehci_pci" "megaraid_sas" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 32;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  system.build.g5k-image =
    import "${toString modulesPath}/../lib/make-system-tarball.nix" {
      fileName = image_name;
      stdenv = pkgs.stdenv;
      closureInfo = pkgs.closureInfo;
      pixz = pkgs.pixz;
      extraCommands = "mkdir -p etc/ssh root tmp var/log";
      storeContents = [{
        object = config.system.build.toplevel;
        symlink = "/run/current-system";
      }];

      contents = [
        {
          source = config.system.build.initialRamdisk + "/"
            + config.system.boot.loader.initrdFile;
          target = "/boot/" + config.system.boot.loader.initrdFile;
        }
        {
          source = config.boot.kernelPackages.kernel + "/"
            + config.system.boot.loader.kernelFile;
          target = "/boot/" + config.system.boot.loader.kernelFile;
        }
        {
          source = "${
              builtins.unsafeDiscardStringContext config.system.build.toplevel
            }/init";
          target = "/boot/init";
        }
      ];

    };

  system.build.g5k-image-info = pkgs.writeText "g5k-image-info.json"
    (builtins.toJSON {
      kernel = config.boot.kernelPackages.kernel + "/"
        + config.system.boot.loader.kernelFile;
      initrd = config.system.build.initialRamdisk + "/"
        + config.system.boot.loader.initrdFile;
      init = "${
          builtins.unsafeDiscardStringContext config.system.build.toplevel
        }/init";
      image = "${config.system.build.g5k-image}/tarball/${image_name}.tar.xz";
      kaenv = config.system.build.kadeploy_env_description;
    });

  system.build.g5k-image-all = pkgs.stdenv.mkDerivation {
    name = "g5k-image-all";
    dontUnpack = true;
    doCheck = false;

    installPhase = ''
      mkdir $out
      ln -s ${config.system.build.g5k-image-info} $out/g5k-image-info.json
      ln -s ${config.system.build.kadeploy_env_description} $out/${image_name}.yaml
      ln -s ${config.system.build.g5k-image}/tarball/${image_name}.tar.xz $out/${image_name}.tar.xz
    '';
  };

  boot.postBootCommands = ''
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

  system.build.kadeploy_env_description = pkgs.writeTextFile {
    name = "${image_name}.yaml";
    text = ''
      name: ${image_name}
      version: 1
      description: NixOS 
      author: ${author}
      visibility: shared
      destructive: false
      os: linux
      image:
        file: ${file_image_baseurl}/${image_name}.tar.xz
        kind: tar
        compression: xz
      postinstalls:
      - archive: ${postinstall}
        compression: gzip
        script:  ${postinstall_args}
      boot:
        kernel: /boot/bzImage 
        initrd: /boot/initrd
        kernel_params: init=boot/init console=tty0 console=ttyS0,115200
      filesystem: ext4
      partition_type: 131
      multipart: false
    '';
  };

  networking.hostName = "";
  formatAttr = "g5k-image-all";
  #formatAttr = "g5k-image";
  #formatAttr = "g5k-image-info";
}
