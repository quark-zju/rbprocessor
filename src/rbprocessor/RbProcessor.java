package rbprocessor;

import com.topcoder.client.contestApplet.common.LocalPreferences;
import com.topcoder.client.contestant.ProblemComponentModel;
import com.topcoder.shared.language.Language;
import com.topcoder.shared.problem.Renderer;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

/**
 * Ruby Processor. A sub plug-in for TopCoder Arena plug-in CodeProcessor, use
 * external Ruby script to pre/post process code and define custom tags.
 *
 * @author Wu Jun <quark@zju.edu.cn>
 */
public class RbProcessor {

    private static LocalPreferences pref = LocalPreferences.getInstance();
    private static MyClassLoader loader;
    private RbCore rb;
    private Map<String, String> tags = new HashMap<>();

    {
        try {
            String selfJarPath = RbProcessor.class.getProtectionDomain().getCodeSource().getLocation().getPath();

            // A custom class loader seems to be a must 
            // to resolve JRuby class load issue.
            // 
            // Using container.setLoadPaths() or
            // hacking system class paths 
            // won't resolve class load problem.
            // 
            // RbCore, RbProcessor, MyClassLoader use 
            //   default (Topcoder's) class loader
            // RbCoreImpl uses custom class loader 
            //   MyClassLoader
            //
            // See http://jira.codehaus.org/browse/JRUBY-4106
            loader = new MyClassLoader(
                    new URL[]{
                        new URL("file:" + selfJarPath + "!/META-INF/jruby.home"),
                        new URL("file:" + selfJarPath)
                    },
                    new String[]{
                        "rbprocessor.RbCore"
                    });
        } catch (MalformedURLException ex) {
            System.err.println(ex);
        }
    }

    public RbProcessor() throws ClassNotFoundException, InstantiationException, IllegalAccessException {
        rb = (RbCore) loader.loadClass("rbprocessor.RbCoreImpl").newInstance();
    }

    public String preProcess(String source, ProblemComponentModel component, Language language, Renderer renderer) {
        rb.setVariable("@src", source);
        rb.setVariable("@prob", component);
        rb.setVariable("@lang", language);

        Object[] results = rb.runScript("preprocess(@src, @lang, @prob)");

        switch (results.length) {
            case 0:
                return source;
            case 1:
                return (String) results[0];
            default:
                @SuppressWarnings("unchecked") Map customTags = (Map) results[1];
                this.tags = new HashMap<>();
                for (Object k : customTags.keySet()) {
                    String tag = "$" + k.toString().toUpperCase() + "$";
                    this.tags.put(tag, customTags.get(k).toString());
                }
                return (String) results[0];
        }
    }

    public String postProcess(String source, Language language) {
        rb.setVariable("@src", source);
        rb.setVariable("@lang", language);

        Object[] results = rb.runScript("postprocess(@src, @lang)");

        if (results.length >= 1) {
            source = (String) results[0];
        }

        if (pref.getBoolean("rbprocessor.poweredby", true)) {
            String commentPrefix = language.getName().equals("VB") ? "'" : "//";
            source += "\n" + commentPrefix + " Powered by RbProcessor v0.1";
        }

        return source;
    }

    public Map getUserDefinedTags() {
        return this.tags;
    }
}
