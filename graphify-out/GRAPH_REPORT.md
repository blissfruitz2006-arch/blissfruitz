# Graph Report - .  (2026-04-18)

## Corpus Check
- Large corpus: 285 files · ~264,718 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 2562 nodes · 4584 edges · 59 communities detected
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 1131 edges (avg confidence: 0.73)
- Token cost: 5,000 input · 2,000 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Admin UI & Theming|Admin UI & Theming]]
- [[_COMMUNITY_Graphify Analytics Core|Graphify Analytics Core]]
- [[_COMMUNITY_Authentication Framework|Authentication Framework]]
- [[_COMMUNITY_Multi-language AST Extraction|Multi-language AST Extraction]]
- [[_COMMUNITY_Tooling & Installer|Tooling & Installer]]
- [[_COMMUNITY_Core State Management|Core State Management]]
- [[_COMMUNITY_Content Views (Blog & Shared)|Content Views (Blog & Shared)]]
- [[_COMMUNITY_App Entry & Routing|App Entry & Routing]]
- [[_COMMUNITY_Media & Ingestion Utilities|Media & Ingestion Utilities]]
- [[_COMMUNITY_CustomerAdmin Services|Customer/Admin Services]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 63 edges
2. `package:flutter_riverpod/flutter_riverpod.dart` - 56 edges
3. `package:google_fonts/google_fonts.dart` - 51 edges
4. `../../config/theme.dart` - 48 edges
5. `Response` - 47 edges
6. `Request` - 43 edges
7. `build_from_json()` - 42 edges
8. `cluster()` - 37 edges
9. `main()` - 35 edges
10. `_labels()` - 34 edges

## Surprising Connections (you probably didn't know these)
- `test_count_words_sample_md()` --calls--> `count_words()`  [INFERRED]
  graphify\tests\test_detect.py → graphify\graphify\detect.py
- `test_make_id_strips_dots_and_underscores()` --calls--> `_make_id()`  [INFERRED]
  graphify\tests\test_extract.py → graphify\graphify\extract.py
- `test_make_id_no_leading_trailing_underscores()` --calls--> `_make_id()`  [INFERRED]
  graphify\tests\test_extract.py → graphify\graphify\extract.py
- `main()` --calls--> `god_nodes()`  [INFERRED]
  graphify\graphify\__main__.py → graphify\worked\mixed-corpus\raw\analyze.py
- `main()` --calls--> `surprising_connections()`  [INFERRED]
  graphify\graphify\__main__.py → graphify\worked\mixed-corpus\raw\analyze.py

## Communities

### Community 0 - "Admin UI & Theming"
Cohesion: 0.01
Nodes (424): admin_image_picker.dart, ../app_image.dart, ../components/admin_common_widgets.dart, ../config/supabase_config.dart, ../../config/theme.dart, dart:ui, ../glass_card.dart, AppTheme (+416 more)

### Community 1 - "Graphify Analytics Core"
Cohesion: 0.02
Nodes (233): _cross_community_surprises(), _cross_file_surprises(), _file_category(), god_nodes(), graph_diff(), _is_concept_node(), _is_file_node(), _node_community_map() (+225 more)

### Community 2 - "Authentication Framework"
Cohesion: 0.03
Nodes (101): Auth, BasicAuth, BearerAuth, DigestAuth, NetRCAuth, Authentication handlers. Auth objects are callables that modify a request befor, Load credentials from ~/.netrc based on the request host., Base class for all authentication handlers. (+93 more)

### Community 3 - "Multi-language AST Extraction"
Cohesion: 0.02
Nodes (169): _csharp_extra_walk(), extract_blade(), extract_c(), extract_cpp(), extract_csharp(), extract_dart(), extract_elixir(), _extract_generic() (+161 more)

### Community 4 - "Tooling & Installer"
Cohesion: 0.02
Nodes (129): _agents_install(), _agents_uninstall(), _antigravity_install(), _antigravity_uninstall(), _check_skill_version(), claude_install(), claude_uninstall(), _cursor_install() (+121 more)

### Community 5 - "Core State Management"
Cohesion: 0.02
Nodes (105): auth_provider.dart, dart:convert, email_service.dart, addItem, addToCart, applyCoupon, CartNotifier, clearCart (+97 more)

### Community 6 - "Content Views (Blog & Shared)"
Cohesion: 0.02
Nodes (104): AppFooter, BlogDetailScreen, build, Center, Divider, _formatDate, SingleChildScrollView, SizedBox (+96 more)

### Community 7 - "App Entry & Routing"
Cohesion: 0.02
Nodes (104): app.dart, config/routes.dart, dart:async, BlissFruitzApp, _BlissFruitzAppState, build, dispose, initState (+96 more)

### Community 8 - "Media & Ingestion Utilities"
Cohesion: 0.03
Nodes (100): _detect_url_type(), _download_binary(), _fetch_arxiv(), _fetch_html(), _fetch_tweet(), _fetch_webpage(), _html_to_markdown(), ingest() (+92 more)

### Community 9 - "Customer/Admin Services"
Cohesion: 0.02
Nodes (88): auth_service.dart, customer_detail_screen.dart, dart:io, dart:js_interop, dart:js_interop_unsafe, _ActionButton, AdminGlassCard, build (+80 more)

### Community 10 - "Community 10"
Cohesion: 0.03
Nodes (89): _body_content(), cache_dir(), cached_files(), check_semantic_cache(), clear_cache(), file_hash(), load_cached(), Delete all graphify-out/cache/*.json files. (+81 more)

### Community 11 - "Community 11"
Cohesion: 0.04
Nodes (67): Base, Server, LinearAlgebra, package:blissfruitz/app.dart, package:flutter_test/flutter_test.dart, area(), Analyzer, compute_score() (+59 more)

### Community 12 - "Community 12"
Cohesion: 0.03
Nodes (71): _AddressCard, AddressScreen, _AddressScreenState, build, Center, Container, Icon, initState (+63 more)

### Community 13 - "Community 13"
Cohesion: 0.05
Nodes (67): Export graph as an Obsidian Canvas file - communities as groups, nodes as cards., to_canvas(), collect_files(), extract_python(), Extract classes, functions, and imports from a .py file via tree-sitter AST., Call-graph pass must produce INFERRED calls edges., AST-resolved call edges are deterministic and should be EXTRACTED/1.0., Same input always produces same output. (+59 more)

### Community 14 - "Community 14"
Cohesion: 0.05
Nodes (65): handle_delete(), handle_enrich(), handle_get(), handle_list(), handle_search(), handle_upload(), API module - exposes the document pipeline over HTTP. Thin layer over parser, v, Accept a list of file paths, run the full pipeline on each,     and return a su (+57 more)

### Community 15 - "Community 15"
Cohesion: 0.04
Nodes (19): ApiClient, CacheManager, Config, createProcessor(), DataProcessor, Get-Data(), GraphifyDemo, HttpClient (+11 more)

### Community 16 - "Community 16"
Cohesion: 0.07
Nodes (51): classify_file(), detect(), FileType, _is_noise_dir(), _load_graphifyignore(), _looks_like_paper(), Return True if this directory name looks like a venv, cache, or dep dir., Read .graphifyignore from root **and ancestor directories**.      Returns a li (+43 more)

### Community 17 - "Community 17"
Cohesion: 0.05
Nodes (40): _ActivityTimeline, AdminDashboardScreen, _AnimatedNumber, build, _buildActionChip, _buildHeroMetricCard, _buildInventorySection, _buildLatestOrdersSection (+32 more)

### Community 18 - "Community 18"
Cohesion: 0.13
Nodes (30): _git_root(), _hooks_dir(), install(), _install_hook(), Walk up to find .git directory., Return the git hooks directory, respecting core.hooksPath if set (e.g. Husky)., Install a single git hook, appending if an existing hook is present., Remove graphify section from a git hook using start/end markers. (+22 more)

### Community 19 - "Community 19"
Cohesion: 0.07
Nodes (28): dart:typed_data, build, dispose, EditProfileScreen, _EditProfileScreenState, initState, SizedBox, SnackBar (+20 more)

### Community 20 - "Community 20"
Cohesion: 0.19
Nodes (22): _estimate_tokens(), print_benchmark(), _query_subgraph_tokens(), Token-reduction benchmark - measures how much context graphify saves vs naive fu, Print a human-readable benchmark report., Run BFS from best-matching nodes and return estimated tokens in the subgraph con, Measure token reduction: corpus tokens vs graphify query tokens.      Args:, run_benchmark() (+14 more)

### Community 21 - "Community 21"
Cohesion: 0.12
Nodes (20): build(), _normalize_id(), Normalize an ID string the same way extract._make_id does.      Used to reconc, Merge multiple extraction results into one graph., Merge multiple extraction results into one graph.      directed=True produces, test_assert_valid_passes_silently(), test_assert_valid_raises_on_errors(), test_dangling_edge_source() (+12 more)

### Community 22 - "Community 22"
Cohesion: 0.12
Nodes (15): AppImage, build, ClipRRect, Container, _placeholder, _resolveUrl, _shimmerPlaceholder, BannerSkeleton (+7 more)

### Community 23 - "Community 23"
Cohesion: 0.24
Nodes (7): AppDelegate, FlutterAppDelegate, FlutterImplicitEngineDelegate, AppServiceProvider, CashierGateway, PaymentGateway, StripeGateway

### Community 24 - "Community 24"
Cohesion: 0.43
Nodes (6): EventServiceProvider, NotifyAdmins, OrderPlaced, SendWelcomeEmail, ShipOrder, UserRegistered

### Community 25 - "Community 25"
Cohesion: 0.29
Nodes (6): AppUpdateSettings, calculateShipping, GeneralSettings, MaintenanceSettings, PaymentSettings, ShippingSettings

### Community 26 - "Community 26"
Cohesion: 0.33
Nodes (5): Animal, -initWithName, -speak, Dog, -fetch

### Community 27 - "Community 27"
Cohesion: 0.33
Nodes (5): delivery, hours, old, only, StaticContent

### Community 28 - "Community 28"
Cohesion: 0.6
Nodes (2): ColorResolver, DefaultPalette

### Community 29 - "Community 29"
Cohesion: 0.4
Nodes (4): Cart, CartItem, copyWith, product.dart

### Community 30 - "Community 30"
Cohesion: 0.5
Nodes (1): Transformer

### Community 31 - "Community 31"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 32 - "Community 32"
Cohesion: 0.5
Nodes (2): RunnerTests, XCTestCase

### Community 33 - "Community 33"
Cohesion: 0.5
Nodes (3): calculateDiscount, Coupon, user_profile.dart

### Community 34 - "Community 34"
Cohesion: 0.5
Nodes (3): Function, openRazorpayCheckout, UnsupportedError

### Community 35 - "Community 35"
Cohesion: 0.67
Nodes (1): graphify - extract · build · cluster · analyze · report.

### Community 36 - "Community 36"
Cohesion: 0.67
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 37 - "Community 37"
Cohesion: 0.67
Nodes (2): Address, copyWith

### Community 38 - "Community 38"
Cohesion: 0.67
Nodes (2): category.dart, Product

### Community 39 - "Community 39"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 40 - "Community 40"
Cohesion: 1.0
Nodes (1): BannerModel

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (1): BlogPost

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (1): Category

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (1): Offer

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (1): Review

### Community 45 - "Community 45"
Cohesion: 1.0
Nodes (1): UserProfile

### Community 46 - "Community 46"
Cohesion: 1.0
Nodes (2): Attention Is All You Need, Transformer Architecture

### Community 47 - "Community 47"
Cohesion: 1.0
Nodes (0): 

### Community 48 - "Community 48"
Cohesion: 1.0
Nodes (0): 

### Community 49 - "Community 49"
Cohesion: 1.0
Nodes (0): 

### Community 50 - "Community 50"
Cohesion: 1.0
Nodes (0): 

### Community 51 - "Community 51"
Cohesion: 1.0
Nodes (0): 

### Community 52 - "Community 52"
Cohesion: 1.0
Nodes (0): 

### Community 53 - "Community 53"
Cohesion: 1.0
Nodes (0): 

### Community 54 - "Community 54"
Cohesion: 1.0
Nodes (0): 

### Community 55 - "Community 55"
Cohesion: 1.0
Nodes (1): Cart Web Design

### Community 56 - "Community 56"
Cohesion: 1.0
Nodes (1): Checkout Mobile Design

### Community 57 - "Community 57"
Cohesion: 1.0
Nodes (1): Homepage Mobile Design

### Community 58 - "Community 58"
Cohesion: 1.0
Nodes (1): App Routes Doc

## Knowledge Gaps
- **1284 isolated node(s):** `MainActivity`, `Invert communities dict: node_id -> community_id.`, `Return True if this node is a file-level hub node (e.g. 'client', 'models')`, `Return the top_n most-connected real entities - the core abstractions.      Fi`, `Find connections that are genuinely surprising - not obvious from file structure` (+1279 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 39`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (2 nodes): `banner_model.dart`, `BannerModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (2 nodes): `blog_post.dart`, `BlogPost`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (2 nodes): `category.dart`, `Category`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (2 nodes): `offer.dart`, `Offer`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (2 nodes): `review.dart`, `Review`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (2 nodes): `user_profile.dart`, `UserProfile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (2 nodes): `Attention Is All You Need`, `Transformer Architecture`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 48`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (1 nodes): `manifest.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (1 nodes): `__init__.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 52`** (1 nodes): `GeneratedPluginRegistrant.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 53`** (1 nodes): `Runner-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 54`** (1 nodes): `razorpay_checkout.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 55`** (1 nodes): `Cart Web Design`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 56`** (1 nodes): `Checkout Mobile Design`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 57`** (1 nodes): `Homepage Mobile Design`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 58`** (1 nodes): `App Routes Doc`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/foundation.dart` connect `Community 9` to `Community 0`, `Community 5`, `Community 6`, `Community 7`, `Community 12`?**
  _High betweenness centrality (0.434) - this node is a cross-community bridge._
- **Why does `open` connect `Community 1` to `Community 8`, `Community 9`, `Community 11`, `Community 14`?**
  _High betweenness centrality (0.432) - this node is a cross-community bridge._
- **Why does `to_json()` connect `Community 1` to `Community 4`, `Community 13`?**
  _High betweenness centrality (0.242) - this node is a cross-community bridge._
- **Are the 75 inferred relationships involving `str` (e.g. with `file_hash()` and `to_html()`) actually correct?**
  _`str` has 75 INFERRED edges - model-reasoned connections that need verification._
- **What connects `MainActivity`, `Invert communities dict: node_id -> community_id.`, `Return True if this node is a file-level hub node (e.g. 'client', 'models')` to the rest of the system?**
  _1284 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.01 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._