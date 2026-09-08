import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_list_item.dart';
import 'add_balance_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabAnimation);
    _scrollController.addListener(_onScroll);

    // Load initial data
    context.read<WalletBloc>().add(const GetBalanceEvent());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabAnimation);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabAnimation() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index != _selectedTabIndex) {
      _selectTab(_tabController.index);
    }
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index && _tabController.index == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }

    final type = _getTransactionType(index);
    context.read<WalletBloc>().add(
          GetTransactionsEvent(type: type, page: 1, limit: 20),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final type = _getTransactionType(_selectedTabIndex);
      context.read<WalletBloc>().add(LoadMoreTransactionsEvent(type: type));
    }
  }

  List<Transaction> _getFilteredTransactions(
      List<Transaction> transactions, int tabIndex) {
    switch (tabIndex) {
      case 1: // Credits
        return transactions.where((tx) => tx.isCredit).toList();
      case 2: // Debits
        return transactions.where((tx) => tx.isDebit).toList();
      case 3: // Reserved
        return transactions.where((tx) => tx.isReserved).toList();
      case 0: // All
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WalletBloc>().add(const RefreshWalletEvent());
              final type = _getTransactionType(_selectedTabIndex);
              if (type != null) {
                context.read<WalletBloc>().add(
                      GetTransactionsEvent(type: type, page: 1, limit: 20),
                    );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BalancePaymentVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Balance added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh wallet
            context.read<WalletBloc>().add(const GetBalanceEvent());
          }
        },
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WalletLoaded ||
              state is TransactionsLoadingMore ||
              state is BalancePaymentVerified) {
            final WalletLoaded loadedState = state is BalancePaymentVerified
                ? WalletLoaded(
                    balance: state.updatedBalance,
                    transactions: const [],
                    currentPage: 1,
                  )
                : state as WalletLoaded;

            final displayedTransactions = _getFilteredTransactions(
              loadedState.transactions,
              _selectedTabIndex,
            );

            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(const RefreshWalletEvent());
                final type = _getTransactionType(_selectedTabIndex);
                if (type != null) {
                  context.read<WalletBloc>().add(
                        GetTransactionsEvent(type: type, page: 1, limit: 20),
                      );
                }
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Balance Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BalanceCard(
                        balance: loadedState.balance,
                        onAddBalance: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddBalanceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Transactions Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (displayedTransactions.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${displayedTransactions.length} items',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Transaction Tabs
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: theme.primaryColor,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: theme.primaryColor,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                          onTap: _selectTab,
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Credits'),
                            Tab(text: 'Debits'),
                            Tab(text: 'Reserved'),
                          ],
                        ),
                        if (loadedState.isFiltering)
                          LinearProgressIndicator(
                            minHeight: 2.5,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryColor,
                            ),
                          )
                        else
                          const Divider(height: 1, thickness: 1),
                      ],
                    ),
                  ),

                  // Transaction List
                  if (displayedTransactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getEmptyIcon(_selectedTabIndex),
                                  size: 36,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getEmptyTitle(_selectedTabIndex),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getEmptySubtitle(_selectedTabIndex),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < displayedTransactions.length) {
                              return TransactionListItem(
                                transaction: displayedTransactions[index],
                              );
                            } else if (loadedState.hasMore) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          childCount: displayedTransactions.length +
                              (loadedState.hasMore ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }

  String? _getTransactionType(int index) {
    switch (index) {
      case 0:
        return null; // All
      case 1:
        return 'credit';
      case 2:
        return 'debit';
      case 3:
        return 'reserved';
      default:
        return null;
    }
  }

  String _getEmptyTitle(int index) {
    switch (index) {
      case 1:
        return 'No Credit Transactions';
      case 2:
        return 'No Debit Transactions';
      case 3:
        return 'No Reserved Funds';
      case 0:
      default:
        return 'No Transactions Yet';
    }
  }

  String _getEmptySubtitle(int index) {
    switch (index) {
      case 1:
        return 'Top-ups, earnings, and refunds will appear here.';
      case 2:
        return 'Campaign payments and balance deductions will appear here.';
      case 3:
        return 'Funds reserved for active campaigns will appear here.';
      case 0:
      default:
        return 'Your wallet activity will show up here once you begin.';
    }
  }

  IconData _getEmptyIcon(int index) {
    switch (index) {
      case 1:
        return Icons.arrow_downward_rounded;
      case 2:
        return Icons.arrow_upward_rounded;
      case 3:
        return Icons.lock_clock_outlined;
      case 0:
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
