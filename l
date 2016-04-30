#! /usr/bin/env python
# -*- coding: utf-8 -*-

from glob import glob
from stat import *
import os

REPO = "\033[95;1m"
DESC = "\033[96m"
BLUE = "\033[34;1m"
NONE = "\033[0m"

LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.flac=01;35:*.mp3=01;35:*.mpc=01;35:*.ogg=01;35:*.wav=01;35:*.java=92:'

def get_screen_cols():
    try:
        import os
        f = os.popen("tput cols")
        n = int(f.read())
        f.close()
        return n
    except:
        return 80

screen_cols = get_screen_cols()

hidden_files = None

def git_info(repo):
    try:
        oldwd = os.getcwd()
        os.chdir(repo)

        try:
            f = open(".git/description", "r")
            desc = f.read().strip()
            f.close()
        except:
            desc = ""

        if desc.startswith("Unnamed repository"):
            desc = ""

        f = os.popen("git log --max-count=1 --pretty=raw . 2> /dev/null", "r")

        reading_comment = 0
        for line in f:
            if line.startswith("author"):
                date = int(line.split()[-2])
                import time
                date = time.strftime("%Y-%m-%d %H:%M", time.localtime(date))
            elif line == "\n":
                reading_comment = 1
            elif reading_comment:
                comment = line.strip()
                break

        f.close()

        if len(desc) > 20:
            desc = desc[:18] + "..."
        else:
            desc = "%-21s" % desc

        return "%s %s  %s" % (desc, date, comment)
    finally:
        os.chdir(oldwd)

def is_hidden(filename):
    global hidden_files

    if hidden_files is None:
        try:
            f = open(".hidden", "r")
            hidden_files = dict([(x.strip(), 1) for x in f])
            f.close()
        except IOError:
            hidden_files = []

    return filename in hidden_files

def get_color(filename, mode):
    import fnmatch

    if S_ISLNK(mode):
        filename = "ln"
    elif S_ISDIR(mode):
        filename = "di"
    elif mode & S_IEXEC:
        filename = "ex"

    for spec in LS_COLORS.split(":"):
        if spec == "":
            continue

        pattern, color = spec.split("=")
        if fnmatch.fnmatch(filename, pattern):
            return color

    return "00"

def get_suffix(mode):
    if S_ISLNK(mode):
        return "@"
    elif S_ISDIR(mode):
        return "/"
    elif mode & S_IEXEC:
        return "*"

    return ""

stuff = []

for entry in glob("*"):
    if is_hidden(entry):
        continue

    mode = os.lstat(entry)[ST_MODE]

    color = get_color(entry, mode)

    if S_ISREG(mode):
        stuff.append((2, entry, mode, color, ""))
    else:
        try:
            stuff.append((0, entry, mode, "31;1", git_info(entry)))
        except:
            stuff.append((1, entry, mode, color, ""))

def print_cols(items):
    items.sort()
    longest_item = max([len(x[1]) for x in items]) + 2
    col = 0

    for item in items:
        if col + longest_item > screen_cols:
            col = 0
            print

        entry, mode, color, description = item[1:]

        if description:
            text = "%s%-*s %s%s" % (REPO, longest_item,
                                  entry + get_suffix(mode),
                                  DESC, description)
            text = text[0:screen_cols + len(REPO) + len(DESC)]
            print text + NONE

            col = 0
            continue

        print "\033[%sm%-*s" % (color,
                                longest_item + len(NONE),
                                entry + NONE + get_suffix(mode)),

        col += longest_item + 2

    print

print_cols(stuff)
