---
layout: post
title: GTX 570 eGPU on a 2013 11" Macbook Air
categories: []
tags: []
published: True
---

<iframe width="560" height="315" src="//www.youtube.com/embed/kZZdwkICE3M" frameborder="0" allowfullscreen></iframe>

**Note**: This is a repost of my [TechInferno Forum article](http://forum.techinferno.com/implementation-guides/4271-%5Bguide%5D-2013-macbook-air-gtx570@4gbps-c-tbec2-pe4l-2-1b-win7.html) from July 28th, 2013. Methods have changed and are somewhat easier these days. Make sure to check out that forum for more info.

_**TLDR:** By buying around $250 in commonly available parts, plus a video card, you can make the graphics of your 11" Macbook Air from 5X to 7X faster. Demo video at end of post. Step-by-step, here's how to exactly do it. Warning: not for the faint of heart!_

Hey everyone!

This is my third article here on this forum, though it's the first that the process can be done by anyone with off-the-shelf parts. No more discontinued exotic parts like the [$180 BPlus TH05](http://www.mediafire.com/download/3xg6ie3gja1ijv7/TH05_brief.pdf) are required. All you need is a macbook air, a graphics card, a power supply, Windows 7, and ~$250 to buy some adapters and software online. All these parts are readily available for anyone.

Like usual, I really want to thank [nando4](http://forum.techinferno.com/members/nando4.htm) for his help in doing all this. He's the mastermind behind the technicals, I just like writing articles and making stuff easier for everyone. He's super dedicated and eGPUs wouldn't be anywhere near where they are today if it wasn't for him! Thanks!

So what are we doing? We're going to make a Macbook Air accept an external video card via Thunderbolt! Yes, you might have read in the news that real commercial solutions are just [around](http://www.slashgear.com/lucid-thunderbolt-external-gpu-demoed-for-undeniable-ultrabook-gaming-boost-11246826/) [the](http://www.anandtech.com/show/5352/msis-gus-ii-external-gpu-via-thunderbolt) [corner](http://www.anandtech.com/show/7040/computex-2013-thunderbolt-graphics-from-silverstone). We've been promised by these companies over-and-over again, with youtube videos, hands-on reviews, press releases, etc, but nobody is releasing anything. It's been like this for over a year. Intel even openly admits its bias against GPU usage where it's listed as unsupported in their [Thunderbolt Certification Application](http://cl.ly/0Z3Q432w2I3x). Talking to one of their thunderbolt guys, here's what that "Not Supported" means:

> The “Not supported” means that Intel won’t neither certify your product nor deliver, at the moment, any Technology License for this kind of usage. As you know, this Technology License is required to develop a Thunderbolt device in the market and Certification is a must have to market any Thunderbolt product.

So with the bad news out of the way, the good news is that you can still do it yourself -- just a bit less elegantly. We'll be using the Sonnet Thunderbolt to ExpressCard adapter, together with the BPlus PE4L ExpressCard to PCI-Express adapter. This PE4L adapter also includes a Delayed PCI-Reset jumper, making Windows 7 + Internal LCD rendering possible on the Macbook. Also, it's not that bad. As you'll see by the benchmarks later in the article, yes you're only running at expresscard 5Gbps x1 2.0 PCI bus speed (as opposed to 16X 2.0 on a proper PC and only half of Thunderbolt's 10Gbps), but its WAY WAY better than the internal integrated graphics of the laptop, plus you can still max out tons of games. The full PC bus speed is super rarely used anyways, so it's not like you'll get 1/16th the performance.

As part of this tutorial, we'll be using Windows 7 BIOS (installed the regular Bootcamp way). Things are possible in Windows 8 as well, but the instructions differ, and I've also had troubles getting Internal LCD rendering working on Windows 8. Yeah I'm not a fan of using legacy Windows versions either, but whatever, every game works on both OSes for now anyways. Oh and we're using Windows because games only exist for it, and I can't get the setup to work on OSX (haven't tried too much though).

Alright, lets get started!

### My laptop specs

- Mid-2013 11" Macbook Air
- 1.7 GHz Intel Core i7-4650U (basically the most maxed out 11" mba)
- 8GB 1600 MHz DDR3
- Intel HD Graphics 5000 1024 MB
- 512GB Apple SSD

### Stuff to buy

- [**Sonnet Echo ExpressCard Pro**](http://www.sonnettech.com/product/echoexpresscard34thunderbolt.html). I purchased mine for $134 at [B&H Photo Video](http://www.bhphotovideo.com/c/product/860811-REG/Sonnet_ECHOPRO_E34_Echo_Pro_ExpressCard_34_Thunderbolt.html). This adapter turns 10Gbps Thunderbolt to 5Gbps ExpressCard, which is needed for the PE4L later. It's probably one of the more expensive parts in your setup because of Intel's arbitrage on Thunderbolt-related parts. Note that Sonnet also sells a **faster 10Gbps** Thunderbolt->PCIExpress box (~US$310 Sonnet Echo Express SE) which might seem like a great idea, but that's all sorts of problems with it, including an underpowered power supply, no PCI Delay switch (making it not easily work with Windows) and dismantling it to be able to use full length and double width video cards.

- [**$70 BPlus PE4L V2.1**](http://www.hwtools.net/Adapter/PE4L%20V2.1.html) ExpressCard to PCI-Express adapter. You want the PE4L-EC060A package that includes the SWEX adapter to power on your power supply. If wanting a neater enclosure solution then purchase a [$170 BPlus PE4H V3.2](http://www.hwtools.net/Adapter/PE4H%20V3.2.html) instead, noting that your chosen video card will require the pci-e power connectors on the side of the card rather than the top. If you're curious, BPlus used to offer a [US$180 TH05](http://www.mediafire.com/download/3xg6ie3gja1ijv7/TH05_brief.pdf) (which included the TB cable), which was a direct Thunderbolt to PCI-Express, but Intel shut it down and the entire BPlus Thunderbolt division in Jan 2013 per [TH05 Recall Notice](http://forum.techinferno.com/diy-e-gpu-projects/2680-th05-recall-notice.html#post36363).

- [**A Thunderbolt cable**](http://www.amazon.com/Apple-MD861ZM-Thunderbolt-Cable-VERSION/dp/B00B3Y4FAS). You can get this at any Apple Store or online. I'd recommend getting a 2m cable since you'll probably want to have your GPU not directly beside your laptop.

- **450W power supply** capable of running the video card. [$24AR-shipped Diablotek PH450](http://www.newegg.com/Product/Product.aspx?Item=N82E16817822002) offers 12V/30A (360W) or [Corsair CX430](http://www.newegg.com/Product/Product.aspx?Item=N82E16817139026) offers 12V/32A (384W) of peak power, enough for ALL current video cards. If getting a basic ATX PSU then carefully read the first rail data on it, eg: 12V1:18A means 12*18=216W of peak power. That wouldn't be enough to drive my GTX570 that can [draw up to 298W peak power](http://www.techpowerup.com/reviews/ASUS/GeForce_GTX_570/25.html). Look at your video card's spec sheet to see the peak wattage only it uses (not the suggested value that often includes motherboard + hard drives, etc). Honestly though, I'd recommend going for the 450W or even 500W power supplies available for around $20 at your local money-laundering stolen-stuff electronics store. If you get a power supply that doesn't output enough or doesn't like power spikes, it'll basically make your computer blue screen a lot mid-gaming. Ask me how I know.

- [**$25 DIY eGPU Setup 1.X**](http://forum.techinferno.com/diy-e-gpu-projects/2123-diy-egpu-setup-1-x.html#post27337), developed by nando. Yes, you're paying for software, get over it. Nando did spectacular work to get Windows 7 Bootcamp to be able to properly accept the external videocard without giving an "Error 12" code. You want the latest 1.20 version incorporating new Macbook features that's not advertised on that linked page as yet.

- **A video card**. I have the NVidia GTX 570, which is an awesome balance of great performance and price. You can use basically any video card you want, including AMD ones. Note on AMD cards, internal LCD rendering won't be possible without using something like [Lucidlogix Virtu](http://www.lucidlogix.com/) (not covered in this article). Also, don't go too crazy and order a NVidia Titan. Yes it's a great card, but you won't see the value for money since you are limited to a slower PCI bus. I'd recommend sticking in the 5xx or 6xx series of NVidia GTX cards.

- **2013 11" Macbook Air**. This is the laptop I have, but these instructions should be identical for the 13" Air. Additionally, the only step that will be different for every other kind of Macbook is the contents of the PCI.BAT file later.

- **A USB memory key** that's at least 4GB for Bootcamp to install windows plus it's drivers.

- Other software: **Windows 7 ISO** (from MSDN / MSDNAA / etc). Don't steal software.

### PART A: Generic prep of Windows 7 64-bit

1. On your mac use Boot Camp Assistant to prep a USB key with Windows 7 64-bit

2. Still with Boot Camp Assistant, partition your main drive and start the Windows 7 installation process. I recommend around at least a 60GB partition. Games are big these days. If you just don't have the space, you can do what I do and [turn off Hibernation Mode](http://www.howtogeek.com/howto/7564/how-to-manage-hibernate-mode-in-windows-7/) and the [Virtual Memory Page File](http://windows.microsoft.com/en-US/windows-vista/Change-the-size-of-virtual-memory) to save hard drive space (about 17GB together). Disabling Virtual Memory is kind of a bad idea, but I've never had troubles doing it -- this laptop's 8GB of ram is usually enough for anything.

3. Once partitioning is done, your computer will auto reboot and the Windows 7 installer will start. Install Windows 7.

4. The Windows 7 installer will install the Boot Camp drivers at the end of it.

5. Go to Intel's site and download the latest [Intel HD 5000 drivers](https://downloadcenter.intel.com/SearchResult.aspx?lang=eng&ProductFamily=Graphics&ProductLine=Laptop+graphics+drivers&ProductProduct=4th+Generation+Intel%C2%AE+Core%E2%84%A2+Processors+with+Intel%C2%AE+HD+Graphics+5000&ProdId=3721&LineId=1101&FamilyId=39) for Windows 7 64-bit. It's the same download for the HD 4000 drivers.

6. Launch Windows Update and apply all required/optional patches. Reboot as required. Repeat this step until nothing’s left. This will take a long time, deal with it.

7. There's some clock weirdness when switching between Windows and OSX, so add the key (via regedit) `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\RealTimeIsUniversal` with DWORD value `1`

### PART B: Putting together the eGPU and understanding the problem

1. On the PE4L, set SW1 (on the right) to position 3 (6.9s, though note it's more like 30s). Set SW2 (on the left) to position 2-3 for 2X (even though only 1X is really supported thanks to Intel requiring us to use the Sonnet Expresscard adapter).

2. Plug in the power (the white connector) into the PE4L from your power supply's floppy disk drive connector. There is no need to plug in the Black and Red cable (this is for automatic powersupply control, which doesnt work on the Macbook). Keep the jumper on both pins on the bottom right of the board.

3. Plug in the motherboard connector to the included SWEX adapter. Make sure it is in the ON position (1-2). Also plug in any required 6-pin/8-pin connectors to your GPU. Mine required 2 6-pin plugs.

4. Plug in the PE4L to your video card. It obviously won't cover all the pins of your video card, that's ok. Yes, I know it looks ghetto.

5. Plug the express card end of the PE4L into the Sonnet ExpressCard Pro.

6. Make sure your laptop is shut down.

7. Plug in the thunderbolt cable to the Sonnet and then the laptop. Also, make sure no monitors are plugged into the video card.

8. Turn on the power to the power supply, the GPUs fans should start, then start your laptop. Hold the Option key. Now wait for the red light to turn off on the PE4L. Once it’s off, select Windows.

9. Go to NVIDIA’s site, download and install the latest drivers for your video card. When prompted to reboot, shut down the computer instead.

10. Turn off the eGPU’s power supply.

11. Start the eGPU's power supply again and boot your laptop, waiting for that red light to go off again before selecting your Windows partition. You will always need to do a power cycle of the eGPU when rebooting your computer because of the way the PE4L works.

12. Once Windows has started, open the Device Manager. Select Scan For New Hardware.

13. Notice the GTX 570 (or whatever card you have) is listed with the yellow exclamation mark. If you double click on it you’ll see the dreaded Error 12. This Error 12 means that Windows wasn’t able to allocate a contiguous block of memory for the video card. Yes you probably have 8GB in your laptop, but the PCI Bus doesn’t work that way. We’re going to get rid of that error by reallocating devices in the PCI Bus.

### PART C: Getting rid of Error 12 on this Windows 7 (BIOS) install

1. Go purchase DIY eGPU Setup 1.x (link above) if you haven't done so already. Run the self-extracting exe when booted into Windows to install to `c:\eGPU`.

2. Open an administrator command line and run c:\eGPU\setup-disk-image.bat. This will install everything and add a boot item so you can load the video card. Next we'll configure DIY eGPU Setup to work with the 2013 Macbook Air and Haswell chipset.

3. Mount the virtual disk image by running `e:\eGPU\eGPU-Setup-mount.bat` in Administrator mode. This will mount a V: drive.

4. In notepad, create the file `V:\config\pci.bat` and paste the following into it. Note that this is the file that changes depending on your Macbook type. If you dont have a 2013 Macbook Air, a couple addresses might change. Post in this thread and hopefully someone will post your config. 

        :: TB TH05 uses 9:0.0 bridge, Sonnet/OWC uses 9:3.0. That 9:3.0 line may need 
        :: to be altered depending on what TB enclosure/adapter you use.
        ::
        :: Disable CMD, set PCIe config space
        @echo -s 0:1c.4 COMMAND=0 1d.b=50 22.w=BEB0 26.w=D3F1 > setpci.arg
        @echo -s 5:00.0 COMMAND=0 1d.b=41 20.w=B0B0 22.w=BB00 24.w=C001 26.w=D1F1 >> setpci.arg
        @echo -s 6:03.0 COMMAND=0 1d.b=31 20.w=B200 22.w=b700 24.w=c001 26.w=CDF1 >> setpci.arg
        @echo -s 6:04.0 COMMAND=0 1c.b=41 1d.b=41   20.w=BAC0 22.w=BAF0 24.w=D1C1 26.w=D1F1 >> setpci.arg
        @echo -s 7:00.0 COMMAND=0 3C.b=0 >> setpci.arg
        @echo -s 8:00.0 COMMAND=0 1c.w=2121 20.l=B300B200 24.l=C9F1C001 28.l=0 30.w=0 3c.b=10 >> setpci.arg
        @echo -s 9:03.0 COMMAND=0 1c.w=2121 20.l=B300B200 24.l=C9F1C001 28.l=0 30.w=0 3c.b=10 >> setpci.arg

        :: NVidia eGPU
        @echo -s a:00.0 COMMAND=0 10.l=b2000000 14.l=c0000000 1c.l=c8000000 24.l=00002F81 3c.b=10 3C.b=10 50.b=1 88.w=140 >> setpci.arg
        @echo -s a:00.1 COMMAND=0 10.l=B30FC000 3c.b=10 >> setpci.arg

        :: Re-enable CMD
        @echo -s 0:1c.4 COMMAND=7 -s 5:0.0 COMMAND=7 -s 6:3.0 COMMAND=7 -s 6:4.0 COMMAND=7 >> setpci.arg
        @echo -s 7:00.0 COMMAND=6 -s 8:0.0 COMMAND=7 -s 9:3.0 COMMAND=7 >> setpci.arg
        @echo -s a:00.0 COMMAND=6 -s a:0.1 COMMAND=6 >> setpci.arg
        setpci @setpci.arg          

5. In notepad, edit the file `V:\config\startup.bat` and paste the following into it:

        call speedup lbacache
        call vidwait 60
        call vidinit -d %eGPU%
        call pci.bat
        call chainload mbr

6. Turn off your MacBook, power cycle the eGPU from the power supply and make sure the thunderbolt cable is still plugged into the MacBook. Make sure no display is plugged into the card.

7. Turn your MacBook on while holding Option. There's no need to wait for the red light to turn off now before proceeding. Select the windows partition.

8. Windows will boot into a menu allowing you to select between Windows and eGPU setup. Select eGPU setup.

9. Once you get to the Blue first menu, press enter for Option 1. This will prep the PCI Bus. Note it might take a few seconds for the eGPU to be detected (basically until the red light goes off)

10. Once that exits, you'll be back at that same boot menu. This time select Windows 7 and wait for it to boot.

11. Open up the Device Manager and you should see the GTX 570 again, except ... without the yellow exclamation mark! Horray! You fixed Error 12! This is basically whats been preventing people for a while from getting eGPUs working on their laptops.

12. Double click on the NVidia icon in the system tray. On the left side click on “Adjust image settings with preview”.

13. I know it’s shocking, but if you see a spinning NVidia logo, your internal LCD screen is being rendered by your external GPU! If you don’t believe me, launch your favorite game and notice how there’s no way the Intel HD 5000 could render it so well. I recommend you now install your fav benchmarking software, GPU-Z, FRAPS, Steam, etc to take advantage of your laptop’s new abilities.

14. You win!

### Install Notes

- Again, for AMD cards to render on the Internal LCD, you’ll need to use Virtu. See [Lucidlogix Virtu : internal LCD mode for AMD eGPUs](http://forum.techinferno.com/diy-e-gpu-projects/2967-lucidlogix-virtu-internal-lcd-mode-amd-egpus.html#post41056) for instructions on how to get this to work.

- When doing Internal LCD mode (which you’re doing when you have no monitor plugged into the video card), PhysX might not be on. Open the NVidia control panel and switch it from CPU to Auto. When doing benchmarks, keep it on CPU though.

- _Dont forget that every time you reboot, you must power cycle the eGPU!_

- If someone knows how to get the eGPU to restart with a reboot of the computer, please let me know. Simply connecting the black and red cable isn't enough on the MBP from my observations. I tried the switch in both positions and both polarities.

### Benchmarking

Cutting to the chase, benchmarks are below. It's insanely fast because the MBA LCD is 1366x768, it's a 15W i7-UM Haswell CPU that is on par performance wise to a high end 35W Sandy Bridge i5 CPU, plus a crazy video card. Woo! :D

#### External Monitor

- 3dmark06: [19921](http://www.3dmark.com/3dm06/17390266)
- vantage: [P15876](http://www.3dmark.com/3dmv/4813914) (gpu=19574)
- 3dmark11: [P4900](http://www.3dmark.com/3dm11/7199083) (gpu=5210)
- 3dmark: Ice Storm: 87663, Cloud Gate: 10128, Fire Strike: 3413 [see results](http://www.3dmark.com/3dm/1258957)

#### Internal Monitor

- 3dmark06: [17645](http://www.3dmark.com/3dm06/17390231)
- vantage: [P15030](http://www.3dmark.com/3dmv/4813893) (gpu=18270)
- 3dmark11: [P4732](http://www.3dmark.com/3dm11/7198964) (gpu=5110)
- 3dmark: Ice Storm: 23839, Cloud Gate: 8943, Fire Strike: 3264 [see results](http://www.3dmark.com/3dm/1258793)

![Benchmarks Table](/assets/benchmarks.png)

- All numbers above are in frames per second done using FRAPS and recording 1 minute of actual gameplay

- All games were run at 1366x768. Internal and external monitor were set to this. VSync off everywhere. The Macbook Air 11" has this resolution on the LCD. Sorry that this kinda makes the numbers seem high for real-world-with-a-monitor gaming.

- "Internal" refers to numbers when rending in internal LCD mode. "External" is when I had an external monitor hooked up

- "Min settings" means that I set every setting to the lowest possible value. This should make the game run as fast as possible (but look ugly). "Max settings" is the opposite. If the game had the option for presets of "Very Low" and "Ultra", etc, I just selected those and didnt go into advanced modes (except to turn off VSync).

- Bioshock Infinite Internal LCD numbers arent ready yet.

### Internal LCD Rendering vs External

A decision you'll need to make is if you want to plug a monitor into your video card or just use your laptop's monitor. Each has it's own pros and cons. You'll get faster performance with an external monitor, but you'll lose the convenience of not needing a giant monitor. This becomes relevant as people make better eGPU cases where your eGPU will be portable. Why bring a monitor to your friend's place when your laptop already has one?

It's actually kind of cool that you even get this choice. The way it works is by the NVidia Optimus drivers taking the video frame memory from the video card, piping it back over the Thunderbolt bridge to the Intel HD 5000 memory and overwriting Intel's memory so that you see the eGPU's output on the Intel LCD. Cool! If you're curious, this is the exact tech that's used when laptops have an NVidia internal discreet graphics chip.

### Conclusion

It has become very clear that gaming is not only high-performance, but super practical on an 11" Macbook Air. There's so much going against it: this hodgepodge of adapters, it has a low voltage CPU, disaster of wiring and exposed sensitive parts, crazy boot-time chainloading software, Intel killing companies producing adapters and products left right and center via legal threats, etc. but somehow, with the right parts and some patience, it works spectacularly. And is quite cheap too!

Again I want to thank nando4 for all his help in working with me tirelessly over the last few months to get this working. Also, thanks goes out to TechInferno and the community thats been built here for allowing people to help eachother so efficiently. If you have any questions/comments, please feel free to reply to this thread.

I'm also available on twitter, [@lg](https://twitter.com/lg).

Thanks everyone -- have a great day! And enjoy gaming, I hear PayDay 2 is awesome too :D

![eGPU Photo 1](/assets/egpu1.jpg) ![eGPU Photo 2](/assets/egpu2.jpg) ![eGPU Photo 3](/assets/egpu3.jpg) ![eGPU Photo 4](/assets/egpu4.jpg)