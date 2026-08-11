import 'package:flutter/material.dart';

/// Dedicated Day Streak Screen:
/// - Displays 7-Day task completion streak, daily rewards calendar, and flame badges.
/// - Styled with Warm Gold Amber (#F59E0B / #D97706) & Slate theme tokens.
class DayStreakScreen extends StatelessWidget {
  const DayStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> streakDays = [
      {'day': 'Day 1', 'reward': '₹5', 'completed': true},
      {'day': 'Day 2', 'reward': '₹5', 'completed': true},
      {'day': 'Day 3', 'reward': '₹10', 'completed': true},
      {'day': 'Day 4', 'reward': '₹10', 'completed': true},
      {'day': 'Day 5', 'reward': '₹15', 'completed': true},
      {'day': 'Day 6', 'reward': '₹15', 'completed': true},
      {'day': 'Day 7', 'reward': '₹25 Bonus', 'completed': true, 'isSpecial': true},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daily Streak & Rewards',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flame Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '7 Days Streak! 🔥',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You are on fire! Complete tasks every day to unlock bonus cash rewards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 7-Day Grid Calendar Section
              const Text(
                '7-Day Streak Calendar',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: streakDays.length,
                itemBuilder: (context, index) {
                  final item = streakDays[index];
                  final isCompleted = item['completed'] as bool;
                  final isSpecial = item['isSpecial'] == true;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSpecial
                          ? const Color(0xFFFEF3C7)
                          : (isCompleted ? const Color(0xFFFFFBEB) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSpecial
                            ? const Color(0xFFF59E0B)
                            : (isCompleted ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                        width: isSpecial ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 14,
                              color: isCompleted
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['day'] as String,
                              style: TextStyle(
                                color: isCompleted
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['reward'] as String,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: isSpecial ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Streak Benefits Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Rule & Benefits',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complete at least 1 task every 24 hours to maintain streak.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reach Day 7 to claim ₹25 instant bonus in your wallet!',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
