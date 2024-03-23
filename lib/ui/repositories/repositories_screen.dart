import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_pagination_example/domain/repository.dart';
import 'package:riverpod_pagination_example/ui/repositories/repositories_view_model.dart';
import 'package:riverpod_pagination_example/ui/repositories/repository_filter_notifier.dart';
import 'package:riverpod_pagination_example/ui/widgets/search_bar.dart';
import 'package:shimmer/shimmer.dart';

class RepositoriesScreen extends ConsumerStatefulWidget {
  const RepositoriesScreen({super.key});

  @override
  ConsumerState createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends ConsumerState<RepositoriesScreen> {
  late final viewModel = ref.read(repositoriesViewModelProvider.notifier);
  late final filterController = ref.read(repositoryFilterNotifierProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final repositoriesState = ref.watch(repositoriesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Pagination Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: NotificationListener(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo is ScrollEndNotification &&
                scrollInfo.metrics.axisDirection == AxisDirection.down &&
                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent) {
              if (viewModel.canLoadMore) {
                viewModel.loadNextPage();
              }
            }
            return true;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              //TODO: Implement refresh
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverToBoxAdapter(child: StyledSearchBar(onSearch: onSearch, debounceDuration: 500))),
                ...repositories(context, repositoriesState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> repositories(BuildContext context, AsyncValue<List<Repository>> vacationsState) {
    final repositories = vacationsState.valueOrNull ?? [];
    final initialLoading = vacationsState.isLoading && repositories.isEmpty;
    final loadingMore = vacationsState.isLoading && repositories.isNotEmpty;

    if (vacationsState.hasError) {
      return [SliverToBoxAdapter(child: Text('Error: ${vacationsState.error}'))];
    }

    return initialLoading
        ? shimmerLoading()
        : repositories.isEmpty
            ? noSearchResultsFound(context)
            : [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final repository = repositories[index];
                      return ListTile(
                        title: Text(repository.name),
                        subtitle: Text(repository.description),
                      );
                    },
                    childCount: repositories.length,
                  ),
                ),
                if (loadingMore) const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              ];
  }

  List<Widget> noSearchResultsFound(BuildContext context) {
    return [
      SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 100),
              const SizedBox(height: 16),
              Text('No repositories found', style: Theme.of(context).textTheme.headline6),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> shimmerLoading() {
    return List.generate(
      10,
      (index) => SliverToBoxAdapter(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            title: Container(
              width: double.infinity,
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(
              width: double.infinity,
              height: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void onSearch(String query) {
    filterController.updateQuery(query);
    viewModel.applyFilter(ref.read(repositoryFilterNotifierProvider));
  }
}
