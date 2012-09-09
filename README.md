RbProcessor is a CodeProcessor plug-in that use external Ruby script to preprocess and postprocess code.

Install
=======
1. Download `rbprocessor.jar` from download page
2. Append `rbprocessor.jar` to CodeProcessor class path
3. Prepare a `$HOME/.config/rbprocessor.rb` or `$HOME/.rbprocessor.rb`.

rbprocessor.rb
==============
`rbprocessor.rb` must have two methods:

    def preprocess(src, lang, prob)
        # Makes $HELLO$ tag available
        user_tags     = { hello: 'world' }

        # If you want to use FileEdit's code template,
        # set processed_src to ''
        processed_src = "main() {\n\n}"

        [processed_src, user_tags]
    end

    def postprocess(src, lang)
        processed_src = src.gsub(/^\s+$/, '')

        # postprocess only process code, no user tags
        processed_src
    end

`rbprocessor.rb` is reloaded on the fly if change detected.


Dependencies
============
Common
------
* Java 1.7
* Topcoder Arena 6.5

Use
---
* CodeProcessor Arena plug-in

Build
-----
* JRuby 1.7 jruby-complete.jar


contestapplet.conf
==================
You can change some options by editing this file:

* `rbprocessor.scriptpath=/path/to/rbprocessor.rb`

     Load `rbprocessor.rb` from alternative path.

* `rbprocessor.poweredby=false` 

    Hide "Powered by" line.

* `rbprocessor.debug=true` to hide "Powered by" line.

    Print debug messages to stderr.

Build
=====
`make` and you will get `rbprocessor.jar`. 
If the link in `Makefile` is out-dated, you may need 

