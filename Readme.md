# Project YCMenu (not final name)
### A [RubyMotion](http://www.rubymotion.com/) Mac application.

This is a system bar application that fetches the top items from HackerNews every 2 minutes. Clicking on the link will take you to the linked URL.

The application will remember which links you've clicked before!

---
[![Code Climate](https://codeclimate.com/github/MohawkApps/YCMenu.png)](https://codeclimate.com/github/MohawkApps/YCMenu) [![Stories in Ready](https://badge.waffle.io/MohawkApps/YCMenu.png)](http://waffle.io/MohawkApps/YCMenu)
---

## Running the app

### Prerequisites:

1. XCode 5 with current Mac SDK.
2. You must have a registered and licensed copy or RubyMotion on your computer. If you do not, you will need to [purchase a license here](http://www.rubymotion.com/). You should always be renning the most recent version of RubyMotion.

## Compiling:

1. ```cd``` into the directory and run ```bundle update```
2. Run ```rake``` and the application will build and launch in your system bar.

## ToDo:

* Create a custom view to include:
	* Number of comments
	* Title
	* Number of upvotes
* Allow the user to go directly to comments **or** URL of the news item
* Make it prettier
* ~~Remember what URLS the user clicked and indicate it to them somehow~~
* …
* Design large (1024px) icon
* Come up with marketing material
* Submit to the Mac App Store
