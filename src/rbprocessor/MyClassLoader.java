package rbprocessor;

import java.net.URL;
import java.net.URLClassLoader;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Custom class loader, load class from custom URLs, if failed or class name is
 * blacklisted, load from parent class loader.
 *
 * @author Wu Jun <quark@zju.edu.cn>
 */
public class MyClassLoader extends URLClassLoader {

    private static boolean DEBUG = false;
    private Set<String> blacklistClasses = new HashSet<>();
    private static Map<String, Class<?>> parentLoadedClasses = new HashMap<>();

    public MyClassLoader(URL[] urls) {
        super(urls);
    }

    public MyClassLoader(URL[] urls, String[] blacklist) {
        super(urls);
        this.blacklistClasses.addAll(Arrays.asList(blacklist));
    }

    @Override
    public Class<?> loadClass(String name) throws ClassNotFoundException {
        Class<?> klass = findLoadedClass(name);

        if (klass != null) {
            // Already loaded in this class loader
            return klass;
        }

        try {
            // Try to load using this class loader
            if (!blacklistClasses.contains(name)) {
                klass = findClass(name);
                if (DEBUG) {
                    System.err.println("Class: " + name + " is loaded.");
                }
            } else {
                if (DEBUG) {
                    System.err.println("Class: " + name + " skip loading.");
                }
            }
        } catch (ClassNotFoundException e) {
            klass = null;
        }

        if (klass == null) {
            // Load from static cache of parent class loader
            //
            // This is a workaround for the situation
            // there are ONE parent class loader
            // and many MyClassLoader
            // 
            // Parent class loader may use "forName"
            // use it across different MyClassLoader
            // may cause LinkageError in parent class loader:
            //   "attempted  duplicate class definition"
            if (parentLoadedClasses.containsKey(name)) {
                klass = parentLoadedClasses.get(name);
                if (DEBUG) {
                    System.err.println("Class: " + name + " ... using parent's cache");
                }
            }
        }

        if (klass == null) {
            // Load from parent class loader
            //
            // Not using 'super' here because parent class loader
            // could be non-standard too.
            if (DEBUG) {
                System.err.println("Class: " + name + " ... using parent's");
            }

            ClassLoader parentLoader = MyClassLoader.class.getClassLoader();
            klass = parentLoader.loadClass(name);

            if (klass != null) {
                parentLoadedClasses.put(name, klass);
            }
        }
        return klass;
    }
}
