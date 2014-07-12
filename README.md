skeleton
========

Creates skeleton directories and files based upon skeleton files

Features:
* Basic file manipulation format
* Github repository integration
* Github gist integration
* Regex find and replace within files
* Arguments from command line ($0..$x)

Basic file manipulatuion format:

```
# Simple skeleton descriptor
#comment
# comment 2
dir_here/
mkdir dir_here2
regex package.json
    $NAME
    $0
mkdir dir3%20/docs
mynewfile relpath
dlfile myfile repo@user/somedir/somefile.d
rmdir byebye
```
The first line is required. This is simply a way to say what format the descriptor is in.<br/>
Comments are prepended by # on its own line.

Note it is based upon no spaces. If you want spaces in arguments, use %20 escaping.

TODO
-----
Lua support
