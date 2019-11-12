#!/bin/zsh

##   Audirvana Scrobbler
##   Ver: 1.0.1
##
##   Scrobble Audirvana tracks to last.fm
##   Req: python3 + scrobblerh (pip install)
##
##   2019-11-10


# set properties
export DEFAULT_SLEEP_TIME=3
export AUDIRVANA_IDLE_THRESHOLD=$(( 300 / DEFAULT_SLEEP_TIME ))
export AUDIRVANA_IDLE_TIME=0
export AUDIRVANA_RUNNING_STATE
export CURRENT_ALBUM=""
export CURRENT_ARTIST=""
export CURRENT_PLAYER_STATE
export CURRENT_POSITION=""
export CURRENT_TRACK=""
export LASTFM_USER=""
export NOW_PLAYING_TRACK_DATA=""
export OK_TO_SCROBBLE=false
export PLAYED_ENOUGH=240
export PREVIOUS_TRACK_INFO=""
export SCROBBLE_MESSAGE="Nothing to scrobble."
export SLEEP_TIME="$DEFAULT_SLEEP_TIME"
export TERM=xterm-256color
export THRESHOLD=75
export TIMESTAMP
export TRACK_DURATION=""
export TRACK_HAS_BEEN_SCROBBLED=false
export VERSION="1.0.1"


# functions
function IS_AUDIRVANA_RUNNING {
	AUDIRVANA_RUNNING_STATE=$(osascript <<-APPLESCRIPT
		tell application "System Events"
			set listApplicationProcessNames to name of every application process
			if listApplicationProcessNames contains "Audirvana" then
				set AUDIRVANA_RUNNING_STATE to "yes"
			else
				set AUDIRVANA_RUNNING_STATE to "no"
			end if
		end tell
	APPLESCRIPT
	)
}

function CHECK_AUDIRVANA_STATE {
	CURRENT_PLAYER_STATE=$(osascript -e 'tell application "Audirvana" to get player state')
}

function GET_NOW_PLAYING_DATA {
	NOW_PLAYING_TRACK_DATA=$(osascript <<-APPLESCRIPT
	tell application "Audirvana"
		set playingTrack to playing track title
		set playingAlbum to playing track album
		set playingArtist to playing track artist
		set playingDuration to playing track duration
		set playingPosition to player position
	end tell

	set myList to {playingTrack, playingAlbum, playingArtist, playingDuration, playingPosition}
	set myString to "" as text
	repeat with myItem in myList
		set myString to myString & myItem & linefeed
	end repeat
	return myString
	APPLESCRIPT
)
	CURRENT_TRACK=$(echo "$NOW_PLAYING_TRACK_DATA" | sed -n 1p)
	CURRENT_ALBUM=$(echo "$NOW_PLAYING_TRACK_DATA" | sed -n 2p)
	CURRENT_ARTIST=$(echo "$NOW_PLAYING_TRACK_DATA" | sed -n 3p)
	TRACK_DURATION=$(echo "$NOW_PLAYING_TRACK_DATA" | sed -n 4p)
	CURRENT_POSITION=$(echo "$NOW_PLAYING_TRACK_DATA" | sed -n 5p | awk '{print int($1)}')
	TRACK_THRESHOLD=$(( TRACK_DURATION*THRESHOLD/100 ))
	CURRENT_TRACK_INFO="$CURRENT_TRACK - $CURRENT_ARTIST - $CURRENT_ALBUM"
}

function TEST_IF_TRACK_IS_ABOVE_THRESHOLD {
	if [[ ${CURRENT_POSITION} -gt $TRACK_THRESHOLD ]] && [[ $TRACK_HAS_BEEN_SCROBBLED = false ]]; then
		SCROBBLE
	fi
}

function ECHO_FUNCTION {
	echo -n "\e[0J" # clear everything after the cursor
	echo "\r\e[0K  Audirvana....: $1\n  Last.fm......: $SCROBBLE_MESSAGE"
	tput cup 4
}

function COMPARE_TRACK_DATA {
	if [[ "$CURRENT_TRACK_INFO" != "$PREVIOUS_TRACK_INFO" ]]; then
		TRACK_HAS_BEEN_SCROBBLED=false
		TIMESTAMP=$(date "+%Y-%m-%d.%H:%M")		
		NOW_PLAYING
	fi
	PREVIOUS_TRACK_INFO="$CURRENT_TRACK_INFO"
}

function NOW_PLAYING {
	SCROBBLE_MESSAGE=$(scrobbler now-playing "$LASTFM_USER" "$CURRENT_ARTIST" "$CURRENT_TRACK" -a "$CURRENT_ALBUM" -d "$TRACK_DURATION"s)
	SCROBBLE_MESSAGE="$SCROBBLE_MESSAGE:u"
	SCROBBLE_MESSAGE="$(tput setaf 2)[${SCROBBLE_MESSAGE%?}] $(tput sgr 0)${CURRENT_TRACK} — ${CURRENT_ARTIST}"
}

function SCROBBLE {
	SCROBBLE_MESSAGE=$(scrobbler scrobble "$LASTFM_USER" "$CURRENT_ARTIST" "$CURRENT_TRACK" "$TIMESTAMP" -a "$CURRENT_ALBUM" -d "$TRACK_DURATION"s)
	SCROBBLE_MESSAGE="$SCROBBLE_MESSAGE:u"
	SCROBBLE_MESSAGE="$(tput setaf 2)[${SCROBBLE_MESSAGE%?}] $(tput sgr 0)${CURRENT_TRACK} — ${CURRENT_ARTIST}"
	TRACK_HAS_BEEN_SCROBBLED=true
}


# initiate script
echo "\e[?25l" # hide cursor
clear
printf "\n  Audirvana Scrobbler Script %s * Running...\n  =============================================\n\n" "$VERSION"

while sleep $SLEEP_TIME; do
	if (( AUDIRVANA_IDLE_TIME >= AUDIRVANA_IDLE_THRESHOLD )); then
		SLEEP_TIME="$LONG_SLEEP_TIME"
	fi
	IS_AUDIRVANA_RUNNING
	if [ "$AUDIRVANA_RUNNING_STATE" = no ]; then
		ECHO_FUNCTION "Application is not running."
		AUDIRVANA_IDLE_TIME=$(( AUDIRVANA_IDLE_TIME + 1))
	elif [ "$AUDIRVANA_RUNNING_STATE" = yes ]; then
		CHECK_AUDIRVANA_STATE
		if [ "$CURRENT_PLAYER_STATE" = "Playing" ]; then
			AUDIRVANA_IDLE_TIME=0
			SLEEP_TIME="$DEFAULT_SLEEP_TIME"
			GET_NOW_PLAYING_DATA
			TEST_IF_TRACK_IS_ABOVE_THRESHOLD
			ECHO_FUNCTION "$(tput setaf 3)♫ ${CURRENT_TRACK} — ${CURRENT_ARTIST} • ${CURRENT_ALBUM}$(tput sgr 0)"
			COMPARE_TRACK_DATA
		elif [ "$CURRENT_PLAYER_STATE" = "Paused" ] || [ "$CURRENT_PLAYER_STATE" = "Stopped" ]; then
			ECHO_FUNCTION "Player is stopped/paused."
			AUDIRVANA_IDLE_TIME=$(( AUDIRVANA_IDLE_TIME + 1))
		fi
	fi
done
