# audirvana-scrobbler

Scrobbles **Audirvana** playing tracks to **Last.fm**. Uses *zsh*, *AppleScript* and *Python 3* ([scrobbler](https://github.com/hauzer/scrobbler/)).

Loops every 3 seconds (the ````DEFAULT_SLEEP_TIME```` variable). The loop time increases to 20 seconds (the ````LONG_SLEEP_TIME```` variable) if Audirvana has been idle for 5 minutes (the ````AUDIRVANA_IDLE_THRESHOLD```` variable).

Scrobbles to Last.fm when 75 % (the ````THRESHOLD```` variable) of the track has been played.

1. Install [scrobbler](https://github.com/hauzer/scrobbler/) (requires Python 3) with ````pip install scrobblerh````
2. Authenticate scrobbler to Last.fm with the ````add-user```` command.
3. Download this script.
4. Change the ````LAST_FM_USER```` variable in the script to your Last.fm username.
5. Run the script with ````./audirvana-scrobbler.sh````
6. Play some music with Audirvana.

![Screenshot](https://github.com/sprtm/audirvana-scrobbler/blob/master/screenshot.png)
