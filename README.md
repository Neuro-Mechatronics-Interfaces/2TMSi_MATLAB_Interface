# 2TMSi_MATLAB_Interface #
This repo contains code to run multiple TMSi SAGAs on the same device (or network) using MATLAB.

## Quick Start ##  
Procedure for running 2 TMSi, step-by-step.   

### 1. Start SAGA Device Handler ###
1. Double-click the "Modify MATLAB parameters" shortcut.  
  a. Confirm that the parameter for "config_stream_service_plus" is set to "configurations/acquisition/config_vr.yaml" (should be line 30: `pars.config_stream_service_plus = "configurations/acquisition/config_vr.yaml";`).
  b. If for whatever reason you have a separate configuration you want to run, then make sure the name matches your configuration yaml file.  
2. Double-click "Modify configuration yaml" shortcut.  
  a. Ensure that the desired SAGA configuration is enabled (look under SAGA: A: Enable, SAGA: B: Enable).  
  b. **Critical**: Make sure that the unit for each SAGA is configured to match whatever unit you're using (SAGAA, SAGAB, SAGA1, SAGA2, SAGA3, SAGA4, or SAGA5).  
  c. **Critical**: Make sure that under "Default: Folder:" the value is set to a folder location that exists on this machine (should be: "C:/Users/Daily/TempData"). Note that this is the root folder where you'll look for any saved output files.  
  c. (Optional, but recommended): Match up the "Type" and "Location" fields of "Array" under each SAGA so that they make sense with your experiment configuration.  
  d. If you are running everything from this machine only, then make sure all the sub-fields with network IP addresses are set to "127.0.0.1". Otherwise, assign them as appropriate per your experiment configuration.  
3. Ensure that both SAGAs are ON.
4. Ensure that both SAGAs are connected to this host computer via USB.  
5. Double-click the "Deploy SAGA Handler" shortcut.  
  a. The SAGA interface should do its thing, eventually producing a message with a timestamp indicating the acquisition state machine is ready (e.g. `->      [30-Mar-2024 12:52:53] SAGA LOOP BEGIN          <-`).  
  b. If you enabled other interfaces, you should have figures pop up which will start populating with squiggles once you run the device handler from a control interface, which we will set up in the next step.  

### 2. Setup SAGA control interface ###  
This is the part Max often just does by creating a UDP port in MATLAB (e.g. `udpSender = udpport("byte");`) and then sending byte messages. For further details on message structure, double-click the "SAGA control message details" shortcut. A more user-friendly (but less flexible) option is described in the following guide.  
1. From the device running the GUI controlling the SAGA devices, double-click the shortcut "Deploy SAGA Handler GUI". 
2. Update any relevant filename specifications in the text edit field, and set the index to the desired value. A byte message is sent only after the "ValueChanged" event is triggered from the UI edit fields, so you have to make sure to make a change somewhere to ensure the value in the edit field on the first go around matches the file names produced by the SAGA device handler. After that, you should only need to worry about the trial index (which auto-increments when a recording stops), or any ad hoc name changes for other identification purposes. The following values are always appended to the filename, even if you forget to add the "%%s" and "%d" anywhere in the name. Note that you can change the relation of where these format specifiers go, as-desired (otherwise if they are missing they are appended to the end of the filename, just before the ".poly5" extension is added):     
  a. "%%s" -- This lets the SAGA device handler distinguish files produced by the two SAGAs when saving to disk during recording.  
  b. "%d" -- This is used locally by the GUI to add in the index. 
3. Once all leads, references, and grounds are connected, you can preview what they look like by clicking the "RUN" button.  
4. To measure impedance, toggle back to "IDLE", which should enable the "IMP" button. Click "IMP" to view impedances.
  a. Close both impedance windows to save the impedances and exit impedance mode.  
  b. Impedance files are saved with the most-recent filename update (described in step 2), but in a *.mat file with "-impedances" after the "A" or "B" associated with each device.  
5. At the end, make sure you click "QUIT" to shutdown the SAGA device handler state machine, before you disconnect or power down either of the SAGAs. Failure to do this step causes bootup to take longer the next time around.  


## Contents ##
* [Using Git](#git-basics)
* [Overview](#instructions)
* [Serial Numbers](#serial-numbers)
* [Network and Messaging](#network-and-messaging)
* [Usage](#usage)
  + Note that this is application-specific, and the example deployment is geared towards online data visualization from one particular experiment with two TMSiSAGA where I wanted to see stim-evoked activity on two arrays as a contour.

## Git Basics ##  
_I'm trying to put these on every repo now._

### 1. Install git ###
To contribute/use code from this repository, the easiest authentication strategy for use with `git` is to create an SSH key and associate it to your GitHub account. You will need to download `git` to do any of this; the necessary keygen (openSSH) tools will subsequently be available in `git bash` that comes with the `git` download. In Windows (versions <11) you should be able to start a `git bash` terminal in your repository folder (or where you want to clone the repo) by right-clicking and selecting `Git Bash Here` from the context menu. In Windows 11, you can do the same thing but have to click the `More Options...` context menu at the bottom and then you will see the `Git Bash Here` option.

### 2. SSH setup ###
Platform-specific instructions for generating SSH keys and starting the SSH-agent that will "remember" your credentials in subsequent `git bash` sessions are provided by GitHub **[here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)**. Follow all the steps in that guide first. **It is recommended to add a passphrase to the generated SSH key!**  

Next, you need to add the key to your GitHub account. Step-by-step instructions that are platform-specific are provided by GitHub **[here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)**. Follow all the steps in that guide to associate the public key to your GitHub account.  

Once you have completed these steps, you should be able to use `git` commands with this and other `Neuro-Mechatronics-Interfaces` organization repositories that you have access to. 

### 3. Setup local repo ###
With `git` installed and your `ssh` credentials ready, you should now be able to clone this repository. Navigate to where you want this repository to go (as a folder) right-click and click `Git Bash Here` then enter:  
```(git)
git clone --recurse-submodules git@github.com:Neuro-Mechatronics-Interfaces/2TMSi_MATLAB_Interface.git
```
If you set up a `passphrase` in the `SSH` step, then you should be prompted for that `passphrase` before it will clone. You will now see a folder called `2TMSi_MATLAB_Interface` inside the folder where you opened the `git bash` terminal. The `--recurse-submodules` option just adds in submodules that Max created so that if he updates code related to this project while working on a different project, he doesn't forget to update it here (or, can create branches to avoid breaking things here if there are conflicts in another version for a different project).  

To avoid overwriting code that others are working on, please create a side branch. Max already made some example side branch but basically the format is `dev/<initials>` (e.g. Jonathan commits on `dev/JS`). To create and use a side branch, in `git bash` use the following command (replacing `MM` with your initials): 
```(git)
git checkout -b dev/MM
```

Now, when you `git commit` and `git push` to the remote repository, you will avoid overwriting changes on `main`. This is useful for collaborative work to avoid destroying each others analysis pipelines for example. If you have a really cool change that you think everybody should have, use the tools on the web interface to submit a pull request from your side branch (`dev/<initials>`) into `main` and assign @m053m716 as a reviewer. Maybe also send Max an email--once he sees the pull request and approves it will be merged into `main` and then anyone using `main` can see what you've added. 

By convention, it is good practice before you start coding to use `git fetch` to see if there have been recent changes on `main`. If you notice changes, you will want to `rebase` onto `main` so that your side branch stems from the current version of `main`. If you get too far behind `main`, then you may be working with deprecated code so keep that in mind if you plan on using the code here for development. Also, if you are planning on actively contributing/developing code in this repo please just let Max know so he isn't constantly squashing/forcing pushes to `main` (which is basically just done to keep the commit structure tidy). Thanks!


## Instructions ##

### TL;DR Setup ###
To use this code, you need to have a little bit of prior information. 
I've modified the TMSiSAGA package from its original state because I'm meddlesome and retentive like that. 
As such, you need to get:
* The serial number of each SAGA unit
* A list of "Tags" you want to assign to those serial numbers
* The TCP/IP and UDP port/firewall rules should prompt you in MATLAB to enable communications (at least in newer versions of MATLAB) on the required ports. If you think you are having issues with Firewall/permissions, try getting everything to run on `127.0.0.1` (localhost) first; it is most-likely some issue with your router or other network configuration.  
* Determine which script should run the stream service. If you are not sure, use `deploy__nhp_tmsi_sagas.m`. For a more advanced interface, use `deploy__nhp_tmsi_sagas_plus.m`. 
  + Each of these scripts has a `.bat` file associated with it. The `deploy__nhp_...` scripts are just `try..catch` wrappers to the actual `deploy__tmsi_stream_service<x>.m`. Once you have identified which service/script you want, you should make a desktop shortcut pointed to the appropriate `.bat` file. For example, on a Windows 10 device I have a desktop shortcut `1_deploy_tmsi`. If I right-click it and open Properties, then in `Target:` I have:
  ```
  C:\Windows\System32\cmd.exe /k "C:\MyRepos\NML-NHP\2TMSi_MATLAB_Interface\deploy__nhp_tmsi_sagas_plus.bat"
  ```
  In `Start in:` I have:
  ```
  C:\MyRepos\NML-NHP\2TMSi_MATLAB_Interface
  ```
  So the shortcut must run the `.bat` file from this repo in order for everything to work properly.  
  + If you are using the "normal" service, then check in `parameters.m` to see which `parameters.config` you should update (or better, make a copy of the one it currently points to and then change the value in `parameters.m` to point to the new yaml file you made, where you can set your local changes).  
  + If you are using the "advanced" service (the one ending in `_plus`), you will update `parameters.config_stream_service_plus` so that it now points to the new copy of whatever file it was previously pointing to.  

### Serial Numbers ###
You will need to assign each serial number to a corresponding tag (I use "A", "B", ... etc.). 
Make sure that the tags and serial numbers and ordering matches up so that elements are matched.  

#### NML Devices ####
A more comprehensive and hopefully current version of this table is kept on the `NML_share` drive in `Equipment Manuals and Software` in the `Equipment tracking.gsheet` file.  
| Unit Name | General Home | Data Recorder SN (Top) | Docking Station SN (Bottom) | Tag (Max Interface) |
| --------- | ------------ | ---------------------- | --------------------------- | ------------------- |
| SAGA-1    | Wean 4120    | 1000190062             | 1005190054                  | S1                  |
| SAGA-2    | Wean 4120    | 1000190076             | 1005190062                  | S2                  |
| SAGA-3    | Wean 4120    | 1000210046             | 1005210038                  | S3                  |
| SAGA-4    | Wean 4120    | 1000220037             | 1005220030                  | S4                  |
| SAGA-5    | Wean 4120    | 1000220035             | 1005220009                  | S5                  |
| SAGA-A    | Mellon 125k  | 1000210037             | 1005210028                  | A                   |
| SAGA-B    | Mellon 125k  | 1000210036             | 1005210029                  | B                   |

### Network and Messaging ###

Since this has gotten a little out-of-hand, I'm moving it into a [separate markdown document](NETWORK.md).

## Usage ##
_NOTE: ORDER OF OPERATIONS MATTERS FOR THESE SCRIPTS!  
Each of these steps should be started in a separate MATLAB session, possibly using different machines on the same network switch._

_NOTE 2: DEPENDING ON WHICH SAGA DEVICES ARE IN USE, YOU NEED TO ADJUST THE SERIAL NUMBERS IN `deploy__tmsi_stream_service.m` ACCORDINGLY. 
Please refer to the table in the [NML Devices](#nml-devices) section and use the `Data Recorder` column values corresponding to your machine._

  0. **TURN ON SAGA DEVICES AND ENSURE EVERYTHING IS PLUGGED IN!**

  1. On a local network computer (probably the one running TMSiSAGA
      devices), you will first run `deploy__tmsi_tcp_servers.m`.
	  
	  This will start the control server. The control server broadcasts to UDP ports 3030 ("state"), and 3031 ("name"), there are others but I'm not using them for now.

      The "state" port allows you to move the state machine between:
      "idle", "run", "record", and "quit" states (as of 5/7/22). 

      The "name" port broadcasts the current filename to any udp 
      receivers listening on that port within the local network. 

          For example, a common local network is "10.0.0.x" for devices 
          network, or "192.168.1.x" or "192.168.0.x" for devices 
          connected to a network router or switch respectively. The 
          broadcast address for a network is "a.b.c.255" network device
          "a.b.c.x".

      The "extra" port is just a loopback that broadcasts whatever was
      sent to the control server as a string as it was received (e.g.
      "set.tank.random/random_3025_01_02" for subject "random" and date
      "3025-01-02"). 

  2. Once the TMSi control/data servers are running, next start
      another MATLAB session and run the `deploy__tmsi_stream_service.m`
      to open communication with the TMSi SAGA device(s). 
      
          This runs a set of nested blocking loops which handle sampling 
          from those devices and querying the control server state. Two
          sets of buffers are created:

              `buffer` - One for each SAGA device. This is a smaller
                          buffer; the sets of samples from each call to
                          SAGA device array are appended to this buffer
                          and each buffer element has an event listener
                          with a callback that is triggered when the
                          buffer fills up. This basically acts as a
                          circular buffer, and the callback re-indexes
                          the data so that samples are sent in the
                          correct order. AS OF 5/8/22, TESTING INDICATES
                          THAT PASSING SAMPLES VIA TCP I LOSE ~40-200
                          SAMPLES ON EACH "FRAME" OF ~16k SAMPLES. THAT
                          IS ~1% SAMPLE LOSS WHICH IS OKAY FOR MY
                          APPLICATION BUT SOMETHING YOU SHOULD NOTE IF
                          YOU USE THIS CODE!

              `rec_buffer` - These should be LARGER buffers (currently I
                              have it as of 5/8/22 set so that they store
                              up to 10 minutes of data before looping
                              back around, that is overkill for the
                              length of triggered recordings I anticipate
                              using for my purposes but just be aware of
                              this, I have not set anything to handle the
                              case where it loops back on itself and
                              overwrites data). FROM TESTING AS OF
                              5/8/22, I DO NOT SEE ANY SAMPLE LOSS WHEN
                              DUMPING THE SAME SAMPLES INTO `rec_buffer`
                              AS I DUMP INTO `buffer`. Therefore, I am
                              pretty sure the sample loss via
                              tcpclient/tcpserver interaction is due to
                              the circular buffer having a mismatch on
                              the total number of samples each time. I'm
                              sure there is a better way to do it than
                              what I'm doing, but I don't want to spend
                              more time on it right now, so again, PLEASE
                              BE AWARE OF THESE LIMITATIONS IF YOU USE
                              THIS CODE!!

  3. The last thing to do is, most-likely in the same session running the
  servers (but you could do this in a third, separate session just to be
  safe) you would start a `tcpclient` to connect to the "CONTROL" server.
  
  Currently there are only two API functions for the "CONTROL"
  client/server interactions:
      + client__set_rec_name_metadata  - This just sets what your
                                          filename metadata should be.
                                          You should make sure that this
                                          increments between each
                                          recording so that you do not
                                          overwrite an existing file, it
                                          doesn't as of 5/8/22 have
                                          anything built-in to check for
                                          that.
      + client__set_saga_state       - This sets the state of the SAGA.
          You can either set it to "idle" | "run" | "rec" | "quit"
              "idle" -> does nothing
              "run"  -> stream data to tcpserver, but do not dump to diskfile
              "rec"  -> stream data to tcpserver and also dump to diskfile
              "quit" -> stop collecting data and shut down the SAGAs.

          At some point I will probably also add something like "imp" to
          do a quick impedance test, but I haven't put that in as of
          5/8/22.

       So at this point, your workflow is basically:
          a. Create tcpclient connected to control server
          b. Make sure that the SAGA loop is already running. If you
              clicked the run button for steps 1. and 2. you should be 
              good at this point. This really shouldn't be in the list.
          c. Alternate as: i. client__set_rec_name_metadata(...)
                          ii. client__set_saga_state("rec" (or "run"))
                         iii. client__set_saga_state("idle"), then back
                                  to (i) until
                          iv. client__set_saga_state("quit")

  At this point I haven't done much to test the shutdown but basically
  PLEASE MAKE SURE TO CALL THE `lib.cleanUp();` at the end on whichever
  session is running the SAGA devices. I may have commented it out on my
  end during testing so just again, double-check that before you start
  the script. If you intend to cycle through
  `client__set_saga_state("quit")` a bunch, then you might consider
  commenting it out as once you call `lib.cleanup` you'll have to re-run
  all the way through step 2 again rather than just restarting the loop.
  Note that you should be able to keep whatever client from step 3 even
  if you have to go back to step 2 so, now that I think about it, steps 2
  and 3 should probably flip but I'm too lazy to go back and fix that
  part.
