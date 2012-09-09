JAVAC_FLAGS=-d bin -Xlint:unchecked -cp src:lib/jruby-complete.jar:lib/ContestApplet.jar -source 7

.PHONY: all clean lib

all: rbprocessor.jar

lib: lib/jruby-complete.jar lib/ContestApplet.jar 
	-@mkdir -p bin
	true

lib/jruby-complete.jar:
	wget http://jruby.org.s3.amazonaws.com/downloads/1.7.0.preview2/jruby-complete-1.7.0.preview2.jar -O $@

lib/ContestApplet.jar:
	wget http://community.topcoder.com/contest/classes/ContestApplet.jar -O $@

bin/%.class: src/%.java
	javac $(JAVAC_FLAGS) $^

rbprocessor.jar: bin/rbprocessor/RbProcessor.class bin/rbprocessor/MyClassLoader.class bin/rbprocessor/RbCore.class bin/rbprocessor/RbCoreImpl.class
	cp lib/jruby-complete.jar $@
	jar uf $@ -C bin .

clean:
	-rm -rf rbprocessor.jar bin/*

