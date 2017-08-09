
PagerDuty integrated Nagios
===========================

This Docker image installs and configures Nagios 4.3.2 on Ubuntu 14.04 with Nagios Plugins, Nagiosgraph, NRPE and, PagerDuty integration plugins as well.


## Usage

### Pull the image from Docker hub

```
docker pull sunggun/nagios
```

### Run the Container

```bash
docker run --name nagios -d \
  -v <your-nagios-etc-directory>:/usr/local/nagios/etc/ \
  -h <your-hostname>  \
  -p 80:80 sunggun/nagios:4.3.2
```

### Access to Nagios Dashboard
```
http://hostname
```

### Credential

Default user account and password is 

- User name : `nagiosadmin`
- Password : `nagios123`

You can change user name and password :

```
docker exec nagios htpasswd -c -b -s /usr/local/nagios/etc/htpasswd.users <username> <password>
```
