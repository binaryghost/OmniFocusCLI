NAME: OmniFocusCLI

AUTHOR:	Don Southard aka. @binaryghost

CHANGELOG:


**[ October 31, 2011 10:42:17 AM version 1.5 ]**

- Fixed Growl support. Now it works with the MAS version of Growl and will hopefully gracefully fail if Growl is not running. That should alleviate all the issues I have recieved lately

- Started implementing Due support. It is **NOT** finished but I wanted to push this out now because so many people where having problems with Growl.

- I am also including my Alfred extension in the github repo. Many people have asked for me to just ship the extension all wrapped up and ready to go and I figure its a good idea since you can easily import extensions in to Alfred app now

- Added "Agendas" to the existing "Agenda" context lookup just as another option, different people spell it differently.


[ 6/17/2011 11:04:04AM version 1.4 ]

-Fixed major bug in Context support for Non-MAS version of OF.
Thanks to Thierry for taking the time to submit the bug report!

-Added a simple help printout if no task is submitted from CLI

-Fixed misc. bugs and did random code cleanup. Hopefully I didn't break anything in the process :)



[ 6/06/2011 02:14:11PM version 1.3 ]

-Contexts are no longer case sensitive and it has sub-context support!

-Added natural language context support
*i.e. Call Joe Blow* (gives it a context of Phone)

*i.e. Talk to Joe about blah blah* (gives a context of Agenda : Joe if one exists)

*i.e. Mow grass at home* (gives it a context of Home)

-Added Agenda support with sub-contexts (That means a context named "Agenda" with sub-contexts of names for people you need to speak with.)

*i.e. Speak with Steve about new iPhone* (gives it a context of Agenda : Steve)

-Removed the Diagnostic Report since its annoying if you are working in the terminal and it clears the screen you were working in and prints out a long useless report :)

-Fixed parsing bug in due date code

-Fixed a bug in my own Waiting for... context

-Fixed a bug in the initial check for empty task

[ 5/27/2011 09:51:32AM version 1.2 ]

-Started adding DUE DATES!!! This was tricky because I didn't want to mess up start dates. Now you can just type "due" followed by a number of days, weeks or months!

i.e. Mow the grass due 1w

...or... Pull the weeds 2d @Home due 3d (creates a task with a start date of 2 days and a due date of 3 days, plus a context of @Home)

[ 5/26/2011 04:17:43PM version 1.1.1 ]

-Fixed a bug in the hidden due date feature that I do not like. I'm going to officially support due dates eventually.

[ 5/26/2011 12:30:42PM version 1.1 ]

I know this is a big jump in version numbers but I basically rewrote atleast half the code. 

-OmniFocusCLI now reads in your root Contexts directly from OmniFocus in REALTIME! Change your contexts and OmniFocuCLI will still work! This is a major advancement. Contexts are no longer required to start with an @ symbol. Sub-contexts are still not supported but should be soon. This feature may break if OmniGroup ever changes the schema of their database so obviously there are no guarantees. It was also ONLY tested on a Mac App Store version of OmniFocus.

-How the task name was originally created was garabage and I completely rewrote it so it is optimized and more intelligent. 

-Misc bug fixes

[ 5/24/2011 04:19:33PM version 1.0.2 ]
-detection for NULL tasks from the Terminal (Alfred doesn't let you anyway) to prevent blank tasks from being created

[ 5/20/2011 03:02:41PM version 1.0.1]
-Fixed a bug with blank start dates setting "Today" value
-Added "Noon"/"noon" support


__INSTALL:__   
Start by downloading the latest version of OmniFocusCLI from this link to its GitHub Repo: [OmniFocusCLI](https://github.com/binaryghost/OmniFocusCLI/zipball/master)

Double click the Alfred Extension to add to Alfred or copy the script to your /usr/local/bin directory

If it doesn't, it is probably because the script does not have permissions to execute on your computer.

To fix this, simple fire up the Terminal. Browse to the location of your script and execute:

**chmod +x OmniFocusCLI.sh**

The next time you try to add a task, it should work fine!

MORE INFORMATION:

Please visit [DirtDon.com](http://www.dirtdon.com/?p=963)

To submit bugs or feature requests please email [support@dirtdon.com](mailto:support@dirtdon.com)

