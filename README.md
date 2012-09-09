RbProcessor is a CodeProcessor plug-in that use Ruby script to preprocess and postprocess code.

[CodeProcessor](http://community.topcoder.com/contest/classes/CodeProcessor/CodeProcessor.jar) is a [TopCoder Arena plug-in](http://community.topcoder.com/tc?module=Static&d1=applet&d2=plugins).

Installation
============
1. Download `rbprocessor.jar` from [download page](/quark-zju/rbprocessor/downloads).
2. Append `rbprocessor.jar` to CodeProcessor class path.
   * Use ':' as separator in Linux.
3. Configure CodeProcessor
   * Use 'popsedit.EntryPoint' or Standard Editor as the Editor
     * [Poopsedit](http://community.topcoder.com/contest/classes/PopsEdit/PopsEdit.jar) is a standalone plugin.
     * Standard Editor's highlighting may not work. It seems it is caused by some bug of CodeProcessor.
     * Use FileEdit if you known what happens.
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

Other location is possible by editing `contestapplet.conf`, see below.

Builtin
-------
If RbProcessor can not find any of above files, a builtin script will be used.

Note: the builtin script is still a working-in-progress, may contain bugs.

The builtin script does:

* Code templates for C++, C#, Java and VB
    * Append problem description to code automatically. This can be disabled by
      `NO_PROBLEMDESC=true`
* Test code templates for C++, C#, Java and VB
    * Colorful output by default, can be disabled by `USE_COLOR=false`
* [Fileedit](http://community.topcoder.com/contest/classes/FileEdit/FileEdit.htm)-like external editor support
    * Can be disabled by `NO_CODE_DIR=true`. Do this if you use internal
      editor.
    * Code will be saved to `/tmp/tc/` by default, can be changed by `CODE_DIR`
      environment variable.
    * Do not overwrite code by default, set `CODE_OVERWRITE=true` to
      always overwrite external code.
* Postprocessor code (remove code between $BEGINCUT$ and $ENDCUT$)

It is recommended to read [the source](/quark-zju/rbprocessor/blob/master/lib/rbprocessor.rb) to see how it works.


Reload
------
`rbprocessor.rb` will be reloaded on the fly if change detected.

Content
------
`rbprocessor.rb` is Ruby 1.9 script, and should have two methods:

```ruby
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
```

See [CodeProcess Documentation](http://community.topcoder.com/contest/classes/CodeProcessor/How%20to%20use%20CodeProcessor%20v2.htm) for details.


contestapplet.conf
==================
You can change some options by editing this file:

* `rbprocessor.scriptpath=/path/to/rbprocessor.rb`: Load `rbprocessor.rb` from alternative path.
* `rbprocessor.poweredby=false`: Hide "Powered by" line.
* `rbprocessor.debug=true`: Print debug messages to stderr.


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


Building from Source
====================
`make` and you will get `rbprocessor.jar`. 

Links in `Makefile` may expire, in that case you may need to manually find `jruby-complete.jar` and `ContestApplet.jar`.

