# The most important template
# vms/sys-net.nix
{ pkgs, ... }: {
  microvm.vms."sys-net" = {
    autostart = true;
    config = {
      system.stateVersion = "26.05";
      microvm.hypervisor = "qemu";
      microvm.mem = 1024;
      microvm.volumes = [{
        mountPoint = "/var";
        image = "/var/lib/libvirt/images/sys-net-var.img";
        size = 2048;
      }];
      microvm.interfaces = [{
        type = "tap";
        id = "tap-sysnet";  # The id of your interface
        mac = "02:00:00:00:00:02"; # Your custom MAC address here
      }];
    microvm.devices = [{
    bus = "pci";
    path = "0000:0b:00.0"; # Find using lspci -nn
    }];
    boot.initrd.availableKernelModules = [ "e1000e" "igb" "r8169" "ixgbe" ]; # Better to have them all
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    networking.useNetworkd = true;
    systemd.network.enable = true;
    services.udev.enable = true;
    systemd.network.networks."10-lan" = {
      matchConfig = {
        MACAddress = "02:00:00:00:00:02"; # Change to your one.
      };
      networkConfig = { 
        Address = "10.42.42.2/24"; # You might want to change this
        IPv4Forwarding = true;
     };
    };
    systemd.network.networks."20-wan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        DHCP = "yes";
        IPv4Forwarding = true;
     };
    };
    systemd.network.links."10-lan0" = {
      matchConfig.MACAddress = "02:00:00:00:00:02"; # The whole arrangement of the interfaces is very important.
      linkConfig.Name = "lan0";
      };
   services.openssh.enable = true; # only way to control this
   services.openssh.settings.PermitRootLogin = "yes";
   users.users.root.password = "nixos";  # This is very dumb, use ssh keys
   environment.systemPackages = with pkgs; [
     cloudflare-warp
     curl pciutils
     wireguard-tools
   ];

    services.resolved.enable = true;
    services.cloudflare-warp.enable = true;

    services.unbound = {  # local dns cache.
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" "::1" "10.42.42.2"];
          access-control = [ "127.0.0.0/8 allow" "10.42.42.0/24 allow" ];
          qname-minimisation = true;
          harden-dnssec-stripped = true;
          harden-glue = true;
          harden-algo-downgrade = true;
          prefetch = true;
          num-threads = 1;
          msg-cache-size = "100m";
          rrset-cache-size = "200m";
          tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
        };
        forward-zone = [{
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
           ];
        }];
      };
    };

    # Change the rules and guard the ssh
    networking.firewall.enable = false;
    networking.nftables.enable = true;
    networking.nftables.ruleset = ''
    table inet filter {
      chain input {
        type filter hook input priority filter; policy drop;
        ct state invalid drop;
        ct state established,related accept;
        iif "lo" accept;
        ip saddr 10.42.42.0/24 tcp dport 22 accept;
        ip saddr != 10.42.42.0/24 udp sport 67 udp dport 68 accept;
        ip saddr 10.42.42.0/24 udp dport 53 accept;
        ip saddr 10.42.42.0/24 tcp dport 53 accept;
        ip6 nexthdr ipv6-icmp accept;
        ip protocol icmp accept;
        log prefix "NFT DROP IN: " flags all counter drop;
      }
      chain forward {
        type filter hook forward priority filter; policy drop;
        ct state established,related accept;
        ct state invalid drop;
        ip saddr 10.42.42.0/24 accept;
        log prefix "NFT DROP FWD: " flags all counter drop;
      }
    }
    table ip nat {
      chain postrouting {
        type nat hook postrouting priority srcnat;
        ip saddr 10.42.42.0/24 ip daddr != 10.42.42.0/24 masquerade;
        oifname != "lan0" masquerade;
        oifname "CloudflareWARP" masquerade;
      }
    }
  '';
  };
 };
}
