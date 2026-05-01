<!DOCTYPE html>

<html lang="en" data-content_root="../">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Working With Safe Text &#8212; MarkupSafe Documentation (3.0.x)</title>
    <link rel="stylesheet" type="text/css" href="../_static/pygments.css?v=7a9665a2" />
    <link rel="stylesheet" type="text/css" href="../_static/jinja.css?v=85659ec6" />
    <script src="../_static/documentation_options.js?v=9f2e3481"></script>
    <script src="../_static/doctools.js?v=9bcbadda"></script>
    <script src="../_static/sphinx_highlight.js?v=dc90522c"></script>
    <link rel="canonical" href="https://markupsafe.palletsprojects.com/en/stable/escaping/" />
    <link rel="icon" href="../_static/markupsafe-icon.svg"/>
    <link rel="index" title="Index" href="../genindex/" />
    <link rel="search" title="Search" href="../search/" />
    <link rel="next" title="HTML Representations" href="../html/" />
    <link rel="prev" title="MarkupSafe" href="../" /> 
  <script async type="text/javascript" src="/_/static/javascript/readthedocs-addons.js"></script><meta name="readthedocs-project-slug" content="markupsafe" /><meta name="readthedocs-version-slug" content="stable" /><meta name="readthedocs-resolver-filename" content="/escaping/" /><meta name="readthedocs-http-status" content="200" /></head><body>
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
          <a href="../html/" title="HTML Representations"
             accesskey="N">next</a> |</li>
        <li class="right" >
          <a href="../" title="MarkupSafe"
             accesskey="P">previous</a> |</li>
        <li class="nav-item nav-item-0"><a href="../">MarkupSafe Documentation (3.0.x)</a> &#187;</li>
        <li class="nav-item nav-item-this"><a href="">Working With Safe Text</a></li> 
      </ul>
    </div>  

    <div class="document">
      <div class="documentwrapper">
        <div class="bodywrapper">
          <div class="body" role="main">
            
  <section id="working-with-safe-text">
<span id="module-markupsafe"></span><h1>Working With Safe Text<a class="headerlink" href="#working-with-safe-text" title="Link to this heading">¶</a></h1>
<dl class="py function">
<dt class="sig sig-object py" id="markupsafe.escape">
<span class="sig-prename descclassname"><span class="pre">markupsafe.</span></span><span class="sig-name descname"><span class="pre">escape</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span></em>, <em class="sig-param"><span class="positional-only-separator o"><abbr title="Positional-only parameter separator (PEP 570)"><span class="pre">/</span></abbr></span></em><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.escape" title="Link to this definition">¶</a></dt>
<dd><p>Replace the characters <code class="docutils literal notranslate"><span class="pre">&amp;</span></code>, <code class="docutils literal notranslate"><span class="pre">&lt;</span></code>, <code class="docutils literal notranslate"><span class="pre">&gt;</span></code>, <code class="docutils literal notranslate"><span class="pre">'</span></code>, and <code class="docutils literal notranslate"><span class="pre">&quot;</span></code> in
the string with HTML-safe sequences. Use this if you need to display
text that might contain such characters in HTML.</p>
<p>If the object has an <code class="docutils literal notranslate"><span class="pre">__html__</span></code> method, it is called and the
return value is assumed to already be safe for HTML.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>s</strong> (<a class="reference external" href="https://docs.python.org/3/library/typing.html#typing.Any" title="(in Python v3.13)"><em>Any</em></a>) – An object to be converted to a string and escaped.</p>
</dd>
<dt class="field-even">Returns<span class="colon">:</span></dt>
<dd class="field-even"><p>A <a class="reference internal" href="#markupsafe.Markup" title="markupsafe.Markup"><code class="xref py py-class docutils literal notranslate"><span class="pre">Markup</span></code></a> string with the escaped text.</p>
</dd>
<dt class="field-odd">Return type<span class="colon">:</span></dt>
<dd class="field-odd"><p><a class="reference internal" href="#markupsafe.Markup" title="markupsafe.Markup"><em>Markup</em></a></p>
</dd>
</dl>
</dd></dl>

<dl class="py class">
<dt class="sig sig-object py" id="markupsafe.Markup">
<em class="property"><span class="k"><span class="pre">class</span></span><span class="w"> </span></em><span class="sig-prename descclassname"><span class="pre">markupsafe.</span></span><span class="sig-name descname"><span class="pre">Markup</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">object</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">''</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">encoding</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">None</span></span></em>, <em class="sig-param"><span class="n"><span class="pre">errors</span></span><span class="o"><span class="pre">=</span></span><span class="default_value"><span class="pre">'strict'</span></span></em><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.Markup" title="Link to this definition">¶</a></dt>
<dd><p>A string that is ready to be safely inserted into an HTML or XML
document, either because it was escaped or because it was marked
safe.</p>
<p>Passing an object to the constructor converts it to text and wraps
it to mark it safe without escaping. To escape the text, use the
<a class="reference internal" href="#markupsafe.escape" title="markupsafe.escape"><code class="xref py py-meth docutils literal notranslate"><span class="pre">escape()</span></code></a> class method instead.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="s2">&quot;Hello, &lt;em&gt;World&lt;/em&gt;!&quot;</span><span class="p">)</span>
<span class="go">Markup(&#39;Hello, &lt;em&gt;World&lt;/em&gt;!&#39;)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="mi">42</span><span class="p">)</span>
<span class="go">Markup(&#39;42&#39;)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="o">.</span><span class="n">escape</span><span class="p">(</span><span class="s2">&quot;Hello, &lt;em&gt;World&lt;/em&gt;!&quot;</span><span class="p">)</span>
<span class="go">Markup(&#39;Hello &amp;lt;em&amp;gt;World&amp;lt;/em&amp;gt;!&#39;)</span>
</pre></div>
</div>
<p>This implements the <code class="docutils literal notranslate"><span class="pre">__html__()</span></code> interface that some frameworks
use. Passing an object that implements <code class="docutils literal notranslate"><span class="pre">__html__()</span></code> will wrap the
output of that method, marking it safe.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="k">class</span><span class="w"> </span><span class="nc">Foo</span><span class="p">:</span>
<span class="gp">... </span>    <span class="k">def</span><span class="w"> </span><span class="nf">__html__</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
<span class="gp">... </span>        <span class="k">return</span> <span class="s1">&#39;&lt;a href=&quot;/foo&quot;&gt;foo&lt;/a&gt;&#39;</span>
<span class="gp">...</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="n">Foo</span><span class="p">())</span>
<span class="go">Markup(&#39;&lt;a href=&quot;/foo&quot;&gt;foo&lt;/a&gt;&#39;)</span>
</pre></div>
</div>
<p>This is a subclass of <a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><code class="xref py py-class docutils literal notranslate"><span class="pre">str</span></code></a>. It has the same methods, but
escapes their arguments and returns a <code class="docutils literal notranslate"><span class="pre">Markup</span></code> instance.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="s2">&quot;&lt;em&gt;</span><span class="si">%s</span><span class="s2">&lt;/em&gt;&quot;</span><span class="p">)</span> <span class="o">%</span> <span class="p">(</span><span class="s2">&quot;foo &amp; bar&quot;</span><span class="p">,)</span>
<span class="go">Markup(&#39;&lt;em&gt;foo &amp;amp; bar&lt;/em&gt;&#39;)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="s2">&quot;&lt;em&gt;Hello&lt;/em&gt; &quot;</span><span class="p">)</span> <span class="o">+</span> <span class="s2">&quot;&lt;foo&gt;&quot;</span>
<span class="go">Markup(&#39;&lt;em&gt;Hello&lt;/em&gt; &amp;lt;foo&amp;gt;&#39;)</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><ul class="simple">
<li><p><strong>object</strong> (<em>t.Any</em>)</p></li>
<li><p><strong>encoding</strong> (<a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><em>str</em></a><em> | </em><em>None</em>)</p></li>
<li><p><strong>errors</strong> (<a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)"><em>str</em></a>)</p></li>
</ul>
</dd>
<dt class="field-even">Return type<span class="colon">:</span></dt>
<dd class="field-even"><p>te.Self</p>
</dd>
</dl>
<dl class="py method">
<dt class="sig sig-object py" id="markupsafe.Markup.unescape">
<span class="sig-name descname"><span class="pre">unescape</span></span><span class="sig-paren">(</span><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.Markup.unescape" title="Link to this definition">¶</a></dt>
<dd><p>Convert escaped markup back into a text string. This replaces
HTML entities with the characters they represent.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="s2">&quot;Main &amp;raquo; &lt;em&gt;About&lt;/em&gt;&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">unescape</span><span class="p">()</span>
<span class="go">&#39;Main » &lt;em&gt;About&lt;/em&gt;&#39;</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Return type<span class="colon">:</span></dt>
<dd class="field-odd"><p><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)">str</a></p>
</dd>
</dl>
</dd></dl>

<dl class="py method">
<dt class="sig sig-object py" id="markupsafe.Markup.striptags">
<span class="sig-name descname"><span class="pre">striptags</span></span><span class="sig-paren">(</span><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.Markup.striptags" title="Link to this definition">¶</a></dt>
<dd><p><a class="reference internal" href="#markupsafe.Markup.unescape" title="markupsafe.Markup.unescape"><code class="xref py py-meth docutils literal notranslate"><span class="pre">unescape()</span></code></a> the markup, remove tags, and normalize
whitespace to single spaces.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="n">Markup</span><span class="p">(</span><span class="s2">&quot;Main &amp;raquo;        &lt;em&gt;About&lt;/em&gt;&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">striptags</span><span class="p">()</span>
<span class="go">&#39;Main » About&#39;</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Return type<span class="colon">:</span></dt>
<dd class="field-odd"><p><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)">str</a></p>
</dd>
</dl>
</dd></dl>

<dl class="py method">
<dt class="sig sig-object py" id="markupsafe.Markup.escape">
<em class="property"><span class="k"><span class="pre">classmethod</span></span><span class="w"> </span></em><span class="sig-name descname"><span class="pre">escape</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span></em>, <em class="sig-param"><span class="positional-only-separator o"><abbr title="Positional-only parameter separator (PEP 570)"><span class="pre">/</span></abbr></span></em><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.Markup.escape" title="Link to this definition">¶</a></dt>
<dd><p>Escape a string. Calls <a class="reference internal" href="#markupsafe.escape" title="markupsafe.escape"><code class="xref py py-func docutils literal notranslate"><span class="pre">escape()</span></code></a> and ensures that for
subclasses the correct type is returned.</p>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>s</strong> (<em>t.Any</em>)</p>
</dd>
<dt class="field-even">Return type<span class="colon">:</span></dt>
<dd class="field-even"><p>te.Self</p>
</dd>
</dl>
</dd></dl>

</dd></dl>

<section id="optional-values">
<h2>Optional Values<a class="headerlink" href="#optional-values" title="Link to this heading">¶</a></h2>
<dl class="py function">
<dt class="sig sig-object py" id="markupsafe.escape_silent">
<span class="sig-prename descclassname"><span class="pre">markupsafe.</span></span><span class="sig-name descname"><span class="pre">escape_silent</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span></em>, <em class="sig-param"><span class="positional-only-separator o"><abbr title="Positional-only parameter separator (PEP 570)"><span class="pre">/</span></abbr></span></em><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.escape_silent" title="Link to this definition">¶</a></dt>
<dd><p>Like <a class="reference internal" href="#markupsafe.escape" title="markupsafe.escape"><code class="xref py py-func docutils literal notranslate"><span class="pre">escape()</span></code></a> but treats <code class="docutils literal notranslate"><span class="pre">None</span></code> as the empty string.
Useful with optional values, as otherwise you get the string
<code class="docutils literal notranslate"><span class="pre">'None'</span></code> when the value is <code class="docutils literal notranslate"><span class="pre">None</span></code>.</p>
<div class="doctest highlight-default notranslate"><div class="highlight"><pre><span></span><span class="gp">&gt;&gt;&gt; </span><span class="n">escape</span><span class="p">(</span><span class="kc">None</span><span class="p">)</span>
<span class="go">Markup(&#39;None&#39;)</span>
<span class="gp">&gt;&gt;&gt; </span><span class="n">escape_silent</span><span class="p">(</span><span class="kc">None</span><span class="p">)</span>
<span class="go">Markup(&#39;&#39;)</span>
</pre></div>
</div>
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>s</strong> (<a class="reference external" href="https://docs.python.org/3/library/typing.html#typing.Any" title="(in Python v3.13)"><em>Any</em></a><em> | </em><em>None</em>)</p>
</dd>
<dt class="field-even">Return type<span class="colon">:</span></dt>
<dd class="field-even"><p><a class="reference internal" href="#markupsafe.Markup" title="markupsafe.Markup"><em>Markup</em></a></p>
</dd>
</dl>
</dd></dl>

</section>
<section id="convert-an-object-to-a-string">
<h2>Convert an Object to a String<a class="headerlink" href="#convert-an-object-to-a-string" title="Link to this heading">¶</a></h2>
<dl class="py function">
<dt class="sig sig-object py" id="markupsafe.soft_str">
<span class="sig-prename descclassname"><span class="pre">markupsafe.</span></span><span class="sig-name descname"><span class="pre">soft_str</span></span><span class="sig-paren">(</span><em class="sig-param"><span class="n"><span class="pre">s</span></span></em>, <em class="sig-param"><span class="positional-only-separator o"><abbr title="Positional-only parameter separator (PEP 570)"><span class="pre">/</span></abbr></span></em><span class="sig-paren">)</span><a class="headerlink" href="#markupsafe.soft_str" title="Link to this definition">¶</a></dt>
<dd><p>Convert an object to a string if it isn’t already. This preserves
a <a class="reference internal" href="#markupsafe.Markup" title="markupsafe.Markup"><code class="xref py py-class docutils literal notranslate"><span class="pre">Markup</span></code></a> string rather than converting it back to a basic
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
<dl class="field-list simple">
<dt class="field-odd">Parameters<span class="colon">:</span></dt>
<dd class="field-odd"><p><strong>s</strong> (<a class="reference external" href="https://docs.python.org/3/library/typing.html#typing.Any" title="(in Python v3.13)"><em>Any</em></a>)</p>
</dd>
<dt class="field-even">Return type<span class="colon">:</span></dt>
<dd class="field-even"><p><a class="reference external" href="https://docs.python.org/3/library/stdtypes.html#str" title="(in Python v3.13)">str</a></p>
</dd>
</dl>
</dd></dl>

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
              <img class="logo" src="../_static/markupsafe-logo.svg" alt="Logo of MarkupSafe"/>
            </a></p>
  

  <h3>Contents</h3>
  <ul>
<li><a class="reference internal" href="#">Working With Safe Text</a><ul>
<li><a class="reference internal" href="#markupsafe.escape"><code class="docutils literal notranslate"><span class="pre">escape()</span></code></a></li>
<li><a class="reference internal" href="#markupsafe.Markup"><code class="docutils literal notranslate"><span class="pre">Markup</span></code></a><ul>
<li><a class="reference internal" href="#markupsafe.Markup.unescape"><code class="docutils literal notranslate"><span class="pre">Markup.unescape()</span></code></a></li>
<li><a class="reference internal" href="#markupsafe.Markup.striptags"><code class="docutils literal notranslate"><span class="pre">Markup.striptags()</span></code></a></li>
<li><a class="reference internal" href="#markupsafe.Markup.escape"><code class="docutils literal notranslate"><span class="pre">Markup.escape()</span></code></a></li>
</ul>
</li>
<li><a class="reference internal" href="#optional-values">Optional Values</a><ul>
<li><a class="reference internal" href="#markupsafe.escape_silent"><code class="docutils literal notranslate"><span class="pre">escape_silent()</span></code></a></li>
</ul>
</li>
<li><a class="reference internal" href="#convert-an-object-to-a-string">Convert an Object to a String</a><ul>
<li><a class="reference internal" href="#markupsafe.soft_str"><code class="docutils literal notranslate"><span class="pre">soft_str()</span></code></a></li>
</ul>
</li>
</ul>
</li>
</ul>
<h3>Navigation</h3>
<ul>
  <li><a href="../">Overview</a>
    <ul>
          <li>Previous: <a href="../" title="previous chapter">MarkupSafe</a>
          <li>Next: <a href="../html/" title="next chapter">HTML Representations</a>
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
    &#169; Copyright 2010 Pallets.
      Created using <a href="https://www.sphinx-doc.org/">Sphinx</a> 8.2.3.
    </div>
  </body>
</html>