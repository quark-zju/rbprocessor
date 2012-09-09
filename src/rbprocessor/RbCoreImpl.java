package rbprocessor;

import com.topcoder.client.contestApplet.common.LocalPreferences;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import org.jruby.CompatVersion;
import org.jruby.embed.EvalFailedException;
import org.jruby.embed.ParseFailedException;
import org.jruby.embed.ScriptingContainer;

/**
 * Simple JRuby interface. This class is intended to be loaded by RbProcessor
 * via MyClassLoader and casted to RbCore to resolve Linkage problems.
 *
 * @author Wu Jun <quark@zju.edu.cn>
 */
public class RbCoreImpl extends RbCore {

    private ScriptingContainer container;
    private long newestScriptTime = -1;
    private static LocalPreferences pref = LocalPreferences.getInstance();
    private static boolean DEBUG = false;
    private static String[] userScriptPaths;

    {
        DEBUG = pref.getBoolean("rbprocessor.debug", false);
        MyClassLoader.setDebug(DEBUG);

        userScriptPaths = new String[]{
            pref.getProperty("rbprocessor.scriptpath", "rbprocessor.rb"),
            System.getProperty("user.home") + "/.rbprocessor.rb",
            System.getProperty("user.home") + "/.config/rbprocessor.rb"
        };
    }

    private void loadUserScriptOnDemand() throws FileNotFoundException {
        for (String path : userScriptPaths) {
            File file = new File(path);
            if (!file.exists()) {
                continue;
            }

            if (file.lastModified() > newestScriptTime) {
                if (DEBUG) {
                    System.err.println("Loading Script: " + path);
                }
                try {
                    container.runScriptlet(new FileInputStream(file), path);
                    newestScriptTime = file.lastModified();
                } catch (ParseFailedException | EvalFailedException ex) {
                    System.err.println("Script Error: " + path + ": " + ex);
                }
            }
            return;
        }

        throw new FileNotFoundException(userScriptPaths[0]);
    }

    public RbCoreImpl() throws FileNotFoundException {
        container = new ScriptingContainer();

        // Set container's classLoader to (MyClassLoader) to resolve
        // loading issues.
        //
        // See http://www.ruby-forum.com/topic/664018
        container.setClassLoader(container.getClass().getClassLoader());

        container.setCompatVersion(CompatVersion.RUBY1_9);

        loadUserScriptOnDemand();
    }

    @Override
    public Object[] runScript(String script) {
        try {
            loadUserScriptOnDemand();
        } catch (FileNotFoundException ex) {
            ;
        }

        Object[] results = null;
        try {
            results = (Object[]) container.runScriptlet("Array[" + script + "].flatten.to_java");
        } catch (ParseFailedException | EvalFailedException ex) {
            System.err.println(ex);
        }
        return results;
    }

    @Override
    public void setVariable(String name, Object value) {
        container.put(name, value);
    }
}
