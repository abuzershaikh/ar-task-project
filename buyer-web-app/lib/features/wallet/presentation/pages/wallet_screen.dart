import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    context.read<WalletBloc>().add(const GetBalanceEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<WalletBloc>().add(const LoadMoreTransactionsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WalletBloc>().add(const RefreshWalletEvent());
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

            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(const RefreshWalletEvent());
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
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

                      // Tabs for transaction types
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).primaryColor,
                            onTap: (index) {
                              context.read<WalletBloc>().add(
                                    GetTransactionsEvent(
                                      type: _getTransactionType(index),
                                    ),
                                  );
                            },
                            tabs: const [
                              Tab(text: 'All'),
                              Tab(text: 'Credits'),
                              Tab(text: 'Debits'),
                              Tab(text: 'Reserved'),
                            ],
                          ),
                        ),
                      ),

                      // Transactions List Header
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Transactions List
                      if (loadedState.transactions.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < loadedState.transactions.length) {
                                  return TransactionListItem(
                                    transaction: loadedState.transactions[index],
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
                              childCount: loadedState.transactions.length +
                                  (loadedState.hasMore ? 1 : 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
}
