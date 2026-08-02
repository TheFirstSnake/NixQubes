# This configuration.nix is a template and an example.

{ config, pkgs, modulesPath, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (modulesPath + "/profiles/hardened.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  # Find the pci id of device with lspci -nn
  # The kernel parameter will be different for intel:
  # intel_iommu=on
  # Look at the changes in hardware-configuration.nix
  # Also, probably add vmd as a kernel module in intel
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;
  boot.kernelParams = [ "amd_iommu=on" "iommu=pt" "vfio-pci.ids=10ec:8125" ];
  boot.initrd.kernelModules = ["vfio_pci" "vfio" "vfio_iommu_type1" ];
  services.udev.extraRules = ''
    SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm", MODE="0660"
   '';

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = false;
  systemd.network.enable = true;
  networking.useNetworkd = true;  # NetworkManager hasn't been tried yet.
  systemd.network.networks."10-ignore-enp11s0" = {
    matchConfig.Name = "enp11s0"; # The current interface name here.
    linkConfig.Unmanaged = "yes";
  };
  systemd.network.networks."10-host-lan" = {
    matchConfig.Name = "tap-sysnet";
    networkConfig = {
      Address = "10.42.42.1/24";
      Gateway = "10.42.42.2";
    };
  };
  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."apophis" = { # Don't mind my name.
    isNormalUser = true;
    description = "The First Snake";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "libvirtd" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  waybar tmux mpv
  wofi xhost dig thunderbird htop qimgv 
  alacritty mako wl-clipboard clipman slurp grim wf-recorder
  firefox p7zip net-tools busybox
  wget chromium toybox
  git pwvucontrol
  easyeffects autotiling
  gh keepassxc
  vim unzip
  emacs 
  ];

  fonts.packages = with pkgs; [
  noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji liberation_ttf jetbrains-mono
  nerd-fonts.jetbrains-mono nerd-fonts.fira-code
  nerd-fonts.symbols-only
  ];
  
  # Security
  security.apparmor.enable = true;
 
  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
   enable = true;
   alsa.enable = true;
   alsa.support32Bit = false; # This one was compiling locally and gets stuck in the openblas zblas3 test.
   pulse.enable = true;
   jack.enable = true;
};
   
  # Bluetooth
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings.General.Experimental = true;
  hardware.bluetooth.settings.General.MultiProfile = "multiple";
  services.blueman.enable = true;  
  
  # List services that you want to enable:

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [ thunar-volman ];
  programs.dconf.enable = true;

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall.enable = false;

  networking.nftables.enable = true;
  
  # I tried it with nftables. Your own rules would work better because this firewall is very weak.
  networking.nftables.ruleset = ''
table inet filter {
	set virt_interfaces {
        type ifname;
	flags interval;
        elements = { "docker0*", "br-*", "lxcbr0*", "virbr*", "podman*", "cni*", "flannel*", "calico*", "waydroid*" }
        }

	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept;
		iifname @virt_interfaces udp dport 53 accept;
		iifname @virt_interfaces tcp dport 53 accept;
		iifname @virt_interfaces tcp dport 8080 accept;
		iif "lo" accept;
		ip protocol icmp accept;
		ip6 nexthdr ipv6-icmp accept;
		udp sport 67 udp dport 68 accept;
		udp sport 68 udp dport 67 accept;
		udp dport 53 accept;
		tcp dport 53 accept;
		tcp dport { 80, 443 } accept;
		tcp dport 22 ct state new accept;
		ct state invalid drop;
		log prefix "NFT DROP IN: " flags all counter drop;
	}

	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related accept;
		ct state invalid drop;
		iifname @virt_interfaces oifname @virt_interfaces accept;
		iifname @virt_interfaces oifname != @virt_interfaces accept;
		iifname != @virt_interfaces oifname @virt_interfaces accept;
		iifname "tap-sysnet" oifname @virt_interfaces tcp dport 443 accept;
		log prefix "NFT DROP FWD: " flags all counter drop;
	}

	chain output {
		type filter hook output priority filter; policy accept;
	}
}

table ip nat {
    chain postrouting {
	type nat hook postrouting priority srcnat;
	ip saddr { 10.42.42.0/24, 172.16.0.0/12, 192.168.0.0/16 } oifname "tap-sysnet" masquerade;
    }
}
'';

  networking.nameservers = [ "10.42.42.2" ]; # Subject to your change

  system.stateVersion = "26.05"; # Nix Version here

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # This is a peronalized part here. You should change or delete it, depending on your fiesystem.  
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0771 microvm kvm - -"
    "h /var/lib/libvirt/images - - - - +C"
   ];

  programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "sudo" ];
  };

  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  programs.starship = {
    enable = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  }; 

  programs.xwayland.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users."apophis" = import ./home.nix;

}

