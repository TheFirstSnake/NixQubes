{ config, pkgs, ... }:

{

  xdg.configFile."alacritty/alacritty.toml".source = ./dotfiles/alacritty.toml;  
  wayland.windowManager.sway = {
    enable = true;
    config = null;
    extraConfig = builtins.readFile ./dotfiles/sway/config;
  };

  programs.waybar = {
    enable = true;
    style = builtins.readFile ./dotfiles/waybar/style.css;
  };

  xdg.configFile."waybar/config".source = ./dotfiles/waybar/config;
  
  home.username = "apophis";
  home.homeDirectory = "/home/apophis";

  home.stateVersion = "26.05";
  
  home.packages = with pkgs; [
    waybar wofi mako wl-clipboard clipman slurp grim wf-recorder autotiling
    alacritty firefox emacs nano vim 
    easyeffects
    pwvucontrol tree 
    xhost dig wget unzip gh
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };  

  programs.git = {
    enable = true;
    settings.user.name = "TheFirstSnake";
    settings.user.email = "sg717717717717@gmail.com";
    settings = {
      init.defaultBranch = "main";
     };
  };

  programs.zsh = {
    enable = true; 
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ./dotfiles/.zshrc;
  };  

  programs.starship = {
    enable = true;
  };

  programs.home-manager.enable = true; 

}
