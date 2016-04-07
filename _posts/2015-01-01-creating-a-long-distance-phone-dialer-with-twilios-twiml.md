---
layout: post
title: Creating a long distance phone dialer with Twilio's TwiML
categories: []
tags: []
published: True
---

This winter vacation, I had a bunch of spare time at home with my parents. It turns out that my parents call to Romania a lot -- especially during the holiday season. Since Romania is far away from here in Canada, if they were to use the local phone provider, Bell, they'd be destroyed with long distance charges (c'mon guys, it's 2015!). Usually you'd go out and get calling cards, etc, but in the past, when i was still living with them, what I did to get around the high fees of Bell and the unreliability and inconvenience of calling cards is I set up Asterisk.

Asterisk is a self-hosted PBX that can connect to SIP/IAX trunks provided by VoIP companies (I personally used to use [Unlimitel](unlimitel.ca), they're great). Problem with Asterisk is that it needs maintenance. It needs to run on a server, it's very complicated, patches sometimes break backwards compatibility, etc etc. I needed something less involved that if I were to get hit by a bus and go silent (otherwise known as starting a [startup](https://signwithenvoy.com)), they'd be hopeless to figure it out.

Phone tech has gotten significantly more advanced in the recent years. Though some companies like Bell still party like it's 1960, companies like Twilio have come along and made things a lot more powerful, easier and cost efficient.

Today's we're going to set up a minimally hosted service which accepts Twilio calls on a local number and then forwards them on via VoiceTrading's SIP server.

### Overview

Basically here's the flow of what I wanted to do:

1. Parents dial a phone number
2. Twilio accepts call
3. Parents type in a secret code
4. Twilio waits for a caller to type new phone number
6. Call gets forwarded via SIP to VoiceTrading
7. VoiceTrading calls the number and connects the call
8. If the call errors at all, tell the caller

### TwiML Serverside

Luckily for us [TwiML](https://www.twilio.com/docs/api/twiml) can help do exactly this. It helps accept calls, play text-to-speech messages, accept input, redirect via SIP, etc. _The unfortunate part is it does not allow for any logic_. For example, if you prompt the caller to press 1 for abc and 2 for def, you need a serverside script to process the input. I feel like if they just added a tag as part of TwiML which let you change flow depending on input, we wouldn't even need a serverside component. But oh well, can't have em all...

One thing I know I strongly dislike maintaining is backend code. I spent almost 3 years at Twitter during crazy downtime days helping deal with it. I try these days to avoid building services that require me to SSH into anything, or run any kind of daemon or process that might crash. I basically want an even less involved platform-as-a-service than something like Heroku. No thx to applying security patches, upgrading versions of stuff, etc.

So, for the first time in almost 10 years, I busted out my DreamHost account which provides, wait for it, _PHP_ CGI. I really wanted to avoid PHP because I've become so much better at much better languages, but honestly, in this case it fits the bill _perfectly_. With a strong focus on simplicity, here's the script I ended up building:

{% gist ba26bba8219af9da5e1d %}

Man, it's killing me that I can't just do this all in one XML and not even need a serverside component! Either way, DreamHost is super low maintenance. You upload the script and well, you're done. Never need to touch it again or reboot dynos, or any of that.

Basically Twilio re-calls the same script with each input the user does. We pass GET parameters to specify which part of the flow the caller's part of. Super simple, easy to read and understand.

### Hooking it up to Twilio

Twilio kind of hides this functionality, but it's not too bad.

1. Log into your Twilio account and make sure you have a phone number created that you'll receive calls from.
2. Go to `Dev Tools` then `TwiML Apps`, then click `Create TwiML App`.
3. Set the `Friendly Name` to something, and the `Voice Request URL` to where you placed your script.
4. You can skip the `Messaging Request URL` since we're not doing any kind of text message forwarding.
5. Save your settings
6. Now go to the `Numbers` page and click on your phone number.
7. Click on `Configure with Application` on the Voice section and select your script.
8. Click Save and you're done!

![Twilio app screenshot](/assets/twilioapp.png)

![Twilio number screenshot](/assets/twilionum.png)

Should you have any problems, Twilio has great developer tools and debugging capability to see exactly what you sent it and what went wrong. They even have a web dialer so you don't even need to pick up the phone.

### That's it!

Twilio has been a dream to work with. Not only do we use them for [Envoy](http://signwithenvoy.com) at work, but I'm happy I now have an excuse to use them for myself too.

I have just built a maintenance-free system and saved a ton of time and headaches for the future. Cool stuff. Who'd have thought PHP could have been so useful? ;)

