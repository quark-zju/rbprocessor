package rbprocessor;

public abstract class RbCore {
    public abstract Object[] runScript(String script);
    public abstract void setVariable(String name, Object value);
}
