#!/bin/sh

set -e

cd $HOME

if [ ! -n "$WERCKER_SLACKHOOK_URL" ]
then
    fail 'missing or empty option url, please check wercker.yml'
fi

# if no username is provided use the default - werckerbot
if [ -z "$WERCKER_SLACKHOOK_USERNAME" ]; then
  export WERCKER_SLACKHOOK_USERNAME=werckerbot
fi

# if no icon-url is provided for the bot use the default wercker icon
if [ -z "$WERCKER_SLACKHOOK_ICON_URL" ]; then
  export WERCKER_SLACKHOOK_ICON_URL="https://raw.githubusercontent.com/wantedly/step-pretty-slack-notify/master/icons/$WERCKER_RESULT.jpg"
fi

# check if this event is a build or deploy
if [ -n "$DEPLOY" ]; then
  # its a deploy!
  export ACTION="deploy"
  export ACTION_URL=$WERCKER_DEPLOY_URL
else
  # its a build!
  export ACTION="build"
  export ACTION_URL=$WERCKER_BUILD_URL
fi

export MESSAGE="<$ACTION_URL|$ACTION> for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY has $WERCKER_RESULT on branch $WERCKER_GIT_BRANCH"
export FALLBACK="$ACTION for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY has $WERCKER_RESULT on branch $WERCKER_GIT_BRANCH"
export COLOR="good"

if [ "$WERCKER_RESULT" = "failed" ]; then
  export MESSAGE="$MESSAGE at step: $WERCKER_FAILED_STEP_DISPLAY_NAME"
  export FALLBACK="$FALLBACK at step: $WERCKER_FAILED_STEP_DISPLAY_NAME"
  export COLOR="danger"
fi


if ! type go-slack &> /dev/null ;
then
    info 'go-slack not found, start installing it'
    sudo wget -O/usr/local/bin/go-slack https://github.com/rodrigosaito/go-slack/releases/download/v0.0.2/go-slack_linux_amd64
    sudo chmod +x /usr/local/bin/go-slack
    success 'go-slack installed succesfully'
else
    info 'skip go-slack install, command already available'
    debug "type go-slack: $(type go-slack)"
fi

info 'starting slack notification'

go-slack -url $WERCKER_SLACKHOOK_URL -username $WERCKER_SLACKHOOK_USERNAME -icon-url $WERCKER_SLACKHOOK_ICON_URL "$MESSAGE"
