<!DOCTYPE html>

<html lang="en" data-content_root="../">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Template Designer Documentation &#8212; Jinja Documentation (3.1.x)</title>
    <link rel="stylesheet" type="text/css" href="../_static/pygments.css?v=bb251e69" />
    <link rel="stylesheet" type="text/css" href="../_static/jinja.css?v=85659ec6" />
    <script src="../_static/documentation_options.js?v=59b26c69"></script>
    <script src="../_static/doctools.js?v=9bcbadda"></script>
    <script src="../_static/sphinx_highlight.js?v=dc90522c"></script>
    <link rel="canonical" href="https://jinja.palletsprojects.com/en/stable/templates/" />
    <link rel="icon" href="../_static/jinja-icon.svg"/>
    <link rel="index" title="Index" href="../genindex/" />
    <link rel="search" title="Search" href="../search/" />
    <link rel="next" title="Extensions" href="../extensions/" />
    <link rel="prev" title="Native Python Types" href="../nativetypes/" /> 
  <script async type="text/javascript" src="/_/static/javascript/readthedocs-addons.js"></script><meta name="readthedocs-project-slug" content="jinja" /><meta name="readthedocs-version-slug" content="stable" /><meta name="readthedocs-resolver-filename" content="/templates/" /><meta name="readthedocs-http-status" content="200" /></head><body>
    <div class="related" role="navigation" aria-label="Related">
      <h3>Navigation</h3>
      <ul>
        <li class="right" style="margin-right: 10px">
          <a href="../genindex/" title="General Index"
             accesskey="I">index</a></li>
        <li class="right" >
          <a href="../py-modindex/" title="Python Module Index"
             >modules</a> |</li>
        <li class="right" >
          <a href="../extensions/" title="Extensions"
             accesskey="N">next</a> |</li>
        <li class="right" >
          <a href="../nativetypes/" title="Native Python Types"
             accesskey="P">previous</a> |</li>
        <li class="nav-item nav-item-0"><a href="../">Jinja Documentation (3.1.x)</a> &#187;</li>
        <li class="nav-item nav-item-this"><a href="">Template Designer Documentation</a></li> 
      </ul>
    </div>  

    <div class="document">
      <div class="documentwrapper">
        <div class="bodywrapper">
          <div class="body" role="main">
            
  <section id="template-designer-documentation">
<h1>Template Designer Documentation<a class="headerlink" href="#template-designer-documentation" title="Link to this heading">¶</a></h1>
<p>This document describes the syntax and semantics of the template engine and
will be most useful as reference to those creating Jinja templates.  As the
template engine is very flexible, the configuration from the application can
be slightly different from the code presented here in terms of delimiters and
behavior of undefined values.</p>
<section id="synopsis">
<h2>Synopsis<a class="headerlink" href="#synopsis" title="Link to this heading">¶</a></h2>
<p>A Jinja template is simply a text file. Jinja can generate any text-based
format (HTML, XML, CSV, LaTeX, etc.).  A Jinja template doesn’t need to have a
specific extension: <code class="docutils literal notranslate"><span class="pre">.html</span></code>, <code class="docutils literal notranslate"><span class="pre">.xml</span></code>, or any other extension is just fine.</p>
<p>A template contains <strong>variables</strong> and/or <strong>expressions</strong>, which get replaced
with values when a template is <em>rendered</em>; and <strong>tags</strong>, which control the
logic of the template.  The template syntax is heavily inspired by Django and
Python.</p>
<p>Below is a minimal template that illustrates a few basics using the default
Jinja configuration.  We will cover the details later in this document:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">&lt;!DOCTYPE html&gt;</span>
<span class="p">&lt;</span><span class="nt">html</span> <span class="na">lang</span><span class="o">=</span><span class="s">&quot;en&quot;</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">head</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">title</span><span class="p">&gt;</span>My Webpage<span class="p">&lt;/</span><span class="nt">title</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">head</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">body</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">ul</span> <span class="na">id</span><span class="o">=</span><span class="s">&quot;navigation&quot;</span><span class="p">&gt;</span>
    <span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">navigation</span> <span class="cp">%}</span>
        <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;&lt;</span><span class="nt">a</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">item.href</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">item.caption</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">a</span><span class="p">&gt;&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
    <span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
    <span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>

    <span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>My Webpage<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
    <span class="cp">{{</span> <span class="nv">a_variable</span> <span class="cp">}}</span>

    <span class="c">{# a comment #}</span>
<span class="p">&lt;/</span><span class="nt">body</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">html</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>The following example shows the default configuration settings.  An application
developer can change the syntax configuration from <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">foo</span> <span class="pre">%}</span></code> to <code class="docutils literal notranslate"><span class="pre">&lt;%</span> <span class="pre">foo</span>
<span class="pre">%&gt;</span></code>, or something similar.</p>
<p>There are a few kinds of delimiters. The default Jinja delimiters are
configured as follows:</p>
<ul class="simple">
<li><p><code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">...</span> <span class="pre">%}</span></code> for <a class="reference internal" href="#list-of-control-structures"><span class="std std-ref">Statements</span></a></p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">...</span> <span class="pre">}}</span></code> for <a class="reference internal" href="#expressions"><span class="std std-ref">Expressions</span></a> to print to the template output</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">{#</span> <span class="pre">...</span> <span class="pre">#}</span></code> for <a class="reference internal" href="#comments"><span class="std std-ref">Comments</span></a> not included in the template output</p></li>
</ul>
<p><a class="reference internal" href="#line-statements"><span class="std std-ref">Line Statements and Comments</span></a> are also possible,
though they don’t have default prefix characters. To use them, set
<code class="docutils literal notranslate"><span class="pre">line_statement_prefix</span></code> and <code class="docutils literal notranslate"><span class="pre">line_comment_prefix</span></code> when creating the
<a class="reference internal" href="../api/#jinja2.Environment" title="jinja2.Environment"><code class="xref py py-class docutils literal notranslate"><span class="pre">Environment</span></code></a>.</p>
<section id="template-file-extension">
<h3>Template File Extension<a class="headerlink" href="#template-file-extension" title="Link to this heading">¶</a></h3>
<p>As stated above, any file can be loaded as a template, regardless of
file extension. Adding a <code class="docutils literal notranslate"><span class="pre">.jinja</span></code> extension, like <code class="docutils literal notranslate"><span class="pre">user.html.jinja</span></code>
may make it easier for some IDEs or editor plugins, but is not required.
Autoescaping, introduced later, can be applied based on file extension,
so you’ll need to take the extra suffix into account in that case.</p>
<p>Another good heuristic for identifying templates is that they are in a
<code class="docutils literal notranslate"><span class="pre">templates</span></code> folder, regardless of extension. This is a common layout
for projects.</p>
</section>
</section>
<section id="variables">
<span id="id1"></span><h2>Variables<a class="headerlink" href="#variables" title="Link to this heading">¶</a></h2>
<p>Template variables are defined by the context dictionary passed to the
template.</p>
<p>You can mess around with the variables in templates provided they are passed in
by the application.  Variables may have attributes or elements on them you can
access too.  What attributes a variable has depends heavily on the application
providing that variable.</p>
<p>You can use a dot (<code class="docutils literal notranslate"><span class="pre">.</span></code>) to access attributes of a variable in addition
to the standard Python <code class="docutils literal notranslate"><span class="pre">__getitem__</span></code> “subscript” syntax (<code class="docutils literal notranslate"><span class="pre">[]</span></code>).</p>
<p>The following lines do the same thing:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">foo.bar</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">foo</span><span class="o">[</span><span class="s1">&#39;bar&#39;</span><span class="o">]</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>It’s important to know that the outer double-curly braces are <em>not</em> part of the
variable, but the print statement.  If you access variables inside tags don’t
put the braces around them.</p>
<p>If a variable or attribute does not exist, you will get back an undefined
value.  What you can do with that kind of value depends on the application
configuration: the default behavior is to evaluate to an empty string if
printed or iterated over, and to fail for every other operation.</p>
<div class="admonition-implementation admonition" id="notes-on-subscriptions">
<p class="admonition-title">Implementation</p>
<p>For the sake of convenience, <code class="docutils literal notranslate"><span class="pre">foo.bar</span></code> in Jinja does the following
things on the Python layer:</p>
<ul class="simple">
<li><p>check for an attribute called <code class="code docutils literal notranslate"><span class="pre">bar</span></code> on <code class="code docutils literal notranslate"><span class="pre">foo</span></code>
(<code class="docutils literal notranslate"><span class="pre">getattr(foo,</span> <span class="pre">'bar')</span></code>)</p></li>
<li><p>if there is not, check for an item <code class="docutils literal notranslate"><span class="pre">'bar'</span></code> in <code class="code docutils literal notranslate"><span class="pre">foo</span></code>
(<code class="docutils literal notranslate"><span class="pre">foo.__getitem__('bar')</span></code>)</p></li>
<li><p>if there is not, return an undefined object.</p></li>
</ul>
<p><code class="docutils literal notranslate"><span class="pre">foo['bar']</span></code> works mostly the same with a small difference in sequence:</p>
<ul class="simple">
<li><p>check for an item <code class="docutils literal notranslate"><span class="pre">'bar'</span></code> in <code class="code docutils literal notranslate"><span class="pre">foo</span></code>.
(<code class="docutils literal notranslate"><span class="pre">foo.__getitem__('bar')</span></code>)</p></li>
<li><p>if there is not, check for an attribute called <code class="code docutils literal notranslate"><span class="pre">bar</span></code> on <code class="code docutils literal notranslate"><span class="pre">foo</span></code>.
(<code class="docutils literal notranslate"><span class="pre">getattr(foo,</span> <span class="pre">'bar')</span></code>)</p></li>
<li><p>if there is not, return an undefined object.</p></li>
</ul>
<p>This is important if an object has an item and attribute with the same
name.  Additionally, the <code class="xref py py-func docutils literal notranslate"><span class="pre">attr()</span></code> filter only looks up attributes.</p>
</div>
</section>
<section id="filters">
<span id="id2"></span><h2>Filters<a class="headerlink" href="#filters" title="Link to this heading">¶</a></h2>
<p>Variables can be modified by <strong>filters</strong>.  Filters are separated from the
variable by a pipe symbol (<code class="docutils literal notranslate"><span class="pre">|</span></code>) and may have optional arguments in
parentheses.  Multiple filters can be chained.  The output of one filter is
applied to the next.</p>
<p>For example, <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">name|striptags|title</span> <span class="pre">}}</span></code> will remove all HTML Tags from
variable <code class="code docutils literal notranslate"><span class="pre">name</span></code> and title-case the output (<code class="docutils literal notranslate"><span class="pre">title(striptags(name))</span></code>).</p>
<p>Filters that accept arguments have parentheses around the arguments, just like
a function call.  For example: <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">listx|join(',</span> <span class="pre">')</span> <span class="pre">}}</span></code> will join a list with
commas (<code class="docutils literal notranslate"><span class="pre">str.join(',</span> <span class="pre">',</span> <span class="pre">listx)</span></code>).</p>
<p>The <a class="reference internal" href="#builtin-filters"><span class="std std-ref">List of Builtin Filters</span></a> below describes all the builtin filters.</p>
</section>
<section id="tests">
<span id="id3"></span><h2>Tests<a class="headerlink" href="#tests" title="Link to this heading">¶</a></h2>
<p>Beside filters, there are also so-called “tests” available.  Tests can be used
to test a variable against a common expression.  To test a variable or
expression, you add <code class="code docutils literal notranslate"><span class="pre">is</span></code> plus the name of the test after the variable.  For
example, to find out if a variable is defined, you can do <code class="docutils literal notranslate"><span class="pre">name</span> <span class="pre">is</span> <span class="pre">defined</span></code>,
which will then return true or false depending on whether <code class="code docutils literal notranslate"><span class="pre">name</span></code> is defined
in the current template context.</p>
<p>Tests can accept arguments, too.  If the test only takes one argument, you can
leave out the parentheses.  For example, the following two
expressions do the same thing:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="nb">loop</span><span class="nv">.index</span> <span class="k">is</span> <span class="nf">divisibleby</span> <span class="m">3</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">if</span> <span class="nb">loop</span><span class="nv">.index</span> <span class="k">is</span> <span class="nf">divisibleby</span><span class="o">(</span><span class="m">3</span><span class="o">)</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The <a class="reference internal" href="#builtin-tests"><span class="std std-ref">List of Builtin Tests</span></a> below describes all the builtin tests.</p>
</section>
<section id="comments">
<span id="id4"></span><h2>Comments<a class="headerlink" href="#comments" title="Link to this heading">¶</a></h2>
<p>To comment-out part of a line in a template, use the comment syntax which is
by default set to <code class="docutils literal notranslate"><span class="pre">{#</span> <span class="pre">...</span> <span class="pre">#}</span></code>.  This is useful to comment out parts of the
template for debugging or to add information for other template designers or
yourself:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="c">{# note: commented-out template because we no longer use this</span>
<span class="c">    {% for user in users %}</span>
<span class="c">        ...</span>
<span class="c">    {% endfor %}</span>
<span class="c">#}</span>
</pre></div>
</div>
</section>
<section id="whitespace-control">
<h2>Whitespace Control<a class="headerlink" href="#whitespace-control" title="Link to this heading">¶</a></h2>
<p>In the default configuration:</p>
<ul class="simple">
<li><p>a single trailing newline is stripped if present</p></li>
<li><p>other whitespace (spaces, tabs, newlines etc.) is returned unchanged</p></li>
</ul>
<p>If an application configures Jinja to <code class="code docutils literal notranslate"><span class="pre">trim_blocks</span></code>, the first newline after a
template tag is removed automatically (like in PHP). The <code class="code docutils literal notranslate"><span class="pre">lstrip_blocks</span></code>
option can also be set to strip tabs and spaces from the beginning of a
line to the start of a block. (Nothing will be stripped if there are
other characters before the start of the block.)</p>
<p>With both <code class="docutils literal notranslate"><span class="pre">trim_blocks</span></code> and <code class="docutils literal notranslate"><span class="pre">lstrip_blocks</span></code> disabled (the default), block
tags on their own lines will be removed, but a blank line will remain and the
spaces in the content will be preserved. For example, this template:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="x">&lt;div&gt;</span>
<span class="x">    </span><span class="cp">{%</span> <span class="k">if</span> <span class="kp">True</span> <span class="cp">%}</span>
<span class="x">        yay</span>
<span class="x">    </span><span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="x">&lt;/div&gt;</span>
</pre></div>
</div>
<p>With both <code class="docutils literal notranslate"><span class="pre">trim_blocks</span></code> and <code class="docutils literal notranslate"><span class="pre">lstrip_blocks</span></code> disabled, the template is
rendered with blank lines inside the div:</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>&lt;div&gt;

        yay

&lt;/div&gt;
</pre></div>
</div>
<p>With both <code class="docutils literal notranslate"><span class="pre">trim_blocks</span></code> and <code class="docutils literal notranslate"><span class="pre">lstrip_blocks</span></code> enabled, the template block
lines are completely removed:</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>&lt;div&gt;
        yay
&lt;/div&gt;
</pre></div>
</div>
<p>You can manually disable the <code class="code docutils literal notranslate"><span class="pre">lstrip_blocks</span></code> behavior by putting a
plus sign (<code class="docutils literal notranslate"><span class="pre">+</span></code>) at the start of a block:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;</span>
        {%+ if something %}yay<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>Similarly, you can manually disable the <code class="docutils literal notranslate"><span class="pre">trim_blocks</span></code> behavior by
putting a plus sign (<code class="docutils literal notranslate"><span class="pre">+</span></code>) at the end of a block:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;</span>
    <span class="cp">{%</span> <span class="k">if</span> <span class="nv">something</span> <span class="o">+</span><span class="cp">%}</span>
        yay
    <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>You can also strip whitespace in templates by hand.  If you add a minus
sign (<code class="docutils literal notranslate"><span class="pre">-</span></code>) to the start or end of a block (e.g. a <a class="reference internal" href="#for-loop"><span class="std std-ref">For</span></a> tag), a
comment, or a variable expression, the whitespaces before or after
that block will be removed:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">seq</span> -<span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span>
<span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>This will yield all elements without whitespace between them.  If <code class="code docutils literal notranslate"><span class="pre">seq</span></code> was
a list of numbers from <code class="docutils literal notranslate"><span class="pre">1</span></code> to <code class="docutils literal notranslate"><span class="pre">9</span></code>, the output would be <code class="docutils literal notranslate"><span class="pre">123456789</span></code>.</p>
<p>If <a class="reference internal" href="#line-statements"><span class="std std-ref">Line Statements</span></a> are enabled, they strip leading whitespace
automatically up to the beginning of the line.</p>
<p>By default, Jinja also removes trailing newlines.  To keep single
trailing newlines, configure Jinja to <code class="code docutils literal notranslate"><span class="pre">keep_trailing_newline</span></code>.</p>
<div class="admonition-note admonition">
<p class="admonition-title">Note</p>
<p>You must not add whitespace between the tag and the minus sign.</p>
<p><strong>valid</strong>:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span>- <span class="k">if</span> <span class="nv">foo</span> -<span class="cp">%}</span>...<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<p><strong>invalid</strong>:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span>{% - if foo - %}...<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
</div>
</section>
<section id="escaping">
<h2>Escaping<a class="headerlink" href="#escaping" title="Link to this heading">¶</a></h2>
<p>It is sometimes desirable – even necessary – to have Jinja ignore parts
it would otherwise handle as variables or blocks.  For example, if, with
the default syntax, you want to use <code class="docutils literal notranslate"><span class="pre">{{</span></code> as a raw string in a template and
not start a variable, you have to use a trick.</p>
<p>The easiest way to output a literal variable delimiter (<code class="docutils literal notranslate"><span class="pre">{{</span></code>) is by using a
variable expression:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="s1">&#39;{{&#39;</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>For bigger sections, it makes sense to mark a block <code class="code docutils literal notranslate"><span class="pre">raw</span></code>.  For example, to
include example Jinja syntax in a template, you can use this snippet:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">raw</span> <span class="cp">%}</span>
    &lt;ul&gt;
    {% for item in seq %}
        &lt;li&gt;{{ item }}&lt;/li&gt;
    {% endfor %}
    &lt;/ul&gt;
<span class="cp">{%</span> <span class="k">endraw</span> <span class="cp">%}</span>
</pre></div>
</div>
<div class="admonition-note admonition">
<p class="admonition-title">Note</p>
<p>Minus sign at the end of <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">raw</span> <span class="pre">-%}</span></code> tag cleans all the spaces and newlines
preceding the first character of your raw data.</p>
</div>
</section>
<section id="line-statements">
<span id="id5"></span><h2>Line Statements<a class="headerlink" href="#line-statements" title="Link to this heading">¶</a></h2>
<p>If line statements are enabled by the application, it’s possible to mark a
line as a statement.  For example, if the line statement prefix is configured
to <code class="docutils literal notranslate"><span class="pre">#</span></code>, the following two examples are equivalent:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
# for item in seq
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
# endfor
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>

<span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">seq</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>The line statement prefix can appear anywhere on the line as long as no text
precedes it.  For better readability, statements that start a block (such as
<code class="code docutils literal notranslate"><span class="pre">for</span></code>, <code class="code docutils literal notranslate"><span class="pre">if</span></code>, <code class="code docutils literal notranslate"><span class="pre">elif</span></code> etc.) may end with a colon:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span># for item in seq:
    ...
# endfor
</pre></div>
</div>
<div class="admonition-note admonition">
<p class="admonition-title">Note</p>
<p>Line statements can span multiple lines if there are open parentheses,
braces or brackets:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
# for href, caption in [(&#39;index.html&#39;, &#39;Index&#39;),
                        (&#39;about.html&#39;, &#39;About&#39;)]:
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;&lt;</span><span class="nt">a</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">href</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">caption</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">a</span><span class="p">&gt;&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
# endfor
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
</div>
<p>Since Jinja 2.2, line-based comments are available as well.  For example, if
the line-comment prefix is configured to be <code class="docutils literal notranslate"><span class="pre">##</span></code>, everything from <code class="docutils literal notranslate"><span class="pre">##</span></code> to
the end of the line is ignored (excluding the newline sign):</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span># for item in seq:
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>     ## this comment is ignored
# endfor
</pre></div>
</div>
</section>
<section id="template-inheritance">
<span id="id6"></span><h2>Template Inheritance<a class="headerlink" href="#template-inheritance" title="Link to this heading">¶</a></h2>
<p>The most powerful part of Jinja is template inheritance. Template inheritance
allows you to build a base “skeleton” template that contains all the common
elements of your site and defines <strong>blocks</strong> that child templates can override.</p>
<p>Sounds complicated but is very basic. It’s easiest to understand it by starting
with an example.</p>
<section id="base-template">
<h3>Base Template<a class="headerlink" href="#base-template" title="Link to this heading">¶</a></h3>
<p>This template, which we’ll call <code class="docutils literal notranslate"><span class="pre">base.html</span></code>, defines a simple HTML skeleton
document that you might use for a simple two-column page. It’s the job of
“child” templates to fill the empty blocks with content:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">&lt;!DOCTYPE html&gt;</span>
<span class="p">&lt;</span><span class="nt">html</span> <span class="na">lang</span><span class="o">=</span><span class="s">&quot;en&quot;</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">head</span><span class="p">&gt;</span>
    <span class="cp">{%</span> <span class="k">block</span> <span class="nv">head</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">link</span> <span class="na">rel</span><span class="o">=</span><span class="s">&quot;stylesheet&quot;</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;style.css&quot;</span> <span class="p">/&gt;</span>
    <span class="p">&lt;</span><span class="nt">title</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">title</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span> - My Webpage<span class="p">&lt;/</span><span class="nt">title</span><span class="p">&gt;</span>
    <span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">head</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">body</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">div</span> <span class="na">id</span><span class="o">=</span><span class="s">&quot;content&quot;</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">content</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">div</span> <span class="na">id</span><span class="o">=</span><span class="s">&quot;footer&quot;</span><span class="p">&gt;</span>
        <span class="cp">{%</span> <span class="k">block</span> <span class="nv">footer</span> <span class="cp">%}</span>
        <span class="ni">&amp;copy;</span> Copyright 2008 by <span class="p">&lt;</span><span class="nt">a</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;http://domain.invalid/&quot;</span><span class="p">&gt;</span>you<span class="p">&lt;/</span><span class="nt">a</span><span class="p">&gt;</span>.
        <span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
    <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">body</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">html</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>In this example, the <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">block</span> <span class="pre">%}</span></code> tags define four blocks that child templates
can fill in. All the <code class="code docutils literal notranslate"><span class="pre">block</span></code> tag does is tell the template engine that a
child template may override those placeholders in the template.</p>
<p><code class="docutils literal notranslate"><span class="pre">block</span></code> tags can be inside other blocks such as <code class="docutils literal notranslate"><span class="pre">if</span></code>, but they will
always be executed regardless of if the <code class="docutils literal notranslate"><span class="pre">if</span></code> block is actually
rendered.</p>
</section>
<section id="child-template">
<h3>Child Template<a class="headerlink" href="#child-template" title="Link to this heading">¶</a></h3>
<p>A child template might look like this:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;base.html&quot;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">title</span> <span class="cp">%}</span>Index<span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">head</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nb">super</span><span class="o">()</span> <span class="cp">}}</span>
    <span class="p">&lt;</span><span class="nt">style</span> <span class="na">type</span><span class="o">=</span><span class="s">&quot;text/css&quot;</span><span class="p">&gt;</span>
<span class="w">        </span><span class="p">.</span><span class="nc">important</span><span class="w"> </span><span class="p">{</span><span class="w"> </span><span class="k">color</span><span class="p">:</span><span class="w"> </span><span class="mh">#336699</span><span class="p">;</span><span class="w"> </span><span class="p">}</span>
<span class="w">    </span><span class="p">&lt;/</span><span class="nt">style</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">content</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Index<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">p</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;important&quot;</span><span class="p">&gt;</span>
      Welcome to my awesome homepage.
    <span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">extends</span> <span class="pre">%}</span></code> tag is the key here. It tells the template engine that
this template “extends” another template.  When the template system evaluates
this template, it first locates the parent.  The extends tag should be the
first tag in the template.  Everything before it is printed out normally and
may cause confusion.  For details about this behavior and how to take
advantage of it, see <a class="reference internal" href="../tricks/#null-default-fallback"><span class="std std-ref">Null-Default Fallback</span></a>. Also a block will always be
filled in regardless of whether the surrounding condition is evaluated to be true
or false.</p>
<p>The filename of the template depends on the template loader.  For example, the
<a class="reference internal" href="../api/#jinja2.FileSystemLoader" title="jinja2.FileSystemLoader"><code class="xref py py-class docutils literal notranslate"><span class="pre">FileSystemLoader</span></code></a> allows you to access other templates by giving the
filename.  You can access templates in subdirectories with a slash:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;layout/default.html&quot;</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>But this behavior can depend on the application embedding Jinja.  Note that
since the child template doesn’t define the <code class="docutils literal notranslate"><span class="pre">footer</span></code> block, the value from
the parent template is used instead.</p>
<p>You can’t define multiple <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">block</span> <span class="pre">%}</span></code> tags with the same name in the
same template.  This limitation exists because a block tag works in “both”
directions.  That is, a block tag doesn’t just provide a placeholder to fill
- it also defines the content that fills the placeholder in the <em>parent</em>.
If there were two similarly-named <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">block</span> <span class="pre">%}</span></code> tags in a template,
that template’s parent wouldn’t know which one of the blocks’ content to use.</p>
<p>If you want to print a block multiple times, you can, however, use the special
<code class="code docutils literal notranslate"><span class="pre">self</span></code> variable and call the block with that name:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">title</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">title</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">title</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">self.title</span><span class="o">()</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="super-blocks">
<h3>Super Blocks<a class="headerlink" href="#super-blocks" title="Link to this heading">¶</a></h3>
<p>It’s possible to render the contents of the parent block by calling <code class="docutils literal notranslate"><span class="pre">super()</span></code>.
This gives back the results of the parent block:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">sidebar</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">h3</span><span class="p">&gt;</span>Table Of Contents<span class="p">&lt;/</span><span class="nt">h3</span><span class="p">&gt;</span>
    ...
    <span class="cp">{{</span> <span class="nb">super</span><span class="o">()</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="nesting-extends">
<h3>Nesting extends<a class="headerlink" href="#nesting-extends" title="Link to this heading">¶</a></h3>
<p>In the case of multiple levels of <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">extends</span> <span class="pre">%}</span></code>,
<code class="docutils literal notranslate"><span class="pre">super</span></code> references may be chained (as in <code class="docutils literal notranslate"><span class="pre">super.super()</span></code>)
to skip levels in the inheritance tree.</p>
<p>For example:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span># parent.tmpl
body: <span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}</span>Hi from parent.<span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>

# child.tmpl
<span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;parent.tmpl&quot;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}</span>Hi from child. <span class="cp">{{</span> <span class="nb">super</span><span class="o">()</span> <span class="cp">}}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>

# grandchild1.tmpl
<span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;child.tmpl&quot;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}</span>Hi from grandchild1.<span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>

# grandchild2.tmpl
<span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;child.tmpl&quot;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}</span>Hi from grandchild2. <span class="cp">{{</span> <span class="nb">super</span><span class="nv">.super</span><span class="o">()</span> <span class="cp">}}</span> <span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Rendering <code class="docutils literal notranslate"><span class="pre">child.tmpl</span></code> will give
<code class="docutils literal notranslate"><span class="pre">body:</span> <span class="pre">Hi</span> <span class="pre">from</span> <span class="pre">child.</span> <span class="pre">Hi</span> <span class="pre">from</span> <span class="pre">parent.</span></code></p>
<p>Rendering <code class="docutils literal notranslate"><span class="pre">grandchild1.tmpl</span></code> will give
<code class="docutils literal notranslate"><span class="pre">body:</span> <span class="pre">Hi</span> <span class="pre">from</span> <span class="pre">grandchild1.</span></code></p>
<p>Rendering <code class="docutils literal notranslate"><span class="pre">grandchild2.tmpl</span></code> will give
<code class="docutils literal notranslate"><span class="pre">body:</span> <span class="pre">Hi</span> <span class="pre">from</span> <span class="pre">grandchild2.</span> <span class="pre">Hi</span> <span class="pre">from</span> <span class="pre">parent.</span></code></p>
</section>
<section id="named-block-end-tags">
<h3>Named Block End-Tags<a class="headerlink" href="#named-block-end-tags" title="Link to this heading">¶</a></h3>
<p>Jinja allows you to put the name of the block after the end tag for better
readability:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">sidebar</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">block</span> <span class="nv">inner_sidebar</span> <span class="cp">%}</span>
        ...
    <span class="cp">{%</span> <span class="k">endblock</span> <span class="nv">inner_sidebar</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">endblock</span> <span class="nv">sidebar</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>However, the name after the <code class="code docutils literal notranslate"><span class="pre">endblock</span></code> word must match the block name.</p>
</section>
<section id="block-nesting-and-scope">
<h3>Block Nesting and Scope<a class="headerlink" href="#block-nesting-and-scope" title="Link to this heading">¶</a></h3>
<p>Blocks can be nested for more complex layouts. By default, a block may not
access variables from outside the block (outer scopes):</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">seq</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">loop_item</span> <span class="cp">%}{{</span> <span class="nv">item</span> <span class="cp">}}{%</span> <span class="k">endblock</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>This example would output empty <code class="docutils literal notranslate"><span class="pre">&lt;li&gt;</span></code> items because <code class="code docutils literal notranslate"><span class="pre">item</span></code> is unavailable
inside the block.  The reason for this is that if the block is replaced by
a child template, a variable would appear that was not defined in the block or
passed to the context.</p>
<p>Starting with Jinja 2.2, you can explicitly specify that variables are
available in a block by setting the block to “scoped” by adding the <code class="code docutils literal notranslate"><span class="pre">scoped</span></code>
modifier to a block declaration:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">seq</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">loop_item</span> <span class="k">scoped</span> <span class="cp">%}{{</span> <span class="nv">item</span> <span class="cp">}}{%</span> <span class="k">endblock</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>When overriding a block, the <code class="code docutils literal notranslate"><span class="pre">scoped</span></code> modifier does not have to be provided.</p>
</section>
<section id="required-blocks">
<h3>Required Blocks<a class="headerlink" href="#required-blocks" title="Link to this heading">¶</a></h3>
<p>Blocks can be marked as <code class="docutils literal notranslate"><span class="pre">required</span></code>. They must be overridden at some
point, but not necessarily by the direct child template. Required blocks
may only contain space and comments, and they cannot be rendered
directly.</p>
<div class="literal-block-wrapper docutils container" id="id20">
<div class="code-block-caption"><span class="caption-text"><code class="docutils literal notranslate"><span class="pre">page.txt</span></code></span><a class="headerlink" href="#id20" title="Link to this code">¶</a></div>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="nv">required</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</div>
<div class="literal-block-wrapper docutils container" id="id21">
<div class="code-block-caption"><span class="caption-text"><code class="docutils literal notranslate"><span class="pre">issue.txt</span></code></span><a class="headerlink" href="#id21" title="Link to this code">¶</a></div>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;page.txt&quot;</span> <span class="cp">%}</span>
</pre></div>
</div>
</div>
<div class="literal-block-wrapper docutils container" id="id22">
<div class="code-block-caption"><span class="caption-text"><code class="docutils literal notranslate"><span class="pre">bug_report.txt</span></code></span><a class="headerlink" href="#id22" title="Link to this code">¶</a></div>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="s2">&quot;issue.txt&quot;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}</span><span class="x">Provide steps to demonstrate the bug.</span><span class="cp">{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</div>
<p>Rendering <code class="docutils literal notranslate"><span class="pre">page.txt</span></code> or <code class="docutils literal notranslate"><span class="pre">issue.txt</span></code> will raise
<code class="docutils literal notranslate"><span class="pre">TemplateRuntimeError</span></code> because they don’t override the <code class="docutils literal notranslate"><span class="pre">body</span></code> block.
Rendering <code class="docutils literal notranslate"><span class="pre">bug_report.txt</span></code> will succeed because it does override the
block.</p>
<p>When combined with <code class="docutils literal notranslate"><span class="pre">scoped</span></code>, the <code class="docutils literal notranslate"><span class="pre">required</span></code> modifier must be placed
<em>after</em> the scoped modifier. Here are some valid examples:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="k">scoped</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="nv">required</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="k">scoped</span> <span class="nv">required</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="template-objects">
<h3>Template Objects<a class="headerlink" href="#template-objects" title="Link to this heading">¶</a></h3>
<p><code class="docutils literal notranslate"><span class="pre">extends</span></code>, <code class="docutils literal notranslate"><span class="pre">include</span></code>, and <code class="docutils literal notranslate"><span class="pre">import</span></code> can take a template object
instead of the name of a template to load. This could be useful in some
advanced situations, since you can use Python code to load a template
first and pass it in to <code class="docutils literal notranslate"><span class="pre">render</span></code>.</p>
<div class="highlight-python notranslate"><div class="highlight"><pre><span></span><span class="k">if</span> <span class="n">debug_mode</span><span class="p">:</span>
    <span class="n">layout</span> <span class="o">=</span> <span class="n">env</span><span class="o">.</span><span class="n">get_template</span><span class="p">(</span><span class="s2">&quot;debug_layout.html&quot;</span><span class="p">)</span>
<span class="k">else</span><span class="p">:</span>
    <span class="n">layout</span> <span class="o">=</span> <span class="n">env</span><span class="o">.</span><span class="n">get_template</span><span class="p">(</span><span class="s2">&quot;layout.html&quot;</span><span class="p">)</span>

<span class="n">user_detail</span> <span class="o">=</span> <span class="n">env</span><span class="o">.</span><span class="n">get_template</span><span class="p">(</span><span class="s2">&quot;user/detail.html&quot;</span><span class="p">)</span>
<span class="k">return</span> <span class="n">user_detail</span><span class="o">.</span><span class="n">render</span><span class="p">(</span><span class="n">layout</span><span class="o">=</span><span class="n">layout</span><span class="p">)</span>
</pre></div>
</div>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="nv">layout</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Note how <code class="docutils literal notranslate"><span class="pre">extends</span></code> is passed the variable with the template object
that was passed to <code class="docutils literal notranslate"><span class="pre">render</span></code>, instead of a string.</p>
</section>
</section>
<section id="html-escaping">
<h2>HTML Escaping<a class="headerlink" href="#html-escaping" title="Link to this heading">¶</a></h2>
<p>When generating HTML from templates, there’s always a risk that a variable will
include characters that affect the resulting HTML. There are two approaches:</p>
<ol class="loweralpha simple">
<li><p>manually escaping each variable; or</p></li>
<li><p>automatically escaping everything by default.</p></li>
</ol>
<p>Jinja supports both. What is used depends on the application configuration.
The default configuration is no automatic escaping; for various reasons:</p>
<ul class="simple">
<li><p>Escaping everything except for safe values will also mean that Jinja is
escaping variables known to not include HTML (e.g. numbers, booleans)
which can be a huge performance hit.</p></li>
<li><p>The information about the safety of a variable is very fragile.  It could
happen that by coercing safe and unsafe values, the return value is
double-escaped HTML.</p></li>
</ul>
<section id="working-with-manual-escaping">
<h3>Working with Manual Escaping<a class="headerlink" href="#working-with-manual-escaping" title="Link to this heading">¶</a></h3>
<p>If manual escaping is enabled, it’s <strong>your</strong> responsibility to escape
variables if needed.  What to escape?  If you have a variable that <em>may</em>
include any of the following chars (<code class="docutils literal notranslate"><span class="pre">&gt;</span></code>, <code class="docutils literal notranslate"><span class="pre">&lt;</span></code>, <code class="docutils literal notranslate"><span class="pre">&amp;</span></code>, or <code class="docutils literal notranslate"><span class="pre">&quot;</span></code>) you
<strong>SHOULD</strong> escape it unless the variable contains well-formed and trusted
HTML.  Escaping works by piping the variable through the <code class="docutils literal notranslate"><span class="pre">|e</span></code> filter:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">user.username</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span>
</pre></div>
</div>
</section>
<section id="working-with-automatic-escaping">
<h3>Working with Automatic Escaping<a class="headerlink" href="#working-with-automatic-escaping" title="Link to this heading">¶</a></h3>
<p>When automatic escaping is enabled, everything is escaped by default except
for values explicitly marked as safe.  Variables and expressions
can be marked as safe either in:</p>
<ol class="loweralpha simple">
<li><p>The context dictionary by the application with
<code class="xref py py-class docutils literal notranslate"><span class="pre">markupsafe.Markup</span></code></p></li>
<li><p>The template, with the <code class="docutils literal notranslate"><span class="pre">|safe</span></code> filter.</p></li>
</ol>
<p>If a string that you marked safe is passed through other Python code
that doesn’t understand that mark, it may get lost. Be aware of when
your data is marked safe and how it is processed before arriving at the
template.</p>
<p>If a value has been escaped but is not marked safe, auto-escaping will
still take place and result in double-escaped characters. If you know
you have data that is already safe but not marked, be sure to wrap it in
<code class="docutils literal notranslate"><span class="pre">Markup</span></code> or use the <code class="docutils literal notranslate"><span class="pre">|safe</span></code> filter.</p>
<p>Jinja functions (macros, <code class="code docutils literal notranslate"><span class="pre">super</span></code>, <code class="code docutils literal notranslate"><span class="pre">self.BLOCKNAME</span></code>) always return template
data that is marked as safe.</p>
<p>String literals in templates with automatic escaping are considered
unsafe because native Python strings are not safe.</p>
</section>
</section>
<section id="list-of-control-structures">
<span id="id7"></span><h2>List of Control Structures<a class="headerlink" href="#list-of-control-structures" title="Link to this heading">¶</a></h2>
<p>A control structure refers to all those things that control the flow of a
program - conditionals (i.e. if/elif/else), for-loops, as well as things like
macros and blocks.  With the default syntax, control structures appear inside
<code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">...</span> <span class="pre">%}</span></code> blocks.</p>
<section id="for">
<span id="for-loop"></span><h3>For<a class="headerlink" href="#for" title="Link to this heading">¶</a></h3>
<p>Loop over each item in a sequence.  For example, to display a list of users
provided in a variable called <code class="code docutils literal notranslate"><span class="pre">users</span></code>:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Members<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
  <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.username</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>As variables in templates retain their object properties, it is possible to
iterate over containers like <code class="code docutils literal notranslate"><span class="pre">dict</span></code>:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">dl</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">my_dict.items</span><span class="o">()</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">key</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">value</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">dl</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>Python dicts may not be in the order you want to display them in. If
order matters, use the <code class="docutils literal notranslate"><span class="pre">|dictsort</span></code> filter.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="x">&lt;dl&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">my_dict</span> <span class="o">|</span> <span class="nf">dictsort</span> <span class="cp">%}</span>
<span class="x">    &lt;dt&gt;</span><span class="cp">{{</span> <span class="nv">key</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="x">&lt;/dt&gt;</span>
<span class="x">    &lt;dd&gt;</span><span class="cp">{{</span> <span class="nv">value</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="x">&lt;/dd&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="x">&lt;/dl&gt;</span>
</pre></div>
</div>
<p>Inside of a for-loop block, you can access some special variables:</p>
<table class="docutils align-default">
<thead>
<tr class="row-odd"><th class="head"><p>Variable</p></th>
<th class="head"><p>Description</p></th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.index</span></code></p></td>
<td><p>The current iteration of the loop. (1 indexed)</p></td>
</tr>
<tr class="row-odd"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.index0</span></code></p></td>
<td><p>The current iteration of the loop. (0 indexed)</p></td>
</tr>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.revindex</span></code></p></td>
<td><p>The number of iterations from the end of the loop
(1 indexed)</p></td>
</tr>
<tr class="row-odd"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.revindex0</span></code></p></td>
<td><p>The number of iterations from the end of the loop
(0 indexed)</p></td>
</tr>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.first</span></code></p></td>
<td><p>True if first iteration.</p></td>
</tr>
<tr class="row-odd"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.last</span></code></p></td>
<td><p>True if last iteration.</p></td>
</tr>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.length</span></code></p></td>
<td><p>The number of items in the sequence.</p></td>
</tr>
<tr class="row-odd"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.cycle</span></code></p></td>
<td><p>A helper function to cycle between a list of
sequences.  See the explanation below.</p></td>
</tr>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.depth</span></code></p></td>
<td><p>Indicates how deep in a recursive loop
the rendering currently is.  Starts at level 1</p></td>
</tr>
<tr class="row-odd"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.depth0</span></code></p></td>
<td><p>Indicates how deep in a recursive loop
the rendering currently is.  Starts at level 0</p></td>
</tr>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.previtem</span></code></p></td>
<td><p>The item from the previous iteration of the loop.
Undefined during the first iteration.</p></td>
</tr>
<tr class="row-odd"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.nextitem</span></code></p></td>
<td><p>The item from the following iteration of the loop.
Undefined during the last iteration.</p></td>
</tr>
<tr class="row-even"><td><p><code class="code docutils literal notranslate"><span class="pre">loop.changed(*val)</span></code></p></td>
<td><p>True if previously called with a different value
(or not called at all).</p></td>
</tr>
</tbody>
</table>
<p>Within a for-loop, it’s possible to cycle among a list of strings/variables
each time through the loop by using the special <code class="code docutils literal notranslate"><span class="pre">loop.cycle</span></code> helper:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">row</span> <span class="k">in</span> <span class="nv">rows</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nb">loop</span><span class="nv">.cycle</span><span class="o">(</span><span class="s1">&#39;odd&#39;</span><span class="o">,</span> <span class="s1">&#39;even&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">row</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Since Jinja 2.1, an extra <code class="code docutils literal notranslate"><span class="pre">cycle</span></code> helper exists that allows loop-unbound
cycling.  For more information, have a look at the <a class="reference internal" href="#builtin-globals"><span class="std std-ref">List of Global Functions</span></a>.</p>
<p id="loop-filtering">Unlike in Python, it’s not possible to <code class="code docutils literal notranslate"><span class="pre">break</span></code> or <code class="code docutils literal notranslate"><span class="pre">continue</span></code> in a loop.  You
can, however, filter the sequence during iteration, which allows you to skip
items.  The following example skips all the users which are hidden:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="k">if</span> <span class="k">not</span> <span class="nv">user.hidden</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.username</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The advantage is that the special <code class="code docutils literal notranslate"><span class="pre">loop</span></code> variable will count correctly; thus
not counting the users not iterated over.</p>
<p>If no iteration took place because the sequence was empty or the filtering
removed all the items from the sequence, you can render a default block
by using <code class="code docutils literal notranslate"><span class="pre">else</span></code>:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.username</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;&lt;</span><span class="nt">em</span><span class="p">&gt;</span>no users found<span class="p">&lt;/</span><span class="nt">em</span><span class="p">&gt;&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>Note that, in Python, <code class="code docutils literal notranslate"><span class="pre">else</span></code> blocks are executed whenever the corresponding
loop <strong>did not</strong> <code class="code docutils literal notranslate"><span class="pre">break</span></code>.  Since Jinja loops cannot <code class="code docutils literal notranslate"><span class="pre">break</span></code> anyway,
a slightly different behavior of the <code class="code docutils literal notranslate"><span class="pre">else</span></code> keyword was chosen.</p>
<p>It is also possible to use loops recursively.  This is useful if you are
dealing with recursive data such as sitemaps or RDFa.
To use loops recursively, you basically have to add the <code class="code docutils literal notranslate"><span class="pre">recursive</span></code> modifier
to the loop definition and call the <code class="code docutils literal notranslate"><span class="pre">loop</span></code> variable with the new iterable
where you want to recurse.</p>
<p>The following example implements a sitemap with recursive loops:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;sitemap&quot;</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">sitemap</span> <span class="k">recursive</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;&lt;</span><span class="nt">a</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">item.href</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">item.title</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">a</span><span class="p">&gt;</span>
    <span class="cp">{%</span>- <span class="k">if</span> <span class="nv">item.children</span> -<span class="cp">%}</span>
        <span class="p">&lt;</span><span class="nt">ul</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;submenu&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nb">loop</span><span class="o">(</span><span class="nv">item.children</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
    <span class="cp">{%</span>- <span class="k">endif</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>The <code class="code docutils literal notranslate"><span class="pre">loop</span></code> variable always refers to the closest (innermost) loop. If we
have more than one level of loops, we can rebind the variable <code class="code docutils literal notranslate"><span class="pre">loop</span></code> by
writing <code class="code docutils literal notranslate"><span class="pre">{%</span> <span class="pre">set</span> <span class="pre">outer_loop</span> <span class="pre">=</span> <span class="pre">loop</span> <span class="pre">%}</span></code> after the loop that we want to
use recursively. Then, we can call it using <code class="code docutils literal notranslate"><span class="pre">{{</span> <span class="pre">outer_loop(...)</span> <span class="pre">}}</span></code></p>
<p>Please note that assignments in loops will be cleared at the end of the
iteration and cannot outlive the loop scope.  Older versions of Jinja had
a bug where in some circumstances it appeared that assignments would work.
This is not supported.  See <a class="reference internal" href="#assignments"><span class="std std-ref">Assignments</span></a> for more information about
how to deal with this.</p>
<p>If all you want to do is check whether some value has changed since the
last iteration or will change in the next iteration, you can use <code class="code docutils literal notranslate"><span class="pre">previtem</span></code>
and <code class="code docutils literal notranslate"><span class="pre">nextitem</span></code>:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">values</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">if</span> <span class="nb">loop</span><span class="nv">.previtem</span> <span class="k">is</span> <span class="nf">defined</span> <span class="k">and</span> <span class="nv">value</span> <span class="o">&gt;</span> <span class="nb">loop</span><span class="nv">.previtem</span> <span class="cp">%}</span>
        The value just increased!
    <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">value</span> <span class="cp">}}</span>
    <span class="cp">{%</span> <span class="k">if</span> <span class="nb">loop</span><span class="nv">.nextitem</span> <span class="k">is</span> <span class="nf">defined</span> <span class="k">and</span> <span class="nb">loop</span><span class="nv">.nextitem</span> <span class="o">&gt;</span> <span class="nv">value</span> <span class="cp">%}</span>
        The value will increase even more!
    <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>If you only care whether the value changed at all, using <code class="code docutils literal notranslate"><span class="pre">changed</span></code> is even
easier:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">entry</span> <span class="k">in</span> <span class="nv">entries</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">if</span> <span class="nb">loop</span><span class="nv">.changed</span><span class="o">(</span><span class="nv">entry.category</span><span class="o">)</span> <span class="cp">%}</span>
        <span class="p">&lt;</span><span class="nt">h2</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">entry.category</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">h2</span><span class="p">&gt;</span>
    <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">entry.message</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="if">
<span id="id8"></span><h3>If<a class="headerlink" href="#if" title="Link to this heading">¶</a></h3>
<p>The <code class="code docutils literal notranslate"><span class="pre">if</span></code> statement in Jinja is comparable with the Python if statement.
In the simplest form, you can use it to test if a variable is defined, not
empty and not false:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="nv">users</span> <span class="cp">%}</span>
<span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.username</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>For multiple branches, <code class="code docutils literal notranslate"><span class="pre">elif</span></code> and <code class="code docutils literal notranslate"><span class="pre">else</span></code> can be used like in Python.  You can
use more complex <a class="reference internal" href="#expressions"><span class="std std-ref">Expressions</span></a> there, too:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="nv">kenny.sick</span> <span class="cp">%}</span>
    Kenny is sick.
<span class="cp">{%</span> <span class="k">elif</span> <span class="nv">kenny.dead</span> <span class="cp">%}</span>
    You killed Kenny!  You bastard!!!
<span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
    Kenny looks okay --- so far
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>If can also be used as an <a class="reference internal" href="#if-expression"><span class="std std-ref">inline expression</span></a> and for
<a class="reference internal" href="#loop-filtering"><span class="std std-ref">loop filtering</span></a>.</p>
</section>
<section id="macros">
<span id="id9"></span><h3>Macros<a class="headerlink" href="#macros" title="Link to this heading">¶</a></h3>
<p>Macros are comparable with functions in regular programming languages.  They
are useful to put often used idioms into reusable functions to not repeat
yourself (“DRY”).</p>
<p>Here’s a small example of a macro that renders a form element:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">macro</span> <span class="nv">input</span><span class="o">(</span><span class="nv">name</span><span class="o">,</span> <span class="nv">value</span><span class="o">=</span><span class="s1">&#39;&#39;</span><span class="o">,</span> <span class="nv">type</span><span class="o">=</span><span class="s1">&#39;text&#39;</span><span class="o">,</span> <span class="nv">size</span><span class="o">=</span><span class="m">20</span><span class="o">)</span> -<span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">input</span> <span class="na">type</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">type</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">name</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">name</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">value</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span>
        <span class="nv">value</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">size</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">size</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endmacro</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The macro can then be called like a function in the namespace:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">input</span><span class="o">(</span><span class="s1">&#39;username&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">input</span><span class="o">(</span><span class="s1">&#39;password&#39;</span><span class="o">,</span> <span class="nv">type</span><span class="o">=</span><span class="s1">&#39;password&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>If the macro was defined in a different template, you have to
<a class="reference internal" href="#import"><span class="std std-ref">import</span></a> it first.</p>
<p>Inside macros, you have access to three special variables:</p>
<dl class="simple">
<dt><code class="code docutils literal notranslate"><span class="pre">varargs</span></code></dt><dd><p>If more positional arguments are passed to the macro than accepted by the
macro, they end up in the special <code class="code docutils literal notranslate"><span class="pre">varargs</span></code> variable as a list of values.</p>
</dd>
<dt><code class="code docutils literal notranslate"><span class="pre">kwargs</span></code></dt><dd><p>Like <code class="code docutils literal notranslate"><span class="pre">varargs</span></code> but for keyword arguments.  All unconsumed keyword
arguments are stored in this special variable.</p>
</dd>
<dt><code class="code docutils literal notranslate"><span class="pre">caller</span></code></dt><dd><p>If the macro was called from a <a class="reference internal" href="#call"><span class="std std-ref">call</span></a> tag, the caller is stored
in this variable as a callable macro.</p>
</dd>
</dl>
<p>Macros also expose some of their internal details.  The following attributes
are available on a macro object:</p>
<dl class="simple">
<dt><code class="code docutils literal notranslate"><span class="pre">name</span></code></dt><dd><p>The name of the macro.  <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">input.name</span> <span class="pre">}}</span></code> will print <code class="docutils literal notranslate"><span class="pre">input</span></code>.</p>
</dd>
<dt><code class="code docutils literal notranslate"><span class="pre">arguments</span></code></dt><dd><p>A tuple of the names of arguments the macro accepts.</p>
</dd>
<dt><code class="code docutils literal notranslate"><span class="pre">catch_kwargs</span></code></dt><dd><p>This is <code class="code docutils literal notranslate"><span class="pre">true</span></code> if the macro accepts extra keyword arguments (i.e.: accesses
the special <code class="code docutils literal notranslate"><span class="pre">kwargs</span></code> variable).</p>
</dd>
<dt><code class="code docutils literal notranslate"><span class="pre">catch_varargs</span></code></dt><dd><p>This is <code class="code docutils literal notranslate"><span class="pre">true</span></code> if the macro accepts extra positional arguments (i.e.:
accesses the special <code class="code docutils literal notranslate"><span class="pre">varargs</span></code> variable).</p>
</dd>
<dt><code class="code docutils literal notranslate"><span class="pre">caller</span></code></dt><dd><p>This is <code class="code docutils literal notranslate"><span class="pre">true</span></code> if the macro accesses the special <code class="code docutils literal notranslate"><span class="pre">caller</span></code> variable and may
be called from a <a class="reference internal" href="#call"><span class="std std-ref">call</span></a> tag.</p>
</dd>
</dl>
<p>If a macro name starts with an underscore, it’s not exported and can’t
be imported.</p>
<p>Due to how scopes work in Jinja, a macro in a child template does not
override a macro in a parent template. The following will output
“LAYOUT”, not “CHILD”.</p>
<div class="literal-block-wrapper docutils container" id="id23">
<div class="code-block-caption"><span class="caption-text"><code class="docutils literal notranslate"><span class="pre">layout.txt</span></code></span><a class="headerlink" href="#id23" title="Link to this code">¶</a></div>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">macro</span> <span class="nv">foo</span><span class="o">()</span> <span class="cp">%}</span><span class="x">LAYOUT</span><span class="cp">{%</span> <span class="k">endmacro</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</div>
<div class="literal-block-wrapper docutils container" id="id24">
<div class="code-block-caption"><span class="caption-text"><code class="docutils literal notranslate"><span class="pre">child.txt</span></code></span><a class="headerlink" href="#id24" title="Link to this code">¶</a></div>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="s1">&#39;layout.txt&#39;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">macro</span> <span class="nv">foo</span><span class="o">()</span> <span class="cp">%}</span><span class="x">CHILD</span><span class="cp">{%</span> <span class="k">endmacro</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">block</span> <span class="nv">body</span> <span class="cp">%}{{</span> <span class="nv">foo</span><span class="o">()</span> <span class="cp">}}{%</span> <span class="k">endblock</span> <span class="cp">%}</span>
</pre></div>
</div>
</div>
</section>
<section id="call">
<span id="id10"></span><h3>Call<a class="headerlink" href="#call" title="Link to this heading">¶</a></h3>
<p>In some cases it can be useful to pass a macro to another macro.  For this
purpose, you can use the special <code class="code docutils literal notranslate"><span class="pre">call</span></code> block.  The following example shows
a macro that takes advantage of the call functionality and how it can be
used:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">macro</span> <span class="nv">render_dialog</span><span class="o">(</span><span class="nv">title</span><span class="o">,</span> <span class="nv">class</span><span class="o">=</span><span class="s1">&#39;dialog&#39;</span><span class="o">)</span> -<span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">class</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">h2</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">title</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">h2</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;contents&quot;</span><span class="p">&gt;</span>
            <span class="cp">{{</span> <span class="nv">caller</span><span class="o">()</span> <span class="cp">}}</span>
        <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
    <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endmacro</span> <span class="cp">%}</span>

<span class="cp">{%</span> <span class="k">call</span> <span class="nv">render_dialog</span><span class="o">(</span><span class="s1">&#39;Hello World&#39;</span><span class="o">)</span> <span class="cp">%}</span>
    This is a simple dialog rendered by using a macro and
    a call block.
<span class="cp">{%</span> <span class="k">endcall</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>It’s also possible to pass arguments back to the call block.  This makes it
useful as a replacement for loops.  Generally speaking, a call block works
exactly like a macro without a name.</p>
<p>Here’s an example of how a call block can be used with arguments:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">macro</span> <span class="nv">dump_users</span><span class="o">(</span><span class="nv">users</span><span class="o">)</span> -<span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
    <span class="cp">{%</span>- <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
        <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;&lt;</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.username</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">caller</span><span class="o">(</span><span class="nv">user</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
    <span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
    <span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endmacro</span> <span class="cp">%}</span>

<span class="cp">{%</span> <span class="k">call</span><span class="o">(</span><span class="nv">user</span><span class="o">)</span> <span class="nv">dump_users</span><span class="o">(</span><span class="nv">list_of_user</span><span class="o">)</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">dl</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span>Realname<span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.realname</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span>Description<span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.description</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
    <span class="p">&lt;/</span><span class="nt">dl</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endcall</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="id11">
<h3>Filters<a class="headerlink" href="#id11" title="Link to this heading">¶</a></h3>
<p>Filter sections allow you to apply regular Jinja filters on a block of
template data.  Just wrap the code in the special <code class="code docutils literal notranslate"><span class="pre">filter</span></code> section:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">filter</span> <span class="nf">upper</span> <span class="cp">%}</span>
    This text becomes uppercase
<span class="cp">{%</span> <span class="k">endfilter</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Filters that accept arguments can be called like this:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">filter</span> <span class="nf">center</span><span class="o">(</span><span class="m">100</span><span class="o">)</span> <span class="cp">%}</span>Center this<span class="cp">{%</span> <span class="k">endfilter</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="assignments">
<span id="id12"></span><h3>Assignments<a class="headerlink" href="#assignments" title="Link to this heading">¶</a></h3>
<p>Inside code blocks, you can also assign values to variables.  Assignments at
top level (outside of blocks, macros or loops) are exported from the template
like top level macros and can be imported by other templates.</p>
<p>Assignments use the <code class="code docutils literal notranslate"><span class="pre">set</span></code> tag and can have multiple targets:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">navigation</span> <span class="o">=</span> <span class="o">[(</span><span class="s1">&#39;index.html&#39;</span><span class="o">,</span> <span class="s1">&#39;Index&#39;</span><span class="o">),</span> <span class="o">(</span><span class="s1">&#39;about.html&#39;</span><span class="o">,</span> <span class="s1">&#39;About&#39;</span><span class="o">)]</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">set</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="o">=</span> <span class="nv">call_something</span><span class="o">()</span> <span class="cp">%}</span>
</pre></div>
</div>
<div class="admonition-scoping-behavior admonition">
<p class="admonition-title">Scoping Behavior</p>
<p>Please keep in mind that it is not possible to set variables inside a
block and have them show up outside of it.  This also applies to
loops.  The only exception to that rule are if statements which do not
introduce a scope.  As a result the following template is not going
to do what you might expect:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">iterated</span> <span class="o">=</span> <span class="kp">false</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">seq</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span>
    <span class="cp">{%</span> <span class="k">set</span> <span class="nv">iterated</span> <span class="o">=</span> <span class="kp">true</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">if</span> <span class="k">not</span> <span class="nv">iterated</span> <span class="cp">%}</span> did not iterate <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>It is not possible with Jinja syntax to do this.  Instead use
alternative constructs like the loop else block or the special <code class="code docutils literal notranslate"><span class="pre">loop</span></code>
variable:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">seq</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
    did not iterate
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>As of version 2.10 more complex use cases can be handled using namespace
objects which allow propagating of changes across scopes:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">ns</span> <span class="o">=</span> <span class="nv">namespace</span><span class="o">(</span><span class="nv">found</span><span class="o">=</span><span class="kp">false</span><span class="o">)</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">items</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">if</span> <span class="nv">item.check_something</span><span class="o">()</span> <span class="cp">%}</span>
        <span class="cp">{%</span> <span class="k">set</span> <span class="nv">ns.found</span> <span class="o">=</span> <span class="kp">true</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
    * <span class="cp">{{</span> <span class="nv">item.title</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
Found item having something: <span class="cp">{{</span> <span class="nv">ns.found</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Note that the <code class="docutils literal notranslate"><span class="pre">obj.attr</span></code> notation in the <code class="code docutils literal notranslate"><span class="pre">set</span></code> tag is only allowed for
namespace objects; attempting to assign an attribute on any other object
will raise an exception.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.10: </span>Added support for namespace objects</p>
</div>
</details></div>
</section>
<section id="block-assignments">
<h3>Block Assignments<a class="headerlink" href="#block-assignments" title="Link to this heading">¶</a></h3>
<p>It’s possible to use <code class="code docutils literal notranslate"><span class="pre">set</span></code> as a block to assign the content of the block to a
variable. This can be used to create multi-line strings, since Jinja doesn’t
support Python’s triple quotes (<code class="docutils literal notranslate"><span class="pre">&quot;&quot;&quot;</span></code>, <code class="docutils literal notranslate"><span class="pre">'''</span></code>).</p>
<p>Instead of using an equals sign and a value, you only write the variable name,
and everything until <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">endset</span> <span class="pre">%}</span></code> is captured.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">navigation</span> <span class="cp">%}</span>
<span class="x">    &lt;li&gt;&lt;a href=&quot;/&quot;&gt;Index&lt;/a&gt;</span>
<span class="x">    &lt;li&gt;&lt;a href=&quot;/downloads&quot;&gt;Downloads&lt;/a&gt;</span>
<span class="cp">{%</span> <span class="k">endset</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Filters applied to the variable name will be applied to the block’s content.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">reply</span> <span class="o">|</span> <span class="nf">wordwrap</span> <span class="cp">%}</span>
<span class="x">    You wrote:</span>
<span class="x">    </span><span class="cp">{{</span> <span class="nv">message</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endset</span> <span class="cp">%}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.10: </span>Block assignment supports filters.</p>
</div>
<div class="versionadded">
<p><span class="versionmodified added">Added in version 2.8.</span></p>
</div>
</details></section>
<section id="extends">
<span id="id13"></span><h3>Extends<a class="headerlink" href="#extends" title="Link to this heading">¶</a></h3>
<p>The <code class="code docutils literal notranslate"><span class="pre">extends</span></code> tag can be used to extend one template from another.  You can
have multiple <code class="code docutils literal notranslate"><span class="pre">extends</span></code> tags in a file, but only one of them may be executed at
a time.</p>
<p>See the section about <a class="reference internal" href="#template-inheritance"><span class="std std-ref">Template Inheritance</span></a> above.</p>
</section>
<section id="blocks">
<span id="id14"></span><h3>Blocks<a class="headerlink" href="#blocks" title="Link to this heading">¶</a></h3>
<p>Blocks are used for inheritance and act as both placeholders and replacements
at the same time.  They are documented in detail in the
<a class="reference internal" href="#template-inheritance"><span class="std std-ref">Template Inheritance</span></a> section.</p>
</section>
<section id="include">
<h3>Include<a class="headerlink" href="#include" title="Link to this heading">¶</a></h3>
<p>The <code class="docutils literal notranslate"><span class="pre">include</span></code> tag renders another template and outputs the result into
the current template.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">include</span> <span class="s1">&#39;header.html&#39;</span> <span class="cp">%}</span>
<span class="x">Body goes here.</span>
<span class="cp">{%</span> <span class="k">include</span> <span class="s1">&#39;footer.html&#39;</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The included template has access to context of the current template by
default. Use <code class="docutils literal notranslate"><span class="pre">without</span> <span class="pre">context</span></code> to use a separate context instead.
<code class="docutils literal notranslate"><span class="pre">with</span> <span class="pre">context</span></code> is also valid, but is the default behavior. See
<a class="reference internal" href="#import-visibility"><span class="std std-ref">Import Context Behavior</span></a>.</p>
<p>The included template can <code class="docutils literal notranslate"><span class="pre">extend</span></code> another template and override
blocks in that template. However, the current template cannot override
any blocks that the included template outputs.</p>
<p>Use <code class="docutils literal notranslate"><span class="pre">ignore</span> <span class="pre">missing</span></code> to ignore the statement if the template does not
exist. It must be placed <em>before</em> a context visibility statement.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">include</span> <span class="s2">&quot;sidebar.html&quot;</span> <span class="k">without context</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">include</span> <span class="s2">&quot;sidebar.html&quot;</span> <span class="k">ignore missing</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">include</span> <span class="s2">&quot;sidebar.html&quot;</span> <span class="k">ignore missing</span> <span class="k">with context</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">include</span> <span class="s2">&quot;sidebar.html&quot;</span> <span class="k">ignore missing</span> <span class="k">without context</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>If a list of templates is given, each will be tried in order until one
is not missing. This can be used with <code class="docutils literal notranslate"><span class="pre">ignore</span> <span class="pre">missing</span></code> to ignore if
none of the templates exist.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">include</span> <span class="o">[</span><span class="s1">&#39;page_detailed.html&#39;</span><span class="o">,</span> <span class="s1">&#39;page.html&#39;</span><span class="o">]</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">include</span> <span class="o">[</span><span class="s1">&#39;special_sidebar.html&#39;</span><span class="o">,</span> <span class="s1">&#39;sidebar.html&#39;</span><span class="o">]</span> <span class="k">ignore missing</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>A variable, with either a template name or template object, can also be
passed to the statement.</p>
</section>
<section id="import">
<span id="id15"></span><h3>Import<a class="headerlink" href="#import" title="Link to this heading">¶</a></h3>
<p>Jinja supports putting often used code into macros.  These macros can go into
different templates and get imported from there.  This works similarly to the
import statements in Python.  It’s important to know that imports are cached
and imported templates don’t have access to the current template variables,
just the globals by default.  For more details about context behavior of
imports and includes, see <a class="reference internal" href="#import-visibility"><span class="std std-ref">Import Context Behavior</span></a>.</p>
<p>There are two ways to import templates.  You can import a complete template
into a variable or request specific macros / exported variables from it.</p>
<p>Imagine we have a helper module that renders forms (called <code class="code docutils literal notranslate"><span class="pre">forms.html</span></code>):</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">macro</span> <span class="nv">input</span><span class="o">(</span><span class="nv">name</span><span class="o">,</span> <span class="nv">value</span><span class="o">=</span><span class="s1">&#39;&#39;</span><span class="o">,</span> <span class="nv">type</span><span class="o">=</span><span class="s1">&#39;text&#39;</span><span class="o">)</span> -<span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">input</span> <span class="na">type</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">type</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">value</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">value</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">name</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">name</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endmacro</span> <span class="cp">%}</span>

<span class="cp">{%</span>- <span class="k">macro</span> <span class="nv">textarea</span><span class="o">(</span><span class="nv">name</span><span class="o">,</span> <span class="nv">value</span><span class="o">=</span><span class="s1">&#39;&#39;</span><span class="o">,</span> <span class="nv">rows</span><span class="o">=</span><span class="m">10</span><span class="o">,</span> <span class="nv">cols</span><span class="o">=</span><span class="m">40</span><span class="o">)</span> -<span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">textarea</span> <span class="na">name</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">name</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">rows</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">rows</span> <span class="cp">}}</span><span class="s">&quot;</span> <span class="na">cols</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">cols</span>
        <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">value</span><span class="o">|</span><span class="nf">e</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">textarea</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endmacro</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The easiest and most flexible way to access a template’s variables
and macros is to import the whole template module into a variable.
That way, you can access the attributes:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">import</span> <span class="s1">&#39;forms.html&#39;</span> <span class="k">as</span> <span class="nv">forms</span> <span class="cp">%}</span>
<span class="p">&lt;</span><span class="nt">dl</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span>Username<span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">forms.input</span><span class="o">(</span><span class="s1">&#39;username&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span>Password<span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">forms.input</span><span class="o">(</span><span class="s1">&#39;password&#39;</span><span class="o">,</span> <span class="nv">type</span><span class="o">=</span><span class="s1">&#39;password&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">dl</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">forms.textarea</span><span class="o">(</span><span class="s1">&#39;comment&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>Alternatively, you can import specific names from a template into the current
namespace:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">from</span> <span class="s1">&#39;forms.html&#39;</span> <span class="k">import</span> <span class="nv">input</span> <span class="k">as</span> <span class="nv">input_field</span><span class="o">,</span> <span class="nv">textarea</span> <span class="cp">%}</span>
<span class="p">&lt;</span><span class="nt">dl</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span>Username<span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">input_field</span><span class="o">(</span><span class="s1">&#39;username&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span>Password<span class="p">&lt;/</span><span class="nt">dt</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">input_field</span><span class="o">(</span><span class="s1">&#39;password&#39;</span><span class="o">,</span> <span class="nv">type</span><span class="o">=</span><span class="s1">&#39;password&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">dd</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">dl</span><span class="p">&gt;</span>
<span class="p">&lt;</span><span class="nt">p</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">textarea</span><span class="o">(</span><span class="s1">&#39;comment&#39;</span><span class="o">)</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">p</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>Macros and variables starting with one or more underscores are private and
cannot be imported.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.4: </span>If a template object was passed to the template context, you can
import from that object.</p>
</div>
</details></section>
</section>
<section id="import-context-behavior">
<span id="import-visibility"></span><h2>Import Context Behavior<a class="headerlink" href="#import-context-behavior" title="Link to this heading">¶</a></h2>
<p>By default, included templates are passed the current context and imported
templates are not.  The reason for this is that imports, unlike includes,
are cached; as imports are often used just as a module that holds macros.</p>
<p>This behavior can be changed explicitly: by adding <code class="code docutils literal notranslate"><span class="pre">with</span> <span class="pre">context</span></code>
or <code class="code docutils literal notranslate"><span class="pre">without</span> <span class="pre">context</span></code> to the import/include directive, the current context
can be passed to the template and caching is disabled automatically.</p>
<p>Here are two examples:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">from</span> <span class="s1">&#39;forms.html&#39;</span> <span class="k">import</span> <span class="nv">input</span> <span class="k">with context</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">include</span> <span class="s1">&#39;header.html&#39;</span> <span class="k">without context</span> <span class="cp">%}</span>
</pre></div>
</div>
<div class="admonition-note admonition">
<p class="admonition-title">Note</p>
<p>In Jinja 2.0, the context that was passed to the included template
did not include variables defined in the template.  As a matter of
fact, this did not work:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">box</span> <span class="k">in</span> <span class="nv">boxes</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">include</span> <span class="s2">&quot;render_box.html&quot;</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The included template <code class="docutils literal notranslate"><span class="pre">render_box.html</span></code> is <em>not</em> able to access
<code class="code docutils literal notranslate"><span class="pre">box</span></code> in Jinja 2.0. As of Jinja 2.1, <code class="docutils literal notranslate"><span class="pre">render_box.html</span></code> <em>is</em> able
to do so.</p>
</div>
</section>
<section id="expressions">
<span id="id16"></span><h2>Expressions<a class="headerlink" href="#expressions" title="Link to this heading">¶</a></h2>
<p>Jinja allows basic expressions everywhere.  These work very similarly to
regular Python; even if you’re not working with Python
you should feel comfortable with it.</p>
<section id="literals">
<h3>Literals<a class="headerlink" href="#literals" title="Link to this heading">¶</a></h3>
<p>The simplest form of expressions are literals.  Literals are representations
for Python objects such as strings and numbers.  The following literals exist:</p>
<dl>
<dt><code class="docutils literal notranslate"><span class="pre">&quot;Hello</span> <span class="pre">World&quot;</span></code></dt><dd><p>Everything between two double or single quotes is a string.  They are
useful whenever you need a string in the template (e.g. as
arguments to function calls and filters, or just to extend or include a
template).</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">42</span></code> / <code class="docutils literal notranslate"><span class="pre">123_456</span></code></dt><dd><p>Integers are whole numbers without a decimal part. The ‘_’ character
can be used to separate groups for legibility.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">42.23</span></code> / <code class="docutils literal notranslate"><span class="pre">42.1e2</span></code> / <code class="docutils literal notranslate"><span class="pre">123_456.789</span></code></dt><dd><p>Floating point numbers can be written using a ‘.’ as a decimal mark.
They can also be written in scientific notation with an upper or
lower case ‘e’ to indicate the exponent part. The ‘_’ character can
be used to separate groups for legibility, but cannot be used in the
exponent part.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">['list',</span> <span class="pre">'of',</span> <span class="pre">'objects']</span></code></dt><dd><p>Everything between two brackets is a list.  Lists are useful for storing
sequential data to be iterated over.  For example, you can easily
create a list of links using lists and tuples for (and with) a for loop:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">href</span><span class="o">,</span> <span class="nv">caption</span> <span class="k">in</span> <span class="o">[(</span><span class="s1">&#39;index.html&#39;</span><span class="o">,</span> <span class="s1">&#39;Index&#39;</span><span class="o">),</span> <span class="o">(</span><span class="s1">&#39;about.html&#39;</span><span class="o">,</span> <span class="s1">&#39;About&#39;</span><span class="o">),</span>
                         <span class="o">(</span><span class="s1">&#39;downloads.html&#39;</span><span class="o">,</span> <span class="s1">&#39;Downloads&#39;</span><span class="o">)]</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;&lt;</span><span class="nt">a</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;</span><span class="cp">{{</span> <span class="nv">href</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">caption</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">a</span><span class="p">&gt;&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">('tuple',</span> <span class="pre">'of',</span> <span class="pre">'values')</span></code></dt><dd><p>Tuples are like lists that cannot be modified (“immutable”).  If a tuple
only has one item, it must be followed by a comma (<code class="docutils literal notranslate"><span class="pre">('1-tuple',)</span></code>).
Tuples are usually used to represent items of two or more elements.
See the list example above for more details.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">{'dict':</span> <span class="pre">'of',</span> <span class="pre">'key':</span> <span class="pre">'and',</span> <span class="pre">'value':</span> <span class="pre">'pairs'}</span></code></dt><dd><p>A dict in Python is a structure that combines keys and values.  Keys must
be unique and always have exactly one value.  Dicts are rarely used in
templates; they are useful in some rare cases such as the <code class="xref py py-func docutils literal notranslate"><span class="pre">xmlattr()</span></code>
filter.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">true</span></code> / <code class="docutils literal notranslate"><span class="pre">false</span></code></dt><dd><p><code class="docutils literal notranslate"><span class="pre">true</span></code> is always true and <code class="docutils literal notranslate"><span class="pre">false</span></code> is always false.</p>
</dd>
</dl>
<div class="admonition-note admonition">
<p class="admonition-title">Note</p>
<p>The special constants <code class="code docutils literal notranslate"><span class="pre">true</span></code>, <code class="code docutils literal notranslate"><span class="pre">false</span></code>, and <code class="code docutils literal notranslate"><span class="pre">none</span></code> are indeed lowercase.
Because that caused confusion in the past, (<code class="code docutils literal notranslate"><span class="pre">True</span></code> used to expand
to an undefined variable that was considered false),
all three can now also be written in title case
(<code class="code docutils literal notranslate"><span class="pre">True</span></code>, <code class="code docutils literal notranslate"><span class="pre">False</span></code>, and <code class="code docutils literal notranslate"><span class="pre">None</span></code>).
However, for consistency, (all Jinja identifiers are lowercase)
you should use the lowercase versions.</p>
</div>
</section>
<section id="math">
<h3>Math<a class="headerlink" href="#math" title="Link to this heading">¶</a></h3>
<p>Jinja allows you to calculate with values.  This is rarely useful in templates
but exists for completeness’ sake.  The following operators are supported:</p>
<dl>
<dt><code class="docutils literal notranslate"><span class="pre">+</span></code></dt><dd><p>Adds two objects together. Usually the objects are numbers, but if both are
strings or lists, you can concatenate them this way.  This, however, is not
the preferred way to concatenate strings!  For string concatenation, have
a look-see at the <code class="docutils literal notranslate"><span class="pre">~</span></code> operator.  <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">1</span> <span class="pre">+</span> <span class="pre">1</span> <span class="pre">}}</span></code> is <code class="docutils literal notranslate"><span class="pre">2</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">-</span></code></dt><dd><p>Subtract the second number from the first one.  <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">3</span> <span class="pre">-</span> <span class="pre">2</span> <span class="pre">}}</span></code> is <code class="docutils literal notranslate"><span class="pre">1</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">/</span></code></dt><dd><p>Divide two numbers.  The return value will be a floating point number.
<code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">1</span> <span class="pre">/</span> <span class="pre">2</span> <span class="pre">}}</span></code> is <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">0.5</span> <span class="pre">}}</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">//</span></code></dt><dd><p>Divide two numbers and return the truncated integer result.
<code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">20</span> <span class="pre">//</span> <span class="pre">7</span> <span class="pre">}}</span></code> is <code class="docutils literal notranslate"><span class="pre">2</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">%</span></code></dt><dd><p>Calculate the remainder of an integer division.  <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">11</span> <span class="pre">%</span> <span class="pre">7</span> <span class="pre">}}</span></code> is <code class="docutils literal notranslate"><span class="pre">4</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">*</span></code></dt><dd><p>Multiply the left operand with the right one.  <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">2</span> <span class="pre">*</span> <span class="pre">2</span> <span class="pre">}}</span></code> would
return <code class="docutils literal notranslate"><span class="pre">4</span></code>.  This can also be used to repeat a string multiple times.
<code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">'='</span> <span class="pre">*</span> <span class="pre">80</span> <span class="pre">}}</span></code> would print a bar of 80 equal signs.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">**</span></code></dt><dd><p>Raise the left operand to the power of the right operand.
<code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">2**3</span> <span class="pre">}}</span></code> would return <code class="docutils literal notranslate"><span class="pre">8</span></code>.</p>
<p>Unlike Python, chained pow is evaluated left to right.
<code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">3**3**3</span> <span class="pre">}}</span></code> is evaluated as <code class="docutils literal notranslate"><span class="pre">(3**3)**3</span></code> in Jinja, but would
be evaluated as <code class="docutils literal notranslate"><span class="pre">3**(3**3)</span></code> in Python. Use parentheses in Jinja
to be explicit about what order you want. It is usually preferable
to do extended math in Python and pass the results to <code class="docutils literal notranslate"><span class="pre">render</span></code>
rather than doing it in the template.</p>
<p>This behavior may be changed in the future to match Python, if it’s
possible to introduce an upgrade path.</p>
</dd>
</dl>
</section>
<section id="comparisons">
<h3>Comparisons<a class="headerlink" href="#comparisons" title="Link to this heading">¶</a></h3>
<dl class="simple">
<dt><code class="docutils literal notranslate"><span class="pre">==</span></code></dt><dd><p>Compares two objects for equality.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">!=</span></code></dt><dd><p>Compares two objects for inequality.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">&gt;</span></code></dt><dd><p><code class="docutils literal notranslate"><span class="pre">true</span></code> if the left hand side is greater than the right hand side.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">&gt;=</span></code></dt><dd><p><code class="docutils literal notranslate"><span class="pre">true</span></code> if the left hand side is greater or equal to the right hand side.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">&lt;</span></code></dt><dd><p><code class="docutils literal notranslate"><span class="pre">true</span></code> if the left hand side is lower than the right hand side.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">&lt;=</span></code></dt><dd><p><code class="docutils literal notranslate"><span class="pre">true</span></code> if the left hand side is lower or equal to the right hand side.</p>
</dd>
</dl>
</section>
<section id="logic">
<h3>Logic<a class="headerlink" href="#logic" title="Link to this heading">¶</a></h3>
<p>For <code class="docutils literal notranslate"><span class="pre">if</span></code> statements, <code class="docutils literal notranslate"><span class="pre">for</span></code> filtering, and <code class="docutils literal notranslate"><span class="pre">if</span></code> expressions, it can be
useful to combine multiple expressions.</p>
<dl>
<dt><code class="docutils literal notranslate"><span class="pre">and</span></code></dt><dd><p>For <code class="docutils literal notranslate"><span class="pre">x</span> <span class="pre">and</span> <span class="pre">y</span></code>, if <code class="docutils literal notranslate"><span class="pre">x</span></code> is false, then the value is <code class="docutils literal notranslate"><span class="pre">x</span></code>, else <code class="docutils literal notranslate"><span class="pre">y</span></code>. In
a boolean context, this will be treated as <code class="docutils literal notranslate"><span class="pre">True</span></code> if both operands are
truthy.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">or</span></code></dt><dd><p>For <code class="docutils literal notranslate"><span class="pre">x</span> <span class="pre">or</span> <span class="pre">y</span></code>, if <code class="docutils literal notranslate"><span class="pre">x</span></code> is true, then the value is <code class="docutils literal notranslate"><span class="pre">x</span></code>, else <code class="docutils literal notranslate"><span class="pre">y</span></code>. In a
boolean context, this will be treated as <code class="docutils literal notranslate"><span class="pre">True</span></code> if at least one operand is
truthy.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">not</span></code></dt><dd><p>For <code class="docutils literal notranslate"><span class="pre">not</span> <span class="pre">x</span></code>, if <code class="docutils literal notranslate"><span class="pre">x</span></code> is false, then the value is <code class="docutils literal notranslate"><span class="pre">True</span></code>, else
<code class="docutils literal notranslate"><span class="pre">False</span></code>.</p>
<p>Prefer negating <code class="docutils literal notranslate"><span class="pre">is</span></code> and <code class="docutils literal notranslate"><span class="pre">in</span></code> using their infix notation:
<code class="docutils literal notranslate"><span class="pre">foo</span> <span class="pre">is</span> <span class="pre">not</span> <span class="pre">bar</span></code> instead of <code class="docutils literal notranslate"><span class="pre">not</span> <span class="pre">foo</span> <span class="pre">is</span> <span class="pre">bar</span></code>; <code class="docutils literal notranslate"><span class="pre">foo</span> <span class="pre">not</span> <span class="pre">in</span> <span class="pre">bar</span></code> instead
of <code class="docutils literal notranslate"><span class="pre">not</span> <span class="pre">foo</span> <span class="pre">in</span> <span class="pre">bar</span></code>. All other expressions require prefix notation:
<code class="docutils literal notranslate"><span class="pre">not</span> <span class="pre">(foo</span> <span class="pre">and</span> <span class="pre">bar).</span></code></p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">(expr)</span></code></dt><dd><p>Parentheses group an expression. This is used to change evaluation order, or
to make a long expression easier to read or less ambiguous.</p>
</dd>
</dl>
</section>
<section id="other-operators">
<h3>Other Operators<a class="headerlink" href="#other-operators" title="Link to this heading">¶</a></h3>
<p>The following operators are very useful but don’t fit into any of the other
two categories:</p>
<dl>
<dt><code class="docutils literal notranslate"><span class="pre">in</span></code></dt><dd><p>Perform a sequence / mapping containment test.  Returns true if the left
operand is contained in the right.  <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">1</span> <span class="pre">in</span> <span class="pre">[1,</span> <span class="pre">2,</span> <span class="pre">3]</span> <span class="pre">}}</span></code> would, for
example, return true.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">is</span></code></dt><dd><p>Performs a <a class="reference internal" href="#tests"><span class="std std-ref">test</span></a>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">|</span></code> (pipe, vertical bar)</dt><dd><p>Applies a <a class="reference internal" href="#filters"><span class="std std-ref">filter</span></a>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">~</span></code> (tilde)</dt><dd><p>Converts all operands into strings and concatenates them.</p>
<p><code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">&quot;Hello</span> <span class="pre">&quot;</span> <span class="pre">~</span> <span class="pre">name</span> <span class="pre">~</span> <span class="pre">&quot;!&quot;</span> <span class="pre">}}</span></code> would return (assuming <code class="code docutils literal notranslate"><span class="pre">name</span></code> is set
to <code class="docutils literal notranslate"><span class="pre">'John'</span></code>) <code class="docutils literal notranslate"><span class="pre">Hello</span> <span class="pre">John!</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">()</span></code></dt><dd><p>Call a callable: <code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">post.render()</span> <span class="pre">}}</span></code>.  Inside of the parentheses you
can use positional arguments and keyword arguments like in Python:</p>
<p><code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">post.render(user,</span> <span class="pre">full=true)</span> <span class="pre">}}</span></code>.</p>
</dd>
<dt><code class="docutils literal notranslate"><span class="pre">.</span></code> / <code class="docutils literal notranslate"><span class="pre">[]</span></code></dt><dd><p>Get an attribute of an object.  (See <a class="reference internal" href="#variables"><span class="std std-ref">Variables</span></a>)</p>
</dd>
</dl>
</section>
<section id="if-expression">
<span id="id17"></span><h3>If Expression<a class="headerlink" href="#if-expression" title="Link to this heading">¶</a></h3>
<p>It is also possible to use inline <code class="code docutils literal notranslate"><span class="pre">if</span></code> expressions.  These are useful in some
situations.  For example, you can use this to extend from one template if a
variable is defined, otherwise from the default layout template:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">extends</span> <span class="nv">layout_template</span> <span class="k">if</span> <span class="nv">layout_template</span> <span class="k">is</span> <span class="nf">defined</span> <span class="k">else</span> <span class="s1">&#39;default.html&#39;</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The general syntax is <code class="docutils literal notranslate"><span class="pre">&lt;do</span> <span class="pre">something&gt;</span> <span class="pre">if</span> <span class="pre">&lt;something</span> <span class="pre">is</span> <span class="pre">true&gt;</span> <span class="pre">else</span> <span class="pre">&lt;do</span>
<span class="pre">something</span> <span class="pre">else&gt;</span></code>.</p>
<p>The <code class="code docutils literal notranslate"><span class="pre">else</span></code> part is optional.  If not provided, the else block implicitly
evaluates into an <a class="reference internal" href="../api/#jinja2.Undefined" title="jinja2.Undefined"><code class="xref py py-class docutils literal notranslate"><span class="pre">Undefined</span></code></a> object (regardless of what <code class="docutils literal notranslate"><span class="pre">undefined</span></code>
in the environment is set to):</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="s2">&quot;[{}]&quot;</span><span class="nv">.format</span><span class="o">(</span><span class="nv">page.title</span><span class="o">)</span> <span class="k">if</span> <span class="nv">page.title</span> <span class="cp">}}</span>
</pre></div>
</div>
</section>
<section id="python-methods">
<span id="id18"></span><h3>Python Methods<a class="headerlink" href="#python-methods" title="Link to this heading">¶</a></h3>
<p>You can also use any of the methods defined on a variable’s type.
The value returned from the method invocation is used as the value of the expression.
Here is an example that uses methods defined on strings (where <code class="docutils literal notranslate"><span class="pre">page.title</span></code> is a string):</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>{{ page.title.capitalize() }}
</pre></div>
</div>
<p>This works for methods on user-defined types. For example, if variable
<code class="docutils literal notranslate"><span class="pre">f</span></code> of type <code class="docutils literal notranslate"><span class="pre">Foo</span></code> has a method <code class="docutils literal notranslate"><span class="pre">bar</span></code> defined on it, you can do the
following:</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>{{ f.bar(value) }}
</pre></div>
</div>
<p>Operator methods also work as expected. For example, <code class="docutils literal notranslate"><span class="pre">%</span></code> implements
printf-style for strings:</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>{{ &quot;Hello, %s!&quot; % name }}
</pre></div>
</div>
<p>Although you should prefer the <code class="docutils literal notranslate"><span class="pre">.format</span></code> method for that case (which
is a bit contrived in the context of rendering a template):</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>{{ &quot;Hello, {}!&quot;.format(name) }}
</pre></div>
</div>
</section>
</section>
<section id="list-of-builtin-filters">
<span id="builtin-filters"></span><h2>List of Builtin Filters<a class="headerlink" href="#list-of-builtin-filters" title="Link to this heading">¶</a></h2>
<table class="docutils align-left">
<tbody>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-filters.abs" title="jinja-filters.abs"><code class="xref py py-func docutils literal notranslate"><span class="pre">abs()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.forceescape" title="jinja-filters.forceescape"><code class="xref py py-func docutils literal notranslate"><span class="pre">forceescape()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.map" title="jinja-filters.map"><code class="xref py py-func docutils literal notranslate"><span class="pre">map()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.select" title="jinja-filters.select"><code class="xref py py-func docutils literal notranslate"><span class="pre">select()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.unique" title="jinja-filters.unique"><code class="xref py py-func docutils literal notranslate"><span class="pre">unique()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-filters.attr" title="jinja-filters.attr"><code class="xref py py-func docutils literal notranslate"><span class="pre">attr()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.format" title="jinja-filters.format"><code class="xref py py-func docutils literal notranslate"><span class="pre">format()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.max" title="jinja-filters.max"><code class="xref py py-func docutils literal notranslate"><span class="pre">max()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.selectattr" title="jinja-filters.selectattr"><code class="xref py py-func docutils literal notranslate"><span class="pre">selectattr()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.upper" title="jinja-filters.upper"><code class="xref py py-func docutils literal notranslate"><span class="pre">upper()</span></code></a></p></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-filters.batch" title="jinja-filters.batch"><code class="xref py py-func docutils literal notranslate"><span class="pre">batch()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.groupby" title="jinja-filters.groupby"><code class="xref py py-func docutils literal notranslate"><span class="pre">groupby()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.min" title="jinja-filters.min"><code class="xref py py-func docutils literal notranslate"><span class="pre">min()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.slice" title="jinja-filters.slice"><code class="xref py py-func docutils literal notranslate"><span class="pre">slice()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.urlencode" title="jinja-filters.urlencode"><code class="xref py py-func docutils literal notranslate"><span class="pre">urlencode()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-filters.capitalize" title="jinja-filters.capitalize"><code class="xref py py-func docutils literal notranslate"><span class="pre">capitalize()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.indent" title="jinja-filters.indent"><code class="xref py py-func docutils literal notranslate"><span class="pre">indent()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.pprint" title="jinja-filters.pprint"><code class="xref py py-func docutils literal notranslate"><span class="pre">pprint()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.sort" title="jinja-filters.sort"><code class="xref py py-func docutils literal notranslate"><span class="pre">sort()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.urlize" title="jinja-filters.urlize"><code class="xref py py-func docutils literal notranslate"><span class="pre">urlize()</span></code></a></p></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-filters.center" title="jinja-filters.center"><code class="xref py py-func docutils literal notranslate"><span class="pre">center()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.int" title="jinja-filters.int"><code class="xref py py-func docutils literal notranslate"><span class="pre">int()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.random" title="jinja-filters.random"><code class="xref py py-func docutils literal notranslate"><span class="pre">random()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.string" title="jinja-filters.string"><code class="xref py py-func docutils literal notranslate"><span class="pre">string()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.wordcount" title="jinja-filters.wordcount"><code class="xref py py-func docutils literal notranslate"><span class="pre">wordcount()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-filters.default" title="jinja-filters.default"><code class="xref py py-func docutils literal notranslate"><span class="pre">default()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.items" title="jinja-filters.items"><code class="xref py py-func docutils literal notranslate"><span class="pre">items()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.reject" title="jinja-filters.reject"><code class="xref py py-func docutils literal notranslate"><span class="pre">reject()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.striptags" title="jinja-filters.striptags"><code class="xref py py-func docutils literal notranslate"><span class="pre">striptags()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.wordwrap" title="jinja-filters.wordwrap"><code class="xref py py-func docutils literal notranslate"><span class="pre">wordwrap()</span></code></a></p></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-filters.dictsort" title="jinja-filters.dictsort"><code class="xref py py-func docutils literal notranslate"><span class="pre">dictsort()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.join" title="jinja-filters.join"><code class="xref py py-func docutils literal notranslate"><span class="pre">join()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.rejectattr" title="jinja-filters.rejectattr"><code class="xref py py-func docutils literal notranslate"><span class="pre">rejectattr()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.sum" title="jinja-filters.sum"><code class="xref py py-func docutils literal notranslate"><span class="pre">sum()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.xmlattr" title="jinja-filters.xmlattr"><code class="xref py py-func docutils literal notranslate"><span class="pre">xmlattr()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-filters.escape" title="jinja-filters.escape"><code class="xref py py-func docutils literal notranslate"><span class="pre">escape()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.last" title="jinja-filters.last"><code class="xref py py-func docutils literal notranslate"><span class="pre">last()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.replace" title="jinja-filters.replace"><code class="xref py py-func docutils literal notranslate"><span class="pre">replace()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.title" title="jinja-filters.title"><code class="xref py py-func docutils literal notranslate"><span class="pre">title()</span></code></a></p></td>
<td></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-filters.filesizeformat" title="jinja-filters.filesizeformat"><code class="xref py py-func docutils literal notranslate"><span class="pre">filesizeformat()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.length" title="jinja-filters.length"><code class="xref py py-func docutils literal notranslate"><span class="pre">length()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.reverse" title="jinja-filters.reverse"><code class="xref py py-func docutils literal notranslate"><span class="pre">reverse()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.tojson" title="jinja-filters.tojson"><code class="xref py py-func docutils literal notranslate"><span class="pre">tojson()</span></code></a></p></td>
<td></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-filters.first" title="jinja-filters.first"><code class="xref py py-func docutils literal notranslate"><span class="pre">first()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.list" title="jinja-filters.list"><code class="xref py py-func docutils literal notranslate"><span class="pre">list()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.round" title="jinja-filters.round"><code class="xref py py-func docutils literal notranslate"><span class="pre">round()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.trim" title="jinja-filters.trim"><code class="xref py py-func docutils literal notranslate"><span class="pre">trim()</span></code></a></p></td>
<td></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-filters.float" title="jinja-filters.float"><code class="xref py py-func docutils literal notranslate"><span class="pre">float()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.lower" title="jinja-filters.lower"><code class="xref py py-func docutils literal notranslate"><span class="pre">lower()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.safe" title="jinja-filters.safe"><code class="xref py py-func docutils literal notranslate"><span class="pre">safe()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-filters.truncate" title="jinja-filters.truncate"><code class="xref py py-func docutils literal notranslate"><span class="pre">truncate()</span></code></a></p></td>
<td></td>
</tr>
</tbody>
</table>
<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.abs">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">abs</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">x</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-filters.abs" title="Link to this definition">¶</a></dt>
<dd><p>Return the absolute value of the argument.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.attr">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">attr</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">obj</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">name</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference internal" href="../api/#jinja2.Undefined" title="jinja2.runtime.Undefined"><span class="pre">jinja2.runtime.Undefined</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">Any</span></span></span><a class="headerlink" href="#jinja-filters.attr" title="Link to this definition">¶</a></dt>
<dd><p>Get an attribute of an object. <code class="docutils literal notranslate"><span class="pre">foo|attr(&quot;bar&quot;)</span></code> works like
<code class="docutils literal notranslate"><span class="pre">foo.bar</span></code>, but returns undefined instead of falling back to <code class="docutils literal notranslate"><span class="pre">foo[&quot;bar&quot;]</span></code>
if the attribute doesn’t exist.</p>
<p>See <a class="reference internal" href="#notes-on-subscriptions"><span class="std std-ref">Notes on subscriptions</span></a> for more details.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.batch">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">batch</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">linecount</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">fill_with</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Optional[V]'</span></span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[t.List[V]]'</span></span></span></span><a class="headerlink" href="#jinja-filters.batch" title="Link to this definition">¶</a></dt>
<dd><p>A filter that batches items. It works pretty much like <code class="code docutils literal notranslate"><span class="pre">slice</span></code>
just the other way round. It returns a list of lists with the
given number of items. If you provide a second parameter this
is used to fill up missing items. See this example:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">table</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">for</span> <span class="nv">row</span> <span class="k">in</span> <span class="nv">items</span><span class="o">|</span><span class="nf">batch</span><span class="o">(</span><span class="m">3</span><span class="o">,</span> <span class="s1">&#39;&amp;nbsp;&#39;</span><span class="o">)</span> <span class="cp">%}</span>
  <span class="p">&lt;</span><span class="nt">tr</span><span class="p">&gt;</span>
  <span class="cp">{%</span>- <span class="k">for</span> <span class="nv">column</span> <span class="k">in</span> <span class="nv">row</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">td</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">column</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">td</span><span class="p">&gt;</span>
  <span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
  <span class="p">&lt;/</span><span class="nt">tr</span><span class="p">&gt;</span>
<span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">table</span><span class="p">&gt;</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.capitalize">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">capitalize</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.capitalize" title="Link to this definition">¶</a></dt>
<dd><p>Capitalize a value. The first character will be uppercase, all others
lowercase.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.center">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">center</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">width</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">80</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.center" title="Link to this definition">¶</a></dt>
<dd><p>Centers the value in a field of a given width.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.default">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">default</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">V</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">default_value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">V</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">''</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">boolean</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">V</span></span></span><a class="headerlink" href="#jinja-filters.default" title="Link to this definition">¶</a></dt>
<dd><p>If the value is undefined it will return the passed default value,
otherwise the value of the variable:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">my_variable</span><span class="o">|</span><span class="nf">default</span><span class="o">(</span><span class="s1">&#39;my_variable is not defined&#39;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>This will output the value of <code class="docutils literal notranslate"><span class="pre">my_variable</span></code> if the variable was
defined, otherwise <code class="docutils literal notranslate"><span class="pre">'my_variable</span> <span class="pre">is</span> <span class="pre">not</span> <span class="pre">defined'</span></code>. If you want
to use default with variables that evaluate to false you have to
set the second parameter to <code class="code docutils literal notranslate"><span class="pre">true</span></code>:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="s1">&#39;&#39;</span><span class="o">|</span><span class="nf">default</span><span class="o">(</span><span class="s1">&#39;the string was empty&#39;</span><span class="o">,</span> <span class="kp">true</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.11: </span>It’s now possible to configure the <a class="reference internal" href="../api/#jinja2.Environment" title="jinja2.Environment"><code class="xref py py-class docutils literal notranslate"><span class="pre">Environment</span></code></a> with
<a class="reference internal" href="../api/#jinja2.ChainableUndefined" title="jinja2.ChainableUndefined"><code class="xref py py-class docutils literal notranslate"><span class="pre">ChainableUndefined</span></code></a> to make the <code class="code docutils literal notranslate"><span class="pre">default</span></code> filter work
on nested elements and attributes that may contain undefined values
in the chain without getting an <a class="reference internal" href="../api/#jinja2.UndefinedError" title="jinja2.UndefinedError"><code class="xref py py-exc docutils literal notranslate"><span class="pre">UndefinedError</span></code></a>.</p>
</div>
</details><dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">d</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.dictsort">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">dictsort</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Mapping</span><span class="p"><span class="pre">[</span></span><span class="pre">K</span><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">V</span><span class="p"><span class="pre">]</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">case_sensitive</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">by</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'te.Literal[&quot;key&quot;,</span> <span class="pre">&quot;value&quot;]'</span></span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">'key'</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">reverse</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference internal" href="../extensions/#jinja2.nodes.List" title="jinja2.nodes.List"><span class="pre">List</span></a><span class="p"><span class="pre">[</span></span><a class="reference internal" href="../extensions/#jinja2.nodes.Tuple" title="jinja2.nodes.Tuple"><span class="pre">Tuple</span></a><span class="p"><span class="pre">[</span></span><span class="pre">K</span><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">V</span><span class="p"><span class="pre">]</span></span><span class="p"><span class="pre">]</span></span></span></span><a class="headerlink" href="#jinja-filters.dictsort" title="Link to this definition">¶</a></dt>
<dd><p>Sort a dict and yield (key, value) pairs. Python dicts may not
be in the order you want to display them in, so sort them first.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">mydict</span><span class="o">|</span><span class="nf">dictsort</span> <span class="cp">%}</span>
<span class="x">    sort the dict by key, case insensitive</span>

<span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">mydict</span><span class="o">|</span><span class="nf">dictsort</span><span class="o">(</span><span class="nv">reverse</span><span class="o">=</span><span class="kp">true</span><span class="o">)</span> <span class="cp">%}</span>
<span class="x">    sort the dict by key, case insensitive, reverse order</span>

<span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">mydict</span><span class="o">|</span><span class="nf">dictsort</span><span class="o">(</span><span class="kp">true</span><span class="o">)</span> <span class="cp">%}</span>
<span class="x">    sort the dict by key, case sensitive</span>

<span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">mydict</span><span class="o">|</span><span class="nf">dictsort</span><span class="o">(</span><span class="kp">false</span><span class="o">,</span> <span class="s1">&#39;value&#39;</span><span class="o">)</span> <span class="cp">%}</span>
<span class="x">    sort the dict by value, case insensitive</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.escape">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">escape</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Any'</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'Markup'</span></span></span></span><a class="headerlink" href="#jinja-filters.escape" title="Link to this definition">¶</a></dt>
<dd><p>Replace the characters <code class="docutils literal notranslate"><span class="pre">&amp;</span></code>, <code class="docutils literal notranslate"><span class="pre">&lt;</span></code>, <code class="docutils literal notranslate"><span class="pre">&gt;</span></code>, <code class="docutils literal notranslate"><span class="pre">'</span></code>, and <code class="docutils literal notranslate"><span class="pre">&quot;</span></code> in
the string with HTML-safe sequences. Use this if you need to display
text that might contain such characters in HTML.</p>
<p>If the object has an <code class="docutils literal notranslate"><span class="pre">__html__</span></code> method, it is called and the
return value is assumed to already be safe for HTML.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>s</strong> – An object to be converted to a string and escaped.</p>
</dd>
<dt class="field-even">Returns<span class="colon">:</span></dt>
<dd class="field-even"><p>A <code class="xref py py-class docutils literal notranslate"><span class="pre">Markup</span></code> string with the escaped text.</p>
</dd>
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">e</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.filesizeformat">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">filesizeformat</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#float" title="(in Python v3.13)"><span class="pre">float</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">binary</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.filesizeformat" title="Link to this definition">¶</a></dt>
<dd><p>Format the value like a ‘human-readable’ file size (i.e. 13 kB,
4.1 MB, 102 Bytes, etc).  Per default decimal prefixes are used (Mega,
Giga, etc.), if the second parameter is set to <code class="code docutils literal notranslate"><span class="pre">True</span></code> the binary
prefixes are used (Mebi, Gibi).</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.first">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">first</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">seq</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Union[V,</span> <span class="pre">Undefined]'</span></span></span></span><a class="headerlink" href="#jinja-filters.first" title="Link to this definition">¶</a></dt>
<dd><p>Return the first item of a sequence.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.float">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">float</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">default</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#float" title="(in Python v3.13)"><span class="pre">float</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">0.0</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#float" title="(in Python v3.13)"><span class="pre">float</span></a></span></span><a class="headerlink" href="#jinja-filters.float" title="Link to this definition">¶</a></dt>
<dd><p>Convert the value into a floating point number. If the
conversion doesn’t work it will return <code class="docutils literal notranslate"><span class="pre">0.0</span></code>. You can
override this default using the first parameter.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.forceescape">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">forceescape</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Union[str,</span> <span class="pre">HasHTML]'</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">markupsafe.Markup</span></span></span><a class="headerlink" href="#jinja-filters.forceescape" title="Link to this definition">¶</a></dt>
<dd><p>Enforce HTML escaping.  This will probably double escape variables.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.format">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">format</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="o"><span class="pre">*</span></span><span class="n"><span class="pre">args</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">**</span></span><span class="n"><span class="pre">kwargs</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.format" title="Link to this definition">¶</a></dt>
<dd><p>Apply the given values to a <a class="reference external" href="https://docs.python.org/library/stdtypes.html#printf-style-string-formatting">printf-style</a> format string, like
<code class="docutils literal notranslate"><span class="pre">string</span> <span class="pre">%</span> <span class="pre">values</span></code>.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="s2">&quot;%s, %s!&quot;</span><span class="o">|</span><span class="nf">format</span><span class="o">(</span><span class="nv">greeting</span><span class="o">,</span> <span class="nv">name</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">Hello, World!</span>
</pre></div>
</div>
<p>In most cases it should be more convenient and efficient to use the
<code class="docutils literal notranslate"><span class="pre">%</span></code> operator or <a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str.format" title="(in Python v3.13)"><code class="xref py py-meth docutils literal notranslate"><span class="pre">str.format()</span></code></a>.</p>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>{{ &quot;%s, %s!&quot; % (greeting, name) }}
{{ &quot;{}, {}!&quot;.format(greeting, name) }}
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.groupby">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">groupby</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">default</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">case_sensitive</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.List[_GroupTuple]'</span></span></span></span><a class="headerlink" href="#jinja-filters.groupby" title="Link to this definition">¶</a></dt>
<dd><p>Group a sequence of objects by an attribute using Python’s
<a class="reference external" href="https://docs.python.org/3/library/itertools.html#itertools.groupby" title="(in Python v3.13)"><code class="xref py py-func docutils literal notranslate"><span class="pre">itertools.groupby()</span></code></a>. The attribute can use dot notation for
nested access, like <code class="docutils literal notranslate"><span class="pre">&quot;address.city&quot;</span></code>. Unlike Python’s <code class="docutils literal notranslate"><span class="pre">groupby</span></code>,
the values are sorted first so only one group is returned for each
unique value.</p>
<p>For example, a list of <code class="docutils literal notranslate"><span class="pre">User</span></code> objects with a <code class="docutils literal notranslate"><span class="pre">city</span></code> attribute
can be rendered in groups. In this example, <code class="docutils literal notranslate"><span class="pre">grouper</span></code> refers to
the <code class="docutils literal notranslate"><span class="pre">city</span></code> value of the group.</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">city</span><span class="o">,</span> <span class="nv">items</span> <span class="k">in</span> <span class="nv">users</span><span class="o">|</span><span class="nf">groupby</span><span class="o">(</span><span class="s2">&quot;city&quot;</span><span class="o">)</span> <span class="cp">%}</span>
  <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">city</span> <span class="cp">}}</span>
    <span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">items</span> <span class="cp">%}</span>
      <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.name</span> <span class="cp">}}</span>
    <span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
  <span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p><code class="docutils literal notranslate"><span class="pre">groupby</span></code> yields namedtuples of <code class="docutils literal notranslate"><span class="pre">(grouper,</span> <span class="pre">list)</span></code>, which
can be used instead of the tuple unpacking above. <code class="docutils literal notranslate"><span class="pre">grouper</span></code> is the
value of the attribute, and <code class="docutils literal notranslate"><span class="pre">list</span></code> is the items with that value.</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">group</span> <span class="k">in</span> <span class="nv">users</span><span class="o">|</span><span class="nf">groupby</span><span class="o">(</span><span class="s2">&quot;city&quot;</span><span class="o">)</span> <span class="cp">%}</span>
  <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">group.grouper</span> <span class="cp">}}</span>: <span class="cp">{{</span> <span class="nv">group.list</span><span class="o">|</span><span class="nf">join</span><span class="o">(</span><span class="s2">&quot;, &quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>You can specify a <code class="docutils literal notranslate"><span class="pre">default</span></code> value to use if an object in the list
does not have the given attribute.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="x">&lt;ul&gt;</span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">city</span><span class="o">,</span> <span class="nv">items</span> <span class="k">in</span> <span class="nv">users</span><span class="o">|</span><span class="nf">groupby</span><span class="o">(</span><span class="s2">&quot;city&quot;</span><span class="o">,</span> <span class="nv">default</span><span class="o">=</span><span class="s2">&quot;NY&quot;</span><span class="o">)</span> <span class="cp">%}</span>
<span class="x">  &lt;li&gt;</span><span class="cp">{{</span> <span class="nv">city</span> <span class="cp">}}</span><span class="x">: </span><span class="cp">{{</span> <span class="nv">items</span><span class="o">|</span><span class="nf">map</span><span class="o">(</span><span class="nv">attribute</span><span class="o">=</span><span class="s2">&quot;name&quot;</span><span class="o">)|</span><span class="nf">join</span><span class="o">(</span><span class="s2">&quot;, &quot;</span><span class="o">)</span> <span class="cp">}}</span><span class="x">&lt;/li&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span><span class="x">&lt;/ul&gt;</span>
</pre></div>
</div>
<p>Like the <a class="reference internal" href="#jinja-filters.sort" title="jinja-filters.sort"><code class="xref py py-func docutils literal notranslate"><span class="pre">sort()</span></code></a> filter, sorting and grouping is
case-insensitive by default. The <code class="docutils literal notranslate"><span class="pre">key</span></code> for each group will have
the case of the first item in that group of values. For example, if
a list of users has cities <code class="docutils literal notranslate"><span class="pre">[&quot;CA&quot;,</span> <span class="pre">&quot;NY&quot;,</span> <span class="pre">&quot;ca&quot;]</span></code>, the “CA” group
will have two values. This can be disabled by passing
<code class="docutils literal notranslate"><span class="pre">case_sensitive=True</span></code>.</p>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.1: </span>Added the <code class="docutils literal notranslate"><span class="pre">case_sensitive</span></code> parameter. Sorting and grouping is
case-insensitive by default, matching other filters that do
comparisons.</p>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.0: </span>Added the <code class="docutils literal notranslate"><span class="pre">default</span></code> parameter.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.6: </span>The attribute supports dot notation for nested access.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.indent">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">indent</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">width</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">4</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">first</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">blank</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.indent" title="Link to this definition">¶</a></dt>
<dd><p>Return a copy of the string with each line indented by 4 spaces. The
first line and blank lines are not indented by default.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>width</strong> – Number of spaces, or a string, to indent by.</p></li>
<li><p><strong>first</strong> – Don’t skip indenting the first line.</p></li>
<li><p><strong>blank</strong> – Don’t skip indenting empty lines.</p></li>
</ul>
</dd>
</dl>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.0: </span><code class="docutils literal notranslate"><span class="pre">width</span></code> can be a string.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.10: </span>Blank lines are not indented by default.</p>
<p>Rename the <code class="docutils literal notranslate"><span class="pre">indentfirst</span></code> argument to <code class="docutils literal notranslate"><span class="pre">first</span></code>.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.int">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">int</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">default</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">0</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">base</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">10</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></span><a class="headerlink" href="#jinja-filters.int" title="Link to this definition">¶</a></dt>
<dd><p>Convert the value into an integer. If the
conversion doesn’t work it will return <code class="docutils literal notranslate"><span class="pre">0</span></code>. You can
override this default using the first parameter. You
can also override the default base (10) in the second
parameter, which handles input with prefixes such as
0b, 0o and 0x for bases 2, 8 and 16 respectively.
The base is ignored for decimal numbers and non-string values.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.items">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">items</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Mapping</span><span class="p"><span class="pre">[</span></span><span class="pre">K</span><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">V</span><span class="p"><span class="pre">]</span></span><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference internal" href="../api/#jinja2.Undefined" title="jinja2.runtime.Undefined"><span class="pre">jinja2.runtime.Undefined</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">Iterator</span><span class="p"><span class="pre">[</span></span><a class="reference internal" href="../extensions/#jinja2.nodes.Tuple" title="jinja2.nodes.Tuple"><span class="pre">Tuple</span></a><span class="p"><span class="pre">[</span></span><span class="pre">K</span><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">V</span><span class="p"><span class="pre">]</span></span><span class="p"><span class="pre">]</span></span></span></span><a class="headerlink" href="#jinja-filters.items" title="Link to this definition">¶</a></dt>
<dd><p>Return an iterator over the <code class="docutils literal notranslate"><span class="pre">(key,</span> <span class="pre">value)</span></code> items of a mapping.</p>
<p><code class="docutils literal notranslate"><span class="pre">x|items</span></code> is the same as <code class="docutils literal notranslate"><span class="pre">x.items()</span></code>, except if <code class="docutils literal notranslate"><span class="pre">x</span></code> is
undefined an empty iterator is returned.</p>
<p>This filter is useful if you expect the template to be rendered with
an implementation of Jinja in another programming language that does
not have a <code class="docutils literal notranslate"><span class="pre">.items()</span></code> method on its mapping type.</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">dl</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">key</span><span class="o">,</span> <span class="nv">value</span> <span class="k">in</span> <span class="nv">my_dict</span><span class="o">|</span><span class="nf">items</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">dt</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">key</span> <span class="cp">}}</span>
    <span class="p">&lt;</span><span class="nt">dd</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">value</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">dl</span><span class="p">&gt;</span>
</pre></div>
</div>
<div class="versionadded">
<p><span class="versionmodified added">Added in version 3.1.</span></p>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.join">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">join</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">d</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">''</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">NoneType</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.join" title="Link to this definition">¶</a></dt>
<dd><p>Return a string which is the concatenation of the strings in the
sequence. The separator between elements is an empty string per
default, you can define it with the optional parameter:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="o">[</span><span class="m">1</span><span class="o">,</span> <span class="m">2</span><span class="o">,</span> <span class="m">3</span><span class="o">]|</span><span class="nf">join</span><span class="o">(</span><span class="s1">&#39;|&#39;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; 1|2|3</span>

<span class="cp">{{</span> <span class="o">[</span><span class="m">1</span><span class="o">,</span> <span class="m">2</span><span class="o">,</span> <span class="m">3</span><span class="o">]|</span><span class="nf">join</span> <span class="cp">}}</span>
<span class="x">    -&gt; 123</span>
</pre></div>
</div>
<p>It is also possible to join certain attributes of an object:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">join</span><span class="o">(</span><span class="s1">&#39;, &#39;</span><span class="o">,</span> <span class="nv">attribute</span><span class="o">=</span><span class="s1">&#39;username&#39;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.6: </span>The <code class="code docutils literal notranslate"><span class="pre">attribute</span></code> parameter was added.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.last">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">last</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">seq</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Reversible[V]'</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Union[V,</span> <span class="pre">Undefined]'</span></span></span></span><a class="headerlink" href="#jinja-filters.last" title="Link to this definition">¶</a></dt>
<dd><p>Return the last item of a sequence.</p>
<p>Note: Does not work with generators. You may want to explicitly
convert it to a list:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">data</span> <span class="o">|</span> <span class="nf">selectattr</span><span class="o">(</span><span class="s1">&#39;name&#39;</span><span class="o">,</span> <span class="s1">&#39;==&#39;</span><span class="o">,</span> <span class="s1">&#39;Jinja&#39;</span><span class="o">)</span> <span class="o">|</span> <span class="nf">list</span> <span class="o">|</span> <span class="nf">last</span> <span class="cp">}}</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.length">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">length</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">obj</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-filters.length" title="Link to this definition">¶</a></dt>
<dd><p>Return the number of items in a container.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">count</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.list">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">list</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.List[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.list" title="Link to this definition">¶</a></dt>
<dd><p>Convert the value into a list.  If it was a string the returned list
will be a list of characters.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.lower">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">lower</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.lower" title="Link to this definition">¶</a></dt>
<dd><p>Convert a value to lowercase.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.map">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">map</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">*</span></span><span class="n"><span class="pre">args</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">**</span></span><span class="n"><span class="pre">kwargs</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span></span></span><a class="headerlink" href="#jinja-filters.map" title="Link to this definition">¶</a></dt>
<dd><p>Applies a filter on a sequence of objects or looks up an attribute.
This is useful when dealing with lists of objects but you are really
only interested in a certain value of it.</p>
<p>The basic usage is mapping on an attribute.  Imagine you have a list
of users but you are only interested in a list of usernames:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="x">Users on this page: </span><span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">map</span><span class="o">(</span><span class="nv">attribute</span><span class="o">=</span><span class="s1">&#39;username&#39;</span><span class="o">)|</span><span class="nf">join</span><span class="o">(</span><span class="s1">&#39;, &#39;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>You can specify a <code class="docutils literal notranslate"><span class="pre">default</span></code> value to use if an object in the list
does not have the given attribute.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">map</span><span class="o">(</span><span class="nv">attribute</span><span class="o">=</span><span class="s2">&quot;username&quot;</span><span class="o">,</span> <span class="nv">default</span><span class="o">=</span><span class="s2">&quot;Anonymous&quot;</span><span class="o">)|</span><span class="nf">join</span><span class="o">(</span><span class="s2">&quot;, &quot;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Alternatively you can let it invoke a filter by passing the name of the
filter and the arguments afterwards.  A good example would be applying a
text conversion filter on a sequence:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="x">Users on this page: </span><span class="cp">{{</span> <span class="nv">titles</span><span class="o">|</span><span class="nf">map</span><span class="o">(</span><span class="s1">&#39;lower&#39;</span><span class="o">)|</span><span class="nf">join</span><span class="o">(</span><span class="s1">&#39;, &#39;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Similar to a generator comprehension such as:</p>
<div class="highlight-python notranslate"><div class="highlight"><pre><span></span><span class="p">(</span><span class="n">u</span><span class="o">.</span><span class="n">username</span> <span class="k">for</span> <span class="n">u</span> <span class="ow">in</span> <span class="n">users</span><span class="p">)</span>
<span class="p">(</span><span class="nb">getattr</span><span class="p">(</span><span class="n">u</span><span class="p">,</span> <span class="s2">&quot;username&quot;</span><span class="p">,</span> <span class="s2">&quot;Anonymous&quot;</span><span class="p">)</span> <span class="k">for</span> <span class="n">u</span> <span class="ow">in</span> <span class="n">users</span><span class="p">)</span>
<span class="p">(</span><span class="n">do_lower</span><span class="p">(</span><span class="n">x</span><span class="p">)</span> <span class="k">for</span> <span class="n">x</span> <span class="ow">in</span> <span class="n">titles</span><span class="p">)</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.11.0: </span>Added the <code class="docutils literal notranslate"><span class="pre">default</span></code> parameter.</p>
</div>
<div class="versionadded">
<p><span class="versionmodified added">Added in version 2.7.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.max">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">max</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">case_sensitive</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">NoneType</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Union[V,</span> <span class="pre">Undefined]'</span></span></span></span><a class="headerlink" href="#jinja-filters.max" title="Link to this definition">¶</a></dt>
<dd><p>Return the largest item from the sequence.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="o">[</span><span class="m">1</span><span class="o">,</span> <span class="m">2</span><span class="o">,</span> <span class="m">3</span><span class="o">]|</span><span class="nf">max</span> <span class="cp">}}</span>
<span class="x">    -&gt; 3</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>case_sensitive</strong> – Treat upper and lower case strings as distinct.</p></li>
<li><p><strong>attribute</strong> – Get the object with the max value of this attribute.</p></li>
</ul>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.min">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">min</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">case_sensitive</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">NoneType</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Union[V,</span> <span class="pre">Undefined]'</span></span></span></span><a class="headerlink" href="#jinja-filters.min" title="Link to this definition">¶</a></dt>
<dd><p>Return the smallest item from the sequence.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="o">[</span><span class="m">1</span><span class="o">,</span> <span class="m">2</span><span class="o">,</span> <span class="m">3</span><span class="o">]|</span><span class="nf">min</span> <span class="cp">}}</span>
<span class="x">    -&gt; 1</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>case_sensitive</strong> – Treat upper and lower case strings as distinct.</p></li>
<li><p><strong>attribute</strong> – Get the object with the min value of this attribute.</p></li>
</ul>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.pprint">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">pprint</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.pprint" title="Link to this definition">¶</a></dt>
<dd><p>Pretty print a variable. Useful for debugging.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.random">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">random</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">seq</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Sequence[V]'</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Union[V,</span> <span class="pre">Undefined]'</span></span></span></span><a class="headerlink" href="#jinja-filters.random" title="Link to this definition">¶</a></dt>
<dd><p>Return a random item from the sequence.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.reject">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">reject</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">*</span></span><span class="n"><span class="pre">args</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">**</span></span><span class="n"><span class="pre">kwargs</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.reject" title="Link to this definition">¶</a></dt>
<dd><p>Filters a sequence of objects by applying a test to each object,
and rejecting the objects with the test succeeding.</p>
<p>If no test is specified, each object will be evaluated as a boolean.</p>
<p>Example usage:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">numbers</span><span class="o">|</span><span class="nf">reject</span><span class="o">(</span><span class="s2">&quot;odd&quot;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Similar to a generator comprehension such as:</p>
<div class="highlight-python notranslate"><div class="highlight"><pre><span></span><span class="p">(</span><span class="n">n</span> <span class="k">for</span> <span class="n">n</span> <span class="ow">in</span> <span class="n">numbers</span> <span class="k">if</span> <span class="ow">not</span> <span class="n">test_odd</span><span class="p">(</span><span class="n">n</span><span class="p">))</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.7.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.rejectattr">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">rejectattr</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">*</span></span><span class="n"><span class="pre">args</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">**</span></span><span class="n"><span class="pre">kwargs</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.rejectattr" title="Link to this definition">¶</a></dt>
<dd><p>Filters a sequence of objects by applying a test to the specified
attribute of each object, and rejecting the objects with the test
succeeding.</p>
<p>If no test is specified, the attribute’s value will be evaluated as
a boolean.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">rejectattr</span><span class="o">(</span><span class="s2">&quot;is_active&quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">rejectattr</span><span class="o">(</span><span class="s2">&quot;email&quot;</span><span class="o">,</span> <span class="s2">&quot;none&quot;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Similar to a generator comprehension such as:</p>
<div class="highlight-python notranslate"><div class="highlight"><pre><span></span><span class="p">(</span><span class="n">user</span> <span class="k">for</span> <span class="n">user</span> <span class="ow">in</span> <span class="n">users</span> <span class="k">if</span> <span class="ow">not</span> <span class="n">user</span><span class="o">.</span><span class="n">is_active</span><span class="p">)</span>
<span class="p">(</span><span class="n">user</span> <span class="k">for</span> <span class="n">user</span> <span class="ow">in</span> <span class="n">users</span> <span class="k">if</span> <span class="ow">not</span> <span class="n">test_none</span><span class="p">(</span><span class="n">user</span><span class="o">.</span><span class="n">email</span><span class="p">))</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.7.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.replace">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">replace</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">old</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">new</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">count</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.replace" title="Link to this definition">¶</a></dt>
<dd><p>Return a copy of the value with all occurrences of a substring
replaced with a new one. The first argument is the substring
that should be replaced, the second is the replacement string.
If the optional third argument <code class="docutils literal notranslate"><span class="pre">count</span></code> is given, only the first
<code class="docutils literal notranslate"><span class="pre">count</span></code> occurrences are replaced:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="s2">&quot;Hello World&quot;</span><span class="o">|</span><span class="nf">replace</span><span class="o">(</span><span class="s2">&quot;Hello&quot;</span><span class="o">,</span> <span class="s2">&quot;Goodbye&quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; Goodbye World</span>

<span class="cp">{{</span> <span class="s2">&quot;aaaaargh&quot;</span><span class="o">|</span><span class="nf">replace</span><span class="o">(</span><span class="s2">&quot;a&quot;</span><span class="o">,</span> <span class="s2">&quot;d&#39;oh, &quot;</span><span class="o">,</span> <span class="m">2</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; d&#39;oh, d&#39;oh, aaargh</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.reverse">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">reverse</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><span class="pre">V</span><span class="p"><span class="pre">]</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><span class="pre">V</span><span class="p"><span class="pre">]</span></span></span></span><a class="headerlink" href="#jinja-filters.reverse" title="Link to this definition">¶</a></dt>
<dd><p>Reverse the object or return an iterator that iterates over it the other
way round.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.round">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">round</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#float" title="(in Python v3.13)"><span class="pre">float</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">precision</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">0</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">method</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'te.Literal[&quot;common&quot;,</span> <span class="pre">&quot;ceil&quot;,</span> <span class="pre">&quot;floor&quot;]'</span></span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">'common'</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#float" title="(in Python v3.13)"><span class="pre">float</span></a></span></span><a class="headerlink" href="#jinja-filters.round" title="Link to this definition">¶</a></dt>
<dd><p>Round the number to a given precision. The first
parameter specifies the precision (default is <code class="docutils literal notranslate"><span class="pre">0</span></code>), the
second the rounding method:</p>
<ul class="simple">
<li><p><code class="docutils literal notranslate"><span class="pre">'common'</span></code> rounds either up or down</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">'ceil'</span></code> always rounds up</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">'floor'</span></code> always rounds down</p></li>
</ul>
<p>If you don’t specify a method <code class="docutils literal notranslate"><span class="pre">'common'</span></code> is used.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="m">42.55</span><span class="o">|</span><span class="nf">round</span> <span class="cp">}}</span>
<span class="x">    -&gt; 43.0</span>
<span class="cp">{{</span> <span class="m">42.55</span><span class="o">|</span><span class="nf">round</span><span class="o">(</span><span class="m">1</span><span class="o">,</span> <span class="s1">&#39;floor&#39;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; 42.5</span>
</pre></div>
</div>
<p>Note that even if rounded to 0 precision, a float is returned.  If
you need a real integer, pipe it through <code class="code docutils literal notranslate"><span class="pre">int</span></code>:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="m">42.55</span><span class="o">|</span><span class="nf">round</span><span class="o">|</span><span class="nf">int</span> <span class="cp">}}</span>
<span class="x">    -&gt; 43</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.safe">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">safe</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">markupsafe.Markup</span></span></span><a class="headerlink" href="#jinja-filters.safe" title="Link to this definition">¶</a></dt>
<dd><p>Mark the value as safe which means that in an environment with automatic
escaping enabled this variable will not be escaped.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.select">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">select</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">*</span></span><span class="n"><span class="pre">args</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">**</span></span><span class="n"><span class="pre">kwargs</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.select" title="Link to this definition">¶</a></dt>
<dd><p>Filters a sequence of objects by applying a test to each object,
and only selecting the objects with the test succeeding.</p>
<p>If no test is specified, each object will be evaluated as a boolean.</p>
<p>Example usage:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">numbers</span><span class="o">|</span><span class="nf">select</span><span class="o">(</span><span class="s2">&quot;odd&quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">numbers</span><span class="o">|</span><span class="nf">select</span><span class="o">(</span><span class="s2">&quot;odd&quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">numbers</span><span class="o">|</span><span class="nf">select</span><span class="o">(</span><span class="s2">&quot;divisibleby&quot;</span><span class="o">,</span> <span class="m">3</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">numbers</span><span class="o">|</span><span class="nf">select</span><span class="o">(</span><span class="s2">&quot;lessthan&quot;</span><span class="o">,</span> <span class="m">42</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">strings</span><span class="o">|</span><span class="nf">select</span><span class="o">(</span><span class="s2">&quot;equalto&quot;</span><span class="o">,</span> <span class="s2">&quot;mystring&quot;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Similar to a generator comprehension such as:</p>
<div class="highlight-python notranslate"><div class="highlight"><pre><span></span><span class="p">(</span><span class="n">n</span> <span class="k">for</span> <span class="n">n</span> <span class="ow">in</span> <span class="n">numbers</span> <span class="k">if</span> <span class="n">test_odd</span><span class="p">(</span><span class="n">n</span><span class="p">))</span>
<span class="p">(</span><span class="n">n</span> <span class="k">for</span> <span class="n">n</span> <span class="ow">in</span> <span class="n">numbers</span> <span class="k">if</span> <span class="n">test_divisibleby</span><span class="p">(</span><span class="n">n</span><span class="p">,</span> <span class="mi">3</span><span class="p">))</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.7.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.selectattr">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">selectattr</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">*</span></span><span class="n"><span class="pre">args</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">**</span></span><span class="n"><span class="pre">kwargs</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.selectattr" title="Link to this definition">¶</a></dt>
<dd><p>Filters a sequence of objects by applying a test to the specified
attribute of each object, and only selecting the objects with the
test succeeding.</p>
<p>If no test is specified, the attribute’s value will be evaluated as
a boolean.</p>
<p>Example usage:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">selectattr</span><span class="o">(</span><span class="s2">&quot;is_active&quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">users</span><span class="o">|</span><span class="nf">selectattr</span><span class="o">(</span><span class="s2">&quot;email&quot;</span><span class="o">,</span> <span class="s2">&quot;none&quot;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Similar to a generator comprehension such as:</p>
<div class="highlight-python notranslate"><div class="highlight"><pre><span></span><span class="p">(</span><span class="n">user</span> <span class="k">for</span> <span class="n">user</span> <span class="ow">in</span> <span class="n">users</span> <span class="k">if</span> <span class="n">user</span><span class="o">.</span><span class="n">is_active</span><span class="p">)</span>
<span class="p">(</span><span class="n">user</span> <span class="k">for</span> <span class="n">user</span> <span class="ow">in</span> <span class="n">users</span> <span class="k">if</span> <span class="n">test_none</span><span class="p">(</span><span class="n">user</span><span class="o">.</span><span class="n">email</span><span class="p">))</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.7.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.slice">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">slice</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Collection[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">slices</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">fill_with</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Optional[V]'</span></span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[t.List[V]]'</span></span></span></span><a class="headerlink" href="#jinja-filters.slice" title="Link to this definition">¶</a></dt>
<dd><p>Slice an iterator and return a list of lists containing
those items. Useful if you want to create a div containing
three ul tags that represent columns:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;columnwrapper&quot;</span><span class="p">&gt;</span>
  <span class="cp">{%</span>- <span class="k">for</span> <span class="nv">column</span> <span class="k">in</span> <span class="nv">items</span><span class="o">|</span><span class="nf">slice</span><span class="o">(</span><span class="m">3</span><span class="o">)</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">ul</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;column-</span><span class="cp">{{</span> <span class="nb">loop</span><span class="nv">.index</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span>
    <span class="cp">{%</span>- <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">column</span> <span class="cp">%}</span>
      <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">item</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
    <span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
    <span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
  <span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>If you pass it a second argument it’s used to fill missing
values on the last iteration.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.sort">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">sort</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">reverse</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">case_sensitive</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">NoneType</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.List[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.sort" title="Link to this definition">¶</a></dt>
<dd><p>Sort an iterable using Python’s <a class="reference external" href="https://docs.python.org/3/library/functions.html#sorted" title="(in Python v3.13)"><code class="xref py py-func docutils literal notranslate"><span class="pre">sorted()</span></code></a>.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">city</span> <span class="k">in</span> <span class="nv">cities</span><span class="o">|</span><span class="nf">sort</span> <span class="cp">%}</span>
<span class="x">    ...</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>reverse</strong> – Sort descending instead of ascending.</p></li>
<li><p><strong>case_sensitive</strong> – When sorting strings, sort upper and lower
case separately.</p></li>
<li><p><strong>attribute</strong> – When sorting objects or dicts, an attribute or
key to sort by. Can use dot notation like <code class="docutils literal notranslate"><span class="pre">&quot;address.city&quot;</span></code>.
Can be a list of attributes like <code class="docutils literal notranslate"><span class="pre">&quot;age,name&quot;</span></code>.</p></li>
</ul>
</dd>
</dl>
<p>The sort is stable, it does not change the relative order of
elements that compare equal. This makes it is possible to chain
sorts on different attributes and ordering.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span><span class="o">|</span><span class="nf">sort</span><span class="o">(</span><span class="nv">attribute</span><span class="o">=</span><span class="s2">&quot;name&quot;</span><span class="o">)</span>
    <span class="o">|</span><span class="nf">sort</span><span class="o">(</span><span class="nv">reverse</span><span class="o">=</span><span class="kp">true</span><span class="o">,</span> <span class="nv">attribute</span><span class="o">=</span><span class="s2">&quot;age&quot;</span><span class="o">)</span> <span class="cp">%}</span>
<span class="x">    ...</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>As a shortcut to chaining when the direction is the same for all
attributes, pass a comma separate list of attributes.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span><span class="o">|</span><span class="nf">sort</span><span class="o">(</span><span class="nv">attribute</span><span class="o">=</span><span class="s2">&quot;age,name&quot;</span><span class="o">)</span> <span class="cp">%}</span>
<span class="x">    ...</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.11.0: </span>The <code class="docutils literal notranslate"><span class="pre">attribute</span></code> parameter can be a comma separated list of
attributes, e.g. <code class="docutils literal notranslate"><span class="pre">&quot;age,name&quot;</span></code>.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.6: </span>The <code class="docutils literal notranslate"><span class="pre">attribute</span></code> parameter was added.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.string">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">string</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Any'</span></span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'str'</span></span></span></span><a class="headerlink" href="#jinja-filters.string" title="Link to this definition">¶</a></dt>
<dd><p>Convert an object to a string if it isn’t already. This preserves
a <code class="xref py py-class docutils literal notranslate"><span class="pre">Markup</span></code> string rather than converting it back to a basic
string, so it will still be marked as safe and won’t be escaped
again.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="n">value</span> <span class="o">=</span> <span class="n">escape</span><span class="p">(</span><span class="s2">&quot;&lt;User 1&gt;&quot;</span><span class="p">)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">value</span>
<span class="go">Markup(&#39;&amp;lt;User 1&amp;gt;&#39;)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">escape</span><span class="p">(</span><span class="nb">str</span><span class="p">(</span><span class="n">value</span><span class="p">))</span>
<span class="go">Markup(&#39;&amp;amp;lt;User 1&amp;amp;gt;&#39;)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">escape</span><span class="p">(</span><span class="n">soft_str</span><span class="p">(</span><span class="n">value</span><span class="p">))</span>
<span class="go">Markup(&#39;&amp;lt;User 1&amp;gt;&#39;)</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.striptags">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">striptags</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Union[str,</span> <span class="pre">HasHTML]'</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.striptags" title="Link to this definition">¶</a></dt>
<dd><p>Strip SGML/XML tags and replace adjacent whitespace by one space.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.sum">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">sum</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">iterable</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">NoneType</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">start</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">V</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">0</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">V</span></span></span><a class="headerlink" href="#jinja-filters.sum" title="Link to this definition">¶</a></dt>
<dd><p>Returns the sum of a sequence of numbers plus the value of parameter
‘start’ (which defaults to 0).  When the sequence is empty it returns
start.</p>
<p>It is also possible to sum up only certain attributes:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="x">Total: </span><span class="cp">{{</span> <span class="nv">items</span><span class="o">|</span><span class="nf">sum</span><span class="o">(</span><span class="nv">attribute</span><span class="o">=</span><span class="s1">&#39;price&#39;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.6: </span>The <code class="docutils literal notranslate"><span class="pre">attribute</span></code> parameter was added to allow summing up over
attributes.  Also the <code class="docutils literal notranslate"><span class="pre">start</span></code> parameter was moved on to the right.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.title">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">title</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.title" title="Link to this definition">¶</a></dt>
<dd><p>Return a titlecased version of the value. I.e. words will start with
uppercase letters, all remaining characters are lowercase.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.tojson">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">tojson</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">indent</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="pre">markupsafe.Markup</span></span></span><a class="headerlink" href="#jinja-filters.tojson" title="Link to this definition">¶</a></dt>
<dd><p>Serialize an object to a string of JSON, and mark it safe to
render in HTML. This filter is only for use in HTML documents.</p>
<p>The returned string is safe to render in HTML documents and
<code class="docutils literal notranslate"><span class="pre">&lt;script&gt;</span></code> tags. The exception is in HTML attributes that are
double quoted; either use single quotes or the <code class="docutils literal notranslate"><span class="pre">|forceescape</span></code>
filter.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>value</strong> – The object to serialize to JSON.</p></li>
<li><p><strong>indent</strong> – The <code class="docutils literal notranslate"><span class="pre">indent</span></code> parameter passed to <code class="docutils literal notranslate"><span class="pre">dumps</span></code>, for
pretty-printing the value.</p></li>
</ul>
</dd>
</dl>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.9.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.trim">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">trim</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">chars</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.trim" title="Link to this definition">¶</a></dt>
<dd><p>Strip leading and trailing characters, by default whitespace.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.truncate">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">truncate</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">length</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">255</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">killwords</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">end</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">'...'</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">leeway</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.truncate" title="Link to this definition">¶</a></dt>
<dd><p>Return a truncated copy of the string. The length is specified
with the first parameter which defaults to <code class="docutils literal notranslate"><span class="pre">255</span></code>. If the second
parameter is <code class="docutils literal notranslate"><span class="pre">true</span></code> the filter will cut the text at length. Otherwise
it will discard the last word. If the text was in fact
truncated it will append an ellipsis sign (<code class="docutils literal notranslate"><span class="pre">&quot;...&quot;</span></code>). If you want a
different ellipsis sign than <code class="docutils literal notranslate"><span class="pre">&quot;...&quot;</span></code> you can specify it using the
third parameter. Strings that only exceed the length by the tolerance
margin given in the fourth parameter will not be truncated.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="s2">&quot;foo bar baz qux&quot;</span><span class="o">|</span><span class="nf">truncate</span><span class="o">(</span><span class="m">9</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; &quot;foo...&quot;</span>
<span class="cp">{{</span> <span class="s2">&quot;foo bar baz qux&quot;</span><span class="o">|</span><span class="nf">truncate</span><span class="o">(</span><span class="m">9</span><span class="o">,</span> <span class="kp">True</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; &quot;foo ba...&quot;</span>
<span class="cp">{{</span> <span class="s2">&quot;foo bar baz qux&quot;</span><span class="o">|</span><span class="nf">truncate</span><span class="o">(</span><span class="m">11</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; &quot;foo bar baz qux&quot;</span>
<span class="cp">{{</span> <span class="s2">&quot;foo bar baz qux&quot;</span><span class="o">|</span><span class="nf">truncate</span><span class="o">(</span><span class="m">11</span><span class="o">,</span> <span class="kp">False</span><span class="o">,</span> <span class="s1">&#39;...&#39;</span><span class="o">,</span> <span class="m">0</span><span class="o">)</span> <span class="cp">}}</span>
<span class="x">    -&gt; &quot;foo bar...&quot;</span>
</pre></div>
</div>
<p>The default leeway on newer Jinja versions is 5 and was 0 before but
can be reconfigured globally.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.unique">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">unique</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="s"><span class="pre">'t.Iterable[V]'</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">case_sensitive</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">attribute</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">NoneType</span></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><span class="s"><span class="pre">'t.Iterator[V]'</span></span></span></span><a class="headerlink" href="#jinja-filters.unique" title="Link to this definition">¶</a></dt>
<dd><p>Returns a list of unique items from the given iterable.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="o">[</span><span class="s1">&#39;foo&#39;</span><span class="o">,</span> <span class="s1">&#39;bar&#39;</span><span class="o">,</span> <span class="s1">&#39;foobar&#39;</span><span class="o">,</span> <span class="s1">&#39;FooBar&#39;</span><span class="o">]|</span><span class="nf">unique</span><span class="o">|</span><span class="nf">list</span> <span class="cp">}}</span>
<span class="x">    -&gt; [&#39;foo&#39;, &#39;bar&#39;, &#39;foobar&#39;]</span>
</pre></div>
</div>
<p>The unique items are yielded in the same order as their first occurrence in
the iterable passed to the filter.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>case_sensitive</strong> – Treat upper and lower case strings as distinct.</p></li>
<li><p><strong>attribute</strong> – Filter objects with unique values for this attribute.</p></li>
</ul>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.upper">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">upper</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.upper" title="Link to this definition">¶</a></dt>
<dd><p>Convert a value to uppercase.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.urlencode">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">urlencode</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">Mapping</span><span class="p"><span class="pre">[</span></span><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><a class="reference internal" href="../extensions/#jinja2.nodes.Tuple" title="jinja2.nodes.Tuple"><span class="pre">Tuple</span></a><span class="p"><span class="pre">[</span></span><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span><span class="p"><span class="pre">]</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.urlencode" title="Link to this definition">¶</a></dt>
<dd><p>Quote data for use in a URL path or query using UTF-8.</p>
<p>Basic wrapper around <a class="reference external" href="https://docs.python.org/3/library/urllib.parse.html#urllib.parse.quote" title="(in Python v3.13)"><code class="xref py py-func docutils literal notranslate"><span class="pre">urllib.parse.quote()</span></code></a> when given a
string, or <a class="reference external" href="https://docs.python.org/3/library/urllib.parse.html#urllib.parse.urlencode" title="(in Python v3.13)"><code class="xref py py-func docutils literal notranslate"><span class="pre">urllib.parse.urlencode()</span></code></a> for a dict or iterable.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>value</strong> – Data to quote. A string will be quoted directly. A
dict or iterable of <code class="docutils literal notranslate"><span class="pre">(key,</span> <span class="pre">value)</span></code> pairs will be joined as a
query string.</p>
</dd>
</dl>
<p>When given a string, “/” is not quoted. HTTP servers treat “/” and
“%2F” equivalently in paths. If you need quoted slashes, use the
<code class="docutils literal notranslate"><span class="pre">|replace(&quot;/&quot;,</span> <span class="pre">&quot;%2F&quot;)</span></code> filter.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.7.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.urlize">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">urlize</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">trim_url_limit</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">nofollow</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">False</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">target</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">rel</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">extra_schemes</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Iterable</span><span class="p"><span class="pre">[</span></span><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="p"><span class="pre">]</span></span><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.urlize" title="Link to this definition">¶</a></dt>
<dd><p>Convert URLs in text into clickable links.</p>
<p>This may not recognize links in some situations. Usually, a more
comprehensive formatter, such as a Markdown library, is a better
choice.</p>
<p>Works on <code class="docutils literal notranslate"><span class="pre">http://</span></code>, <code class="docutils literal notranslate"><span class="pre">https://</span></code>, <code class="docutils literal notranslate"><span class="pre">www.</span></code>, <code class="docutils literal notranslate"><span class="pre">mailto:</span></code>, and email
addresses. Links with trailing punctuation (periods, commas, closing
parentheses) and leading punctuation (opening parentheses) are
recognized excluding the punctuation. Email addresses that include
header fields are not recognized (for example,
<code class="docutils literal notranslate"><span class="pre">mailto:address&#64;example.com?cc=copy&#64;example.com</span></code>).</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>value</strong> – Original text containing URLs to link.</p></li>
<li><p><strong>trim_url_limit</strong> – Shorten displayed URL values to this length.</p></li>
<li><p><strong>nofollow</strong> – Add the <code class="docutils literal notranslate"><span class="pre">rel=nofollow</span></code> attribute to links.</p></li>
<li><p><strong>target</strong> – Add the <code class="docutils literal notranslate"><span class="pre">target</span></code> attribute to links.</p></li>
<li><p><strong>rel</strong> – Add the <code class="docutils literal notranslate"><span class="pre">rel</span></code> attribute to links.</p></li>
<li><p><strong>extra_schemes</strong> – Recognize URLs that start with these schemes
in addition to the default behavior. Defaults to
<code class="docutils literal notranslate"><span class="pre">env.policies[&quot;urlize.extra_schemes&quot;]</span></code>, which defaults to no
extra schemes.</p></li>
</ul>
</dd>
</dl>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.0: </span>The <code class="docutils literal notranslate"><span class="pre">extra_schemes</span></code> parameter was added.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.0: </span>Generate <code class="docutils literal notranslate"><span class="pre">https://</span></code> links for URLs without a scheme.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.0: </span>The parsing rules were updated. Recognize email addresses with
or without the <code class="docutils literal notranslate"><span class="pre">mailto:</span></code> scheme. Validate IP addresses. Ignore
parentheses and brackets in more cases.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.8: </span>The <code class="docutils literal notranslate"><span class="pre">target</span></code> parameter was added.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.wordcount">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">wordcount</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></span><a class="headerlink" href="#jinja-filters.wordcount" title="Link to this definition">¶</a></dt>
<dd><p>Count the words in that string.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.wordwrap">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">wordwrap</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">width</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">79</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">break_long_words</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">True</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">wrapstring</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="w"> </span><span class="p"><span class="pre">|</span></span><span class="w"> </span><a class="reference external" href="https://docs.python.org/3/library/constants.html#None" title="(in Python v3.13)"><span class="pre">None</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">break_on_hyphens</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">True</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.wordwrap" title="Link to this definition">¶</a></dt>
<dd><p>Wrap a string to the given width. Existing newlines are treated
as paragraphs to be wrapped separately.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>s</strong> – Original text to wrap.</p></li>
<li><p><strong>width</strong> – Maximum length of wrapped lines.</p></li>
<li><p><strong>break_long_words</strong> – If a word is longer than <code class="docutils literal notranslate"><span class="pre">width</span></code>, break
it across lines.</p></li>
<li><p><strong>break_on_hyphens</strong> – If a word contains hyphens, it may be split
across lines.</p></li>
<li><p><strong>wrapstring</strong> – String to join each wrapped line. Defaults to
<code class="xref py py-attr docutils literal notranslate"><span class="pre">Environment.newline_sequence</span></code>.</p></li>
</ul>
</dd>
</dl>
<details class="changelog">
<summary>Changelog</summary><div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.11: </span>Existing newlines are treated as paragraphs wrapped separately.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.11: </span>Added the <code class="docutils literal notranslate"><span class="pre">break_on_hyphens</span></code> parameter.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 2.7: </span>Added the <code class="docutils literal notranslate"><span class="pre">wrapstring</span></code> parameter.</p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-filters.xmlattr">
<span class="sig-prename descclassname"><span class="pre">jinja-filters.</span></span><span class="sig-name descname"><span class="pre">xmlattr</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">d</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Mapping</span><span class="p"><span class="pre">[</span></span><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a><span class="p"><span class="pre">,</span></span><span class="w"> </span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span></span></em>, <em class="sig-param"><span class="n"><span class="pre">autospace</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span><span class="w"> </span><span class="o"><span class="pre">=</span></span><span class="w"> </span><span class="default_value"><span class="pre">True</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></span><a class="headerlink" href="#jinja-filters.xmlattr" title="Link to this definition">¶</a></dt>
<dd><p>Create an SGML/XML attribute string based on the items in a dict.</p>
<p><strong>Values</strong> that are neither <code class="docutils literal notranslate"><span class="pre">none</span></code> nor <code class="docutils literal notranslate"><span class="pre">undefined</span></code> are automatically
escaped, safely allowing untrusted user input.</p>
<p>User input should not be used as <strong>keys</strong> to this filter. If any key
contains a space, <code class="docutils literal notranslate"><span class="pre">/</span></code> solidus, <code class="docutils literal notranslate"><span class="pre">&gt;</span></code> greater-than sign, or <code class="docutils literal notranslate"><span class="pre">=</span></code> equals
sign, this fails with a <code class="docutils literal notranslate"><span class="pre">ValueError</span></code>. Regardless of this, user input
should never be used as keys to this filter, or must be separately validated
first.</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="cp">{{</span> <span class="o">{</span><span class="s1">&#39;class&#39;</span><span class="o">:</span> <span class="s1">&#39;my_list&#39;</span><span class="o">,</span> <span class="s1">&#39;missing&#39;</span><span class="o">:</span> <span class="kp">none</span><span class="o">,</span>
        <span class="s1">&#39;id&#39;</span><span class="o">:</span> <span class="s1">&#39;list-%d&#39;</span><span class="o">|</span><span class="nf">format</span><span class="o">(</span><span class="nv">variable</span><span class="o">)}|</span><span class="nf">xmlattr</span> <span class="cp">}}</span><span class="p">&gt;</span>
...
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>Results in something like this:</p>
<div class="highlight-html notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;my_list&quot;</span> <span class="na">id</span><span class="o">=</span><span class="s">&quot;list-42&quot;</span><span class="p">&gt;</span>
...
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<p>As you can see it automatically prepends a space in front of the item
if the filter returned something unless the second parameter is false.</p>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.1.4: </span>Keys with <code class="docutils literal notranslate"><span class="pre">/</span></code> solidus, <code class="docutils literal notranslate"><span class="pre">&gt;</span></code> greater-than sign, or <code class="docutils literal notranslate"><span class="pre">=</span></code> equals sign
are not allowed.</p>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.1.3: </span>Keys with spaces are not allowed.</p>
</div>
</dd></dl>

</section>
<section id="list-of-builtin-tests">
<span id="builtin-tests"></span><h2>List of Builtin Tests<a class="headerlink" href="#list-of-builtin-tests" title="Link to this heading">¶</a></h2>
<table class="docutils align-left">
<tbody>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-tests.boolean" title="jinja-tests.boolean"><code class="xref py py-func docutils literal notranslate"><span class="pre">boolean()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.even" title="jinja-tests.even"><code class="xref py py-func docutils literal notranslate"><span class="pre">even()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.in" title="jinja-tests.in"><code class="xref py py-func docutils literal notranslate"><span class="pre">in()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.mapping" title="jinja-tests.mapping"><code class="xref py py-func docutils literal notranslate"><span class="pre">mapping()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.sequence" title="jinja-tests.sequence"><code class="xref py py-func docutils literal notranslate"><span class="pre">sequence()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-tests.callable" title="jinja-tests.callable"><code class="xref py py-func docutils literal notranslate"><span class="pre">callable()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.false" title="jinja-tests.false"><code class="xref py py-func docutils literal notranslate"><span class="pre">false()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.integer" title="jinja-tests.integer"><code class="xref py py-func docutils literal notranslate"><span class="pre">integer()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.ne" title="jinja-tests.ne"><code class="xref py py-func docutils literal notranslate"><span class="pre">ne()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.string" title="jinja-tests.string"><code class="xref py py-func docutils literal notranslate"><span class="pre">string()</span></code></a></p></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-tests.defined" title="jinja-tests.defined"><code class="xref py py-func docutils literal notranslate"><span class="pre">defined()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.filter" title="jinja-tests.filter"><code class="xref py py-func docutils literal notranslate"><span class="pre">filter()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.iterable" title="jinja-tests.iterable"><code class="xref py py-func docutils literal notranslate"><span class="pre">iterable()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.none" title="jinja-tests.none"><code class="xref py py-func docutils literal notranslate"><span class="pre">none()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.test" title="jinja-tests.test"><code class="xref py py-func docutils literal notranslate"><span class="pre">test()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-tests.divisibleby" title="jinja-tests.divisibleby"><code class="xref py py-func docutils literal notranslate"><span class="pre">divisibleby()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.float" title="jinja-tests.float"><code class="xref py py-func docutils literal notranslate"><span class="pre">float()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.le" title="jinja-tests.le"><code class="xref py py-func docutils literal notranslate"><span class="pre">le()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.number" title="jinja-tests.number"><code class="xref py py-func docutils literal notranslate"><span class="pre">number()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.true" title="jinja-tests.true"><code class="xref py py-func docutils literal notranslate"><span class="pre">true()</span></code></a></p></td>
</tr>
<tr class="row-odd"><td><p><a class="reference internal" href="#jinja-tests.eq" title="jinja-tests.eq"><code class="xref py py-func docutils literal notranslate"><span class="pre">eq()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.ge" title="jinja-tests.ge"><code class="xref py py-func docutils literal notranslate"><span class="pre">ge()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.lower" title="jinja-tests.lower"><code class="xref py py-func docutils literal notranslate"><span class="pre">lower()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.odd" title="jinja-tests.odd"><code class="xref py py-func docutils literal notranslate"><span class="pre">odd()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.undefined" title="jinja-tests.undefined"><code class="xref py py-func docutils literal notranslate"><span class="pre">undefined()</span></code></a></p></td>
</tr>
<tr class="row-even"><td><p><a class="reference internal" href="#jinja-tests.escaped" title="jinja-tests.escaped"><code class="xref py py-func docutils literal notranslate"><span class="pre">escaped()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.gt" title="jinja-tests.gt"><code class="xref py py-func docutils literal notranslate"><span class="pre">gt()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.lt" title="jinja-tests.lt"><code class="xref py py-func docutils literal notranslate"><span class="pre">lt()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.sameas" title="jinja-tests.sameas"><code class="xref py py-func docutils literal notranslate"><span class="pre">sameas()</span></code></a></p></td>
<td><p><a class="reference internal" href="#jinja-tests.upper" title="jinja-tests.upper"><code class="xref py py-func docutils literal notranslate"><span class="pre">upper()</span></code></a></p></td>
</tr>
</tbody>
</table>
<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.boolean">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">boolean</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.boolean" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is a boolean value.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.11.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.callable">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">callable</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">obj</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.callable" title="Link to this definition">¶</a></dt>
<dd><p>Return whether the object is callable (i.e., some kind of function).</p>
<p>Note that classes are callable, as are instances of classes with a
__call__() method.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.defined">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">defined</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.defined" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is defined:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="nv">variable</span> <span class="k">is</span> <span class="nf">defined</span> <span class="cp">%}</span>
<span class="x">    value of variable: </span><span class="cp">{{</span> <span class="nv">variable</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
<span class="x">    variable is not defined</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>See the <code class="xref py py-func docutils literal notranslate"><span class="pre">default()</span></code> filter for a simple way to set undefined
variables.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.divisibleby">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">divisibleby</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em>, <em class="sig-param"><span class="n"><span class="pre">num</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.divisibleby" title="Link to this definition">¶</a></dt>
<dd><p>Check if a variable is divisible by a number.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.eq">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">eq</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">a</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">b</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.eq" title="Link to this definition">¶</a></dt>
<dd><p>Same as a == b.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">==</span></code>, <code class="docutils literal notranslate"><span class="pre">equalto</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.escaped">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">escaped</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.escaped" title="Link to this definition">¶</a></dt>
<dd><p>Check if the value is escaped.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.even">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">even</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.even" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is even.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.false">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">false</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.false" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is False.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.11.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.filter">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">filter</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.filter" title="Link to this definition">¶</a></dt>
<dd><p>Check if a filter exists by name. Useful if a filter may be
optionally available.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="s1">&#39;markdown&#39;</span> <span class="k">is</span> <span class="nf">filter</span> <span class="cp">%}</span>
<span class="x">    </span><span class="cp">{{</span> <span class="nv">value</span> <span class="o">|</span> <span class="nf">markdown</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
<span class="x">    </span><span class="cp">{{</span> <span class="nv">value</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 3.0.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.float">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">float</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.float" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is a float.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.11.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.ge">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">ge</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">a</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">b</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.ge" title="Link to this definition">¶</a></dt>
<dd><p>Same as a &gt;= b.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">&gt;=</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.gt">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">gt</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">a</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">b</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.gt" title="Link to this definition">¶</a></dt>
<dd><p>Same as a &gt; b.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">&gt;</span></code>, <code class="docutils literal notranslate"><span class="pre">greaterthan</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.in">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">in</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">seq</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Container</span><span class="p"><span class="pre">[</span></span><span class="pre">Any</span><span class="p"><span class="pre">]</span></span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.in" title="Link to this definition">¶</a></dt>
<dd><p>Check if value is in seq.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.10.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.integer">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">integer</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.integer" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is an integer.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.11.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.iterable">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">iterable</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.iterable" title="Link to this definition">¶</a></dt>
<dd><p>Check if it’s possible to iterate over an object.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.le">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">le</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">a</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">b</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.le" title="Link to this definition">¶</a></dt>
<dd><p>Same as a &lt;= b.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">&lt;=</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.lower">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">lower</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.lower" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is lowercased.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.lt">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">lt</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">a</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">b</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.lt" title="Link to this definition">¶</a></dt>
<dd><p>Same as a &lt; b.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">&lt;</span></code>, <code class="docutils literal notranslate"><span class="pre">lessthan</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.mapping">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">mapping</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.mapping" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is a mapping (dict etc.).</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.6.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.ne">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">ne</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">a</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">b</span></span></em>, <em class="sig-param"><span class="o"><span class="pre">/</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-tests.ne" title="Link to this definition">¶</a></dt>
<dd><p>Same as a != b.</p>
<dl class="field-list simple">
<dt class="field-odd">Aliases<span class="colon">:</span></dt>
<dd class="field-odd"><p><code class="docutils literal notranslate"><span class="pre">!=</span></code></p>
</dd>
</dl>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.none">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">none</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.none" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is none.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.number">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">number</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.number" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is a number.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.odd">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">odd</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/functions.html#int" title="(in Python v3.13)"><span class="pre">int</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.odd" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is odd.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.sameas">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">sameas</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">other</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.sameas" title="Link to this definition">¶</a></dt>
<dd><p>Check if an object points to the same memory address than another
object:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="nv">foo.attribute</span> <span class="k">is</span> <span class="nf">sameas</span> <span class="kp">false</span> <span class="cp">%}</span>
<span class="x">    the foo attribute really is the `False` singleton</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.sequence">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">sequence</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.sequence" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is a sequence. Sequences are variables
that are iterable.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.string">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">string</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.string" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is a string.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.test">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">test</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.test" title="Link to this definition">¶</a></dt>
<dd><p>Check if a test exists by name. Useful if a test may be
optionally available.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">if</span> <span class="s1">&#39;loud&#39;</span> <span class="k">is</span> <span class="nf">test</span> <span class="cp">%}</span>
<span class="x">    </span><span class="cp">{%</span> <span class="k">if</span> <span class="nv">value</span> <span class="k">is</span> <span class="nf">loud</span> <span class="cp">%}</span>
<span class="x">        </span><span class="cp">{{</span> <span class="nv">value</span><span class="o">|</span><span class="nf">upper</span> <span class="cp">}}</span>
<span class="x">    </span><span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
<span class="x">        </span><span class="cp">{{</span> <span class="nv">value</span><span class="o">|</span><span class="nf">lower</span> <span class="cp">}}</span>
<span class="x">    </span><span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">else</span> <span class="cp">%}</span>
<span class="x">    </span><span class="cp">{{</span> <span class="nv">value</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 3.0.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.true">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">true</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.true" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the object is True.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.11.</span></p>
</div>
</details></dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.undefined">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">undefined</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><span class="pre">Any</span></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.undefined" title="Link to this definition">¶</a></dt>
<dd><p>Like <a class="reference internal" href="#jinja-tests.defined" title="jinja-tests.defined"><code class="xref py py-func docutils literal notranslate"><span class="pre">defined()</span></code></a> but the other way round.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-tests.upper">
<span class="sig-prename descclassname"><span class="pre">jinja-tests.</span></span><span class="sig-name descname"><span class="pre">upper</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">value</span></span><span class="p"><span class="pre">:</span></span><span class="w"> </span><span class="n"><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><span class="pre">str</span></a></span></em><span class="sig-paren">)</span> <span class="sig-return"><span class="sig-return-icon">&#x2192;</span> <span class="sig-return-typehint"><a class="reference external" href="https://docs.python.org/3/library/functions.html#bool" title="(in Python v3.13)"><span class="pre">bool</span></a></span></span><a class="headerlink" href="#jinja-tests.upper" title="Link to this definition">¶</a></dt>
<dd><p>Return true if the variable is uppercased.</p>
</dd></dl>

</section>
<section id="list-of-global-functions">
<span id="builtin-globals"></span><h2>List of Global Functions<a class="headerlink" href="#list-of-global-functions" title="Link to this heading">¶</a></h2>
<p>The following functions are available in the global scope by default:</p>
<dl class="py function">
<dt class="sig sig-object py" id="jinja-globals.range">
<span class="sig-prename descclassname"><span class="pre">jinja-globals.</span></span><span class="sig-name descname"><span class="pre">range</span></span><span class="sig-paren">(</span><span class="optional">[</span><em class="sig-param"><span class="n"><span class="pre">start</span></span></em>, <span class="optional">]</span><em class="sig-param"><span class="n"><span class="pre">stop</span></span></em><span class="optional">[</span>, <em class="sig-param"><span class="n"><span class="pre">step</span></span></em><span class="optional">]</span><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.range" title="Link to this definition">¶</a></dt>
<dd><p>Return a list containing an arithmetic progression of integers.
<code class="docutils literal notranslate"><span class="pre">range(i,</span> <span class="pre">j)</span></code> returns <code class="docutils literal notranslate"><span class="pre">[i,</span> <span class="pre">i+1,</span> <span class="pre">i+2,</span> <span class="pre">...,</span> <span class="pre">j-1]</span></code>;
start (!) defaults to <code class="docutils literal notranslate"><span class="pre">0</span></code>.
When step is given, it specifies the increment (or decrement).
For example, <code class="docutils literal notranslate"><span class="pre">range(4)</span></code> and <code class="docutils literal notranslate"><span class="pre">range(0,</span> <span class="pre">4,</span> <span class="pre">1)</span></code> return <code class="docutils literal notranslate"><span class="pre">[0,</span> <span class="pre">1,</span> <span class="pre">2,</span> <span class="pre">3]</span></code>.
The end point is omitted!
These are exactly the valid indices for a list of 4 elements.</p>
<p>This is useful to repeat a template block multiple times, e.g.
to fill a list.  Imagine you have 7 users in the list but you want to
render three empty items to enforce a height with CSS:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">ul</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">user.username</span> <span class="cp">}}</span><span class="p">&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">number</span> <span class="k">in</span> <span class="nv">range</span><span class="o">(</span><span class="m">10</span> <span class="o">-</span> <span class="nv">users</span><span class="o">|</span><span class="nf">count</span><span class="o">)</span> <span class="cp">%}</span>
    <span class="p">&lt;</span><span class="nt">li</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;empty&quot;</span><span class="p">&gt;&lt;</span><span class="nt">span</span><span class="p">&gt;</span>...<span class="p">&lt;/</span><span class="nt">span</span><span class="p">&gt;&lt;/</span><span class="nt">li</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-globals.lipsum">
<span class="sig-prename descclassname"><span class="pre">jinja-globals.</span></span><span class="sig-name descname"><span class="pre">lipsum</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">n</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">5</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">html</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">True</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">min</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">20</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">max</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">100</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.lipsum" title="Link to this definition">¶</a></dt>
<dd><p>Generates some lorem ipsum for the template.  By default, five paragraphs
of HTML are generated with each paragraph between 20 and 100 words.
If html is False, regular text is returned.  This is useful to generate simple
contents for layout testing.</p>
</dd></dl>

<dl class="py function">
<dt class="sig sig-object py" id="jinja-globals.dict">
<span class="sig-prename descclassname"><span class="pre">jinja-globals.</span></span><span class="sig-name descname"><span class="pre">dict</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">\**items</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.dict" title="Link to this definition">¶</a></dt>
<dd><p>A convenient alternative to dict literals.  <code class="docutils literal notranslate"><span class="pre">{'foo':</span> <span class="pre">'bar'}</span></code> is the same
as <code class="docutils literal notranslate"><span class="pre">dict(foo='bar')</span></code>.</p>
</dd></dl>

<dl class="py class">
<dt class="sig sig-object py" id="jinja-globals.cycler">
<em class="property"><span class="pre">class</span><span class="w"> </span></em><span class="sig-prename descclassname"><span class="pre">jinja-globals.</span></span><span class="sig-name descname"><span class="pre">cycler</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">\*items</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.cycler" title="Link to this definition">¶</a></dt>
<dd><p>Cycle through values by yielding them one at a time, then restarting
once the end is reached.</p>
<p>Similar to <code class="docutils literal notranslate"><span class="pre">loop.cycle</span></code>, but can be used outside loops or across
multiple loops. For example, render a list of folders and files in a
list, alternating giving them “odd” and “even” classes.</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">row_class</span> <span class="o">=</span> <span class="nv">cycler</span><span class="o">(</span><span class="s2">&quot;odd&quot;</span><span class="o">,</span> <span class="s2">&quot;even&quot;</span><span class="o">)</span> <span class="cp">%}</span>
<span class="p">&lt;</span><span class="nt">ul</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;browser&quot;</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">folder</span> <span class="k">in</span> <span class="nv">folders</span> <span class="cp">%}</span>
  <span class="p">&lt;</span><span class="nt">li</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;folder </span><span class="cp">{{</span> <span class="nv">row_class.next</span><span class="o">()</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">folder</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">file</span> <span class="k">in</span> <span class="nv">files</span> <span class="cp">%}</span>
  <span class="p">&lt;</span><span class="nt">li</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;file </span><span class="cp">{{</span> <span class="nv">row_class.next</span><span class="o">()</span> <span class="cp">}}</span><span class="s">&quot;</span><span class="p">&gt;</span><span class="cp">{{</span> <span class="nv">file</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
<span class="p">&lt;/</span><span class="nt">ul</span><span class="p">&gt;</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>items</strong> – Each positional argument will be yielded in the order
given for each cycle.</p>
</dd>
</dl>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.1.</span></p>
</div>
</details><dl class="py property">
<dt class="sig sig-object py" id="jinja-globals.cycler.current">
<em class="property"><span class="pre">property</span><span class="w"> </span></em><span class="sig-name descname"><span class="pre">current</span></span><a class="headerlink" href="#jinja-globals.cycler.current" title="Link to this definition">¶</a></dt>
<dd><p>Return the current item. Equivalent to the item that will be
returned next time <a class="reference internal" href="#jinja-globals.cycler.next" title="jinja-globals.cycler.next"><code class="xref py py-meth docutils literal notranslate"><span class="pre">next()</span></code></a> is called.</p>
</dd></dl>

<dl class="py method">
<dt class="sig sig-object py" id="jinja-globals.cycler.next">
<span class="sig-name descname"><span class="pre">next</span></span><span class="sig-paren">(</span><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.cycler.next" title="Link to this definition">¶</a></dt>
<dd><p>Return the current item, then advance <a class="reference internal" href="#jinja-globals.cycler.current" title="jinja-globals.cycler.current"><code class="xref py py-attr docutils literal notranslate"><span class="pre">current</span></code></a> to the
next item.</p>
</dd></dl>

<dl class="py method">
<dt class="sig sig-object py" id="jinja-globals.cycler.reset">
<span class="sig-name descname"><span class="pre">reset</span></span><span class="sig-paren">(</span><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.cycler.reset" title="Link to this definition">¶</a></dt>
<dd><p>Resets the current item to the first item.</p>
</dd></dl>

</dd></dl>

<dl class="py class">
<dt class="sig sig-object py" id="jinja-globals.joiner">
<em class="property"><span class="pre">class</span><span class="w"> </span></em><span class="sig-prename descclassname"><span class="pre">jinja-globals.</span></span><span class="sig-name descname"><span class="pre">joiner</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">sep</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">',</span> <span class="pre">'</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.joiner" title="Link to this definition">¶</a></dt>
<dd><p>A tiny helper that can be used to “join” multiple sections.  A joiner is
passed a string and will return that string every time it’s called, except
the first time (in which case it returns an empty string).  You can
use this to join things:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">pipe</span> <span class="o">=</span> <span class="nv">joiner</span><span class="o">(</span><span class="s2">&quot;|&quot;</span><span class="o">)</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">if</span> <span class="nv">categories</span> <span class="cp">%}</span> <span class="cp">{{</span> <span class="nv">pipe</span><span class="o">()</span> <span class="cp">}}</span>
    Categories: <span class="cp">{{</span> <span class="nv">categories</span><span class="o">|</span><span class="nf">join</span><span class="o">(</span><span class="s2">&quot;, &quot;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">if</span> <span class="nv">author</span> <span class="cp">%}</span> <span class="cp">{{</span> <span class="nv">pipe</span><span class="o">()</span> <span class="cp">}}</span>
    Author: <span class="cp">{{</span> <span class="nv">author</span><span class="o">()</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">if</span> <span class="nv">can_edit</span> <span class="cp">%}</span> <span class="cp">{{</span> <span class="nv">pipe</span><span class="o">()</span> <span class="cp">}}</span>
    <span class="p">&lt;</span><span class="nt">a</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;?action=edit&quot;</span><span class="p">&gt;</span>Edit<span class="p">&lt;/</span><span class="nt">a</span><span class="p">&gt;</span>
<span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
</pre></div>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.1.</span></p>
</div>
</details></dd></dl>

<dl class="py class">
<dt class="sig sig-object py" id="jinja-globals.namespace">
<em class="property"><span class="pre">class</span><span class="w"> </span></em><span class="sig-prename descclassname"><span class="pre">jinja-globals.</span></span><span class="sig-name descname"><span class="pre">namespace</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">...</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#jinja-globals.namespace" title="Link to this definition">¶</a></dt>
<dd><p>Creates a new container that allows attribute assignment using the
<code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">set</span> <span class="pre">%}</span></code> tag:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">ns</span> <span class="o">=</span> <span class="nv">namespace</span><span class="o">()</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">set</span> <span class="nv">ns.foo</span> <span class="o">=</span> <span class="s1">&#39;bar&#39;</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>The main purpose of this is to allow carrying a value from within a loop
body to an outer scope.  Initial values can be provided as a dict, as
keyword arguments, or both (same behavior as Python’s <code class="code docutils literal notranslate"><span class="pre">dict</span></code> constructor):</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">set</span> <span class="nv">ns</span> <span class="o">=</span> <span class="nv">namespace</span><span class="o">(</span><span class="nv">found</span><span class="o">=</span><span class="kp">false</span><span class="o">)</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">for</span> <span class="nv">item</span> <span class="k">in</span> <span class="nv">items</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">if</span> <span class="nv">item.check_something</span><span class="o">()</span> <span class="cp">%}</span>
        <span class="cp">{%</span> <span class="k">set</span> <span class="nv">ns.found</span> <span class="o">=</span> <span class="kp">true</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">endif</span> <span class="cp">%}</span>
    * <span class="cp">{{</span> <span class="nv">item.title</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
Found item having something: <span class="cp">{{</span> <span class="nv">ns.found</span> <span class="cp">}}</span>
</pre></div>
</div>
<div class="versionchanged">
<p><span class="versionmodified changed">Changed in version 3.2: </span>Namespace attributes can be assigned to in multiple assignment.</p>
</div>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.10.</span></p>
</div>
</details></dd></dl>

</section>
<section id="extensions">
<h2>Extensions<a class="headerlink" href="#extensions" title="Link to this heading">¶</a></h2>
<p>The following sections cover the built-in Jinja extensions that may be
enabled by an application.  An application could also provide further
extensions not covered by this documentation; in which case there should
be a separate document explaining said <a class="reference internal" href="../extensions/#jinja-extensions"><span class="std std-ref">extensions</span></a>.</p>
<section id="i18n">
<span id="i18n-in-templates"></span><h3>i18n<a class="headerlink" href="#i18n" title="Link to this heading">¶</a></h3>
<p>If the <a class="reference internal" href="../extensions/#i18n-extension"><span class="std std-ref">i18n Extension</span></a> is enabled, it’s possible to mark text in
the template as translatable. To mark a section as translatable, use a
<code class="docutils literal notranslate"><span class="pre">trans</span></code> block:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="cp">%}</span><span class="x">Hello, </span><span class="cp">{{</span> <span class="nv">user</span> <span class="cp">}}</span><span class="x">!</span><span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Inside the block, no statements are allowed, only text and simple
variable tags.</p>
<p>Variable tags can only be a name, not attribute access, filters, or
other expressions. To use an expression, bind it to a name in the
<code class="docutils literal notranslate"><span class="pre">trans</span></code> tag for use in the block.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="nv">user</span><span class="o">=</span><span class="nv">user.username</span> <span class="cp">%}</span><span class="x">Hello, </span><span class="cp">{{</span> <span class="nv">user</span> <span class="cp">}}</span><span class="x">!</span><span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>To bind more than one expression, separate each with a comma (<code class="docutils literal notranslate"><span class="pre">,</span></code>).</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="nv">book_title</span><span class="o">=</span><span class="nv">book.title</span><span class="o">,</span> <span class="nv">author</span><span class="o">=</span><span class="nv">author.name</span> <span class="cp">%}</span>
<span class="x">This is </span><span class="cp">{{</span> <span class="nv">book_title</span> <span class="cp">}}</span><span class="x"> by </span><span class="cp">{{</span> <span class="nv">author</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>To pluralize, specify both the singular and plural forms separated by
the <code class="docutils literal notranslate"><span class="pre">pluralize</span></code> tag.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="nv">count</span><span class="o">=</span><span class="nv">list</span><span class="o">|</span><span class="nf">length</span> <span class="cp">%}</span>
<span class="x">There is </span><span class="cp">{{</span> <span class="nv">count</span> <span class="cp">}}</span><span class="x"> </span><span class="cp">{{</span> <span class="nv">name</span> <span class="cp">}}</span><span class="x"> object.</span>
<span class="cp">{%</span> <span class="k">pluralize</span> <span class="cp">%}</span>
<span class="x">There are </span><span class="cp">{{</span> <span class="nv">count</span> <span class="cp">}}</span><span class="x"> </span><span class="cp">{{</span> <span class="nv">name</span> <span class="cp">}}</span><span class="x"> objects.</span>
<span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>By default, the first variable in a block is used to determine whether
to use singular or plural form. If that isn’t correct, specify the
variable used for pluralizing as a parameter to <code class="docutils literal notranslate"><span class="pre">pluralize</span></code>.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="p">...</span><span class="o">,</span> <span class="nv">user_count</span><span class="o">=</span><span class="nv">users</span><span class="o">|</span><span class="nf">length</span> <span class="cp">%}</span><span class="x">...</span>
<span class="cp">{%</span> <span class="k">pluralize</span> <span class="nv">user_count</span> <span class="cp">%}</span><span class="x">...</span><span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>When translating blocks of text, whitespace and linebreaks result in
hard to read and error-prone translation strings. To avoid this, a trans
block can be marked as trimmed, which will replace all linebreaks and
the whitespace surrounding them with a single space and remove leading
and trailing whitespace.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="nv">trimmed</span> <span class="nv">book_title</span><span class="o">=</span><span class="nv">book.title</span> <span class="cp">%}</span>
<span class="x">    This is </span><span class="cp">{{</span> <span class="nv">book_title</span> <span class="cp">}}</span><span class="x">.</span>
<span class="x">    You should read it!</span>
<span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>This results in <code class="docutils literal notranslate"><span class="pre">This</span> <span class="pre">is</span> <span class="pre">%(book_title)s.</span> <span class="pre">You</span> <span class="pre">should</span> <span class="pre">read</span> <span class="pre">it!</span></code> in the
translation file.</p>
<p>If trimming is enabled globally, the <code class="docutils literal notranslate"><span class="pre">notrimmed</span></code> modifier can be used
to disable it for a block.</p>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.10: </span>The <code class="docutils literal notranslate"><span class="pre">trimmed</span></code> and <code class="docutils literal notranslate"><span class="pre">notrimmed</span></code> modifiers have been added.</p>
</div>
</details><p>If the translation depends on the context that the message appears in,
the <code class="docutils literal notranslate"><span class="pre">pgettext</span></code> and <code class="docutils literal notranslate"><span class="pre">npgettext</span></code> functions take a <code class="docutils literal notranslate"><span class="pre">context</span></code> string
as the first argument, which is used to select the appropriate
translation. To specify a context with the <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">trans</span> <span class="pre">%}</span></code> tag, provide
a string as the first token after <code class="docutils literal notranslate"><span class="pre">trans</span></code>.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">trans</span> <span class="s2">&quot;fruit&quot;</span> <span class="cp">%}</span><span class="x">apple</span><span class="cp">{%</span> <span class="k">endtrans</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">trans</span> <span class="s2">&quot;fruit&quot;</span> <span class="nv">trimmed</span> <span class="nv">count</span> -<span class="cp">%}</span>
<span class="x">    1 apple</span>
<span class="cp">{%</span>- <span class="k">pluralize</span> -<span class="cp">%}</span>
<span class="x">    </span><span class="cp">{{</span> <span class="nv">count</span> <span class="cp">}}</span><span class="x"> apples</span>
<span class="cp">{%</span>- <span class="k">endtrans</span> <span class="cp">%}</span>
</pre></div>
</div>
<div class="versionadded">
<p><span class="versionmodified added">Added in version 3.1: </span>A context can be passed to the <code class="docutils literal notranslate"><span class="pre">trans</span></code> tag to use <code class="docutils literal notranslate"><span class="pre">pgettext</span></code> and
<code class="docutils literal notranslate"><span class="pre">npgettext</span></code>.</p>
</div>
<p>It’s possible to translate strings in expressions with these functions:</p>
<ul class="simple">
<li><p><code class="docutils literal notranslate"><span class="pre">_(message)</span></code>: Alias for <code class="docutils literal notranslate"><span class="pre">gettext</span></code>.</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">gettext(message)</span></code>: Translate a message.</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">ngettext(singular,</span> <span class="pre">plural,</span> <span class="pre">n)</span></code>: Translate a singular or plural
message based on a count variable.</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">pgettext(context,</span> <span class="pre">message)</span></code>: Like <code class="docutils literal notranslate"><span class="pre">gettext()</span></code>, but picks the
translation based on the context string.</p></li>
<li><p><code class="docutils literal notranslate"><span class="pre">npgettext(context,</span> <span class="pre">singular,</span> <span class="pre">plural,</span> <span class="pre">n)</span></code>: Like <code class="docutils literal notranslate"><span class="pre">npgettext()</span></code>,
but picks the translation based on the context string.</p></li>
</ul>
<p>You can print a translated string like this:</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="kp">_</span><span class="o">(</span><span class="s2">&quot;Hello, World!&quot;</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>To use placeholders, use the <code class="docutils literal notranslate"><span class="pre">format</span></code> filter.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="kp">_</span><span class="o">(</span><span class="s2">&quot;Hello, %(user)s!&quot;</span><span class="o">)|</span><span class="nf">format</span><span class="o">(</span><span class="nv">user</span><span class="o">=</span><span class="nv">user.username</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>Always use keyword arguments to <code class="docutils literal notranslate"><span class="pre">format</span></code>, as other languages may not
use the words in the same order.</p>
<p>If <a class="reference internal" href="../extensions/#newstyle-gettext"><span class="std std-ref">New Style Gettext</span></a> calls are activated, using placeholders is
easier. Formatting is part of the <code class="docutils literal notranslate"><span class="pre">gettext</span></code> call instead of using the
<code class="docutils literal notranslate"><span class="pre">format</span></code> filter.</p>
<div class="highlight-jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{{</span> <span class="nv">gettext</span><span class="o">(</span><span class="s1">&#39;Hello World!&#39;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">gettext</span><span class="o">(</span><span class="s1">&#39;Hello %(name)s!&#39;</span><span class="o">,</span> <span class="nv">name</span><span class="o">=</span><span class="s1">&#39;World&#39;</span><span class="o">)</span> <span class="cp">}}</span>
<span class="cp">{{</span> <span class="nv">ngettext</span><span class="o">(</span><span class="s1">&#39;%(num)d apple&#39;</span><span class="o">,</span> <span class="s1">&#39;%(num)d apples&#39;</span><span class="o">,</span> <span class="nv">apples</span><span class="o">|</span><span class="nf">count</span><span class="o">)</span> <span class="cp">}}</span>
</pre></div>
</div>
<p>The <code class="docutils literal notranslate"><span class="pre">ngettext</span></code> function’s format string automatically receives the
count as a <code class="docutils literal notranslate"><span class="pre">num</span></code> parameter in addition to the given parameters.</p>
</section>
<section id="expression-statement">
<h3>Expression Statement<a class="headerlink" href="#expression-statement" title="Link to this heading">¶</a></h3>
<p>If the expression-statement extension is loaded, a tag called <code class="code docutils literal notranslate"><span class="pre">do</span></code> is available
that works exactly like the regular variable expression (<code class="docutils literal notranslate"><span class="pre">{{</span> <span class="pre">...</span> <span class="pre">}}</span></code>); except
it doesn’t print anything.  This can be used to modify lists:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">do</span> <span class="nv">navigation.append</span><span class="o">(</span><span class="s1">&#39;a string&#39;</span><span class="o">)</span> <span class="cp">%}</span>
</pre></div>
</div>
</section>
<section id="loop-controls">
<h3>Loop Controls<a class="headerlink" href="#loop-controls" title="Link to this heading">¶</a></h3>
<p>If the application enables the <a class="reference internal" href="../extensions/#loopcontrols-extension"><span class="std std-ref">Loop Controls</span></a>, it’s possible to
use <code class="code docutils literal notranslate"><span class="pre">break</span></code> and <code class="code docutils literal notranslate"><span class="pre">continue</span></code> in loops.  When <code class="code docutils literal notranslate"><span class="pre">break</span></code> is reached, the loop is
terminated;  if <code class="code docutils literal notranslate"><span class="pre">continue</span></code> is reached, the processing is stopped and continues
with the next iteration.</p>
<p>Here’s a loop that skips every second item:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
    <span class="cp">{%</span>- <span class="k">if</span> <span class="nb">loop</span><span class="nv">.index</span> <span class="k">is</span> <span class="nf">even</span> <span class="cp">%}{%</span> <span class="k">continue</span> <span class="cp">%}{%</span> <span class="k">endif</span> <span class="cp">%}</span>
    ...
<span class="cp">{%</span> <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Likewise, a loop that stops processing after the 10th iteration:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">for</span> <span class="nv">user</span> <span class="k">in</span> <span class="nv">users</span> <span class="cp">%}</span>
    <span class="cp">{%</span>- <span class="k">if</span> <span class="nb">loop</span><span class="nv">.index</span> <span class="o">&gt;=</span> <span class="m">10</span> <span class="cp">%}{%</span> <span class="k">break</span> <span class="cp">%}{%</span> <span class="k">endif</span> <span class="cp">%}</span>
<span class="cp">{%</span>- <span class="k">endfor</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>Note that <code class="docutils literal notranslate"><span class="pre">loop.index</span></code> starts with 1, and <code class="docutils literal notranslate"><span class="pre">loop.index0</span></code> starts with 0
(See: <a class="reference internal" href="#for-loop"><span class="std std-ref">For</span></a>).</p>
</section>
<section id="debug-statement">
<h3>Debug Statement<a class="headerlink" href="#debug-statement" title="Link to this heading">¶</a></h3>
<p>If the <a class="reference internal" href="../extensions/#debug-extension"><span class="std std-ref">Debug Extension</span></a> is enabled, a <code class="docutils literal notranslate"><span class="pre">{%</span> <span class="pre">debug</span> <span class="pre">%}</span></code> tag will be
available to dump the current context as well as the available filters
and tests. This is useful to see what’s available to use in the template
without setting up a debugger.</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="p">&lt;</span><span class="nt">pre</span><span class="p">&gt;</span><span class="cp">{%</span> <span class="k">debug</span> <span class="cp">%}</span><span class="p">&lt;/</span><span class="nt">pre</span><span class="p">&gt;</span>
</pre></div>
</div>
<div class="highlight-text notranslate"><div class="highlight"><pre><span></span>{&#39;context&#39;: {&#39;cycler&#39;: &lt;class &#39;jinja2.utils.Cycler&#39;&gt;,
             ...,
             &#39;namespace&#39;: &lt;class &#39;jinja2.utils.Namespace&#39;&gt;},
 &#39;filters&#39;: [&#39;abs&#39;, &#39;attr&#39;, &#39;batch&#39;, &#39;capitalize&#39;, &#39;center&#39;, &#39;count&#39;, &#39;d&#39;,
             ..., &#39;urlencode&#39;, &#39;urlize&#39;, &#39;wordcount&#39;, &#39;wordwrap&#39;, &#39;xmlattr&#39;],
 &#39;tests&#39;: [&#39;!=&#39;, &#39;&lt;&#39;, &#39;&lt;=&#39;, &#39;==&#39;, &#39;&gt;&#39;, &#39;&gt;=&#39;, &#39;callable&#39;, &#39;defined&#39;,
           ..., &#39;odd&#39;, &#39;sameas&#39;, &#39;sequence&#39;, &#39;string&#39;, &#39;undefined&#39;, &#39;upper&#39;]}
</pre></div>
</div>
</section>
<section id="with-statement">
<h3>With Statement<a class="headerlink" href="#with-statement" title="Link to this heading">¶</a></h3>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.3.</span></p>
</div>
</details><p>The with statement makes it possible to create a new inner scope.
Variables set within this scope are not visible outside of the scope.</p>
<p>With in a nutshell:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">with</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">set</span> <span class="nv">foo</span> <span class="o">=</span> <span class="m">42</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">foo</span> <span class="cp">}}</span>           foo is 42 here
<span class="cp">{%</span> <span class="k">endwith</span> <span class="cp">%}</span>
foo is not visible here any longer
</pre></div>
</div>
<p>Because it is common to set variables at the beginning of the scope,
you can do that within the <code class="code docutils literal notranslate"><span class="pre">with</span></code> statement.  The following two examples
are equivalent:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">with</span> <span class="nv">foo</span> <span class="o">=</span> <span class="m">42</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">foo</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endwith</span> <span class="cp">%}</span>

<span class="cp">{%</span> <span class="k">with</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">set</span> <span class="nv">foo</span> <span class="o">=</span> <span class="m">42</span> <span class="cp">%}</span>
    <span class="cp">{{</span> <span class="nv">foo</span> <span class="cp">}}</span>
<span class="cp">{%</span> <span class="k">endwith</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>An important note on scoping here.  In Jinja versions before 2.9 the
behavior of referencing one variable to another had some unintended
consequences.  In particular one variable could refer to another defined
in the same with block’s opening statement.  This caused issues with the
cleaned up scoping behavior and has since been improved.  In particular
in newer Jinja versions the following code always refers to the variable
<code class="code docutils literal notranslate"><span class="pre">a</span></code> from outside the <code class="code docutils literal notranslate"><span class="pre">with</span></code> block:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">with</span> <span class="nv">a</span><span class="o">={},</span> <span class="nv">b</span><span class="o">=</span><span class="nv">a.attribute</span> <span class="cp">%}</span>...<span class="cp">{%</span> <span class="k">endwith</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>In earlier Jinja versions the <code class="code docutils literal notranslate"><span class="pre">b</span></code> attribute would refer to the results of
the first attribute.  If you depend on this behavior you can rewrite it to
use the <code class="docutils literal notranslate"><span class="pre">set</span></code> tag:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">with</span> <span class="nv">a</span><span class="o">={}</span> <span class="cp">%}</span>
    <span class="cp">{%</span> <span class="k">set</span> <span class="nv">b</span> <span class="o">=</span> <span class="nv">a.attribute</span> <span class="cp">%}</span>
<span class="cp">{%</span> <span class="k">endwith</span> <span class="cp">%}</span>
</pre></div>
</div>
<div class="admonition-extension admonition">
<p class="admonition-title">Extension</p>
<p>In older versions of Jinja (before 2.9) it was required to enable this
feature with an extension.  It’s now enabled by default.</p>
</div>
</section>
</section>
<section id="autoescape-overrides">
<span id="id19"></span><h2>Autoescape Overrides<a class="headerlink" href="#autoescape-overrides" title="Link to this heading">¶</a></h2>
<details class="changelog">
<summary>Changelog</summary><div class="versionadded">
<p><span class="versionmodified added">Added in version 2.4.</span></p>
</div>
</details><p>If you want you can activate and deactivate the autoescaping from within
the templates.</p>
<p>Example:</p>
<div class="highlight-html+jinja notranslate"><div class="highlight"><pre><span></span><span class="cp">{%</span> <span class="k">autoescape</span> <span class="kp">true</span> <span class="cp">%}</span>
    Autoescaping is active within this block
<span class="cp">{%</span> <span class="k">endautoescape</span> <span class="cp">%}</span>

<span class="cp">{%</span> <span class="k">autoescape</span> <span class="kp">false</span> <span class="cp">%}</span>
    Autoescaping is inactive within this block
<span class="cp">{%</span> <span class="k">endautoescape</span> <span class="cp">%}</span>
</pre></div>
</div>
<p>After an <code class="code docutils literal notranslate"><span class="pre">endautoescape</span></code> the behavior is reverted to what it was before.</p>
<div class="admonition-extension admonition">
<p class="admonition-title">Extension</p>
<p>In older versions of Jinja (before 2.9) it was required to enable this
feature with an extension.  It’s now enabled by default.</p>
</div>
</section>
</section>


            <div class="clearer"></div>
          </div>
        </div>
      </div>
  <span id="sidebar-top"></span>
      <div class="sphinxsidebar" role="navigation" aria-label="Main">
        <div class="sphinxsidebarwrapper">
  
    
            <p class="logo"><a href="../">
              <img class="logo" src="../_static/jinja-logo.svg" alt="Logo of Jinja"/>
            </a></p>
  

  <h3>Contents</h3>
  <ul>
<li><a class="reference internal" href="#">Template Designer Documentation</a><ul>
<li><a class="reference internal" href="#synopsis">Synopsis</a><ul>
<li><a class="reference internal" href="#template-file-extension">Template File Extension</a></li>
</ul>
</li>
<li><a class="reference internal" href="#variables">Variables</a></li>
<li><a class="reference internal" href="#filters">Filters</a></li>
<li><a class="reference internal" href="#tests">Tests</a></li>
<li><a class="reference internal" href="#comments">Comments</a></li>
<li><a class="reference internal" href="#whitespace-control">Whitespace Control</a></li>
<li><a class="reference internal" href="#escaping">Escaping</a></li>
<li><a class="reference internal" href="#line-statements">Line Statements</a></li>
<li><a class="reference internal" href="#template-inheritance">Template Inheritance</a><ul>
<li><a class="reference internal" href="#base-template">Base Template</a></li>
<li><a class="reference internal" href="#child-template">Child Template</a></li>
<li><a class="reference internal" href="#super-blocks">Super Blocks</a></li>
<li><a class="reference internal" href="#nesting-extends">Nesting extends</a></li>
<li><a class="reference internal" href="#named-block-end-tags">Named Block End-Tags</a></li>
<li><a class="reference internal" href="#block-nesting-and-scope">Block Nesting and Scope</a></li>
<li><a class="reference internal" href="#required-blocks">Required Blocks</a></li>
<li><a class="reference internal" href="#template-objects">Template Objects</a></li>
</ul>
</li>
<li><a class="reference internal" href="#html-escaping">HTML Escaping</a><ul>
<li><a class="reference internal" href="#working-with-manual-escaping">Working with Manual Escaping</a></li>
<li><a class="reference internal" href="#working-with-automatic-escaping">Working with Automatic Escaping</a></li>
</ul>
</li>
<li><a class="reference internal" href="#list-of-control-structures">List of Control Structures</a><ul>
<li><a class="reference internal" href="#for">For</a></li>
<li><a class="reference internal" href="#if">If</a></li>
<li><a class="reference internal" href="#macros">Macros</a></li>
<li><a class="reference internal" href="#call">Call</a></li>
<li><a class="reference internal" href="#id11">Filters</a></li>
<li><a class="reference internal" href="#assignments">Assignments</a></li>
<li><a class="reference internal" href="#block-assignments">Block Assignments</a></li>
<li><a class="reference internal" href="#extends">Extends</a></li>
<li><a class="reference internal" href="#blocks">Blocks</a></li>
<li><a class="reference internal" href="#include">Include</a></li>
<li><a class="reference internal" href="#import">Import</a></li>
</ul>
</li>
<li><a class="reference internal" href="#import-context-behavior">Import Context Behavior</a></li>
<li><a class="reference internal" href="#expressions">Expressions</a><ul>
<li><a class="reference internal" href="#literals">Literals</a></li>
<li><a class="reference internal" href="#math">Math</a></li>
<li><a class="reference internal" href="#comparisons">Comparisons</a></li>
<li><a class="reference internal" href="#logic">Logic</a></li>
<li><a class="reference internal" href="#other-operators">Other Operators</a></li>
<li><a class="reference internal" href="#if-expression">If Expression</a></li>
<li><a class="reference internal" href="#python-methods">Python Methods</a></li>
</ul>
</li>
<li><a class="reference internal" href="#list-of-builtin-filters">List of Builtin Filters</a><ul>
<li><a class="reference internal" href="#jinja-filters.abs"><code class="docutils literal notranslate"><span class="pre">abs()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.attr"><code class="docutils literal notranslate"><span class="pre">attr()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.batch"><code class="docutils literal notranslate"><span class="pre">batch()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.capitalize"><code class="docutils literal notranslate"><span class="pre">capitalize()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.center"><code class="docutils literal notranslate"><span class="pre">center()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.default"><code class="docutils literal notranslate"><span class="pre">default()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.dictsort"><code class="docutils literal notranslate"><span class="pre">dictsort()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.escape"><code class="docutils literal notranslate"><span class="pre">escape()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.filesizeformat"><code class="docutils literal notranslate"><span class="pre">filesizeformat()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.first"><code class="docutils literal notranslate"><span class="pre">first()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.float"><code class="docutils literal notranslate"><span class="pre">float()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.forceescape"><code class="docutils literal notranslate"><span class="pre">forceescape()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.format"><code class="docutils literal notranslate"><span class="pre">format()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.groupby"><code class="docutils literal notranslate"><span class="pre">groupby()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.indent"><code class="docutils literal notranslate"><span class="pre">indent()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.int"><code class="docutils literal notranslate"><span class="pre">int()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.items"><code class="docutils literal notranslate"><span class="pre">items()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.join"><code class="docutils literal notranslate"><span class="pre">join()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.last"><code class="docutils literal notranslate"><span class="pre">last()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.length"><code class="docutils literal notranslate"><span class="pre">length()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.list"><code class="docutils literal notranslate"><span class="pre">list()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.lower"><code class="docutils literal notranslate"><span class="pre">lower()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.map"><code class="docutils literal notranslate"><span class="pre">map()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.max"><code class="docutils literal notranslate"><span class="pre">max()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.min"><code class="docutils literal notranslate"><span class="pre">min()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.pprint"><code class="docutils literal notranslate"><span class="pre">pprint()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.random"><code class="docutils literal notranslate"><span class="pre">random()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.reject"><code class="docutils literal notranslate"><span class="pre">reject()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.rejectattr"><code class="docutils literal notranslate"><span class="pre">rejectattr()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.replace"><code class="docutils literal notranslate"><span class="pre">replace()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.reverse"><code class="docutils literal notranslate"><span class="pre">reverse()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.round"><code class="docutils literal notranslate"><span class="pre">round()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.safe"><code class="docutils literal notranslate"><span class="pre">safe()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.select"><code class="docutils literal notranslate"><span class="pre">select()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.selectattr"><code class="docutils literal notranslate"><span class="pre">selectattr()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.slice"><code class="docutils literal notranslate"><span class="pre">slice()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.sort"><code class="docutils literal notranslate"><span class="pre">sort()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.string"><code class="docutils literal notranslate"><span class="pre">string()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.striptags"><code class="docutils literal notranslate"><span class="pre">striptags()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.sum"><code class="docutils literal notranslate"><span class="pre">sum()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.title"><code class="docutils literal notranslate"><span class="pre">title()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.tojson"><code class="docutils literal notranslate"><span class="pre">tojson()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.trim"><code class="docutils literal notranslate"><span class="pre">trim()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.truncate"><code class="docutils literal notranslate"><span class="pre">truncate()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.unique"><code class="docutils literal notranslate"><span class="pre">unique()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.upper"><code class="docutils literal notranslate"><span class="pre">upper()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.urlencode"><code class="docutils literal notranslate"><span class="pre">urlencode()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.urlize"><code class="docutils literal notranslate"><span class="pre">urlize()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.wordcount"><code class="docutils literal notranslate"><span class="pre">wordcount()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.wordwrap"><code class="docutils literal notranslate"><span class="pre">wordwrap()</span></code></a></li>
<li><a class="reference internal" href="#jinja-filters.xmlattr"><code class="docutils literal notranslate"><span class="pre">xmlattr()</span></code></a></li>
</ul>
</li>
<li><a class="reference internal" href="#list-of-builtin-tests">List of Builtin Tests</a><ul>
<li><a class="reference internal" href="#jinja-tests.boolean"><code class="docutils literal notranslate"><span class="pre">boolean()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.callable"><code class="docutils literal notranslate"><span class="pre">callable()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.defined"><code class="docutils literal notranslate"><span class="pre">defined()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.divisibleby"><code class="docutils literal notranslate"><span class="pre">divisibleby()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.eq"><code class="docutils literal notranslate"><span class="pre">eq()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.escaped"><code class="docutils literal notranslate"><span class="pre">escaped()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.even"><code class="docutils literal notranslate"><span class="pre">even()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.false"><code class="docutils literal notranslate"><span class="pre">false()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.filter"><code class="docutils literal notranslate"><span class="pre">filter()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.float"><code class="docutils literal notranslate"><span class="pre">float()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.ge"><code class="docutils literal notranslate"><span class="pre">ge()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.gt"><code class="docutils literal notranslate"><span class="pre">gt()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.in"><code class="docutils literal notranslate"><span class="pre">in()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.integer"><code class="docutils literal notranslate"><span class="pre">integer()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.iterable"><code class="docutils literal notranslate"><span class="pre">iterable()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.le"><code class="docutils literal notranslate"><span class="pre">le()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.lower"><code class="docutils literal notranslate"><span class="pre">lower()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.lt"><code class="docutils literal notranslate"><span class="pre">lt()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.mapping"><code class="docutils literal notranslate"><span class="pre">mapping()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.ne"><code class="docutils literal notranslate"><span class="pre">ne()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.none"><code class="docutils literal notranslate"><span class="pre">none()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.number"><code class="docutils literal notranslate"><span class="pre">number()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.odd"><code class="docutils literal notranslate"><span class="pre">odd()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.sameas"><code class="docutils literal notranslate"><span class="pre">sameas()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.sequence"><code class="docutils literal notranslate"><span class="pre">sequence()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.string"><code class="docutils literal notranslate"><span class="pre">string()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.test"><code class="docutils literal notranslate"><span class="pre">test()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.true"><code class="docutils literal notranslate"><span class="pre">true()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.undefined"><code class="docutils literal notranslate"><span class="pre">undefined()</span></code></a></li>
<li><a class="reference internal" href="#jinja-tests.upper"><code class="docutils literal notranslate"><span class="pre">upper()</span></code></a></li>
</ul>
</li>
<li><a class="reference internal" href="#list-of-global-functions">List of Global Functions</a><ul>
<li><a class="reference internal" href="#jinja-globals.range"><code class="docutils literal notranslate"><span class="pre">range()</span></code></a></li>
<li><a class="reference internal" href="#jinja-globals.lipsum"><code class="docutils literal notranslate"><span class="pre">lipsum()</span></code></a></li>
<li><a class="reference internal" href="#jinja-globals.dict"><code class="docutils literal notranslate"><span class="pre">dict()</span></code></a></li>
<li><a class="reference internal" href="#jinja-globals.cycler"><code class="docutils literal notranslate"><span class="pre">cycler</span></code></a><ul>
<li><a class="reference internal" href="#jinja-globals.cycler.current"><code class="docutils literal notranslate"><span class="pre">cycler.current</span></code></a></li>
<li><a class="reference internal" href="#jinja-globals.cycler.next"><code class="docutils literal notranslate"><span class="pre">cycler.next()</span></code></a></li>
<li><a class="reference internal" href="#jinja-globals.cycler.reset"><code class="docutils literal notranslate"><span class="pre">cycler.reset()</span></code></a></li>
</ul>
</li>
<li><a class="reference internal" href="#jinja-globals.joiner"><code class="docutils literal notranslate"><span class="pre">joiner</span></code></a></li>
<li><a class="reference internal" href="#jinja-globals.namespace"><code class="docutils literal notranslate"><span class="pre">namespace</span></code></a></li>
</ul>
</li>
<li><a class="reference internal" href="#extensions">Extensions</a><ul>
<li><a class="reference internal" href="#i18n">i18n</a></li>
<li><a class="reference internal" href="#expression-statement">Expression Statement</a></li>
<li><a class="reference internal" href="#loop-controls">Loop Controls</a></li>
<li><a class="reference internal" href="#debug-statement">Debug Statement</a></li>
<li><a class="reference internal" href="#with-statement">With Statement</a></li>
</ul>
</li>
<li><a class="reference internal" href="#autoescape-overrides">Autoescape Overrides</a></li>
</ul>
</li>
</ul>
<h3>Navigation</h3>
<ul>
  <li><a href="../">Overview</a>
    <ul>
          <li>Previous: <a href="../nativetypes/" title="previous chapter">Native Python Types</a>
          <li>Next: <a href="../extensions/" title="next chapter">Extensions</a>
    </ul>
  </li>
</ul>
<search id="searchbox" style="display: none" role="search">
  <h3 id="searchlabel">Quick search</h3>
    <div class="searchformwrapper">
    <form class="search" action="../search/" method="get">
      <input type="text" name="q" aria-labelledby="searchlabel" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"/>
      <input type="submit" value="Go" />
    </form>
    </div>
</search>
<script>document.getElementById('searchbox').style.display = "block"</script><div id="ethical-ad-placement"></div>
        </div>
      </div>
      <div class="clearer"></div>
    </div>
    <div class="footer" role="contentinfo">
    &#169; Copyright 2007 Pallets.
      Created using <a href="https://www.sphinx-doc.org/">Sphinx</a> 8.1.3.
    </div>
  </body>
</html>