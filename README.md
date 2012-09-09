RbProcessor is a CodeProcessor plug-in that use external Ruby script to preprocess and postprocess code.

[CodeProcessor](http://community.topcoder.com/contest/classes/CodeProcessor/CodeProcessor.jar) is a [TopCoder Arena plug-in](http://community.topcoder.com/tc?module=Static&d1=applet&d2=plugins).

Install
=======
1. Download `rbprocessor.jar` from download page
2. Append `rbprocessor.jar` to CodeProcessor class path
3. Configure CodeProcessor:

    *  Use 'popsedit.EntryPoint' or Standard Editor as the Editor
       (If you use Standard Editor, code highlighting may not working.
        You can do fileedit things in ruby script, thuns fileedit is
        not so useful, see following).
    *  Use 'rbprocessor.RbProcessor' as the CodeProcessor.

4. Write `$HOME/.config/rbprocessor.rb` or `$HOME/.rbprocessor.rb`.
 

rbprocessor.rb
==============

Location
--------
`rbprocessor.rb` can be located at:

* $PWD/rbprocessor.rb
* $HOME/.config/rbprocessor.rb
* $HOME/.rbprocessor.rb

RbProcessor has one buildin `rbprocessor.rb`.
If RbProcessor can not find above files, builtin one will be used.

Other location is possible by editing `contestapplet.conf`, see below.

Reload
------
`rbprocessor.rb` will be reloaded on the fly if change detected.

Content
------
`rbprocessor.rb` is Ruby 1.9 script, and should have two methods:

    def preprocess(src, lang, prob, render)
        # $src, $lang, $prob, $render are available too

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

See [CodeProcess Documentation](http://community.topcoder.com/contest/classes/CodeProcessor/How%20to%20use%20CodeProcessor%20v2.htm) for details.


contestapplet.conf
==================
You can change some options by editing this file:

* `rbprocessor.scriptpath=/path/to/rbprocessor.rb`

     Load `rbprocessor.rb` from alternative path.

* `rbprocessor.poweredby=false` 

    Hide "Powered by" line.

* `rbprocessor.debug=true`

    Print debug messages to stderr.


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


Build
=====
`make` and you will get `rbprocessor.jar`. 

Links in `Makefile` may expire, you may need to manually find `jruby-complete.jar` and `ContestApplet.jar` then.

