# -------------------------------------------------------------------------------------
#  Initializing Pagerduty Plugin
# -------------------------------------------------------------------------------------

if [[ $(dpkg-query -l | grep pdagent | wc -l) < 1 ]]; then
    wget -O - https://packages.pagerduty.com/GPG-KEY-pagerduty | apt-key add
    sh -c 'echo "deb https://packages.pagerduty.com/pdagent deb/" >/etc/apt/sources.list.d/pdagent.list'
    apt-get update
    apt-get install -y pdagent pdagent-integration
    rm -rf /var/lib/apt/lists/*
fi

rm /var/run/pdagent/pdagentd.pid
service pdagent restart
