# These are They
## A generative music project in SuperCollider

"These are They" is an algorithmic "machine" that takes categorized sound files and enters them into a stew of transformations and interruptions. The sound files are not provided here, but there is an explanation of the categories below, so you can add your own and experiment.

This project is still under development, so changes may occur suddenly.

### What you need
To run "These are They", you need [SuperCollider](http://supercollider.github.io/download.html). You will also need to install SC3 Plugins, which can be found on the same download page (choose the package that is appropriate for your operating system). 

Once SuperCollider and SC3 Plugins are installed, you'll need to add the Wavesets Quark. Open SuperCollider and enter

```
Quarks.gui
```

To run this line of code, put the cursor on the same line as the code and hit Shift-Enter. A window will open with a list of available Quarks. Find Wavesets, click the + next to it, and then select "Reompile class library" at the top right of the window. You now have the necessary code to run "These are They".

To start the piece, open these-are-they.scd. Hit ctrl-enter, and you'll get a window with a start button. You can hit "Start" to begin, but nothing will really happen until you add audio.

### Adding Audio
In the project directory, you'll need to create an audio folder with five subfolders: bombas, chips, ludes, sonks, and talkers (names are case-sensitive). The files you put in each of those folders will have different functions and transformations within the piece. Below is an explanation of how files in each folder function. The files themselves should be uncompressed (wav or aiff). They can have any sample rate and bit depth, but, by default, the piece runs at 44.1k (files will be resampled appropriately). Files in bombas, ludes, and sonks should be stereo, interleaved. Files in chips and talkers can either be stereo or mono (only the left channel will be used in talkers).

bombas -> The piece periodically reaches a threshold where there's something of an explosion, or at least a wiggly moment. Every so often, that wiggly moment is replaced by files in the bombas folder: two played at the same time, marginally detuned, in the order they appear in the folder. These are relatively rare moments but can be generally striking.

chips -> Files in this folder get output in little clusters, usually short snippets, forwards or backwards, slower or faster. You generally don't hear these at the very beginning, but after a little time, they get spit out.

ludes -> These are interludes. They get played as-is after a certain amount of explosions / wiggly moments. Other material may overlap at the beginning, but once that winds down, the lude just plays unaccompanied until it's done. This would be a place where you can do your own thing without the app mangling it.

sonks -> These are meant to be lush, dramatic pieces that usually appear blurred, detuned, and slowed down. Sometimes, however, they come into focus. Often, you don't hear them as long, uninterrupted segments, but there are exceptions. 

talkers -> The original intent was that these would be recordings of talking, though there's no reason why they couldn't be something else entirely. These files are played back at normal speed or slower, and two are always being played at the same time. They alternate between dry, roughly pitched up, and spectrally altered, and they are periodically "stuttered" in '80s sampler fashion.

### Basic Modifications
First of all, keep all files and folders in their original structure, so that paths aren't broken. If you get an error dealing with buffers being empty or Document.current being undefined, you may have to modify a line near the top of the code:

```
~docDir = Document.current.dir;
```

You can change it to

```
~docDir = "/absolute/path/to/these-are-they-folder";
```

Just below, you can define the number of output channels. Currently, 2 (stereo) or 4 (quad) are acceptable:

```
~numChans = 4; // quad output
```

Any changes made to these-are-they.scd or to the files in the audio folder require you to re-execute the code in these-are-they.scd to take effect. It's a good idea to close the Start / Stop window before doing this, so you don't wind up with a bunch of orphan windows.
