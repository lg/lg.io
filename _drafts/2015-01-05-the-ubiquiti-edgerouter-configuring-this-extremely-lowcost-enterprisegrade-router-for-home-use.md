---
layout: post
title: "The Ubiquiti EdgeRouter: Configuring this extremely low-cost, enterprise-grade router for home use"
categories: []
tags: []
published: True
---

I've gotten a new, inexplicable, love for [Ubiquiti](http://unbt.com). They fit in my favorite category of companies: they make high quality products that cost nothing compared to the old-boys-club equivalents and that look spectacular. I'm actually quite surprised how they're able to do all the products that they do, but I couldn't support them more.

After finding out about them from [MonkeyBrains](https://twitter.com/monkeybrainsnet), I looked through their product line to be quite surprised at the feature sets yet still low cost. Being a huge fan of networking equipment, I decided to buy their cheapest router, the EdgeMAX EdgeRouter Lite. A 3 port, gigabit-capable router, that can really only be configured by commandline.

For this article, we're going to configure it for home-use.

![EdgeRouter Lite](/assets/erlite.png)

**A Challenger Appears!**

### Getting going

First off, like I mentioned, this thing is only _really_ configurable via commandline. It uses a forked version of the opensourced edition of [Vyatta](https://en.wikipedia.org/wiki/Vyatta) 6.3 (now maintained as [VyOS](http://vyos.net/wiki/Main_Page) post their acquisition by Brocade). So to learn about how this thing works, you'll need to read pages upon pages of documentation from the [old Vyatta docs](http://ftp.het.net/iso/vyatta/vc6.3/docs/) keeping in mind the Ubnt has modified a bunch of stuff too. So a lot of help is available on their [community page](http://community.ubnt.com/t5/EdgeMAX/bd-p/EdgeMAX). Oddly enough, they don't document anything they do, so you're stuck reading release notes and harassing the employees that troll the forums.

A great way to get started is to read the [EdgeOS CLI Primer](http://community.ubnt.com/t5/EdgeMAX/EdgeOS-CLI-Primer-part-1/m-p/285388#U285388) and the [Basic System](http://ftp.het.net/iso/vyatta/vc6.3/docs/Vyatta_BasicSystem_R6.3_v01.pdf) [PDF] docs.

When you buy and receive yours, plug into Port 0, assign yourself a Static IP, and use the https Web UI to upload the latest version of their firmware (which is 1.6 as of this writing). This will get you up to speed with all the latest Web UI (which is still heavily limited). Use the Wizards on the 1.6 Web UI to get an initial configuration that can actually route something. Then lets start customizing it.

Log in via SSH with `ubnt`/`ubnt`.

### Port forwarding

As of 1.4, Ubiquiti added the non-Vayatta config of `port-forward`. Whereas in the past you'd need to manually create NAT mappings and firewall rules (as per [here](http://wiki.ubnt.com/EdgeMAX_PortForward)), the EdgeRouter now has made it significantly easier with even automatic firewall rules.

    port-forward {
      auto-firewall enable
      hairpin-nat enable
      lan-interface eth1
      rule 1 {
        description "synology webui http"
        forward-to {
          address 192.168.0.10
          port 5000
        }
        original-port 9876
        protocol tcp
      }
      rule 2 {
        description "router ssh"
        forward-to {
          address 192.168.0.1
          port 22
        }
        original-port 8792
        protocol tcp
      }
      wan-interface eth0
    }

As a reminder, to actually set settings on the router, switch to configuration mode, `configure`. Then use commands like `set port-forward auto-firewall enable` or `set port-forward rule 1 forward-to address 192.168.0.10` to actually set the settings.

In this example, we have the WAN on eth0 and LAN on eth1. We enable `auto-firewall` which really makes our life easy to not deal with firewall rules for LAN targets (more on that later). `hairpin-nat` makes it so that if an app on your LAN uses your public IP address as the remote host, the router will turn the packet right around without going out to your ISP.

There are two rules, `rule 1` which we have exposed the [Synology DiskStation Manager WebUI](https://www.synology.com/en-us/dsm/5.1/features) (great device btw) to the outside. Connections from TCP port 9876 on our WAN interface will be forwarded to 192.168.0.10 on port 5000. Firewall rules will automatically be created to allow incoming connections to the LAN for this port because of the `auto-firewall` instruction.

`rule 2` allows me to access the router's SSH for config from the outside. Same deal as `rule 1` except unfortunately when routing to the router itself, it appeared as though I needed to create the firewall rule manually. 

    firewall {
      name WAN_LOCAL {
        [...]
        rule 4 {
          action accept
          description "port forwarding manual - router ssh"
          destination {
              address 192.168.0.1
              port 22
          }
          log disable
          protocol tcp
        }
        [...]
      }
    }

Reminder that `WAN_LOCAL` is for packets between the outside and destined for *the router* versus `WAN_IN` which is for packets destined for *the LAN*. Normally home-grade routers don't really distinguish these two apart, but for advanced configuration's sake, this is the case here.

This firewall rule basically allows traffic that should be going to 192.168.0.1, the router's internal IP, to access port 22, the internal port for ssh.

### DHCP static mappings

It's always useful to have a couple machines on the network use DHCP, yet always get the same IP addresses assigned to them. Fortunately doing so is quite easy.

    service {
      dhcp-server {
        [...]
        hostfile-update enable
        shared-network-name LAN {
          [...]
          authoritative enable
          subnet 192.168.0.0/24 {
            static-mapping driveway-camera {
                ip-address 192.168.0.20
                mac-address 00:02:d1:12:d3:e9
            }
            static-mapping synology {
                ip-address 192.168.0.10
                mac-address 00:11:32:41:1e:25
            }
          }
        }
      }
    }

It's mostly obvious what this does though the `hostfile-update enable` section is useful so you can access these mappings by name from the DNS server and other routing rules.

### Enable UPnP

There are security problems with UPnP in general, but because of stuff like BitTorrent, World of Warcraft and many other applications, we need it to be easy to open ports for faster peer-to-peer. 

    service {
      upnp2 {
        listen-on eth1
        wan eth0
      }
    }

We're using the `upnp2` to do this. It's the more up to date UPnP application in comparison to the legacy `upnp` that was available on the Vayatta system. `upnp2` is more compatible with the latest applications too.

### Dynamic DNS Updates

It's always useful to update a dynamic dns provider like DynDNS whenever your public IP changes. I personally own [lg.io](http://lg.io) and I want it to be updated. Unfortunately my hosting provider [iwantmyname](https://iwantmyname.com/) is not supported by the [built in dynamic-dns service](https://community.ubnt.com/t5/EdgeMAX-CLI-Basics-Knowledge/EdgeMAX-Dynamic-DNS-commands/ta-p/473905).

Therefore, I created a task that runs nightly to update the dns on my domain.

    task-scheduler {
      task iwantmyname_update {
          executable {
              path /config/user-data/iwantmyname_update.sh
          }
          interval 1d
      }
    }

Reminder that everything in the `/config` directory is saved across firmware upgrades, etc. So it's safe to put scripts and such in there. In this case the `/config/user-data/iwantmyname_update.sh` contains the following as per [iwantmyname's API](http://blog.iwantmyname.com/2012/03/ddns-dynamic-dns-service-on-your-own-domain.html): 

    #!/bin/sh

    # This is run by task-scheduler

    /usr/bin/curl -u "trivex@gmail.com:MYAWESOMEPASSWORD" "https://iwantmyname.com/basicauth/ddns?hostname=xxx.lg.io"

### Selective VPN routing (Policy-based Routing)

So here's the fun part. The great part of an enterprise router is that it can do some pretty crazy things. What I like it for? Well, my parents want to use services like Netflix, Hulu, etc. But because of all sorts of anti-consumer business tactics on the publishers' parts, these services don't have a full catalogue available in Canada.

Using the EdgeRouter, you can do things like route all traffic from one LAN client (like an Apple TV) to always go through a VPN (like an OpenVPN). Fancy! Lets do it.

    interfaces {
      [...]
      openvpn vtun0 {
        config-file /config/auth/pia/USEast.ovpn
      }
    }

I use [Private Internet Access](https://www.privateinternetaccess.com/). They're kinda sketch in their branding, but they have a great product and have access to OpenVPN too, which I wanted. What sucks though -- OpenVPN is not hardware accelerated on the EdgeRouter. This sucks for throughput. We'll only be able to do about 7mbit/s. Fortunately that's sufficient for my parents' needs though. The EdgeRouter does support hardware accelerated IPSec, but there aren't any VPN providers out there that I know of that allow you to tunnel IPSec through them.

Here's the config I use with PIA (in `/config/auth/pia/USEast.ovpn`):

    client
    dev vtun
    proto udp
    remote us-east.privateinternetaccess.com 1194
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    ca /config/auth/pia/ca.crt
    tls-client
    remote-cert-tls server
    auth-user-pass /config/auth/pia/pw.txt
    comp-lzo
    verb 1
    reneg-sec 0
    crl-verify /config/auth/pia/crl.pem
    route-nopull

The big deal is the `route-nopull` which makes it so that PIA doesnt set the default gateway and route *all* your traffic to the VPN. Normally you'd use a VPN provider on your computer to route everything, but in this case we only want selective routing. Which we'll set up next.