---
layout: post
title: The future is now, and it's using AWS Lambda
categories: []
tags: []
published: True

---

It's a bit of a sensationalistic title, but hear me out. And sorry for the boring-ish example in this article. This is designed to only excite people who really get it. :)

[AWS Lambda](https://aws.amazon.com/lambda/) lets you run NodeJS code or any binary (or code of any language) as a fast starting and stopping EC2 instance. You can use it to, for example, quickly resize an image as a background worker. What I'll quickly show you here though is that you could even possibly use it as _a full-on back-end for a single-page app_.

What's even more awesome? It basically scales by parallelizing infinitely. No need to ever spin up more EC2 instances or Dynos or any of that. Capacity planning? No need!

So, lets build a quick static webpage (that you can host anywhere, including `file://`)

![Quick page code](/assets/lambda-1.png)

All this page does is connect to Lambda and send `sup1` as the value to `key1` through simple JSON.

Here's the lambda code (which you literally can do on the [AWS Console](https://aws.amazon.com/console/)):

![Lambda code](/assets/lambda-2.png)

This is even simpler. The `handler` callback is called by Lambda whenever this Lambda Function is called. `context.succeed` is used to return a value to the caller.

And lets run it:

![Result code](/assets/lambda-3.png)

FYI, this is crazy. We just did a backend call with full-on backend logic without setting up any kind of instances. No worrying about starting a new [not-even-free-anymore](https://blog.heroku.com/new-dyno-types-public-beta) Heroku Dyno. No choosing machine speed and memory and hard drive sizes. It just works, effortlessly, and scales enormously.

One thing you might note is that we're exposing our AWS public and secret keys. This is actually not that big of a deal. To make this secure, we actually created a new AWS User and with a Policy specifically preventing everything except the one Lambda Function:

![Security policy](/assets/lambda-4.png)

Oh and I mentioned that it scales "infinitely", yeah there's a 100-parallel-requests maximum right now, but I'd imagine this will be removed by AWS as the service matures. Meanwhile, you can ask them for more.

I guess recent AWS changes makes my [lambda-job](https://github.com/lg/lambda-job) project kinda useless. It's all built in now.

Very cool stuff. Hat tip to Amazon for constantly doing new amazing things.

_thanks to [@siong1987](https://twitter.com/siong1987) for the quick review_