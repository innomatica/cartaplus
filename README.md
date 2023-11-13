# Carta Plus

Note that this project uses Firebase backend. You may need to prepare your
own Firebase project and create a skeleton app with unique id, then copy 
necessay files from this repo. The process goes like this roughly.

## Cloud
* Create a [firebase project](https://firebase.google.com/docs/functions/get-started?gen=2nd)
* Set up [firebase authentication for google and email sign-in](https://firebase.google.com/docs/auth/flutter/start)
* Prepare [google sign in](https://pub.dev/packages/google_sign_in)

## Develoment Machine
* Create a [flutter project](https://stackoverflow.com/questions/49047411/flutter-how-to-create-a-new-project)
* Set up [firebase dev environment for the project](https://firebase.google.com/docs/functions/get-started?gen=2nd#set-up-your-environment-and-the-firebase-cli)
* Add [the app to the firebase](https://firebase.google.com/docs/flutter/setup?platform=ios)
* Initialize [firebase functions](https://firebase.google.com/docs/functions/get-started?gen=2nd#initialize-your-project)
* Deploy [the cloud functions](https://firebase.google.com/docs/functions/get-started?gen=2nd#deploy-functions-to-a-production-environment)

## WebDav Settings

As of this writing, only basic authentication is supported

### Apache

* `/etc/apache2/ports.conf`
```
Listen 80
# add port number of choice
Listen 8080
...
```

* `/etc/sites-available/your.domain.conf`
```
DavLockDB /usr/local/share/apache2/DavLock
<VirtualHost *:8080>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	Alias /webdav /var/www/webdav
	<Directory /var/www/webdav>
		DAV On
		AuthName "webdav"
		AuthType Basic
		AuthUserFile /usr/local/share/apache2/webdav-pass
		Require valid-user
	</Directory>
</VirtualHost>
```

* password files
```
sudo mkdir -p /usr/local/share/apache2
sudo hwpasswd -c webdav-pass username
sudo chown www-data:www-data /usr/local/share/apache2/webdav-pass
```

* davloc directory
```
sudo mkdir -p /usr/local/share/apache2/DavLock
sudo chown www-data:www-data /usr/local/share/apache2/DavLock
```

* modules
```
a2enmod auth_basic dav dav_fs
```

* site
```
a2ensite your.domain
systemctl restart apache2
```



### RClone
```
rclone serve webdav --addr :8080 --user username --pass password /var/www/webdav
```

### References

* [Apache HTTP Server Documentation](https://httpd.apache.org/docs/current/)
* [How to Install Apache Server on Debian 11](https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-debian-11)
* [How to Configure WebDav with Apache on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-configure-webdav-access-with-apache-on-ubuntu-18-04)
* [GitHub: awesome-webdav](https://github.com/fstanis/awesome-webdav)

## TODO

- Fix privilege issue when sign out
