# Carta Plus

Carta Plus is [Carta](https://github.com/innomatica/carta) with a backend server, through
which you can share your audiobooks.

# Note to Users

As of April 2024, this app is banned and its store is shut down from Google Play due the violation of their Violent Extremism policy. This requires explanation for the current and future users of this app.

This app is designed to listen to free online audiobooks from

- [LibriVox](https://librivox.org/)
- [Internet Archive](https://archive.org/)
- [Legamus](https://legamus.eu/blog/)

You can navigate those websites within the app using Android System [WebView](https://en.wikipedia.org/wiki/WebView) feature. Then the app automatically detects information about audiobooks on their pages and allows you to bring them to your bookshelf.

What Google alleges is that certain audio materials, arabic language ones specifically, on the aforementioned Internet Archive are regarded as extremism propaganda. And by extension, this app is promoting extremism. Too easy!

Despite apparent absurdity of their reasoning, subsequent appeal yields no result. And the author has no intention to remove the link to Internet Archive. Thus from the version 2.6 onward, this app will be released as apk format directly from this repository until better alternative is found.

[Internet Archive](https://archive.org/) is a true historian in the age of internet. Please consider [supporting them](https://archive.org/donate?origin=iawww-TopNavDonateButton) and take time to think about how internet giants like Google and Facebook are shaping, thus inevitably distorting, our perception of reality.

## WebDav Settings

Note: as of this writing, only basic authentication is supported

### Apache

- `/etc/apache2/ports.conf`

```
Listen 80
# add port number of choice
Listen 8080
...
```

- `/etc/sites-available/your.domain.conf`

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

- password files

```
sudo mkdir -p /usr/local/share/apache2
sudo htpasswd -c webdav-pass username
sudo chown www-data:www-data /usr/local/share/apache2/webdav-pass
```

- davloc directory

```
sudo mkdir -p /usr/local/share/apache2/DavLock
sudo chown www-data:www-data /usr/local/share/apache2/DavLock
```

- modules

```
a2enmod auth_basic dav dav_fs
```

- site

```
a2ensite your.domain
systemctl restart apache2
```

### RClone

```
rclone serve webdav --addr :8080 --user username --pass password /var/www/webdav
```

### References

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/current/)
- [How to Install Apache Server on Debian 11](https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-debian-11)
- [How to Configure WebDav with Apache on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-configure-webdav-access-with-apache-on-ubuntu-18-04)
- [rclone serve webdav](https://rclone.org/commands/rclone_serve_webdav/)
