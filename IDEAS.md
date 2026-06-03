1. Sourcing the Files (The folder Object)
To dynamically read a list of files, you need to use the folder object.

The Push 3 Pathing Issue: You cannot use absolute Mac or Windows file paths (e.g., C:/ or Macintosh HD:/). The Push 3 Standalone runs on Linux. You must use relative paths.

Implementation: Use the thisdevice object to get the current path of your M4L device, and use sprintf or combine to append the relative folder path (e.g., a folder named "Samples" in the same directory as the device).

Reloading: Send a bang to the folder object whenever you need to refresh the directory contents (e.g., via a live.text button mapped to Push).

2. Displaying the List on Push (live.menu)
The most native way to display a list of text items on the Push 3 screen is using the live.menu object.

To dynamically populate it, you must send a clear message to the live.menu, followed by append [filename] for each file output by the folder object.

Alternatively, you can format the output of folder into a single range message (e.g., range file1.wav file2.wav file3.wav) and send that into the live.menu.

3. The Push 3 "Refresh Hack" (The Core Forum Issue)
The biggest issue discussed on the Ableton forums is that Push 3 does not reliably update its screen immediately when a live.menu receives new items dynamically. The device parameters are cached by Push.

To force Push 3 to redraw the menu with your newly loaded files, developers use a few workarounds:

The Bank Switching Trick: The user often has to manually page away to a different parameter bank on the Push 3 and then page back to see the updated list.

The LOM Force-Update: Some developers use the Live Object Model (LOM) to briefly rename the live.menu parameter or toggle its visibility (hidden attribute) via a live.object path, which forces the Push hardware to re-poll the device parameters and refresh the screen.

Deferlow: When sending the clear and append messages to live.menu, ensure they are run through a deferlow object. Max processes these messages faster than Live's API can communicate them to the Push hardware. Throttling the update via deferlow helps ensure the Push API catches the new state.

4. An Alternative Approach: The dict + live.numbox Method
Because dynamically updating live.menu strings can be clunky on Push 3, some M4L developers avoid it entirely:

Load the file names into a coll or dict.

Create a live.numbox (integer) mapped to a Push encoder. Set its minimum to 0 and its maximum to the number of files currently in the folder (dynamically updated).

As the user turns the encoder, the live.numbox outputs an index number.

Look up that index number in the coll/dict and send the resulting filename to a live.text object or an lcd object (if you are building a custom Push screen layout via the newer M4L Push API) so the user can see what they are selecting.

Summary Checklist for Push 3 Compatibility:

[ ] Use relative paths (via thisdevice).

[ ] Use folder to scan the directory.

[ ] Use deferlow when pushing new items to a live.menu.

[ ] Implement a forced parameter refresh or instruct the user to change banks to see the updated list.
