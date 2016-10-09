---
layout: post
title: "Cloudy Gamer: Playing Overwatch on Azure's new monster GPU instances"
categories: []
tags: []
published: True
hidden: true
---

[![](/assets/azure-overwatch/azure-game-streaming-thumb.jpg)](/assets/azure-overwatch/azure-game-streaming.png)<br/>
<sub><sup>**Playing Overwatch at 60FPS, 2560x1600, everything on Epic quality, and streaming from the cloud -- not too shabby!**</sup></sub>

It's no secret that I love the concept of not just streaming AAA game titles from the cloud, but *playing* them live from any computer -- especially on the underpowered laptops I usually use for work. I've done it before using Amazon's EC2 (and written [a full article]({% post_url 2015-07-05-revised-and-much-faster-run-your-own-highend-cloud-gaming-service-on-ec2 %}) for how to do it), but this time, things are a little different. [Microsoft's Azure is first](https://azure.microsoft.com/en-us/blog/azure-n-series-preview-availability/) to give access to NVIDIA's new M60 GPUs, completely new beasts that really set a whole new bar for framerate and image quality.

Before going through this article, I strongly recommend you at least skim my [EC2 Gaming article]({% post_url 2015-07-05-revised-and-much-faster-run-your-own-highend-cloud-gaming-service-on-ec2 %}) from before so you can grasp some of the concepts we'll be doing here. Basically it'll come down to this: we're going to launch an [Azure GPU instance](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/series/#n-series), configure it for ultra-low latency streaming, and actually properly play [Overwatch](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/series/#n-series), a first-person shooter, from a server [over a thousand miles away](http://www.gcmap.com/mapui?P=SFO-HOU)!

And yes, it seems I always need to repeat myself when writing these articles: the latency is just fine, the resolution is amazing, it can be very cost-effective (if you don't forget the machien on), and all very practical for those of you obsessed about minimalism (like me). If you're the hardcore gamer-type who's knee-jerk reaction regardless of anything is "omg i dont trust anything that doesnt have a Zalman watercooled CPU fan or has a '[hardware-offloaded](http://www.killernetworking.com)' networking card" or if you're in some sort of sunk-costs situation of already having spent loads of money on a gaming rig, I strongly recommend not reading this article -- it'll only further infuriate you. :)

Note that in this article I assume you're on a computer similar to mine (a Macbook laptop running MacOS). That's not a requirement to do this stuff though. You could be on Linux or Windows as a client, though some of the client-side tooling changes around a bit. You'll figure it out!

### Costs

Though in EC2-land we had cheaper servers due to Spot Instances, Azure doesn't quite have that concept yet. That means you'll be paying retail. For the bandwidth, it's still going to be the biggest part of the bill.

- NV6 Server: $0.73/hr
- Bandwidth at 10MBit/s: $0.41/hr
- HD storage: $0.003/hr

**Total at 10MBit/s: $1.14/hr**<br/>
**Total at 30Mbit/s: $1.96/hr** (recommended tho)

### Requesting access

As the Azure GPU machines are still in Preview, **you'll need to request access** to them [here](http://gpu.azure.com). Unfortunately, this also means you need to wait until you're invited, though I've been told the wait times are getting shorter and shorter (still around a week or two right now). I find that harassing the PM on the project on Twitter can sometimes help: [@Karan_Batta](https://twitter.com/karan_batta). Sorry Karan ;)

Meanwhile, I suggest watching this quick video I made, plus skim the instructions. That and start saving those pennies!

<iframe width="560" height="315" src="https://www.youtube.com/embed/jeapeI_Kp28" frameborder="0" allowfullscreen></iframe>
<br/>

### Part 1: Creating the Azure instance

1. Once you get the email that you're in, go to the Azure portal and create a new NV6 type machine (has NVIDIA's new M60 GPU). The K80 machines won't work for this since they don't virtualize the display adapter we need.
	1. Enter the Azure Portal
	1. On the left side select 'Virtual machines' and click 'Add'
  ![](/assets/azure-overwatch/virtual-machine-listing.png)
	2. Select 'Windows Server' then 'Windows Server 2016 Technical Preview 5'
	![](/assets/azure-overwatch/windows-server-tile.png)
	![](/assets/azure-overwatch/windows-server-20160r5.png)
	3. When prompted for the deployment model, select 'Resource Manager' and click the 'Create' button
	![](/assets/azure-overwatch/resource-manager.png)
	4. Enter a name and some credentials for the machine. Make sure though that the 'VM disk type' is 'HDD' and the Location is 'South Central US' (this is the only location they support right now)
	![](/assets/azure-overwatch/sample-machien-config.png)
	5. When prompted to pick the size (type) of machine select 'View all' up top and click on the 'NV6' machine type. Try not to panic about the cost, we'll only be using it for a few hours while gaming, not 24/7. :)
	![](/assets/azure-overwatch/nv6.png)
	6. On the Settings screen, most defaults are fine, but do change the Network Security Group to 'None' and turn off Diagnostics
	![](/assets/azure-overwatch/more-machine-config.png)
	7. Confirm everything on the Summary screen and the instance will launch. Note that it takes a few minutes until your machine is Running and it'll have an IP address.
	![](/assets/azure-overwatch/machine-create-summary.png)

1. Install [Microsoft Remote Desktop](https://itunes.apple.com/us/app/microsoft-remote-desktop/id715768417?mt=12) on your Mac if you haven't already. Set up the machine with the username/password you specified when creating the instance and the IP address listed on Azure. Additionally:
	- Select "Connect to admin session" on the machine's properties
	![](/assets/azure-overwatch/rdp-screen-1.png)
	- Unselect "Start session in full screen"
	- Select a resolution of 1024x768
	- Select "Don't play sound" (it's unnecessary)
	![](/assets/azure-overwatch/rdp-screen-2.png)

1. Once connected, you'll need to create a new user account that isn't the account you specified earlier. This is necessary for some driver changes and auto-login steps you'll be doing later.
	1. Right click on the Start button and select 'Control Panel'
	1. Then select 'User Accounts' and then 'User Accounts' again, then 'Manage another account'
	1. Then click to 'Add a user account' and create a new user. _This will be the accout you'll use going forward_.
	1. Once created, click on it on the list
	1. Click on 'Change the account type', select 'Administrator', and confirm
	1. Close the window and disconnect from the session
	![](/assets/azure-overwatch/both-accounts.png)

1. Set up this new user on Microsoft Remote Desktop on the client side and re-login with the new account. You won't need the old account anymore, so feel free to remove settings about it from Remote Desktop.

### Part 2: General configuration for making the server more of a workstation

1. Run Windows Update on it
	- Click the Start button and select 'Settings', then select 'Update & Security' and run Windows Update there
	- It can take a while for this to complete, and even might appear to be stuck at a certain percentage, but all is ok, just keep waiting
	- Once it completes, restart the machine if necessary. It'll probably take several minutes until the machine will be back up and running.

1. Turn on ICMP Ping requests with the Windows Firewall. It's useful for debugging.
	- Click the Start button and type 'Windows Fire' and select 'Windows firewall with Advanced Security'
	- Select 'Inbound rules' on the left side and enable the rule 'File and Printer Sharing (Echo Request - ICMPv4-In)'
	![](/assets/azure-overwatch/icmp-enable.png)
	- You should now be able to ping your server machine from your laptop to figure out what the roundtrip time is

1. Disable Windows Defender
	- Click the Start button and type in 'Windows Defender'
	- Turn off 'Real-time protection'

1. Turn off auto Defragmenting drives (yes this is a real problem that'll happen in the middle of your games)
	- Click the start button and type in 'Defragment' and select 'Defragment and Optimize drives'
	- Click on 'Change settings' for 'Scheduled optimization'
	- Uncheck 'Run on a schedule'

1. Turn on performance flags, plus turn off the boot timeout (since we're on a server)
	- Right click the Start button and select 'System', then select 'Advanced system settings' on the left side
	- In the Performance section, click on 'Settings...'
	- In the Visual Effects tab, select 'Adjust for best performance'
	- In the Advanced tab, select 'Programs' and click Ok
	- Back to the 'System Properties' dialog, click the 'Settings...' button in the 'Startup and Recovery' section
	- Uncheck 'Time to display list of operating systems' since you never get to see that anyways
	- Finally, select '(none)' for 'Write debugging information'

1. Remove unnecessary scheduled tasks
	- Right click the start button and select 'Computer Management'
	- Select 'Task Scheduler' on the left side
	- Now for each of the following in 'Task Scheduler Library > Microsoft > Windows':
		- Disable all tasks in 'Chkdsk'
		- Disable all tasks in 'Diagnostics'
		- Disable all tasks in 'DiskCleanup'
		- Disable all tasks in 'Maintenance'
		- Disable all tasks in 'SystemRestore'
		- Disable all tasks in 'Windows Defender'

1. Disable File and Printer sharing and SMB client on the network
	- Right click the start menu and select 'Network Connections'
	- Double click on 'Ethernet'. Try not to be distracted by the alleged '40.0 Gbps' connection the machine has. :)
	- Click on Properties and uncheck 'Client for Microsoft Networks' and 'File and Printer Sharing for Microsoft Networks'

1. Disable unnecessary services
	- Click the Start button and type in 'Services'
	- For each of the following services, double click on it and select 'Startup Type > Disabled' and Stop the service
		- Server
		- Print spooler

1. Turn on auto-login into Windows, this is useful to make it faster to start playing games after rebooting
	- Press the Start button and type in 'netplwiz'
	- Click on your username
	- Uncheck 'Users must enter a user name and password to use this computer'
	- Then click the OK button and enter your user's password
	![](/assets/azure-overwatch/netplwiz.png)

1. Make the desktop background black (or a non-picture) to minorly speed up Remote Desktop sessions
	- Right click the desktop and select 'Personalize'
	- For 'Background' select 'Solid color'
	- Then pick the black color below (or whatever color your heart desires)

1. Turn off notifications of things you already told it you don't want on
	- Click the start button and type in 'action center' and select 'Security and Maintenance'
	- On the left side select 'Change Security and Maintenance settings'
	- Uncheck all the things that make you feel superior to other people and don't need to be reminded about

1. Turn on always showing icons in the system tray
	- Right click on the taskbar and select 'Properties', then select 'Notification area' > 'Customize...'
	- Click on 'Select which icons appear on the taskbar'
	- Turn on 'Always show all icons in the notification area'

1. Enable file extension showing and system/hidden file showing
	- Open up the File Explorer and click 'View' up top
	- Put a check in 'File name extensions', geez, how is hiding extensions ok?

1. Turn off Combining taskbar icons and some other taskbar cleanups
	- Right click on the taskbar and uncheck 'Show Task View button' and 'Show touch keyboard button'
	- Right click on the taskbar and select 'Properties', then select 'Taskbar buttons' > 'Never combine'

1. Fix the time zone because you're not some crazy sysadmin
	- Right click the time in the systray and select 'Adjust date/time'
	- Select 'Time zone' to be where you are

1. Make the Server Manager not start up every time the computer does
	- Open the Server Manager
	- Go to the 'Manage' menu and select 'Server Manager Properties'
	- Put a check in 'Do not start Server Manager automatically at logon'


### Part 3: NVIDIA M60 video card

1. You'll notice that if you pull up the Device Manager that the driver will be missing for the M60 video card.
![](/assets/azure-overwatch/no-nvidia-driver.png)

1. Get the proper driver from [here](https://azuregpu.blob.core.windows.net/nv-drivers/362.56_grid_win10_64bit_english.exe). It's a custom build for Azure right now, so using NVidia's site driver may not work. The version as of writing this is at 362.56. You may be able to find a more recent one mentioned on the [Azure forum](https://social.msdn.microsoft.com/Forums/azure/en-US/home?forum=AzureGPU).

1. Do the regular Express install and reboot when completed.
![](/assets/azure-overwatch/driver-install-done.png)

1. Disable the default display adapter in Windows or else games will choose the wrong one
	- Right click the Start button and select 'Device Manager'
	![](/assets/azure-overwatch/nvidia-driver-in.png)
	- Expand 'Display adapters', right click on 'Microsoft Hyper-V Video' and select 'Disable'. Though notice the fancy M60 card on there now too!
	![](/assets/azure-overwatch/disable-non-nvidia-driver.png)

1. You're using the Remote Desktop service in Windows to administer everything. The problem is that whenever you disconnect from the server, Remote Desktop will lock the screen (and you'll need to CTRL-ALT-DEL to be able to use things). This is no good if we'll want games to be running.
	- On the desktop, right click and create a shortcut and have it run the command `tscon 1 /dest:console` and name it 'Disconnect'
	![](/assets/azure-overwatch/disconnect-shortcut.png)
	- Right click on it, select Properties and click the 'Advanced' button
	- Put a checkmark in the 'Run as administrator' option
	![](/assets/azure-overwatch/run-as-admin.png)
	- In the next step and we'll be using this link, plus also with Steam later

1. Ok this is a weird one. You'll need to install TightVNC from the internet so you can configure the monitors properly. Depending on the Azure machine type you selects and the amount of graphics cards, you'll need to disable things. **(TODO: All this may be unnecessary)**
	- Download TightVNC 64-bit from [here](http://www.tightvnc.com/download.php).
	- Install it and set some passwords.
	- Once completed, right click on the new system tray icon, select 'Configuration...', and 'Set...' by 'Primary password' and type in a **secure** password. Remember that your machine is open to the world and people most certainly do port scan looking around for machines like yours to play with. Secure passwords are key.
	![](/assets/azure-overwatch/tightvnc-config.png)
	- Now run the Disconnect shortcut you created earlier. It'll disconnect your session.
	- On your Mac in Finder, select the Go menu and select 'Connect to Server' and type in 'vnc://<your_server_ip_address' and connect. (or do similar instructions for another VNC client)
	- Depending on the amount of adapters your machine has, this may be a giant window. Resize it so you can see everything.
	- Right click on the main desktop and select 'Display Settings'
	- Under 'Multiple displays', select 'Show only on 1' and click 'Apply'
	![](/assets/azure-overwatch/show-only-on-1.png)
	- Select 'Keep Settings' and you're done here. You can disconnect from the VNC server.
	![](/assets/azure-overwatch/display-keep-settings.png)
	- Go back in Remote Desktop and you can now uninstall TightVNC. This is the only config that can only be done this way.
	- **HELP REQUESTED:** Is there a better way of doing this without needing to use TightVNC?

### Part 3: Audio

1. Enable audio in Windows Server, the service is off by default
	- Click the Start button and type in 'Services'
	- Double click on 'Windows Audio' and select 'Automatic' for 'Startup type'

1. There is no soundcard on the VM. A free product, VB-CABLE handles this quite well.
	- Download it from [here](http://vbaudio.jcedeveloppement.com/Download_CABLE/VBCABLE_Driver_Pack43.zip)
	- Extract the zip and run the 'VBCABLE_Setup_x64.exe' installer as Administrator


### Part 4: ZeroTier VPN

1. Azure (like EC2 and others) is still *very* fresh with IPv6, and it's current implementation is not enough for use here. We'll need to force disable it in Windows otherwise some software might try to do a [IPv6-over-IPv4](https://en.wikipedia.org/wiki/Teredo_tunneling) tunnel which ruins everything (Zerotier for examples tries to do this).
	- Open up an Administrator PowerShell (click Start, right click on 'Windows PowerShell' and 'Run as Administrator'.
	- Then run the following:

			Set-Net6to4Configuration –State disabled
			Set-NetTeredoConfiguration –Type disabled
			Set-NetIsatapConfiguration –State disabled

	![](/assets/azure-overwatch/teredo.png)

1. For Steam In-Home Streaming to work properly, you'll need to set up a VPN. I strongly recommend [ZeroTier](https://zerotier.com) for this since it's the best at ensuring a peer-to-peer connection between the machines and not re-routing through some other server who knows where. Oh and don't worry, for what you'll be using it for, it's free. They're also a super ethical company and opensource large amounts of their core software.
	- So, go to [Zerotier's website](https://zerotier.com) and create an account there and create a network
	- When configuring the network, there are a few settings necessary:
		- I'd recommend setting 'Access Control' to 'None'. It makes configuration easier, just don't distribute the network id.
		- For 'IPv4 Auto-Assign' select to 'Auto-Assign from Range' and pick an IP range for the VPN. You'll notice the Managed Routes above will be updated.
		- For 'Ethernet Frame Types' unselect IPv6, it's unnecessary since Steam does not support it right now. Make sure IPv4 is on though.
		- Write down that Network ID
		![](/assets/azure-overwatch/zerotier-config.png)
	- Now, go install ZeroTier on the server. The Windows download link is [here](https://download.zerotier.com/dist/ZeroTier%20One.msi). When installing, select to approve everything, including the network adapter.
	- At the end, it'll come up with the ZeroTier One window. Put that Network ID in there and click Join. Click Yes on any Windows prompts.
	![](/assets/azure-overwatch/zerotier-server.png)
	- Repeat the same installation of ZeroTier again except on your laptop. The Mac download link is [here](https://download.zerotier.com/dist/ZeroTier%20One.pkg). Have it join the same network.
	![](/assets/azure-overwatch/zerotier-client.png)
	- On the ZeroTier website under your network, you should now be able to see the IP addresses of the two machines.
	![](/assets/azure-overwatch/zerotier-clients.png)
	- To test the tunnel works, have one ping the other by its 'Managed IP'. The ping times should be around the same as if you pinged the Physical IP of the other machine. Ideally your ping times are way lower than the ones in this screenshot... I'm looking forward to when the Azure GPU machines are closer to where I live!
	![](/assets/azure-overwatch/pinging-zerotier.png)

1. To optimize the network traffic and packet sizes Steam In-Home Streaming uses you might need to adjust MTU on the server-side. I figured out this number by trial and error and using WireShark on the client side to see when what is supposed to be one streaming packet ended up with one big packet and one tiny one.
	- Open up an Administrator PowerShell and run the following on the server. 'Ethernet 2' here is the name of the ZeroTier adapter.

			netsh interface ipv4 show subinterfaces
			netsh interface ipv4 set subinterface "Ethernet 2" mtu=1410 store=persistent

	![](/assets/azure-overwatch/network-adapters.png)

1. I'd recommend rebooting now, just because of all the quirky network changes. Note that ZeroTier will always reconnect on both systems, so if you ever need to make changes, use ZeroTier One on both systems to configure things.

### Part 5: Steam In-Home Streaming + OverWatch

1. Install Steam (yes, even though we eventually want to play Overwatch, we need Steam's [In-Home Streaming](http://store.steampowered.com/streaming/) to work)
	- Click on the Internet Explorer button on the task bar and go to 'https://steampowered.com' and download and install it from there
	- Configure Steam to:
		- Save your password and auto-login (if you have Steam Guard on, you'll need to put in the code they email you)
		- Account > Beta participation, and select 'Steam Beta Update'
		- Friends > Automatically sign into Friends when I start Steam
		- In-Game > In-game FPS counter > Top-left (optional, but I like it since this is the raw FPS on the machine)
		- In-Home Streaming > Enable streaming
		- In-Home Streaming > Advanced Host Options, and Check only the following:
			- 'Adjust resolution to improve performance'
			- 'Enable hardware encoding'
			- 'Enable hardware encoding on NVIDIA GPU'
			- 'Prioritize network traffic'
			- Note that everything else should be unchecked. I've messed with NvFBC, but what Steam does for full-screen capture seems to be superior. Of course, you can mess with it later if you're trying to debug a game. If you try to use NvFBC, please see my previous EC2 Gaming article for instructions on how to get that set up (you need to run a tool).
			![](/assets/azure-overwatch/steam-streaming-server.png)
		- Interface > Favorite window > Library
		- Interface > Notify me about additions or changes [...], *uncheck* it

1. Install [Overwatch](https://playoverwatch.com) using Blizzard's upsell-galore Battle.net launcher thingy

1. Overwatch in particular has some issues quitting properly after being launched from Steam. Fortunately a tool, [bnetlauncher](http://madalien.com/stuff/bnetlauncher/) was built to help properly start/stop the game. Basically, keep the official Battle.net client running, but in the next step use this launcher.

1. To stream games we use Steam's In-Home Streaming functionality since it's the most mature game-streaming tech out there (that I'm aware of). The good news is that you can add non-Steam games (like Overwatch/bnetlauncher) and it works great too.
	- In Steam, click 'Add A Game...' and select 'Add a Non-Steam Game...'
	- Overwatch should be on the list. Don't add it that way, rather select and add bnetlauncher.
	- After its added, right click on it and select Properties. Set the name to be Overwatch
	- As part of the Target, add ' Pro' after the double-quotes.
	![](/assets/azure-overwatch/overwatch.png)

1. On your computer (in Steam), configure it as such:
	- In-Home Streaming > Enable streaming
	- In-Home Streaming > Client options > Beautiful
	- In-Home Streaming > Client options > Advanced client options > Limit bandwidth to > 30 Mbits/s (do NOT set unlimited, it does not work)
	- In-Home Streaming > Client options > Advanced client options > Limit resolution to > Display resolution
	- In-Home Streaming > Client options > Advanced client options > Enable hardware decoding
	- In-Home Streaming > Client options > Advanced client options > Display performance information
	![](/assets/azure-overwatch/steam-streaming-client.png)

### Part 6: Let's play!

It's relatively simple to actually play, but there's some details you need to know:

- First, the Steam clients need to detect eachother. Due to a bug in the Steam Mac client, it can't broadcast over all interfaces (i.e. our VPN adapter) that it's online. This means you'll always need to start the server Steam client *second*.
- One tip, instead of quitting the Steam client on the server, you can also go in the Settings and uncheck and recheck the 'Enable streaming' option
- Always use the Disconnect link on your desktop as the way of closing your Remote Desktop session. Otherwise you'll receive a 'Screen is locked' error.
- Don't forget to Stop the Azure instance when you're done playing. It'll be very expensive if you don't.
- These M60 cards are insanely powerful, experiment with cranking everything up! :)
- I'll be putting together a better troubleshooting guide soon, but if you have troubles, please make sure you read every step above in detail. Even the stuff like MTU settings and disabling IPv6 have made *substantial* differences in weird scenarios for me.
- Happy gaming!!

[![](/assets/azure-overwatch/azure-game-streaming-2-thumb.jpg)](/assets/azure-overwatch/azure-game-streaming-2.png)

There are some interesting components when pressing F6, plus the other information on screen.

![](/assets/azure-overwatch/steam-details.jpg)
- Here you can see all sorts of interesting stats: we're doing 2560x1600 at 60fps via NVENC
- Latency is around 82ms. Once Azure spreads this tech around to all their datacenters, things should really go down in terms of latency.
- We're doing a solid 21MBits, though in action it'll easily hit 30MBits

![](/assets/azure-overwatch/steam-graph.png)
- This graph by Steam shows the latency over time
- Dark blue line is time it took to encode the H264 on the server side
- Light blue line is time it took to transfer to the client side
- Red line is decoding time and display latency

![](/assets/azure-overwatch/overwatch-fps.jpg)
- I enabled Overwatch to tell me FPS in-game just to verify things. Solid ~60FPS.

![](/assets/azure-overwatch/steam-fps.png)
- And just to triple-check (and debug), Steam is configured to overlay the FPS. Also 60FPS.