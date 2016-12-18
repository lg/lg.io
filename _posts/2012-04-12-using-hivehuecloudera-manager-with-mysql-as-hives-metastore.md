---
layout: post
title: Using Hive+Hue+Cloudera Manager with MySQL as Hive's metastore
categories: []
tags: []
published: True
---

Yes, the title I’m sure is an eyebrow-raiser.

Today me and a friend spent the day messing with Hive. We’re testing out Hadoop, so we’ve chosen what should be a pretty easy way of doing this: using Cloudera Manager to set up the environment, and using pretty tools like Hue and Beeswax to make Hive queries.

After some initial fiddling and learning how everything works in the GUI, we got to the point of wanting to automate data insertion tasks. This of course means putting away Beeswax and using the Hive CLI. So we started:

{% highlight bash %}
$ hive
hive> show tables;
no tables
{% endhighlight %}

That’s odd, we had tables that we created earlier in Beeswax for testing. Where were they? It turns out that Beeswax uses a different metastore than the ‘hive’ CLI utility. What’s even worse is that the two can’t even use the same file (its a Derby db, yay Apache-lockin!). Looking at documentation for this shows that we’ll need to set up MySQL for access. Ok. Off to google.

Here’s an article that tells us how to set it up: [http://www.mazsoft.com/blog/post/2010/02/01/Setting-up-HadoopHive-to-use-MySQL-as-metastore](http://www.mazsoft.com/blog/post/2010/02/01/Setting-up-HadoopHive-to-use-MySQL-as-metastore)

Note that the author in that article uses /hadoop as his hadoop root. Our config was in /etc/hive/conf/. Oh also, make sure you mysql server starts at startup, his instructions don’t do that.

Great! All done, right? Kind of.

First off, being the impatient freak that I am, I completely ignored the need to install MySQL JDBC drivers. Oddly enough they’re not even “yum install”-able, so you’ll need to get them from the site listed in that article.

Ok, instructions properly followed, there’s still a problem. MySQL is good in the ‘hive’ command, but not in Beeswax+Hue, it just uses the same old database. It turns out that even if you try your best to modify any config files, Cloudera Manager will rewrite the metastore location incorrectly for you when it starts the services. This thread led me to the solution. You’ll need to add the lines from that original article to “Beeswax Server Hive Configuration Safety Valve”.  This will now allow Hive to connect to the proper metastore when being launched within Hue by Cloudera Manager.

And to think these tools are supposed to make things easier…

Remember, now to use hive from any other client you need to:

- make sure you have the /etc/hive/conf/hive-site.xml file with the proper mysql settings in it
- install the mysql jdbc drivers into /usr/lib/hive/lib

## Some Takeaways

To debug connection problems with the hive commandline utility, you should run: `hive —service metastore`. This will run a local metastore and you’ll see the error output straight away. This will uncover stuff like MySQL JDBC problems:

    Caused by: org.datanucleus.exceptions.NucleusException: Attempt to invoke the “DBCP” plugin to create a ConnectionPool gave an error : The specified datastore driver (“com.mysql.jdbc.Driver”) was not found in the CLASSPATH. Please check your CLASSPATH specification, and the name of the drive`

(by the way, the way to fix that is by going to the article linked above)

Always remember that the commandline tools like `hadoop`, `hive`, etc are actually completely independent of the Hue powered versions of these. You’ll always need to copy around your proper hive-site.xml and hadoop-site.xml files, even into the local /etc/hive/conf and /etc/hadoop/conf directories