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