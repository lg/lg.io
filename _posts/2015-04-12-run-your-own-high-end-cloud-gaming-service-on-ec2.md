---
layout: post
title: Run your own high-end cloud gaming service on EC2
categories: []
tags: []
published: True

---

**How to use EC2 GPU machines + Steam In-Home Streaming + a VPN to play AAA titles on a shitty laptop**

![Live streaming](/assets/ingamestreaming.jpg)

You might have tried a service like the [now defunct OnLive](http://arstechnica.com/gaming/2015/04/onlive-shuts-down-streaming-games-service-sells-patents-to-sony-embargoed-7pm-eastern/). Though personally I've played and beat many AAA games on the service, it unfortunately a) had a very limited selection and b) is now gone. I also have a bunch of games on Steam that I've played using [my eGPU](http://gizmodo.com/a-wonderful-lunatic-turned-a-macbook-air-into-a-badass-967800593). With the new Macbook though, I won't be able to continue my low-end-laptop but high-end gaming extravaganza since there's no Thunderbolt. So why am I not concerned? Steam recently introduced [In-Home Streaming](http://store.steampowered.com/streaming), which basically creates a mini-OnLive in your own home with all the same Steam games I played with my eGPU. But... let's do it over the Internet!

### Cost

Playing games this way is actually quite economical -- especially when comparing to purchasing a full-on gaming rig. Here are the costs you'll need to consider:

- GPU Instance runs about $0.11/hr (on a Spot instance, regularly around $0.70/hr)
- Data transfer will around $0.09/GB, and at a sustained ~10mbit, itll cost you $0.41/hr (4.5GB/hr)

This comes out to around $0.52/hr, not bad, for the cost of a $1000 gaming pc, you get ~1900 hours on much higher-end hardware!

### The catch?

This is all fun and games, but you need to make sure of two things:

1. You are within 20ms to the closest AWS datacenter (test [here](http://www.cloudping.info/)) and has GPU instances
1. You have at least a 10mbit connection and it's unmetered

### Setting it up

1. On AWS, create a new EC2 instance. Use these settings:
  - Base image should be `Microsoft Windows Server 2012 R2 Base` (since Windows still has all the best games)
  <br>![Windows Server 2012 R2](/assets/ec2win2012.png)
  - Use a `g2.2xlarge` instance (to get an NVIDIA GRID K520 graphics card)
  <br>![EC2 GPU class machine](/assets/ec2gpu.png)
  - Use a Spot instance, it's significantly cheaper (1/7th the regular cost) than regular instances
  - For storage, I recommend at least 60GB (so you can install lots of fancy games)
  - Also for storage if you're using spot instances, make sure your primary disk doesn't get deleted on termination
  - For the Security Group, i'd recommend just adding type `All traffic`
  - Finally, for the key pair, create a new one since you'll need one for Windows (to retrieve the password)

1. Once your spot instance is assigned, use Microsoft Remote Desktop to connect to it (get it [here](https://itunes.apple.com/en/app/microsoft-remote-desktop/id715768417?mt=12) on a Mac). The username is `Administrator` and the password you'll need to [retrieve from the EC2 Console](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/IIS4.1GettingPassword.html). Once inside, make sure to install [TightVNC server](http://www.tightvnc.com/download.php) and use Screen Sharing (on a mac) to connect to the server. VNC is necessary so that the server uses the proper video card for rendering.

1. Install the [NVIDIA K520 drivers](http://www.nvidia.com/download/driverResults.aspx/74642/en-us) from the Nvidia website
<br>![NVIDIA K520](/assets/nvidiak520.png)

1. In order to make it actually use the video card, you'll need to completely remove the default driver. Open up Device Manager, and a) disable the `Microsoft Basic Display Adapter`, b) uninstall it and c) delete the driver file `C:\Windows\System32\Drivers\BasicDisplay.sys` (see instructions for how to delete protected drivers [here](http://helpdeskgeek.com/windows-7/windows-7-how-to-delete-files-protected-by-trustedinstaller/)). Reboot and VNC back in.
<br>![Only the NVIDIA GRID K520](/assets/onlyonedevice.png)

1. Start the Windows Audio Service as per the instructions [here](http://www.win2012workstation.com/enable-sound/). Also, since you're on EC2, those machines do not virtualize a sound card. So install [VB-Cable](http://vb-audio.pagesperso-orange.fr/Cable/index.htm) so you can get sound.

1. Install the [Hamachi VPN service](https://secure.logmein.com/products/hamachi/) (it's free). It just makes it very easy to get your computer and the server on the same VPN without port forwarding or other crazy things. Steam In-Home streaming only works on the "local" network, so that's why this is necessary. You might be able to use the built-in VPN server in Windows too, but it's a huge hassle to set up properly.
<br>![VPN all set up](/assets/vpn.png)

1. Install Steam and get yourself on the Beta channel (available in the preferences). Also, start downloading whatever games you'll want to stream. Oh and on your own Steam installation, make sure to turn on Hardware Decoding in the Steam settings, and I also recommend turning on Display Performance Information.
<br>![Steam Settings](/assets/steamsettings.png)

1. Start gamin!
<br>![Live streaming](/assets/ingamestreaming2.jpg)

### Performance

While playing, make sure to hit F6 to see the latency graph. Anything above 50ms will make the delay somewhat noticable, though I've played with delays up to 100ms. It just takes some getting used to and before you know it you won't even know you're streaming your games from a computer far far away.

One other thing you should do is hit F8 while playing (note that sometimes this will cause the client to crash, but the file will still get written). F6 will do a dump of stats in the `C:\Program Files (x86)\Steam\logs\streaming_log.txt` file on the server. Open it up to see detailed latency timings. Here's an example of the interesting lines:

    "AvgPingMS"       "11.066625595092773"

    "AvgCaptureMS"    "4.555628776550293"  
    "AvgConvertMS"    "0.023172963410615921"
    "AvgEncodeMS"     "5.5545558929443359"
    "AvgNetworkMS"    "7.0888233184814453"
    "AvgDecodeMS"     "3.7478375434875488"
    "AvgDisplayMS"    "6.3670969009399414"
    
    "AvgFrameMS"      "27.798770904541016"
    "AvgFPS"          "57.622333526611328"
  
Unfortunately Steam doesnt support pulling the video from the H264 encoder on the GRID's NvFBC (which would reduce AvgEncodeMS a bunch). If you were running a GTX video card locally this is one thing that'd make it faster than using EC2 (in addition to largely decreasing NetworkMS).

See more information about this file in the [Steam In-Home Streaming](https://steamcommunity.com/groups/homestream/discussions/0/540733523404402134/) Steam Group.

### Trouble?

Two quick notes when having trouble.

First, if you have Hamachi running and you can't get your client computer to see the server Steam, usually restarting Steam on the server will get the client to see it again. It's a bit of a pain since you'll need to VNC into the computer to restart things.

Second, if the game freezes, the way to get it out of it's broken state is to Microsoft Remote Desktop in, close things, then go back in via VNC to restore Steam, etc.

### Summary

If you have a) a fast internet connection and b) you're near an AWS datacenter with GPU instances, in my opinion, this is actually quite practical. Not only performance-wise, but it's also quite economical.

Also, RIP OnLive. Loved those guys.

Happy gaming!