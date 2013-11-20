# Hacker Bar
### A [RubyMotion](http://www.rubymotion.com/) Mac application.

This is a system bar application that fetches the top items from HackerNews every 5 minutes. Clicking on the link will take you to the linked URL.

The application will remember which links you've clicked before!

---
[![Code Climate](https://codeclimate.com/github/MohawkApps/Hacker-Bar.png)](https://codeclimate.com/github/MohawkApps/Hacker-Bar) [![Stories in Ready](https://badge.waffle.io/MohawkApps/Hacker-Bar.png)](http://waffle.io/MohawkApps/Hacker-Bar) [![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/MohawkApps/hacker-bar/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
---

## Compiling:

### Prerequisites:

1. XCode 5 with current Mac SDK.
2. You must have a registered and licensed copy or RubyMotion on your computer. If you do not, you will need to [purchase a license here](http://www.rubymotion.com/). You should always be running the most recent version of RubyMotion.

```cd``` into the directory and run ```bundle update```

From there, use the `make` command to build the app. There are a few `make` options:

1. `make run` - builds the app and runs it.
2. `make runclean` - cleans all targets before running.
3. `make build` - builds the app for distribution.
4. `make release` - builds the app for app store release.
