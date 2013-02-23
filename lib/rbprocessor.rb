# External source code directory, nil disables external editing
CODE_DIR    = ENV['NO_CODE_DIR'] ? nil : (ENV['CODE_DIR'] || '/tmp/tc')
# Overwrite external source file if it exists?
OVERWRITE   = (ENV['CODE_OVERWRITE'].to_s.downcase == 'true')
USE_COLOR   = ((ENV['USE_COLOR'] || 'true').to_s.downcase == 'true')

CUT_BEGIN   = "BEGIN CUT HERE"
CUT_END     = "END CUT HERE"
EXEDIT_TIP  = "Please use external editor to edit:\n" 
PROBLEMDESC = ENV['NO_PROBLEMDESC'] ? '' : "\n$PROBLEMDESC$"

CARET_POS   = ''

def debug(*s)
  STDERR.puts *s
end

class String
  def cuted;                 self.gsub(/\n#{LANG_COMMENT[$lang]}\s*#{CUT_BEGIN}.*?#{CUT_END}/m,''); end
  def apply_tags(tags);      tags.inject(self) { |s,kv| s.gsub "$#{kv[0].to_s.upcase}$", kv[1] }; end
  def presence;              self.empty? ? nil : self; end
  def with_cut(title = '');  "#{LANG_COMMENT[$lang]} #{[CUT_BEGIN, title.presence].join(': ')}\n#{self.chomp}\n#{LANG_COMMENT[$lang]} #{CUT_END}"; end
end

class CodeHistory
  def initialize;            @history = {}; end
  def put src, tag = 1;      @history[normalize(src)] = tag; src; end
  def has? src;              @history.has_key? normalize(src); end
  def get src;               @history[normalize(src)]; end

  private
  def normalize s; s.cuted.gsub(/\s+/m, '').hash; end
end

LanguageHistory = CodeHistory.new

LANG_EXT     = ->l {{ 'Java' => '.java', 'C++' => '.cc', 'C#' => '.cs', 'Python' => '.py', 'VB'  => '.vb' }[l.name]}
LANG_COMMENT = ->l {l.name == 'VB' ? "'" : '//'}

# test code generator
class TestCodeGenerator
  require 'erb'

  def initialize
    @long_postfix  = 'L'
    @bool          = 'bool'
    @color_code    = '\\x1b['
    @public        = 'public '
  end

  def result
    [testcode.with_cut('TEST'), maincode.with_cut('MAIN')]
  end

  def ret_type
    $prob.return_type.descriptor($lang)
  end

  def color_str(content, mode = 1)
    USE_COLOR ? "#{@color_code}#{mode}m#{content}#{@color_code}0m" : content
  end

  def print_expr(*vars); nil end

  def equal_expr(type, names)
    names.join(' == ')
  end

  def param(id, type, value)
    if type.dimension == 0
      "#{type.descriptor($lang)} _#{id} = #{value}#{type.base_name.downcase['long'] ? @long_postfix : ''}"
    else
      "#{type.descriptor($lang)} _#{id} = #{value.gsub("\n", ' ')}"
    end
  end

  def testcode
    ERB.new(@ap + <<-'EOS'
    <%= @bool %> _verify(int No, <%= ret_type %> Expected, <%= ret_type %> Received) { <%= print_expr 'Case ', :No, '  ' %> if (<%= equal_expr($prob.return_type, ['Expected','Received']) %>) { <%= print_expr color_str('PASS', '1;32'), "\n" %> return false;} else { <%= "#{print_expr color_str('FAILED', '1;31'), "\n\tExpected: "}; _ap(Expected); #{print_expr "\n\tReceived: "}; _ap(Received); #{print_expr '\n'}" %> return true; } }
    <%= @public %>int run_test(int kase) { int no = -1, failed = 0, passed = 0;<% $prob.test_cases.each_with_index do |kase, i| %>
        if (kase == ++no || kase < 0) { // <%= i %><% n = kase.input.size %><% kase.input.zip([*0...n], $prob.param_types).each do |input, id, type| %>
            <%= param id, type, input %>;<% end %>
            <%= param 'r', $prob.return_type, kase.output %>;
            if (_verify(no, _r, <%= $prob.method_name %>(<%= n.times.to_a.map{|j| "_#{j}" }.join(', ') %>))) { failed = no + 1; <%= print_expr color_str("\tInput\n", '4;33') %><%= n.times.map {|j| "_ap(_#{j}, \"\\t\");" }.join %> } else passed++;
        }<% end %>
        return failed != 0 ? failed : (passed == 0 ? -1 : 0);
    }
    EOS
    ).result(binding)
  end

  def maincode
    ERB.new(<<-EOS
    public static void <%= @main %> {
        <%= $prob.class_name %> t = new <%= $prob.class_name %>();
        <%= @exit %>(t.run_test(args.<%= @length %> > 0 ? <%= @parseint %>(args[0]) : -1));
    }
    EOS
    ).result(binding)
  end

  class CPPTestCodeGenerator < self
    def initialize
      super
      @long_postfix = 'LL'
      @public = ''
      @ap = <<-'EOS'
    template <typename T> void _ap(const vector<T> &V, const char * prefix = "") { cerr << prefix << "{ "; for (typename vector<T>::const_iterator iter = V.begin(); iter != V.end(); ++iter) cerr << '\"' << *iter << "\","; cerr << " }\n"; }
    template <typename T> void _ap(T V, const char * prefix = "") { cerr << prefix << '"' << V << '"' << "\n"; }
      EOS
    end

    def print_expr(*vars)
      ["cerr", *vars.map{|s| s.is_a?(Symbol) ? s : s.inspect}].join(' << ') + ';';
    end

    def maincode
      ERB.new(<<-EOS
int main(int argc, char* argv[]) {
    int n;
    <%= $prob.class_name %> t;
    return t.run_test(argc == 1 ? -1 : (sscanf(argv[1], "%d", &n), n));
}
      EOS
      ).result(binding)
    end
  end

  class CSTestCodeGenerator < self
    def initialize
      super
      @exit         = 'Environment.Exit'
      @main         = 'Main(string[] args)'
      @parseint     = 'Int32.Parse'
      @length       = 'Length'
      @ap = <<-'EOS'
    void _ap (object[] s, string prefix = "") {_ap (string.Join ("\", \"", s), prefix);}
    void _ap (object s, string prefix = "") {Console.WriteLine("{1}{{ \"{0}\" }}", s, prefix);}
      EOS
    end

    def equal_expr(type, names)
      type.dimension > 0 ?  "#{names[0]}.SequenceEqual(#{names[-1]})" : names.join(' == ')
    end

    def print_expr(*vars)
      "Console.Write(\"#{vars.size.times.map{|i| "{#{i}}" }.join }\", #{vars.map{|s| s.is_a?(Symbol) ? s : s.inspect }.join(', ')});"
    end
  end

  class JavaTestCodeGenerator < self
    def initialize
      super
      @exit         = 'System.exit'
      @main         = 'main(String[] args)'
      @parseint     = 'Integer.parseInt'
      @length       = 'length'
      @bool         = 'boolean'
      @color_code   = '\\033['
      @ap = <<-'EOS'
    void _ap(Object[] s, String prefix) { String r = prefix + "{ "; for (Object o : s) { r += '"' + o.toString() + "\", "; } System.err.println(r + " }"); }
    void _ap(Object s, String prefix) { System.err.println(prefix + "\"" + s.toString() + "\""); }
      EOS
    end

    def print_expr(*vars)
      "System.err.printf(\"#{vars.size.times.map{|i| "%s" }.join }\", #{vars.map {|s| s.is_a?(Symbol) ? "((Object)#{s}).toString()" : s.inspect }.join(', ')});"
    end

    def equal_expr(type, names)
      if type.dimension > 0
        "Arrays.equals(#{names.join(', ')})"
      elsif type.descriptor($lang).downcase['string']
        "#{names[0]}.equals(#{names[-1]})"
      else
        names.join(' == ')
      end
    end
  end

  class VBTestCodeGenerator < self
    def initialize
      super
      @color_code = '" & Chr(27) & "['
    end

    def print_expr(*vars)
      "Console.Write \"#{vars.size.times.map{|i| "{#{i}}" }.join}\", #{vars.map{|s| s.is_a?(Symbol) ? s : s.inspect }.join(', ')}"
    end

    def equal_expr(type, names)
      type.dimension > 0 ?  "#{names[0]}.SequenceEqual(#{names[-1]})" : names.join(' = ')
    end

    def param(id, type, value)
      if type.dimension == 0
        "Dim _#{id} As #{type.descriptor($lang)} = #{value}#{type.base_name.downcase['long'] ? 'L' : ''}"
      else
        "Dim _#{id} As #{type.descriptor($lang)} = #{value.gsub("\n", ' ')}"
      end
    end

    def testcode
      ERB.new(<<-'EOS'
    Sub _ap(ByRef s As Object(), ByVal prefix As String)
        _ap(string.Join(""", """, s), prefix)
    End Sub
    Sub _ap(ByRef s As Object, ByVal prefix As String)
        Console.WriteLine("{1} {{ ""{0}"" }}", s, prefix)
    End Sub
    Function Verify(No As Integer, Expected As <%= ret_type %>, Received As <%= ret_type %>)
        <%= print_expr 'Case ', :No, '  ' %>
        If <%= equal_expr($prob.return_type, ['Expected','Received']) %> Then
            <%= print_expr color_str('PASS', '1;32'), "\n" %>
            Return False
        Else
            <%= print_expr color_str('FAILED', '1;31'), "\n\tExpected: ", :Expected, "\n\tReceived: ", :Received, "\n" %>
            Return True
        End If
    End Function
    Public Function RunTest(kase As Integer) As Integer
        Dim No As Integer = -1, Failed As Integer = 0, Passed As Integer = 0<% $prob.test_cases.each_with_index do |kase, i| %>
        If kase = (No = No + 1) Or (kase < 0) Then ' <%= i %><% n = kase.input.size %><% kase.input.zip([*0...n], $prob.param_types).each do |input, id, type| %>
            <%= param id, type, input %><% end %>
            <%= param 'r', $prob.return_type, kase.output %>
            If Verify(No, _r, <%= $prob.method_name %>(<%= n.times.to_a.map{|j| "_#{j}" }.join(', ') %>)) Then Failed = No + 1 : <%= print_expr color_str("\tInput\n", '4;33') %>:<%= n.times.map {|j| "_ap(_#{j}, \"\\t\")" }.join(':') %> Else Passed = Passed + 1
        End If<% end %>
        If Failed <> 0 Then Return Failed Else If Passed = 0 Then Return -1 Else Return 0
    End Function
      EOS
      ).result(binding)
    end

    def maincode
      ERB.new(<<-'EOS'
    Shared Sub Main()
        Dim T As <%= $prob.class_name %> = New <%= $prob.class_name %>, R As Integer
        If Command.Length > 0
            R = T.RunTest(Val(Command))
        Else
            R = T.RunTest(-1)
        End If
        Environment.Exit(R)
    End Sub
      EOS
      ).result(binding)
    end
  end

  def self.generate
    case $lang.name
    when 'C++'
      CPPTestCodeGenerator
    when 'C#'
      CSTestCodeGenerator
    when 'Java'
      JavaTestCodeGenerator
    when 'VB'
      VBTestCodeGenerator
    end.new.result
  end
end

# code template
def template
  require 'erb'

  case $lang.name
  when 'Java'
    ERB.new <<-EOS
import java.util.*;
public class $CLASSNAME$ {
    public $RC$ $METHODNAME$($METHODPARMS$) {
        <%= CARET_POS %>
    }
$TESTCODE$
$MAINCODE$
}
<%= PROBLEMDESC %>
    EOS
  when 'C++'
    ERB.new <<-EOS
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <cstdio>

using namespace std;

struct $CLASSNAME$ {
    $RC$ $METHODNAME$($METHODPARMS$) {
        <%= CARET_POS %>
    }
$TESTCODE$
};

$MAINCODE$
<%= PROBLEMDESC %>
// vim: nowrap et ts=4 sw=4
    EOS
  when 'C#'
    ERB.new <<-EOS
using System;
using System.Collections;
$BEGINCUT$
using System.Linq;
$ENDCUT$

public class $CLASSNAME$ {
    public $RC$ $METHODNAME$($METHODPARMS$) {
        <%= CARET_POS %>
    }
$TESTCODE$
$MAINCODE$
}
<%= PROBLEMDESC %>
    EOS
  when 'VB'
    ERB.new <<-EOS
Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.Math
Imports System.Text
$BEGINCUT$
Imports System.Linq
$ENDCUT$

Public Class $CLASSNAME$
    Public Function $METHODNAME$($METHODPARMS$) As $RC$
        <%= CARET_POS %>
    End Function
$TESTCODE$
$MAINCODE$
End Class
<%= PROBLEMDESC %>
    EOS
  end.result(binding)
end


# Sync with external code file
def file_path
    File.join(CODE_DIR, "#{$prob.class_name}#{LANG_EXT[$lang]}")
end

def sync_code(overwrite)
  return $src if CODE_DIR.nil? || CODE_DIR.empty?

  require 'fileutils'
  FileUtils.mkdir_p CODE_DIR

  # detect which version is newer
  class_name = $prob.class_name

  # remove 'Powered by' lines
  $src.gsub! /\n *#{LANG_COMMENT[$lang]}\s*Powered\s*[bB]y.*$/, ''

  if overwrite || !File.exists?(file_path)
    File.open(file_path, 'w') { |f| f.write $src }
    debug("Writing #{file_path}")
  else
    $src = File.read(file_path) 
    debug("Reading #{file_path}")
  end
end





def preprocess(src, lang, prob, render)
  # get $METHODPARAMS$
  var_name = '`'
  params   = $prob.param_types.zip($prob.param_names).map do |t| 
    if $lang.name != 'VB'
      "#{t[0].descriptor($lang)} #{t[1].empty? ? var_name.next! : t[1]}"
    else
      "ByRef #{t[1].empty? ? var_name.next! : t[1]} As #{t[0].descriptor($lang)}"
    end
  end.join(', ')

  comm = LANG_COMMENT[$lang]
  tags = {
    BEGINCUT:     "#{comm} #{CUT_BEGIN}",
    ENDCUT:       "#{comm} #{CUT_END}",
    PROBLEMDESC:  $render.to_plain_text($lang).lines.map{|l| "#{comm} #{l}"}.join.with_cut('PROBDESC'),
    CLASSNAME:    $prob.class_name,
    RC:           $prob.return_type.descriptor($lang),
    METHODNAME:   $prob.method_name,
    METHODPARMS:  params,
    TESTCODE:     '',
    MAINCODE:     '',
    FILENAME:     "#{$prob.class_name}#{LANG_EXT[$lang]}",
  }

  if $src.empty? || $src.start_with?(EXEDIT_TIP) || LanguageHistory.get(src) != $lang.id
    $src = template 
  end


  if CODE_DIR.nil?
    [$src.apply_tags(tags).cuted, tags]
  else
    tags[:TESTCODE], tags[:MAINCODE] = *TestCodeGenerator.generate
    $src = $src.apply_tags tags
    sync_code(OVERWRITE)
    [EXEDIT_TIP + File.join(CODE_DIR, "#{$prob.class_name}#{LANG_EXT[$lang]}"), tags]
  end
end

def postprocess(src, lang)
  sync_code(false)
  cuted = $src.cuted
  LanguageHistory.put cuted, $lang.id
  cuted
end

# vim: nowrap sw=2 ts=2 et
