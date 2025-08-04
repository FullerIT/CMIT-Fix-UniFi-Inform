# CMIT-Fix-UniFi-Inform

We had a tech accidentally set the force inform url and disconnected all of our endpoints


These are a set of tools used to re-acquire lost devices and get them set back to our controller


Requires plink.exe in the same folder, it will download it, but I recommend just keeping it with your scripts so we don't use up the PuTTY owners bandwidth.


Unifi-Discovery, given a list of mac addresses, search the designated network (class c by default but easily adjusted), this will output the IP addresses to place in deviceParams.json for the next scripts
You may not need discovery if this has just happened recently, but if a network has a power loss, the devices might not be the same IPs you see in your controller.


UniFi-Setup will prime plink with the host keys for the SSH, you do have to press "Y" on each one to get it loaded to the local system.


Fix-UniFi-Inform will go to each IP and set the inform until it sticks and shows connected. If it fails to make it to connected, check your url and maybe power cycle the devices (from the switches if you can regain access to those)


IMPORTANT: deviceParams.json will delete when the script is completed, for security reasons, so keep a copy handy in case you have to run it more than once.

