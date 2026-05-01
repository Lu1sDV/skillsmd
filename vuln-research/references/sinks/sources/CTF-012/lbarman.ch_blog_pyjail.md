<!DOCTYPE html>
<html>

<head>
   <meta charset="utf-8">
   <title>Escaping the PyJail</title>
   <link href="../../css/blog_base.css" rel="stylesheet" />
   <link href="style.css" rel="stylesheet" />
   <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.6.0/styles/default.min.css">
   <script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.6.0/highlight.min.js"></script>
   <script src="highlightjs-line-numbers.min.js"></script>
   <script src="//code.jquery.com/jquery-3.2.1.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4="
      crossorigin="anonymous"></script>
</head>

<body>
   <div id="corpus">
      <article class="markdown-body">
         <h1 id="aurora-in-tromso-a-neutral-and-precise-guide">
            <a name="user-content-aurora-in-tromso-a-neutral-and-precise-guide"
               href="#aurora-in-tromso-a-neutral-and-precise-guide" class="headeranchor-link" aria-hidden="true">
               <span class="headeranchor">
               </span>
            </a>
            Escaping the PyJail
         </h1>
         <p id="dateline">Date: 21/08/2016 - <a href="https://lbarman.ch/">go back home</a></p>

         <p>
            <b>Introduction.</b> This is a fun hacking challenge done at Santa's Hacking Challenge. You have access to a
            restricted, sandboxed Python shell (mimicking an online service), and you need to gain broader access to the
            system.
         </p>
         <p>The challenge is on <a href="root-me.org">root-me.org</a>. They're not too keen on folks spoiling the
            solution, so I'm not linking the exact challenge number here.</p>

         <div id="imgblock">
            <img src="prison.png" id="prison_png" />
            <div id="figref">Source : <a href="http://thehackernews.com/">thehackernews.com</a></div>
         </div>

         <p>
            <b>Scenario.</b> We connect through SSH to a server, and are welcomed by the following text :
         <pre><code class="python">Welcome to this python sandbox! All you need is in exit() function (arg -> find the flag)
>>> 
</code></pre>
         </p>
         <p>
            What happens if we simply quit the Python interpreter ?
         <pre><code class="python">>>> ^CTraceback (most recent call last):
  File "/challenge/file.py", line 49, in <module>
    data = raw_input('>>> ')
KeyboardInterrupt
Error in sys.excepthook:
Traceback (most recent call last):
  File "/usr/lib/Python2.7/dist-packages/apport_Python_hook.py", line 46, in apport_excepthook
    if exc_type in (KeyboardInterrupt, ):
NameError: global name 'KeyboardInterrupt' is not defined

Original exception was:
Traceback (most recent call last):
  File "/challenge/file.py", line 49, in <module>
    data = raw_input('>>> ')
KeyboardInterrupt
Connection closed.
</code></pre>
         Nothing useful here; quitting the interpreter also kills the SSH connection.
         </p>


         <h2 id="reflection">
            <a name="user-content-reflection" href="#reflection" class="headeranchor-link" aria-hidden="true">
               <span class="headeranchor">
               </span>
            </a>
            Intel gathering
         </h2>

         <p>
            Alright, let's explore the sandbox, and in particulare poke around the <i class="code_snippet">exit</i>
            function :
         <pre><code class="python">>>> exit
>>> exit()
TypeError : exit() takes exactly 1 argument (0 given)
>>> exit(1)
You cannot escape !
>>> exit("a")
Denied
</code></pre>
         </p>
         <p>So exit() takes one argument, which we need to find. We get a first non-standard error : the <i
               class="code_snippet">Denied</i> is obviously part of the sandboxing mechanism.</p>
         <p>
            Let's explore what the sandbox let us do :
         <pre><code class="python">>>> a=2
>>> a
>>> print a
2
>>> b="test"
Denied
>>> b='test'
Denied
>>> ""
Denied
>>> eval
Denied
>>> import ''
Denied
>>> import 
Denied
</code></pre>
         </p>
         <p>Our friend <i class="code_snippet">Denied</i> is all over the place. We can do variable assignments, but
            cannot create strings using <i class="code_snippet">"</i> or <i class="code_snippet">'</i>. Built-ins like
            <i class="code_snippet">import</i> also trigger the sandboxing mechanism.
         </p>
         <p>
         <pre><code class="python">>>> dir     
NameError : name 'dir' is not defined
</code></pre>
         </p>
         <p>That's interesting. Some commands are <i class="code_snippet">Denied</i>, while some are <i
               class="code_snippet">Not defined</i>. In Python, you can easily remove functions using the built-in
            function <i class="code_snippet">del</i>. This is probably a good way of creating a sandbox : simply
            destroy/remove the functions that should not be accessible. The obvious problem is that the sandboxing
            script itself might need those functions : doing <i class="code_snippet">del print()</i> will also prevent
            the sandboxing script from using <i class="code_snippet">print()</i>. One option could be to rename the
            functions needed by the script, but not accessible to the users :</p>
         <pre><code class="python">my_super_secret_print=print;     
del(print);
my_super_secret_print("my_message")</code></pre>
         </p>
         <p>But if this technique has been used, there's not much we can do. One other option would be to process the
            input from the user, and prevent him from calling these functions. That would go very well with our "Denied"
            messages ! Let's try it :</p>
         <pre><code class="python">>>> input
Denied
>>> ainputa
Denied
</code></pre>
         </p>
         <p>Indeed, there is a regex search on the input, and if is contains some keywords, we get <i
               class="code_snippet">Denied</i> instead of executing our code. Ok. What the script does is a bit clearer.
            Let's now be a bit more rigorous, and test <a
               href="https://docs.Python.org/2/library/functions.html#dir">every built-in function</a>; maybe the
            developer was careless ? Unfortunately, no function except <i class="code_snippet">print</i> is available.
            In addition, the following characters / strings are blocked : </p>
         <pre><code class="python">input
eval
_
__
"
'
</code></pre>
         </p>

         <h3 id="#error-math">
            <a name="user-content-error-math" href="#error-math" class="headeranchor-link" aria-hidden="true">
               <span class="headeranchor">
               </span>
            </a>
            Errors &amp; Maths
         </h3>

         <p>To better understand the script, I tried listing the possible error messages :
         <ul>
            <li><i class="code_snippet">NameError : name 'abc' is not defined</i> when typing <i
                  class="code_snippet">abc</i></li>
            <li><i class="code_snippet">Denied</i> when typing <i class="code_snippet">import</i></li>
            <li><i class="code_snippet">SyntaxError : unexpected character after line continuation character
                  (&lt;string&gt;, line 1)&lt;/string&gt;</i> when typing <i class="code_snippet">\\</i>
            <li><i class="code_snippet">TypeError : exit() takes exactly 1 argument (0 given)</i> when typing <i
                  class="code_snippet">exit()</i></li>
            <li><i class="code_snippet">SyntaxError : invalid syntax (&lt;string&gt;, line 1)&lt;/string&gt;</i> when
               typing <i class="code_snippet">-</i> : The input is eval'ed.</string>
            <li><i class="code_snippet">ZeroDivisionError : integer division or modulo by zero</i> when typing <i
                  class="code_snippet">10/0</i> : The input is eval'ed.</li>
         </ul>
         </p>



         <p>I realized that most math operations were allowed :
         <ul>
            <li><i class="code_snippet">print 0xa</i> gives <i class="code_snippet">10</i></li>
            <li><i class="code_snippet">print 10^2</i> gives <i class="code_snippet">8</i></li>
            <li><i class="code_snippet">print 10**100</i> outputs a <a
                  href="https://fr.wikipedia.org/wiki/Gogol_(nombre)">gogol</a>.
            <li><i class="code_snippet">print 10/0</i> and <i class="code_snippet">print 10 % 0</i> gives the <i
                  class="code_snippet">ZeroDivisionError</i> error.</li>
         </ul>
         </p>

         <p>Interestingly, the variable <i class="code_snippet">x</i> is set by default in the interpreter (while all
            others 1-char variables are <i class="code_snippet">Undefined</i>). More intriguing, it is set to the string
            <i class="code_snippet">OverFlowError</i>, as the following example demonstrates :
         <pre><code class="python">>>> print x
OverFlowError
>>> print x*2
OverFlowErrorOverFlowError
</code></pre>
         </p>

         <p>(In Python, the <i class="code_snippet">*</i> operators repeats the string). Hence, I tried playing around
            with the integer values fed to <i class="code_snippet">exit()</i>. Unfortunately, in Python, integers are
            like Java's BigInteger, and there's no problem defining <i class="code_snippet">y=10**100</i>.</p>


         <h2 id="reflection">
            <a name="user-content-reflection" href="#reflection" class="headeranchor-link" aria-hidden="true">
               <span class="headeranchor">
               </span>
            </a>
            Reflection
         </h2>

         <p>What should be clear at this point is that we do not have much. There's no evident hole in the system. At
            this point, my options were the following :
         <ol>
            <li>Brute-force the argument of <i class="code_snippet">exit()</i>. This might be acceptable if we are able
               to do a loop within the interpreter. </li>
            <li>Try to gain some extra information about the source/the code. While being a long shot, I really felt
               like I was missing information at that point.</li>
         </ol>
         </p>
         <p>Unfortunately, (1) turns out not to be doable. Python uses indentation for loops, and the current script
            processes input line-by-line. I tried using <i class="code_snippet">\n</i> and <i
               class="code_snippet">\t</i> characters to do a one-liner, without luck. Bruteforcing from my computer
            (through ssh) is of course out of the question. </p>
         <p>To do (2), I started looking into Python reflection. In particular, I found a thread on StackOverflow : <a
               href="http://stackoverflow.com/questions/427453/how-can-i-get-the-source-code-of-a-Python-function">How
               can I get the source code of a Python function?</a>. I dwelt into the topic, but unfortunately, the
            Python reflection is packed in modules (either <i class="code_snippet">inspect</i> or <i
               class="code_snippet">dis</i>). As mentioned, I'm not able to import new modules, and both weren't
            available. However, I got the inspiration from a <a href="http://stackoverflow.com/a/10196254">less-related
               answer</a> to the same question. In Python, functions are objects! It would be great to print the
            contents of our <i class="code_snippet">exit</i> function/object, maybe the flag is hidden there.</p>
         <p>In a normal Python interpreter, listing the contents of an object is super simple, and is done via <i
               class="code_snippet">dir()</i>. But remember how it is blocked by the regex ? So, I can probably access
            <i class="code_snippet">attributeX</i> of the object/function <i class="code_snippet">exit</i> by calling :
         <pre><code class="python">>>> exit.attributeX
</code></pre>
         but I won't be able to list them. I could blindly try attributes such as <i class="code_snippet">flag</i> or <i
            class="code_snippet">pass</i>, but what's there by default ?
         </p>
         <p>On my own machine, I created and executed the following Python script :
         <pre><code class="python">def test( flag_input ):
   if flag_input == 12345:
        print "Success!"
   else:
        print "Failure !"
   return 1

print dir(test)
</code></pre>
         </p>
         <p>
            and the result was :
         <pre><code class="python">['__call__', '__class__', '__closure__', '__code__', '__defaults__', '__delattr__',
'__dict__', '__doc__', '__format__', '__get__', '__getattribute__', '__globals__', '__hash__',
'__init__', '__module__', '__name__', '__new__', '__reduce__', '__reduce_ex__', '__repr__',
'__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'func_closure', 'func_code',
'func_defaults', 'func_dict', 'func_doc', 'func_globals', 'func_name']
</code></pre>
         </p>
         <p>Hold on. Did you see that ? <i class="code_snippet">func_code</i> ? this property is there by default in the
            object (assuming the same version of Python, of course). Can we call it in our sandbox ?
         <pre><code class="python">>>> print exit.func_code
&lt;code object exit at 0xb7b57a40, file "/challenge/file.py", line 27&gt;
</code></pre>
         </p>
         <p>That doesn't help yet. But a quick search brings us <a
               href="https://docs.Python.org/2/library/inspect.html">there</a>, where we learn that the return of <i
               class="code_snippet">func_code</i> is itself an object, with really interesting methods. Again, on my
            local machine :
         <pre><code class="python">def test( flag_input ):
   if flag_input == 12345:
        print "Success!"
   else:
        print "Failure !"
   return 1

print dir(test.func_code)
</code></pre>
         </p>
         <p>
            and the result was :
         <pre><code class="python">['__class__', '__cmp__', '__delattr__', '__doc__', '__eq__', '__format__', '__ge__',
'__getattribute__', '__gt__', '__hash__', '__init__', '__le__', '__lt__', '__ne__',
'__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__',
'__str__', '__subclasshook__', 'co_argcount', 'co_cellvars', 'co_code', 'co_consts',
'co_filename', 'co_firstlineno', 'co_flags', 'co_freevars', 'co_lnotab', 'co_name',
'co_names', 'co_nlocals', 'co_stacksize', 'co_varnames']
</code></pre>
         </p>
         <p>If the input is compared to something, it is probably a simple equality test with a constants. Let's try <i
               class="code_snippet">co_consts</i> on the sandbox :
         <pre><code class="python">>>> print exit.func_code.co_consts
(None, 'flag-THE_FLAG', -1, 'cat .passwd', 'You cannot escape !')
</code></pre>
         </p>
         <p>This looks like the solution ! ... but it's not. Remember the welcome message ?
         <pre><code class="python">Welcome to this python sandbox! All you need is in exit() function (arg -> find the flag)
>>> 
</code></pre>
         <p>So this constant is the one that allows you to get the flag; <i>not</i> the flag, even if it starts with <i
               class="code_snippet">flag_</i>. In this case, this is a hacking challenge, not a real-world scenario;
            trying the wrong flag has little consequence. In a real-world PyJail, testing the wrong flag might rise some
            alerts.</p>
         <p>The final challenge was be able to type that string. Remember that <i class="code_snippet">'</i> and <i
               class="code_snippet">"</i> are forbidden :
         <pre><code class="python">>>> exit("flag-THE_FLAG")
Denied
>>> exit('flag-THE_FLAG')
Denied
>>> a='flag-THE_FLAG'
Denied
</code></pre>
         </p>



         <h2 id="solution">
            <a name="user-content-solution" href="#solution" class="headeranchor-link" aria-hidden="true">
               <span class="headeranchor">
               </span>
            </a>
            Solution
         </h2>

         <p>I tried poking around <i class="code_snippet">join()</i>, <i class="code_snippet">chr</i>, different
            encoding function to convert an integer to a string, but without success. Silly me, the answer was much
            simpler :
         <pre><code class="python">>>> exit(exit.func_code.co_consts[1])
Well done flag : <strong>flag-THE_REAL_FLAG</strong>
Connection closed.
</code></pre>
         </p>


         <h3 id="solution">
            <a name="user-content-unsolved-mystery" href="#unsolved-mystery" class="headeranchor-link"
               aria-hidden="true">
               <span class="headeranchor">
               </span>
            </a>
            Unsolved mystery
         </h3>

         <p>I still wonder what's the use of the variable <i class="code_snippet">x</i> set to <i
               class="code_snippet">OverFlowError</i>. I'll update this section when I find out !</p>

      </article>
   </div>
   <script>
      hljs.initHighlightingOnLoad();
      hljs.initLineNumbersOnLoad();
   </script>
</body>

</html>