# NixQubes
**This is an attempt to partially implement the security infrastructure of QubesOS in Nix, without the restrictions on gpu access or internet access to dom0. It assumes that your physical infrastructure is secure and the only threat are malicious actors on the internet.**

All the configs here are templates and can be modified for personal use.
This is a hobby project and in its very early stages.
Do not blindly copy and paste the configurations, they will brick your system and will not work without extensive changes.
It is advised to merge it with your existing configuration files.
It has only been tested in a single x86_64 personal computer, and needs further testing.

# Current Implementations
**1. Sys-net VM**:

A nix microvm works as the router for your host (dom0). 
This is achieved by hiding the physical network card from your host, by declaring it to be unmanaged and passing it to the microvm. Some rules have been configured in the nftables with default policy drop for a secure setup. Change accordingly.
