
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>
Issue 43604: Fix tempfile.mktemp() - Python tracker

</title>
<link rel="shortcut icon" href="@@file/favicon.ico" />
<link rel="stylesheet" type="text/css" href="@@file/main.css" />
<link rel="stylesheet" type="text/css" href="@@file/style.css" />
<link rel="search" type="application/opensearchdescription+xml" href="@@file/osd.xml" title="Python bug tracker search" />
<meta http-equiv="Content-Type"
      content="text/html; charset=utf-8" />

<script nonce="a7f43e6d366a888ee6f4ea22c9ec356c83644508f4bac2be917674b412fcdcf5" type="text/javascript">
submitted = false;
function submit_once() {
    if (submitted) {
        alert("Your request is being processed.\nPlease be patient.");
        return false;
    }
    submitted = true;
    return true;
}

function help_window(helpurl, width, height) {
    HelpWin = window.open('https://bugs.python.org/' + helpurl, 'RoundupHelpWindow', 'scrollbars=yes,resizable=yes,toolbar=no,height='+height+',width='+width);
    HelpWin.focus ()
}
</script>


<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.15/jquery-ui.js"></script>
<script type="text/javascript" src="@@file/issue.item.js"></script>
<link rel="stylesheet" type="text/css" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/smoothness/jquery-ui.css" />


</head>
<body>
  <!--  Logo  -->
  <h1 id="logoheader">
    <a accesskey="1" href="." id="logolink">
       <img src="@@file/python-logo.gif" alt="homepage" border="0" id="logo" /></a>
  </h1>

<div id="utility-menu">
<!-- Search Box -->
<div id="searchbox">
    <form name="searchform" method="get" action="issue" id="searchform">
      <div id="search">
       <input type="hidden" name="@columns"
              value="id,github,activity,title,creator,assignee,status,type" />
       <input type="hidden" name="@sort" value="-activity" />
       <input type="hidden" name="@filter" value="status" />
       <input type="hidden" name="@action" value="searchid" />
       <input type="hidden" name="ignore" value="file:content" />
       <input class="input-text" id="search-text"
              name="@search_text" size="10" />
       <input type="submit" id="submit" value="search" name="submit" class="input-button" />
       <input type="radio" name="status"
              id="status_notresolved" value="-1,1,3" />
       <label for="status_notresolved">open</label>
       <input type="radio" name="status" checked="checked"
              id="status_all" value="-1,1,2,3" />
       <label for="status_all">all</label>
      </div>
     </form>
</div>
</div>


<div id="left-hand-navigation">
<!--  Main Menu NEED LEVEL TWO HEADER AND FOOTER -->
<div id="menu">
  <ul class="level-one">
    <li><a href="https://www.python.org/" title="Go to the Python homepage">Python Home</a></li>
    <li><a href="https://www.python.org/about/" title="About The Python Language">About</a></li>
    <li><a href="https://www.python.org/blogs/" title="">News</a></li>
    <li><a href="https://www.python.org/doc/" title="">Documentation</a></li>
    <li><a href="https://www.python.org/downloads/" title="">Downloads</a></li>
    <li><a href="https://www.python.org/community/" title="">Community</a></li>
    <li><a href="https://www.python.org/psf/" title="Python Software Foundation">Foundation</a></li>
    <li><a href="https://devguide.python.org/" title="Python Developer's Guide">Developer's Guide</a></li>
    <li class="selected"><a href="." class="selected" title="Python Issue Tracker">Issue Tracker</a>
      <ul class="level-two">
        <li>
          <strong>Issues</strong>
          <ul class="level-three">
            
            <li><a href="issue?@template=search&amp;status=1">Search</a></li>
            <li><a href="issue?@action=random">Random Issue</a></li>
            <li>
              <form method="post" action="issue43604">
                <input type="submit" class="form-small"
                       value="Show issue:" />
                <input class="form-small" size="4" type="text" name="@number" />
                <input type="hidden" name="@type" value="issue" />
                <input type="hidden" name="@action" value="show" />
              </form>
            </li>
          </ul>
        </li>


        <li>
          <strong>Summaries</strong>
          <ul class="level-three">
            

            

            

            <li>
              <a href="issue?status=1&amp;@sort=-activity&amp;@columns=id%2Cgithub%2Cactivity%2Ctitle%2Ccreator%2Cstatus&amp;@dispname=Issues%20with%20patch&amp;@startwith=0&amp;@group=priority&amp;keywords=2&amp;@action=search&amp;@filter=&amp;@pagesize=50">Issues with patch</a>
            </li>

            <li>
              <a href="issue?status=1&amp;@sort=-activity&amp;@columns=id%2Cgithub%2Cactivity%2Ctitle%2Ccreator%2Cstatus&amp;@dispname=Easy%20issues&amp;@startwith=0&amp;@group=priority&amp;keywords=6&amp;@action=search&amp;@filter=&amp;@pagesize=50">Easy issues</a>
            </li>

            <li>
              <a href="issue?@template=stats">Stats</a>
            </li>

          </ul>
        </li>


        <li>
          <strong>User</strong>
          <form method="post" action="issue43604">
          <ul class="level-three">
            <li>
                Login<br />
                <input size="10" name="openid_identifier" style="" /><br />
                <input size="10" type="password" name="__login_password" /><br />
                <input type="hidden" name="@action" value="Login" />
                <input type="checkbox" name="remember" id="remember" />
                <label for="remember">Remember me?</label><br />
                <input class="form-small" type="submit"
                       value="Login" /><br />
                <input type="hidden" name="__came_from"
                       value="https://bugs.python.org/issue43604?">
                
                <input type="hidden" name="@sort" value=""/>
<input type="hidden" name="@group" value=""/>
<input type="hidden" name="@pagesize" value="50"/>
<input type="hidden" name="@startwith" value="0"/>
            </li>
            <li>
                
            </li>
            <li><a href="user?@template=forgotten">Lost&nbsp;your&nbsp;login?</a></li>
          </ul>
          </form>
        </li>

        

        

        <li>
          <strong>Administration</strong>
          <ul class="level-three">
            
            <li>
                <a href="user?@sort=username">User List</a></li>
            <li>
                <a href="user?iscommitter=1&amp;@action=search&amp;@sort=username&amp;@pagesize=300">Committer List</a></li>
            
            
            
          </ul>
        </li>

        <li>
          <strong>Help</strong>
          <ul class="level-three">
            <li><a href="http://docs.python.org/devguide/triaging.html">
                Tracker Documentation</a></li>
            <li><a href="http://wiki.python.org/moin/TrackerDevelopment">
                Tracker Development</a></li>
            <li><a href="https://github.com/python/psf-infra-meta/issues">
                Report Tracker Problem</a></li>
          </ul>
        </li>

      </ul>
    </li>
  </ul>
</div> <!-- menu -->
</div> <!-- left-hand-navigation -->

<div id="content-body">
<div id="body-main">
<div id="content">
<div id="breadcrumb">
 
 
 Issue43604
 
</div>
<div id="migration-notice">
    <div id="migration-images">
        <img width="32" src="@@file/python-logo-small.png" />
        ➜
        <a href="https://github.com/python/cpython/issues"><img width="32" src="@@file/gh-icon.png" /></a>
    </div>
    <p>This issue tracker <b>has been migrated to <a href="https://github.com/python/cpython/issues">GitHub</a></b>,
    and is currently <b>read-only</b>.<br />
    For more information, <a title="GitHub FAQs" href="https://devguide.python.org/gh-faq/">
    see the GitHub FAQs in the Python's Developer Guide.</a></p>
</div>
 
 





<div>

<form method="post" name="itemSynopsis"
      onsubmit="return submit_once()"
      enctype="multipart/form-data" action="issue43604">

<div id="gh-issue-link">
    <a href="https://github.com/python/cpython/issues/87770">
        <img width="32" src="@@file/gh-icon.png" />
        <p>
            <span>This issue has been migrated to GitHub:</span>
            https://github.com/python/cpython/issues/87770
        </p>
    </a>
</div>

<fieldset><legend>classification</legend>
<table class="form">
<tr>
 <th class="required"><a href="http://docs.python.org/devguide/triaging.html#title" target="_blank">Title</a>:</th>
 
 <td colspan="3">
  <span>Fix tempfile.mktemp()</span>
  <input type="hidden" name="title"
         value="Fix tempfile.mktemp()">
 </td>
</tr>

<tr>
 <th class="required"><a href="http://docs.python.org/devguide/triaging.html#type" target="_blank">Type</a>:</th>
 <td>security</td>
 <th><a href="http://docs.python.org/devguide/triaging.html#stage" target="_blank">Stage</a>:</th>
 <td></td>
</tr>

<tr>
 <th><a href="http://docs.python.org/devguide/triaging.html#components" target="_blank">Components</a>:</th>
 <td>Library (Lib)</td>
 <th><a href="http://docs.python.org/devguide/triaging.html#versions" target="_blank">Versions</a>:</th>
 <td>Python 3.10</td>
</tr>
</table>
</fieldset>

<fieldset><legend>process</legend>
<table class="form">
<tr>
  <th><a href="http://docs.python.org/devguide/triaging.html#status" target="_blank">Status</a>:</th>
  <td>open</td>
  <th><a href="http://docs.python.org/devguide/triaging.html#resolution" target="_blank">Resolution</a>:</th>
  <td></td>
</tr>

<tr>
 <th>
    <a href="http://docs.python.org/devguide/triaging.html#dependencies"
       target="_blank">Dependencies</a>:
 </th>
 <td>
  
  
 </td>
 <th><a href="http://docs.python.org/devguide/triaging.html#superseder" target="_blank">Superseder</a>:</th>
 <td>
  
 
 </td>
 </tr>
 <tr>
 <th>
   <a href="http://docs.python.org/devguide/triaging.html#assigned-to"
      target="_blank">Assigned To</a>:
 </th>
 
 <td>
  
 </td>
 <th>
   <a href="http://docs.python.org/devguide/triaging.html#nosy-list"
      target="_blank">Nosy List</a><!--
        <span tal:condition="context/nosy_count" tal:replace="python: ' (%d)' % context.nosy_count" /> -->:
 </th>
 <td>
     dlukes, serhiy.storchaka
     
 </td>
</tr>
<tr>
 <th>
   <a href="http://docs.python.org/devguide/triaging.html#priority"
      target="_blank">Priority</a>:
 </th>
 <td>normal</td>
 <th>
    <a href="http://docs.python.org/devguide/triaging.html#keywords"
       target="_blank">Keywords</a>:
 </th>
 <td></td>


</tr>









</table>
</fieldset>

</form>

<p>Created on <strong>2021-03-23 15:26</strong> by <strong>dlukes</strong>, last changed <strong>2022-04-11 14:59</strong> by <strong>admin</strong>.</p>









<table class="messages">
 <tr><th colspan="4" class="header">Messages (4)</th></tr>
 
  <tr>
    <th>
     <a href="#msg389393" id="msg389393">msg389393</a> - <a
    href="msg389393">(view)</a></th>
   <th>Author: David Lukeš (dlukes) <span title="Contributor form received">*</span></th>
   <th>Date: 2021-03-23 15:26</th>
  </tr>
  <tr>
   <td colspan="4" class="content">
    
    <pre>I recently came across a non-testing use case for `tempfile.mktemp()` where I struggle to find a viable alternative -- temporary named pipes (FIFOs):

```
import os
import tempfile
import subprocess as sp

fifo_path = tempfile.mktemp()
os.mkfifo(fifo_path, 0o600)
try:
    proc = sp.Popen(["cat", fifo_path], stdout=sp.PIPE, text=True)
    with open(fifo_path, "w") as fifo:
        for c in "Kočka leze dírou, pes oknem.":
            print(c, file=fifo)
    proc.wait()
finally:
    os.unlink(fifo_path)

for l in proc.stdout:
    print(l.strip())
```

(`cat` is obviously just a stand-in for some useful program which needs to read from a file, but you want to send it input from Python.)

`os.mkfifo()` needs a path which doesn't point to an existing file, so it's not possible to use a `tempfile.NamedTemporaryFile(delete=False)`, close it, and pass its `.name` attribute to `mkfifo()`.

I know there has been some discussion regarding `mktemp()` in the relatively recent past (see the Python-Dev thread starting with &lt;<a href="https://mail.python.org/pipermail/python-dev/2019-March/156721.html">https://mail.python.org/pipermail/python-dev/2019-March/156721.html</a>&gt;). There has also been some confusion as to what actually makes it unsafe (see &lt;<a href="https://mail.python.org/pipermail/python-dev/2019-March/156778.html">https://mail.python.org/pipermail/python-dev/2019-March/156778.html</a>&gt;). Before the discussion petered out, it looked like people were reaching a consensus "that mktemp() could be made secure by using a longer name generated by a secure random generator" (quoting from the previous link).

A secure `mktemp` could be as simple as (see &lt;<a href="https://mail.python.org/pipermail/python-dev/2019-March/156765.html">https://mail.python.org/pipermail/python-dev/2019-March/156765.html</a>&gt;):

```
def mktemp(suffix='', prefix='tmp', dir=None):
    if dir is None:
        dir = gettempdir()
    return _os.path.join(dir, prefix + secrets.token_urlsafe(ENTROPY_BYTES) + suffix)
```

There's been some discussion as to what `ENTROPY_BYTES` should be. I like Steven D'Aprano's suggestion (see &lt;<a href="https://mail.python.org/pipermail/python-dev/2019-March/156777.html">https://mail.python.org/pipermail/python-dev/2019-March/156777.html</a>&gt;) of having an overkill default just to be on the safe side, which can be overridden if needed. Of course, the security implications of lowering it should be clearly documented.

Fixing `mktemp` would make it possible to get rid of its hybrid deprecated (in the docs) / not depracated (in code) status, which is somewhat confusing for users. Speaking from experience -- when I realized I needed it, the deprecation notice led me down this rabbit hole of reading mailing list threads and submitting issues :) People could stop losing time worrying about `mktemp` and trying to weed it out whenever they come across it (see e.g. <a href="https://bugs.python.org/issue42278">https://bugs.python.org/issue42278</a>).

So I'm wondering whether there would be interest in:

1. A PR which would modify `mktemp` along the lines sketched above, to make it safe in practice. Along with that, it would probably make sense to undeprecate it in the docs, or at least indicate that while users should prefer `mkstemp` when they're fine with the file being created for them, `mktemp` is alright in cases where this is not acceptable.
2. Following that, possibly a PR which would encapsulate the new `mktemp` + `mkfifo` into a `TemporaryNamedPipe` or `TemporaryFifo`:

```
import os
import tempfile
import subprocess as sp

with tempfile.TemporaryNamedPipe() as fifo:
    proc = sp.Popen(["cat", fifo.name], stdout=sp.PIPE, text=True)
    for c in "Kočka leze dírou, pes oknem.":
        print(c, file=fifo)
    proc.wait()

for l in proc.stdout:
    print(l.strip())
```

(Caveat: opening the FIFO for writing cannot happen in `__enter__`, it would have to be delayed until the first call to `fifo.write()` because it hangs if no one is reading from it.)</pre>
   </td>
  </tr>
 
 
  <tr>
    <th>
     <a href="#msg389394" id="msg389394">msg389394</a> - <a
    href="msg389394">(view)</a></th>
   <th>Author: David Lukeš (dlukes) <span title="Contributor form received">*</span></th>
   <th>Date: 2021-03-23 15:41</th>
  </tr>
  <tr>
   <td colspan="4" class="content">
    
    <pre>&gt; A secure `mktemp` could be as simple as ...

Though in practice, I'd rather be inclined to make the change in `tempfile._RandomNameSequence`, so as to get the same behavior across the entire module, instead of special-casing `mktemp`. As Guido van Rossum points out (see &lt;<a href="https://mail.python.org/pipermail/python-dev/2019-March/156746.html">https://mail.python.org/pipermail/python-dev/2019-March/156746.html</a>&gt;), that would improve the security of all the names generated by the `tempfile` module, not just `mktemp`:

&gt; Hm, the random sequence (implemented in tempfile._RandomNameSequence) is
&gt; currently derived from the random module, which is not cryptographically
&gt; secure. Maybe all we need to do is replace its source of randomness with
&gt; one derived from the secrets module. That seems a one-line change.</pre>
   </td>
  </tr>
 
 
  <tr>
    <th>
     <a href="#msg389402" id="msg389402">msg389402</a> - <a
    href="msg389402">(view)</a></th>
   <th>Author: Serhiy Storchaka (serhiy.storchaka) <span title="Contributor form received">*</span> <img src="@@file/committer.png" title="Python committer" alt="(Python committer)" /></th>
   <th>Date: 2021-03-23 18:50</th>
  </tr>
  <tr>
   <td colspan="4" class="content">
    
    <pre>You can use TemporaryDirectory.

with tempfile.TemporaryDirectory() as dir:
    fifo_path = os.path.join(dir, "fifo")
    os.mkfifo(fifo_path, 0o600)
    ...</pre>
   </td>
  </tr>
 
 
  <tr>
    <th>
     <a href="#msg389407" id="msg389407">msg389407</a> - <a
    href="msg389407">(view)</a></th>
   <th>Author: David Lukeš (dlukes) <span title="Contributor form received">*</span></th>
   <th>Date: 2021-03-23 19:35</th>
  </tr>
  <tr>
   <td colspan="4" class="content">
    
    <pre>&gt; You can use TemporaryDirectory.

That was actually the first approach I tried :) I even thought this could be used to make `mktemp` safe -- just create the name in a `TemporaryDirectory`.

However, after reading through the mailing list thread, I realized this just restricts the potential collision/hijacking to misbehaving/malicious processes running under the same user or under the super user. But the core problem with too easily guessable filenames (= not random enough, or not at all, as in your example) remains. Correct me if I'm wrong though.

Sorry, I should probably have mentioned this in OP. I thought about doing so, but then it turned out very long even without it, so I decided it would be better to discuss it only if someone else mentions it.</pre>
   </td>
  </tr>
 
</table>

<table class="history table table-condensed table-striped"><tr><th colspan="4" class="header">
History
</th></tr><tr>
<th>Date</th>
<th>User</th>
<th>Action</th>
<th>Args</th>
</tr>
<tr><td>2022-04-11&nbsp;14:59:43</td><td>admin</td><td>set</td><td>github: 87770</td></tr>
<tr><td>2021-03-23&nbsp;19:35:24</td><td>dlukes</td><td>set</td><td>messages:
  + <a rel="nofollow" href="msg389407">msg389407</a></td></tr>
<tr><td>2021-03-23&nbsp;18:50:58</td><td>serhiy.storchaka</td><td>set</td><td>nosy:
  + <a rel="nofollow" href="user15623">serhiy.storchaka</a><br />messages:
  + <a rel="nofollow" href="msg389402">msg389402</a><br /></td></tr>
<tr><td>2021-03-23&nbsp;15:41:03</td><td>dlukes</td><td>set</td><td>messages:
  + <a rel="nofollow" href="msg389394">msg389394</a></td></tr>
<tr><td>2021-03-23&nbsp;15:26:30</td><td>dlukes</td><td>create</td><td></td></tr>
</table>

</div>


</div> <!-- content-body -->
<div id="footer">
<div id="credits">
  Supported by <a href="https://python.org/psf-landing/" title="The Python Software Foundation">The Python Software Foundation</a>,
  <br>
  Powered by <a href="http://roundup.sourceforge.net" title="Powered by the Roundup Issue Tracker">Roundup</a>
</div> <!-- credits -->
Copyright &copy; 1990-2022, <a href="http://python.org/psf">Python Software Foundation</a><br />
<a href="http://python.org/about/legal">Legal Statements</a>
</div> <!-- footer -->
</div> <!-- body-main -->
</div> <!-- content -->



</body>
</html>

