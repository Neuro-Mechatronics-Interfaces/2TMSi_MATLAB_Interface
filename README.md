# 2TMSi_MATLAB_Interface #
This repo contains code to run multiple TMSi SAGAs on the same device (or network) using MATLAB.

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
* Open the UDP ports 3030-3035 for MATLAB on Inbound/Outbound rules
  + Search "Firewall" on Windows and then go to "Advanced Firewall Settings" to modify these
* Open the TCP/IP ports 5000-5050 for MATLAB on Inbound/Outbound rules
  + Note that for both these changes, consider only allowing these to be open for specific IP addresses you intend to use on your device network. I don't actually know if that helps from a security standpoint but I hope it does.

#### Serial Numbers ####
You will need to assign each serial number to a corresponding tag (I use "A", "B", ... etc.). 
Make sure that the tags and serial numbers and ordering matches up so that elements are matched. 

#### Firewall ####
 I might just be really bad at IT but I had a hell of a time getting that part to work and then magically walked in the next day and it all worked without me ever changing the code so either we have gremlins (like the good kind?) or it might require a computer restart and then some quiet contemplation of your life's choices (waiting) until the network gods decide to let you use their ports. Anyways, consider yourself warned.

### Use ###
_NOTE: ORDER OF OPERATIONS MATTERS FOR THESE SCRIPTS!  
Each of these steps should be started in a separate MATLAB session, possibly using different machines on the same network switch._

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
      another MATLAB session and run the `example__tmsi_stream_service.m`
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
