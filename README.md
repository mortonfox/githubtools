# githubtools

githubtools is a set of scripts to do simple things with Github. Currently,
these are as follows:

* github\_friends.rb: This script sorts your Github followers and following
  into 3 categories: mutual follows, only followers, and only following.
* latest\_rel.rb: This script shows a bit of information about the latest
  releases from the specified repositories.
* backup\_gists.rb: Downloads all of a user's gists, ready for backup.
* backup\_repos.rb: Downloads all of a user's repositories. Produces a git
  bundle and a zip file for each repository.

## Installation

The scripts use the octokit and git Ruby gems. In addition, the netrc gem is
recommended too, as explained in the Authentication section below.

Thus, run the following:

    gem install octokit git netrc

## Authentication

Although githubtools will work fine without Github authentication, it won't be
able to access private gists and repositories and it will be rate-limited by
the Github API.

githubtools uses the [netrc gem](https://github.com/heroku/netrc) to retrieve
login credentials from a
[.netrc file](http://www.gnu.org/software/inetutils/manual/html\_node/The-\_002enetrc-file.html)
in your home directory.

Although adding your Github password to the .netrc file would work, I suggest
using a personal access token instead because it is easier to revoke if there
is a security breach.

To generate an access token:

* Go to <https://github.com/settings/tokens> and click on "Generate new token".
* Fill in an appropriate token description and select the "gist" scope. (That
  is for the backup\_gists script.)
* Click on "Generate token".
* The next screen will show the access token. Copy it.

Add the following to the .netrc file in your home directory:

    machine api.github.com
        login githublogin
        password accesstoken

where ```githublogin``` is your Github user name and ```accesstoken``` is the
access token that you copied from the last step above. The githubtools scripts
should now be able to use your Github account for API access.

## Usage

### github\_friends

Run the script with a username as the first argument. For example:

    ruby github_friends.rb mortonfox

You can control what this script outputs using the -m, -r, and -o options:

    bash-4.3$ ruby github_friends.rb -h
    Usage: github_friends.rb [options] username
        -h, -?, --help                   Option help
        -m, --mutual                     Show mutual friends
        -r, --only-friends               Show only-friends
        -o, --only-followers             Show only-followers
    If none of -m/-r/-o are specified, display all 3 categories.
    bash-4.3$

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

### backup\_gists

Run this script with a username as the first argument. The script will do the
following:

* Create a folder named gists.
* git clone each of the user's gists under that folder.

### backup\_repos

Run this script with a username as the first argument. The script will do the
following:

* Create a folder named repos.
* git clone each of the user's repositories, excluding forks of other repositories.
* Create a git bundle for each repository.
* Use git archive to create a zip file of each repository.
* Delete the cloned repositories.

