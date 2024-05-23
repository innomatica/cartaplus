# Carta Plus

Carta Plus shares the same feature as [Carta](https://github.com/innomatica/carta)
except that it stores app information on the cloud. It allows users to 
maintain the same bookshelf over different devices. Also some communal reading
experience can be possible, such as in a classroom or bookclub situation.


# Note to Users

As of April 2024, this app is banned and its store is shut down from Google Play
due the violation of their Violent Extremism policy. This requires explanation 
for the current and future users of this app.

One of the features of this app is to allow users to freely navigate 
[Internet Archive](https://archive.org/) for their vast collection of audio 
materials using Android System [WebView](https://en.wikipedia.org/wiki/WebView). 
Then the app automatically detects information about audiobooks on their pages 
so that users can bring those to their bookshelves.

What Google alleges is that certain audio materials, arabic language ones 
specifically, on the aforementioned Internet Archive are regarded as extremism 
propaganda. And by extension, this app is promoting extremism.

Despite apparent absurdity of their reasoning, subsequent appeal yields no 
result. And the author has no intention to remove the link to Internet Archive. 
Thus from the version 2.6 onward, this app will be released as apk format 
directly from this repository until better alternative is found.

[Internet Archive](https://archive.org/) is a true historian in the age of 
internet. Please consider 
[supporting them](https://archive.org/donate?origin=iawww-TopNavDonateButton) 
and take time to think about how internet giants like Google and Facebook are 
shaping, thus inevitably distorting, our perception of reality.

# Future of the App

In the near future it is likely that this app is replaced by another, which does 
not rely on any commercial cloud service (Firebase in this case) in favor of a 
self-hosted backend server. Keep in mind that in such occasion, you need to 
spin up your own server and migrate your data by yourself. 

If you do not need communal reading experience, you probably do not need this
app. Thus we **highly encourage current users to switch to** 
[Carta](https://github.com/innomatica/carta).

# [How to Use this App](https://innomatica.github.io/carta/manual/)

## How to Build Your WebDAV Server

The easiest way is to use [Nextcloud](https://nextcloud.com/). You can use run 
your own server or you can use one of the 
[Nextcloud service prividers](https://nextcloud.com/partners/).

If you have a NAS, then you can spin up your WebDAV server using rclone or apache.

### Running RClone

```
rclone serve webdav --addr :8080 --user username --pass password /var/www/webdav
```

### Apache Settings

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

### References

- [How to Configure WebDav with Apache on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-configure-webdav-access-with-apache-on-ubuntu-18-04)
- [rclone serve webdav](https://rclone.org/commands/rclone_serve_webdav/)
