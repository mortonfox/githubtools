# githubtools

githubtools is a set of scripts to do simple things with Github. Currently,
these are as follows:

* github\_friends.rb: This script sorts your Github followers and following
  into 3 categories: mutual follows, only followers, and only following.
* latest\_rel.rb: This script shows a bit of information about the latest
  releases from the specified repositories.

## Usage

### github\_friends

Run the script with a username as the first argument. For example:

    ruby github_friends.rb mortonfox

### latest\_rel

Run the script with one or more Github repos as the arguments. This will give
you a one-line-per-repo summary of the latest release from each repo. For
example:

    $ ruby latest_rel.rb brave/browser-laptop brave/browser-android
    brave/browser-laptop: v0.7.16 Dev Channel at 2016-02-24 16:10
    brave/browser-android: v1.9.0 at 2016-02-24 19:53
    $

If you add the ```-l``` switch, the script adds information on available
downloads. For example:

    $ ruby latest_rel.rb -l brave/browser-laptop brave/browser-android
    brave/browser-laptop: v0.7.16 Dev Channel at 2016-02-24 16:10
     * Brave-Linux-x64.tar.bz2 (61.19 MB): https://github.com/brave/browser-laptop/releases/download/v0.7.16dev/Brave-Linux-x64.tar.bz2
     * Brave.dmg (79.21 MB): https://github.com/brave/browser-laptop/releases/download/v0.7.16dev/Brave.dmg
     * BraveSetup.exe (94.26 MB): https://github.com/brave/browser-laptop/releases/download/v0.7.16dev/BraveSetup.exe
     * tarball: https://api.github.com/repos/brave/browser-laptop/tarball/v0.7.16dev
     * zipball: https://api.github.com/repos/brave/browser-laptop/zipball/v0.7.16dev

    brave/browser-android: v1.9.0 at 2016-02-24 19:53
     * LinkBubble-playstore-release.apk (3.32 MB): https://github.com/brave/browser-android/releases/download/v1.9.0/LinkBubble-playstore-release.apk
     * tarball: https://api.github.com/repos/brave/browser-android/tarball/v1.9.0
     * zipball: https://api.github.com/repos/brave/browser-android/zipball/v1.9.0

    $
