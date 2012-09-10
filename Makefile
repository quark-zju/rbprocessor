JAVAC_FLAGS=-d bin -Xlint:unchecked -cp src:lib/jruby-complete.jar:lib/ContestApplet.jar -source 7

.PHONY: all clean

all: rbprocessor.jar

lib/jruby-complete.jar:
	-@mkdir -p lib
	wget http://jruby.org.s3.amazonaws.com/downloads/1.7.0.preview2/jruby-complete-1.7.0.preview2.jar -O $@

lib/ContestApplet.jar:
	-@mkdir -p lib
	wget http://community.topcoder.com/contest/classes/ContestApplet.jar -O $@

bin/%.class: src/%.java lib/jruby-complete.jar lib/ContestApplet.jar
	javac $(JAVAC_FLAGS) $<

rbprocessor.jar: bin/rbprocessor/RbProcessor.class bin/rbprocessor/MyClassLoader.class bin/rbprocessor/RbCore.class bin/rbprocessor/RbCoreImpl.class lib/rbprocessor.rb lib/jruby-complete.jar
	cp lib/jruby-complete.jar $@
	jar uf $@ -C bin .
	jar uf $@ lib/rbprocessor.rb

clean:
	-rm -rf rbprocessor.jar bin/*

