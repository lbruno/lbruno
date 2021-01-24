#!/bin/bash

wget --mirror --convert-links --page-requisites --adjust-extension --directory-prefix /var/www/blog.lbruno.org --no-host-directories https://lbruno.github.io{,/.well-known/keybase.txt}
find /var/www/blog.lbruno.org -type f -name '*.html' | while read; do
    echo editing $REPLY
    sed -i s/lbruno.github.io/blog.lbruno.org/ $REPLY
done
find /var/www/blog.lbruno.org -type f ! -name '*.gz' | while read; do
    echo gzipping $REPLY
    gzip --force --keep --name -9 $REPLY
done
