# githubtools

<!-- vim-markdown-toc GFM -->

* [Introduction](#introduction)
* [Installation](#installation)
    * [Set up OAuth app](#set-up-oauth-app)
    * [Set up config file](#set-up-config-file)
* [Usage](#usage)
    * [github\_friends](#github_friends)
    * [latest\_rel](#latest_rel)
    * [backup\_gists](#backup_gists)
    * [backup\_repos](#backup_repos)
    * [search\_and\_del](#search_and_del)

<!-- vim-markdown-toc -->

## Introduction

githubtools is a set of scripts to do simple things with Github. Currently, these are as follows:

* github\_friends.rb: This script sorts your Github followers and following into 3 categories: mutual follows, only followers, and only following.
* latest\_rel.rb: This script shows a bit of information about the latest releases from the specified repositories.
* backup\_gists.rb: Downloads all of a user's gists, ready for backup.
* backup\_repos.rb: Downloads all of a user's repositories. Produces a git bundle and a zip file for each repository.
* search\_and\_del.rb: Search for fork repos with names matching the given string and offer to delete them.

## Installation

Get the repo:

```sh
git clone git@github.com:mortonfox/githubtools.git
cd githubtools
```

Install gems:

```sh
bundle install
```

### Set up OAuth app

Go to <https://github.com/settings/developers> and click on "New OAuth App".

Enter the following:

* Application name: githubtools
* Homepage URL: http://github.com/mortonfox/githubtools
* Authorization callback URL: http://localhost:3501/callback

Click on "Generate a new client secret".

Save both the Client ID and Client Secret for later.

### Set up config file

Create a new file ``~/.githubtools.conf`` with the following content:

```
port = 3501
token_file = "~/.githubtools.token"
client_id = CLIENT_ID
client_secret = CLIENT_SECRET
```

Where CLIENT_ID and CLIENT_SECRET are the Client ID and Client Secret you saved earlier.

## Usage

### github\_friends

Run the script with a username as the first argument. For example:

```sh
bundle exec ./github_friends.rb mortonfox
```

You can control what this script outputs using the -m, -r, and -o options:

```console
$ bundle exec ./github_friends.rb -h
Usage: github_friends.rb [options] username
    -h, -?, --help                   Option help
    -m, --mutual                     Show mutual friends
    -r, --only-friends               Show only-friends
    -o, --only-followers             Show only-followers
        --auth                       Ignore saved access token and force reauthentication
        --config-file=FNAME          Config file name. Default is /home/pcheah/.githubtools.conf
  If none of -m/-r/-o are specified, display all 3 categories.
```

### latest\_rel

Run the script with one or more Github repos as the arguments. This will give you a one-line-per-repo summary of the latest release from each repo. For example:

```console
$ bundle exec ./latest_rel.rb brave/browser-laptop brave/browser-android
brave/browser-laptop: v0.7.16 Dev Channel at 2016-02-24 16:10
brave/browser-android: v1.9.0 at 2016-02-24 19:53
```

If you add the ``-l`` switch, the script adds information on available downloads. For example:

```console
$ bundle exec ./latest_rel.rb -l brave/browser-laptop brave/browser-android
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

```

For usage info:

```console
$ bundle exec ./latest_rel.rb -h
Usage: latest_rel.rb [options] owner/repo [owner/repo ...]
    -h, -?, --help                   Option help
    -l, --long                       Long format
    -d, --debug                      Debug mode
```

### backup\_gists

Run this script with a username as the first argument. The script will do the following:

* Create a folder named gists.
* git clone each of the user's gists under that folder.

### backup\_repos

Run this script with no argument to backup the authenticated user's repos. This mode of operation will back up both public and private repos.

Run this script with a username as the first argument to backup that user's public repos.

The script will do the following:

* Create a folder named repos.
* git clone each of the user's repositories, excluding forks of other repositories.
* Create a git bundle for each repository.
* Use git archive to create a zip file of each repository.
* Delete the cloned repositories.

### search\_and\_del

Use this script to clean up unnecessary fork repos. Usually, it's okay to delete a fork after the pull request has been merged. You may also delete the fork before the pull request has been merged but you'll need [a workaround to resurrect the pull request](https://github.com/isaacs/github/issues/168#issuecomment-374201226) if you wish to continue working on it. So use this script *at your own risk*.

Run this script with a search string as the first argument. The script will look for fork repos matching the search string and offer to delete them. If there are fork repos that you with to exclude from this search, add "#keep" to their descriptions.
