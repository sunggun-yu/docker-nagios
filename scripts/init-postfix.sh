#!/bin/bash

# Install postfix for email notification
# Someone may set the hostname to the docker instance with '--hostname'In order to apply hostname correctly, installing is happening in the entrypoint.
if [[ $(dpkg-query -l | grep postfix | wc -l) < 1 ]]; then
    apt-get update
    debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    apt-get install postfix bsd-mailx -y
    rm -rf /var/lib/apt/lists/*
fi

# Restart the Postfix service
service postfix restart
