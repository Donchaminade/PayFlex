import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/catalogue_provider.dart';
import '../../core/providers/client_inbox_provider.dart';
import '../../core/services/payflex_poll_config.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/design/pf_components.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../auth/widgets/registration_feature_guard.dart';
import '../chat/chat_screen.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key, this.isAgent = false});

  final bool isAgent;

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _searchController = TextEditingController();
  Timer? _cataloguePollTimer;

  static const Map<String, IconData> _categoryIcons = {
    'Tous': Icons.dashboard_customize_rounded,
    'Couture': Icons.content_cut_rounded,
    'Coiffure': Icons.face_retouching_natural_rounded,
    'Mécanique': Icons.settings_suggest_rounded,
    'Menuiserie': Icons.carpenter_rounded,
    'Maçonnerie': Icons.construction_rounded,
    'Soudure': Icons.bolt_rounded,
    'Électricité bâtiment': Icons.electrical_services_rounded,
    'Plomberie': Icons.plumbing_rounded,
    'Froid et climatisation': Icons.ac_unit_rounded,
  };

  @override
  void initState() {
    super.initState();
    _cataloguePollTimer = Timer.periodic(PayflexPollConfig.catalogue, (_) {
      if (!mounted) return;
      // IndexedStack garde les écrans montés : ne poll que si l’onglet Catalogue est visible.
      final visible = widget.isAgent
          ? ref.read(agentNavigationIndexProvider) == 2
          : ref.read(navigationIndexProvider) == 1;
      if (!visible) return;
      ref.read(catalogueProvider.notifier).loadProducts(silent: true);
    });
  }

  @override
  void dispose() {
    _cataloguePollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(catalogueProvider);
    final auth = ref.watch(authProvider);
    final inbox = !widget.isAgent && auth.role == 'client' ? ref.watch(clientInboxProvider) : null;
    final showSupportChat = !widget.isAgent;
    
    final cats = catalogue.categoryFilterOptions;
    final selectedIdx = cats.indexOf(catalogue.selectedCategory).clamp(0, cats.isEmpty ? 0 : cats.length - 1);
    final showFeatured = catalogue.selectedCategory == 'Tous' && catalogue.searchQuery.isEmpty && catalogue.featuredProducts.isNotEmpty;
    final picks = catalogue.filteredProducts.where((p) => !showFeatured || p.id != catalogue.featuredProducts.first.id).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Pf.canvas,
        body: RefreshIndicator(
          color: Pf.ink,
          onRefresh: () => ref.read(catalogueProvider.notifier).loadProducts(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: PfHeader(
                    title: 'Explorer',
                    eyebrow: 'Catalogue PayFlex',
                    trailing: [
                      PfCircleButton(
                        icon: Icons.shopping_bag_outlined,
                        semanticLabel: 'Panier',
                        badge: catalogue.cartItemCount,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                      ),
                      if (showSupportChat)
                        PfCircleButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          semanticLabel: 'Discussion support',
                          dot: inbox != null && inbox.chatUnread > 0,
                          onTap: () {
                            if (!auth.canUseAppFeatures) {
                              showRegistrationFeatureLockedSnackBar(context, 'Discussion support');
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                          },
                        ),
                    ],
                  ),
                ),
              ),

              if (catalogue.isOffline)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Pf.gutter),
                    child: OfflineBanner(margin: EdgeInsets.only(bottom: Pf.s12)),
                  ),
                ),

              SliverToBoxAdapter(
                child: PfReveal(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                    child: PfSearchBar(
                      controller: _searchController,
                      hint: 'Machine, outil, kit…',
                      onChanged: (v) {
                        ref.read(catalogueProvider.notifier).search(v);
                        setState(() {});
                      },
                      onClear: () {
                        _searchController.clear();
                        ref.read(catalogueProvider.notifier).search('');
                        setState(() {});
                      },
                      onFilter: () => _showCategorySheet(context, cats),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Pf.s8)),
              SliverToBoxAdapter(
                child: PfReveal(
                  index: 1,
                  child: PfCategoryTabs(
                    selected: selectedIdx,
                    items: [for (final c in cats) PfTabItem(c == 'Tous' ? 'Tout' : c, _categoryIcons[c] ?? Icons.category_rounded)],
                    onSelected: (i) => ref.read(catalogueProvider.notifier).filterByCategory(cats[i]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Pf.s24)),

              if (catalogue.isLoading) ...[
                const SliverToBoxAdapter(child: _CatalogueSkeleton()),
              ] else if (catalogue.filteredProducts.isEmpty) ...[
                SliverToBoxAdapter(
                  child: PfEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Aucun résultat',
                    message: 'Essayez d’autres mots-clés ou une autre catégorie.',
                    action: 'Tout afficher',
                    onAction: () {
                      _searchController.clear();
                      ref.read(catalogueProvider.notifier).search('');
                      ref.read(catalogueProvider.notifier).filterByCategory('Tous');
                    },
                  ),
                ),
              ] else ...[
                if (showFeatured)
                  SliverToBoxAdapter(
                    child: PfReveal(
                      index: 2,
                      scale: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                        child: catalogue.featuredProducts.length == 1
                            ? _buildFeaturedCard(context, catalogue.featuredProducts.first)
                            : _FeaturedTicker(
                                products: catalogue.featuredProducts,
                                itemBuilder: (p) => _buildFeaturedCard(context, p),
                              ),
                      ),
                    ),
                  ),
                if (showFeatured) const SliverToBoxAdapter(child: SizedBox(height: Pf.s32)),
                if (picks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: PfSectionHeader(
                      title: catalogue.searchQuery.isNotEmpty ? 'Résultats « ${catalogue.searchQuery} »' : 'Sélection de la semaine',
                      action: '${catalogue.filteredProducts.length} articles',
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: Pf.s16)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                        itemCount: picks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: Pf.s16),
                        itemBuilder: (context, i) => PfReveal(index: i, scale: true, child: _buildProductCard(context, picks[i])),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: Pf.s32)),
                  const SliverToBoxAdapter(child: PfSectionHeader(title: 'Tous les articles')),
                  const SliverToBoxAdapter(child: SizedBox(height: Pf.s12)),
                  SliverList.builder(
                    itemCount: catalogue.filteredProducts.length,
                    itemBuilder: (context, i) => PfReveal(index: i, child: _buildProductRow(context, catalogue.filteredProducts[i])),
                  ),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, List<String> cats) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Pf.gutter, 0, Pf.gutter, Pf.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catégories', style: Pf.title()),
              const SizedBox(height: Pf.s16),
              Wrap(
                spacing: Pf.s8,
                runSpacing: Pf.s8,
                children: [
                  for (final c in cats)
                    PfPillChip(
                      label: c,
                      icon: _categoryIcons[c],
                      tone: ref.read(catalogueProvider).selectedCategory == c ? PfChipTone.ink : PfChipTone.white,
                      onTap: () {
                        ref.read(catalogueProvider.notifier).filterByCategory(c);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProduct(BuildContext context, Product product) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));

  Widget _buildProductRow(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Pf.gutter, 0, Pf.gutter, Pf.s12),
      child: PfCard(
        padding: const EdgeInsets.all(Pf.s12),
        onTap: () => _openProduct(context, product),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: Pf.br(Pf.rMd),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.network(product.displayImageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Pf.fill, child: const Icon(Icons.inventory_2_rounded, color: Pf.faint))),
              ),
            ),
            const SizedBox(width: Pf.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(), style: Pf.overline(color: Pf.faint)),
                  const SizedBox(height: 2),
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.label(size: 15)),
                  const SizedBox(height: Pf.s4),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: product.formattedPrice, style: Pf.num(size: 13)),
                    TextSpan(text: '  ·  dès ${product.formattedDaily}', style: Pf.body(size: 12)),
                  ])),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Pf.ink, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Product product) {
    return PfFeaturedCard(
      badge: 'À LA UNE',
      title: product.name,
      subtitle: product.category,
      cta: 'Dès ${product.formattedDaily}',
      onCta: () => _openProduct(context, product),
      onTap: () => _openProduct(context, product),
      image: NetworkImage(product.displayImageUrl),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return PfPhotoCard(
      image: NetworkImage(product.displayImageUrl),
      heroTag: product.id,
      title: product.name,
      subtitle: '${product.category} · ${product.formattedPrice}',
      chip: product.formattedDaily,
      onTap: () => _openProduct(context, product),
      width: 220,
      height: 300,
    );
  }
}

class _CatalogueSkeleton extends StatelessWidget {
  const _CatalogueSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PfShimmer(radius: Pf.rXxl, height: 184),
          const SizedBox(height: Pf.s32),
          const PfShimmer(radius: 8, height: 20, width: 180),
          const SizedBox(height: Pf.s16),
          Row(children: const [
            Expanded(child: PfShimmer(radius: Pf.rXl, height: 220)),
            SizedBox(width: Pf.s16),
            Expanded(child: PfShimmer(radius: Pf.rXl, height: 220)),
          ]),
        ],
      ),
    );
  }
}

/// Défilement horizontal continu pour plusieurs produits « vedette ».
class _FeaturedTicker extends StatefulWidget {
  final List<Product> products;
  final Widget Function(Product) itemBuilder;

  const _FeaturedTicker({required this.products, required this.itemBuilder});

  @override
  State<_FeaturedTicker> createState() => _FeaturedTickerState();
}

class _FeaturedTickerState extends State<_FeaturedTicker> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  static const double _cardW = 268;
  static const double _gap = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.products.length < 2) return;
      _timer = Timer.periodic(const Duration(milliseconds: 28), (_) {
        if (!mounted || !_controller.hasClients) return;
        final loop = (_cardW + _gap) * widget.products.length;
        if (loop <= 0) return;
        final next = _controller.offset + 1.1;
        if (next >= loop) {
          _controller.jumpTo(next - loop);
        } else {
          _controller.jumpTo(next);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.products;
    if (p.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemExtent: _cardW + _gap,
        itemCount: p.length * 800,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: _gap),
            child: SizedBox(
              width: _cardW,
              child: widget.itemBuilder(p[i % p.length]),
            ),
          );
        },
      ),
    );
  }
}
