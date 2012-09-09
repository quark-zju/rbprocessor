package rbprocessor;

/**
 * Abstract class defining simple JRuby interface.
 * 
 * @author Wu Jun <quark@zju.edu.cn>
 */
public abstract class RbCore {
    public abstract Object[] runScript(String script);
    public abstract void setVariable(String name, Object value);
}
