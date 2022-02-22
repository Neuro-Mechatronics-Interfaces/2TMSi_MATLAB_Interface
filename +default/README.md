# MATLAB (R2020b) Defaults
[![View Matlab-Defaults on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/84215-matlab-defaults)

This repository contains my (@m053m716) preferred defaults as a package with functions named after Matlab built-ins.

## Installation ##

Simply clone this repository into whatever Project folder that you would like to use the defaults for. Because of the `GitHub` naming convention, which does not allow the remote repository name to start with `+` (which is the default character preceding folders that are Matlab "packages"), you will need to make sure that the contents of this folder are cloned so that they are contained within a folder called `+default` (or whatever you would like the package name to be called on your local machine). Then, any functions contained within the package are effectively within the `+default` "name-space" which means that they can be called as:

```Matlab
>> help default
>> fig = default.figure(); % Creates Untitled Matlab figure with standard preferences
>> fig = default.figure('MyFigure'); % Creates figure named 'MyFigure'
>> fig = default.figure('MyFigure','Position',[0.1 0.1 0.8 0.8]); % Change the "Position" <'Name',value> setting
```

## Example ##

My recommended configuration (Windows 10 machine running Matlab R2020b; this could change with subsequent versions or for UNIX operating systems) is to clone this repository into a **non-project** folder where you plan to contain other custom packages. A convenient location is the default `userpath`:

```Matlab
>> userpath
ans = 
	'C:\Users\Max\Documents\MATLAB'
```

My C: drive is a small SSD, but I have a larger HDD for storing data and other things. So, I can change my `userpath`, which is updated each time a Matlab session is started up as a given User (see: **[`userpath`](https://www.mathworks.com/help/matlab/ref/userpath.html "Mathworks reference for userpath() function")** documentation for details).

```Matlab
>> mkdir('D:\MATLAB\Tools');    % Location I want to store packages etc.
>> userpath('D:\MATLAB\Tools'); % Now, that will be the userpath that loads each time
```

Now, if I put this repository as a package named `+default` in that folder (so: `'D:\MATLAB\Tools\+default'`), each time I start a new MATLAB session by default my local code and command calls will "see" the contents of this repository. ***Note: this is (as of 2020-12-11) still a pretty small repo. If it gets bigger, this may not be desirable, as that will potentially cause MATLAB to run more slowly in general.***

