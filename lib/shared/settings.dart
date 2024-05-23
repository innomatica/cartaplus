// app info
import 'package:flutter/material.dart';

const appId = 'com.innomatic.cartaplus';
const appName = 'Carta Plus';
const appVersion = '2.6.0+35';
const emailDeveloper = 'nuntium.ubique@gmail.com';
const androidNotificationChannelId = 'com.innomatic.cartaplus.channel.audio';
const androidNotificationChannelName = 'Carta playback';

// asset images
const defaultAlbumImage = 'assets/images/open-book-512.png';
const defaultLibriVoxImage = 'assets/images/book-cover-150x150.gif';
const bookPanelBgndImage = 'assets/images/house_of_books.jpg';
const sourceRepoUrlQrCode = 'assets/images/com.innomatic.cartaplus.png';

// urls
const urlHomePage = 'https://www.innomatic.ca';
const urlSourceRepo = 'https://github.com/innomatica/cartaplus';
const urlAppRelease = 'https://github.com/innomatica/cartaplus/releases';
const urlPrivacyPolicy = 'https://innomatica.github.io/cartaplus/privacy/';
const urlDisclaimer = 'https://innomatica.github.io/cartaplus/disclaimer/';
const urlInstruction = 'https://innomatica.github.io/cartaplus/manual/';
const urlAppIconSource = 'https://www.flaticon.com/free-icon/open-book_1940795';
const urlStoreImageSource = 'https://unsplash.com/@florenciaviadana';

// github
const githubUser = 'innomatica';
const githubRepo = 'cartaplus';

// selected books
const urlSelectedBooksJson =
    'https://raw.githubusercontent.com/innomatica/carta/master/extra/data/'
    'selected_books.json';

// hint texts
const urlLibriVoxDoHyangNa =
    'https://librivox.org/short-stories-by-do-hyang-na/';
const urlIaTheHobbit = 'https://archive.org/details/the-hobbit-bbc-radio-drama';
const urlIaTheHobbitImage =
    'https://archive.org/details/the-hobbit-bbc-radio-drama';
const titleIaTheHobbit = 'The Hobbit (BBC Radio Dramatization)';
const authorIaTheHobbit = 'J.R.R. Tolkin';

// default sites
const urlDefaultSearch = 'https://duckduckgo.com';
const urlDefaultTextSite = 'https://www.gutenberg.org/';

// sleep timer setting
const sleepTimeouts = [30, 20, 10, 5, 60];

// enable download
const bool enableDownload = true;

// initial window size
double initialWindowWidth = 0;
double initialWindowHeight = 0;
bool isScreenWide = false;

// bottom padding
const double bottomPadding = 52.0;

// seed color
const seedColorLight = Colors.indigoAccent;
const seedColorDark = Colors.indigoAccent;

// account limits
const int maxBooksToCreate = 50;
const int maxLibrariesToJoin = 5;
const int maxLibrariesToCreate = 1;

// for testing only
const useEmulator = false;
