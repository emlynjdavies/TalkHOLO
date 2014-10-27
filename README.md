Alternative interface of LISST-HOLO for networked data aquisition.

TalkHOLO.m is dependant on read_HOLO_info.m (by A Nimmo-Smith, Plymouth University) - I have not tested TalkHOLO with the version of read_HOLO_info in this repo!

Set-up:
- connect network cable and power LISST-HOLO
- Check comms. are OK
- open TalkHOLO GUI
- enter the LISST-HOLO's FTP password
- Select Sample interval (1 sec is the fastest; 2 seconds is more consistent)
- Select the data diectory (to save holograms to on your local machine)
- Click "Configure LISST-HOLO" (this takes ages due to slow URL request method - see 'Known issues' below).
- Click GO to start sampling (a stop command will be sent if the RAM on the HOLO gets too full)
- "STOP" will send a URL request to the HOLO to stop sampling and then copy the remaining images from the RAM of the HOLO.

USEAGE:
>> TalkHOLO

Known issues:
- some buttons are temporarily enabled all the time, due to comms problems with SINTEF's LISST-HOLO.
- All requests for configuration changes are made via url requests. This is slow. If someone has time to make some improvements, it would be better to download the config file from the HOLO, modify it and re-upload it via FTP.
