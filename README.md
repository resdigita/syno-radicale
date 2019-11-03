# <center>Syno-Radicale Docker</center>
This Radicale Docker image is intended to replace the native calendar server available on a Synology NAS. That one lacks perfomance for larger calendars and synchronization across multiple devices is slow. For iOS it does not support the use of multiple task lists, limiting efficient work organization. For example, the GTD (Get Things Done) methods cannot be used.

Of course, it may also be used for a NAS of other manufacturers or generally for private single servers. It contains no provisions for Kubernetes or the orchestration of a server farm / cloud.


## Requirements and Preparatory Considerations

As far as possible, Synology's functionality and capability should be used to keep maintenance burden as low as possible.

#### Owner of the calendar application process

The Docker container can optionally run as unprivileged user with the same name and user ID as a native Synology user. Specifically it may use a storage location for calendar data protected by Synology security management. If you are the only calendar user, you may choose to use your user account to run the container (and possibly your home directory to store the calendar data). If there are several users, you may create a dedicated user, e.g. radicale.
You have to use ssh to login into the Synology.  Execute the following command in the terminal:
> „id USER_NAME“, e.g. “id radicale“

You get a response like

> admin@DiskStation:~$ id radicale
   uid=1039(radicale) gid=100(users) groups=100(users)

Note the user id (uid=1039) und the group id (gid=100).

(In DSM  the use of ssh must be at least temporarily enabled:  Control Panel → Terminal & SNMP → Terminal → Enable SSH service clicked)

#### Storage Location

To be able to use a users home directory  for storage you have to activate the „home service“ in DSM: Control Panel → User → Advanced → User Home → click „Enable user home service“. As volume to use specify: /homes/radicale and possibly an additional subdirectory in the users home directory.

Alternatively create a dedicated shared directory, e.g. Calendar and and possibly an additional subdirectory, e.g. radicale. Protect it appropriately. Note the path into that subdirectory. In the example above it would  be `/Calendar/radicale`.

#### SSL and Certificate Management

You need a valid certificate to connect to the calendar savely. For iOS and MacOS it is mandatory. Both systems can‘t login without a secure and encrypted connection.


## Installation Steps

1. Open the Docker application in your Synology and download resdigita/syno-radicale

2. Select the image an click on „Launch“ in the task bar.

3. Set the container name, e.g. myradicale

4. Click „Advanced Settings“

5. Select „Volume“ and click „Add Folder“. Select the appropriate folder from the selection tree and enter the mount path /srv/radicale.

6. Select „Port settings“ and enter the desired external port, usually 5232 as well.

7. Select Environment, click the + sign and enter in the variable field USERS (upper case!) and as value one or more pair(s) of calendar users/password. Each pair is separated by „,“ and user name and password are separated by „:“.
As an example:
USERS	guest:topsecret,me:verysecret.

8. Click the + sign again und enter RUNAS in the variable field an e.g.
RUNAS	radicale:1039:100
as for the example above.

9. Click on Apply and start the container

10. Open DSM Control Panel and select „Application Portal“ → „Revers Proxy“. Select „Create“ and fill in the revers proxy specifications: As Source protocol HTTPS, your hostname and a publicly accessible port, e.g. 9080, as destination protocol HTTP, hostname localhost and port 5232 for the radicale container. Open „Custom Header“ and create a WebSocket to autmatically redirect a source http request to https .

11. Open the address https://yourserver.dom:9080 and log in to Radicale to create one or more calendar(s) and address book(s).

12. Configure your calendar clients. Use the URL as shown in the Radicale Web Interface without the numeric calendar name, but including the / after the user name.

13. If Synology is not behind a router or other firewall, configure Synology Firewall to allow access to Radicale port 5232 locally only.

14. Otherwise configure your router / firewall to redirect port 9080 to your Synology.


## Maintenance

After a first start of the syno-radicale container you should stop it in the Synology Docker GUI and delete the USERS environment Variable to protect the passwords. Restart the container (not rebuild!) and Radicale will use the already configured user data.

To add user(s) stop the container, enter an appropriate USERS environment variable and restart (not rebuild!). The container will add the user(s) to the existing one(s).


## Data Transfer from Synology Calendar Package

The Synology Calendar Package uses the same data format as Radicale by default (multifilesystem – each event in a separate ics file). So you may expect to copy the ics files from one location to the other. For a single file this works (usually), but not with a slightly larger calendar with about 10,000 entries. Even if you introduce a pause of 5 seconds after each file,  the Radicale server acknowledges the copy process with an error message. Maybe a longer pause is working, that's not tested.

A relatively simple way is to export the data using a client software and import it into a newly created Radicale calendar. Using MacOS / iOS Calendar, an imported calendar may not be able to use all features of the software (e.g. additional ToDo lists). Then old (imported) calendar and a newly created one have to be used temporarily in parallel.
