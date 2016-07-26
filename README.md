# Copyright/Disclaimer:

This was found on [uninformativ.de](https://www.uninformativ.de/blog/postings/2012-06-21/0/POSTING-de.html) several years ago and is a re-upload of https://github.com/vain/bin-pub/blob/master/soundizer . All credit belongs to Peter Hofmann (https://github.com/vain)


# Examples

    date | ./voice-of-kernel.sh
    date | ./voice-of-kernel.sh -a sine -b sine -c sine -M 3 -A 1 -D 1
    ./voice-of-kernel.sh -b saw -M 3 -A 1 -D 5 < /boot/vmlinuz-4.4.0-24-generic
