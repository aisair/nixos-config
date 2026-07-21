# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Intel QSV
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime-legacy1
    ];
  };
    
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use LTS kernel (TPM doesn't work on latest kernel)
  boot.kernelPackages = pkgs.linuxPackages;

  # Full-disk encryption
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices = {
    crypt-lvm = {
      device = "/dev/disk/by-uuid/986ab49c-9a9e-4756-af36-b2e59dc3f91d";
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
    crypt-data = {
      device = "/dev/disk/by-uuid/74f6c796-b7a0-4abf-8b55-c748a60ffe30";
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
  };

  environment.variables = {
    SUDO_EDITOR = "hx";
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # Define your hostname.
  networking.hostName = "curren";

  age.secrets = {
    wg-public-secret-key = {
      file = ./secrets/wg-public-secret-key.age;
      mode = "g=r";
      group = "systemd-network";
    };
    wg-public-preshared-key = {
      file = ./secrets/wg-public-preshared-key.age;
      mode = "g=r";
      group = "systemd-network";
    };
  };

  # Use systemd-networkd for network connections
  systemd.network = {
    enable = true;
    links = {
      "10-usb-ether-adapter" = {
        matchConfig = {
          PermanentMACAddress = "9c:69:d3:77:a5:7b";
        };
        linkConfig = {
          Name = "usb-ethernet";
        };
      };
    };
    netdevs = {
      "30-wg-public" = { # Meridiana
        netdevConfig = {
          Name = "wg-public";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-public-secret-key.path;
        };
        wireguardPeers = [
          {
            PublicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
            PresharedKeyFile = config.age.secrets.wg-public-preshared-key.path;
            AllowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            Endpoint = "68.235.35.253:1637";
            PersistentKeepalive = 15;
          }
        ];
      };
    };
    networks = {
      "10-ether-adapter" = {
        matchConfig = {
          Name = "usb-ethernet";
        };
        networkConfig = {
          DHCP = "yes";
          MulticastDNS = true;
        };
        dhcpV4Config = {
          UseHostname = false;
        };
        dhcpV6Config = {
          UseHostname = false;
        };
      };
      # "20-wireless" = {
      #   matchConfig = {
      #     Name = "wlan0";
      #   };
      #   networkConfig = {
      #     DHCP = "yes";
      #     MulticastDNS = true;
      #   };
      #   dhcpV4Config = {
      #     UseHostname = false;
      #   };
      #   dhcpV6Config = {
      #     UseHostname = false;
      #   };
      # };
      "30-wg-public" = {
        matchConfig = {
          Name = "wg-public";
        };
        dns = [
          "10.128.0.1"
          "fd7d:76ee:e68f:a993::1"
        ];
        addresses = [
          {
            Address = "10.184.2.184/32";
          }
          {
            Address = "fd7d:76ee:e68f:a993:473e:f384:b46b:1565/128";
          }
        ];
      };
    };
  };
  networking.wireless.iwd.enable = true;
  networking.useDHCP = false;

  # Use systemd-resolved for DNS resolution
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net";
      MulticastDNS = true;
      DNSSEC = true;
      DNSOverTLS = true;
    };
  };

  services.wireguard-namespace = {
    enable = true;
    namespaceName = "vpn";
    interfaceName = "wg-public";
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # SSH agent (I think this is primarily for GitHub operations)
  programs.ssh.startAgent = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define data group for data disk mounted at /data
  users.groups = {
    data = {
      members = [
        "aisair"
        "qbittorrent"
        "jellyfin"
      ];
    };
    nfsshare = {};
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aisair = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.fish;
  };

  # Service account for NFS server
  users.users.nfsshare = {
    isSystemUser = true;
    uid = 989;
    group = "nfsshare";
    extraGroups = [ "data" ];
  };

  programs = {
    fish.enable = true;
    mosh.enable = true;
    git.enable = true;
    tmux.enable = true;
    htop.enable = true;
    gnupg.agent.enable = true;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    helix
    ghostty.terminfo
    tealdeer
    zellij
    iperf3
    nixd
    parted
    ffmpeg
    delta
    trashy
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # OpenSSH daemon
  services.openssh = {
    enable = true;
    ports = [ 22964 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";      
    };
  };

  # NFS daemon
  services.nfs = {
    server = {
      enable = true;
      exports = ''
        /srv/nfs 100.64.0.0/10(insecure,ro,fsid=root) fd7a:115c:a1e0::/48(insecure,ro,fsid=root)
        /srv/nfs/data 100.64.0.0/10(insecure,rw,all_squash,anonuid=989,anongid=988) fd7a:115c:a1e0::/48(insecure,rw,all_squash,anonuid=989,anongid=988)
      '';
    };
    settings = {
      nfsd = {
        vers3 = false;
        vers4 = true;
        "vers4.0" = true;
        "vers4.1" = true;
        "vers4.2" = true;
      };
    };
  };
  # Open port 2049 for NFS
  # Open port 5353 for multicast DNS
  networking.firewall.allowedTCPPorts = [ 2049 5353 ];

  # Tailscale daemon
  services.tailscale = {
    enable = true; 
  };

  # Caddy reverse proxy
  age.secrets = {
    caddy-cloudflare-env = {
      file = ./secrets/caddy-cloudflare-env.age;
    };
  };
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
    };
    environmentFile = config.age.secrets.caddy-cloudflare-env.path;
    globalConfig = ''
      acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    '';
    virtualHosts = {
      "qb.machitan.party" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };
      "jf.machitan.party" = {
        extraConfig = ''
          reverse_proxy localhost:8096
        '';
      };
    };
  };

  # qBittorrent daemon
  services.qbittorrent = {
    enable = true;
    extraArgs = [
      "--confirm-legal-notice"
    ];
  };
  systemd.services.qbittorrent = {
    bindsTo = [ "wg-netnamespace@vpn.service" ];
    requires = [ "network-online.target" "wg-netnamespace@vpn.service" ];
    after = [ "network-online.target" "wg-netnamespace@vpn.service" ];
    serviceConfig = {
      NetworkNamespacePath = [ "/var/run/netns/vpn" ];
      BindReadOnlyPaths = [
        "/etc/netns/vpn/resolv.conf:/etc/resolv.conf"
        "/etc/netns/vpn/nsswitch.conf:/etc/nsswitch.conf"
      ];
      TimeoutStopSec = lib.mkForce 90;
    };
  };
  environment.etc."netns/vpn/resolv.conf" = {
    text = ''
      nameserver 10.128.0.1
      nameserver fd7d:76ee:e68f:a993::1
    '';
  };
  environment.etc."netns/vpn/nsswitch.conf" = {
    text = ''
      passwd:    files systemd
      group:     files [success=merge] systemd
      shadow:    files systemd
      sudoers:   files

      hosts:     files dns
      networks:  files

      ethers:    files
      services:  files
      protocols: files
      rpc:       files

      subuid:    files
      subgid:    files
    '';
  };
  systemd.sockets."proxy-to-qbittorrent" = {
    description = "Socket for proxy to qbittorrent in vpn network namespace";
    listenStreams = [
      "8080"
    ];
    wantedBy = [ "sockets.target" ];
  };
  systemd.services."proxy-to-qbittorrent" = {
    description = "Proxy to qbittorrent in network namespace";
    requires = [
      "qbittorrent.service"
      "proxy-to-qbittorrent.socket"
    ];
    after = [
      "qbittorrent.service"
      "proxy-to-qbittorrent.socket"
    ];
    unitConfig = {
      JoinsNamespaceOf = "qbittorrent.service";
    };
    serviceConfig = {
      User = "qbittorrent";
      Group = "qbittorrent";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:8080";
      PrivateNetwork = "yes";
    };
  };

  # Jellyfin server
  services.jellyfin = {
    enable = true;
  };
  systemd.services.jellyfin = {
    environment = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}

