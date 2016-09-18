---
layout: post
title: "Cloudy Gamer: Playing Overwatch on Azure's new monster GPU instances"
categories: []
tags: []
published: False
---

**UNPUBLISHED, DO NOT DISTRIBUTE YET**

It's no secret that I love the concept of not just streaming AAA game titles from the cloud, but *playing* them live from any computer -- especially the underpowered laptops I usually use for work. I've done it before on Amazon's EC2 (and written a full article for how to do it), but this time, with the latest NVIDIA M60 GPUs becoming available on cloud providers, Microsoft's Azure is first in opening this up to any Joe like me to tinker with.

Before going through this article, I strongly recommend you at least skim my EC2 Gaming article from before so you can grasp some of the concepts we'll be doing here. Basically it'll come down to this: we're going to launch an Azure GPU instance, configure it for ultra-low latency streaming, and actually properly play Overwatch, a first-person shooter, from a server hundreds of miles away!

And yes, it seems I always need to repeat myself when writing these articles: the latency is just fine, the resolution is amazing, it's very cheap (cheaper than a gaming rig depending on usage patterns), and all very practical. If you're the hardcore gamer-type who's knee-jerk reaction regardless of benchmarks is "omg i dont trust anything that doesnt have a Zalman watercooled CPU fan or has a 'hardware-offloaded' networking card" or if you're in some sort of sunk-costs situation of already having spent loads of money on a gaming rig, I strongly recommend not reading this article -- it'll only further infuriate you. :)

For this article, I'll be assuming you're on a Mac, though the Windows instructions are very similar.

With that, lets get started!

1. As the Azure GPU machines are still in Preview, you'll need to request access to them here: http://gpu.azure.com. Unfortunately, this also means you need to wait until you're invited. I find that harassing the PM on the project on Twitter can sometimes help: [@Karan_Batta](https://twitter.com/karan_batta). Sorry Karan ;)

1. Once you're in, on Azure's dashboard, create a Windows Server 2016 instance on an NV6 type machine (has NVIDIA's new M60 GPU). The K80 machines won't work for this since they don't virtualize the display adapter we need. **(TODO UPDATE TO BE MORE CLEAR)**

1. Install Microsoft Remote Desktop on your Mac if you haven't already. Connect to your Azure machine using the username/password you specified when creating the instance.

1. Like any new Windows machine you get access to, I usually have a checklist of things I do to make it usable:
	- Run Windows Update on it
		- Click the Start button and select 'Settings', then select 'Update & Security' and run Windows Update there

	- Turn on always showing icons in the system tray
		- Right click on the taskbar and select 'Properties', then select 'Notification area' > 'Customize...'
		- Click on 'Select which icons appear on the taskbar'
		- Turn on 'Always show all icons in the notification area'

	- Turn off Combining taskbar icons
		- Right click on the taskbar and select 'Properties', then select 'Taskbar buttons' > 'Never combine'

	- Turn off auto Defragmenting drives (yes this is a real problem that'll happen in the middle of your games)
		- Click the start button and type in 'Defragment' and select 'Defragment and Optimize drives'
		- Turn off the scheduled scanning **(TODO UPDATE TO BE MORE CLEAR)**

	- Turn on performance flags, plus turn off the boot timeout (since we're on a server)
		- Right click the Start button and select 'System', then select 'Advanced system settings' on the left side
		- In the Performance section, click on 'Settings...'
		- In the Visual Effects tab, select 'Adjust for best performance'
		- In the Advanced tab, select 'Programs' and click Ok
		- Back to the 'System Properties' dialog, click the 'Settings...' button in the 'Startup and Recovery' section
		- Uncheck 'Time to display list of operating systems' since you never get to see that anyways

	- Enable file extension showing and system/hidden file showing
		- Open up the File Explorer and click 'View' up top
		- Put a check in 'File name extensions' and 'Hidden items'
		- Then, click the 'Options' icon and select the 'View' tab
		- Unselect 'Hide protected operating system files'

	- Remove unnecessary scheduled tasks
		- Press the start button and type and open 'Schedule tasks'
		- Now for each of the following in 'Task Scheduler (Local) > Task Scheduler Library > Microsoft > Windows':
			- Delete all tasks in 'Chkdsk'
			- Delete all tasks in 'Defrag'
			- Delete all tasks in 'Windows Defender'

	- Turn off Windows Firewall (all 3 of them)
		- Right click the Start button and type 'Windows Firewall with Advanced Security'
		- In the thing that opens click on 'Windows Firewall Properties' near the middle of the dialog
		- Now for each of the tabs 'Domain Profile', 'Private Profile' and 'Public Profile', select 'Firewall state' to 'Off'

	- Make the desktop background black (or a non-picture) to minorly speed up Remote Desktop sessions
		- Right click the desktop and select 'Personalize'
		- For 'Background' select 'Solid color'
		- Then pick the black color below (or whatever color your heart desires)

	- Disable File and Printer sharing and SMB client on the network
		- Right click the start menu and select 'Network Connections'
		- Double click on Ethernet. Try not to be distracted by the alleged '40.0 Gbps' connection the machine has.
		- Click on Properties and uncheck 'Client for Microsoft Networks' and 'File and Printer Sharing for Microsoft Networks'

	- Disable unnecessary services
		- Click the Start button and type in 'Services'
		- For each of the following services, double click on it and select 'Startup Type > Disabled'
			- Server
			- Print spooler

1. Install Steam (yes, even thoug we eventually want to play Overwatch, we need Steam's In-Home Streaming to work)
	- Click on the Internet Explorer button on the task bar and go to 'https://steampowered.com' and download and install it from there
	- Configure Steam to:
		- Save your password and auto-login
		- Account > Beta participation, and select 'Steam Beta Update'
		- Friends > Automatically sign into Friends when I start Steam
		- In-Game > In-game FPS counter > Top-left (optional, but I like it since this is the raw FPS on the machine)
		- In-Home Streaming > Enable streaming
		- In-Home Streaming > Advanced Host Options, and Check only the following:
			- 'Adjust resolution to improve performance'
			- 'Enable hardware encoding'
			- 'Enable hardware encoding on NVIDIA GPU'
			- 'Prioritize network traffic'
			- Note that everything else should be unchecked. I've messed with NvFBC, but what Steam does for full-screen capture seems to be superior. Of course, you can mess with it later if you're trying to debug a game.
		- Interface > Favorite window > Library
		- Interface > Notify me about additions or changes [...], *uncheck* it

1. Turn on auto-login into Windows, this is useful to make it faster to start playing games after rebooting
	- Press the Start button and type in 'netplwiz'
	- Click on your username
	- Uncheck 'Users must enter a user name and password to use this computer'
	- Then click the OK button and enter your user's password

1. Disable the default display adapter in Windows or else games will choose the wrong one
	- Right click the Start button and select 'Device Manager'
	- Expand 'Display adapters', right click on 'Microsoft Hyper-V Video' and select 'Disable'

1. Enable audio in Windows Server
	- Click the Start button and type in 'Services'
	- Double click on 'Windows Audio' and select 'Automatic' for 'Startup type'

1. **(TODO: Maybe unnecessary)** Open up Internet Explorer and download Razer Surround. It creates the virtual sound card that you'll need to play games. When installing it, it might fail, so kill it using the Task Manager, but it'll have installed properly anyways.
	- After installing, download Autoruns, an app to let you disable startup items
	- Search for 'Razer Synapse' and uncheck it

1. For Steam In-Home Streaming to work properly, you'll need to set up a VPN. I strongly recommend ZeroTier for this since it's the best at ensuring a peer-to-peer connection between the machines and not re-routing through some other server who knows where. Oh and don't worry, for what you'll be using it for, it's free. They're also a super ethical company and opensource large amounts of their core software.
	- So, go to 'https://zerotier.com' and create an account there and create a network
	- When configuring the network, select 'IPv4 Auto-Assign' and 'Auto-Assign from Range' and pick any range (the default works too)
	- I'd set 'Access Control' to 'None (Public Network)' since nobody knows about your network
	- For 'Ethernet Frame Types', I'd select only 'IPv4 (and ARP)', nothing else
	- Now go install ZeroTier on both the server and your own computer and make them both join the same Network ID you created above

1. **(TODO: Maybe unnecessary with proper firewall settings in azure)** Azure (like EC2 and others) is kind of behind the times and doesn't support IPv6. We'll need to force disable it in Windows otherwise some software might try to do a IPv6-over-IPv4 tunnel which ruins everything (Zerotier for examples tries to do this).
	- Open up an Administrator PowerShell and run the following:

			Set-Net6to4Configuration –State disabled
			Set-NetTeredoConfiguration –Type disabled
			Set-NetIsatapConfiguration –State disabled

1. Ok this is a weird one. You'll need to install TightVNC from the internet so you can configure the monitors properly. Depending on the Azure machine type you selects and the amount of graphics cards, you'll need to disable things. **(TODO: All this may be unnecessary)**
	- Install TightVNC and close Microsoft Remote Desktop
	- On your Mac in Finder, select the Go menu and select 'Connect to Server'
	- Type in 'vnc://<server_private_ip_from_zerotier>' replacing the IP there with the IP address address issued by ZeroTier to the server. You need to do this because the Azure firewall blocks all inbound connections **(TODO: Maybe unnecessary to use private IP)**
	- This is going to be crazy. Disable all monitors in Windows except the one used by the NV60. **(TODO: Needs better instructions)**

1. To optimize the network traffic and packet sizes Steam In-Home Streaming uses you might need to adjust MTU on the server-side. I figured out this number by trial and error and using WireShark on the client side to see when what is supposed to be one streaming packet ended up with one big packet and one tiny one. **(TODO: Maybe include a picture or link to doing it yourself?)**
	- Open up PowerShell and run the following. 'Ethernet 2' here is the name of the ZeroTier adapter.

			netsh interface ipv4 show subinterfaces
			netsh interface ipv4 set subinterface "Ethernet 2" mtu=1410 store=persistent

1. Install Overwatch and configure it **(TODO: Needs more details)**

1. Lets add Overwatch to Steam so we can stream it
	- In Steam, click 'Add A Game...' and select 'Add a Non-Steam Game...'
	- Overwatch should be on the list. If you add it manually, make sure you select 'Overwatch Launcher.exe'. Launching it directly may cause problems **(TODO: Needs fact check)**

1. On your computer (in Steam), configure it as such:
	- In-Home Streaming > Enable streaming
	- In-Home Streaming > Client options > Beautiful
	- In-Home Streaming > Client options > Advanced client options > Limit bandwidth to > 30 Mbits/s (do NOT set unlimited, it does not work)
	- In-Home Streaming > Client options > Advanced client options > Limit resolution to > Display resolution
	- In-Home Streaming > Client options > Advanced client options > Enable hardware decoding
	- In-Home Streaming > Client options > Advanced client options > Display performance information

1. **(TODO: Maybe something better exists?)** To log out of the Microsoft Remote Desktop session, you actually need to do it in a specific way to not *lock* the screen (it's some security thing). So, open up Notepad, paste the following, and save on the desktop as 'logout.cmd'. Note that any time you'll want to log out you'll need to right click on this and select 'Run as administrator'.

		for /f "skip=1 tokens=3 usebackq" %%s in (`query user %username%`) do tscon.exe %%s /dest:console

1. Ok, you're good to go! The way to get this started is a bit odd though and you'll need to do this every time:
	1. Start Steam first on the client
	2. Start Steam on the server
	3. The machines should detect themselves and say they're connected. If they do not, go on the server and open up the Steam preferences and in In-Home Streaming, un-check and re-check the 'Enable streaming' option
	4. With that logout.cmd you created above, right click on it and 'Run as administrator'
	5. On your client computer find Overwatch on the side click the Play button!

