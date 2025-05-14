import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash In-Out'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const CircleAvatar(
            backgroundImage: NetworkImage(
              'https://readdy.ai/api/search-image?query=professional%20headshot%20of%20a%20young%20textile%20business%20owner%2C%20male%2C%2030s%2C%20south%20asian%2C%20professional%20attire%2C%20neutral%20expression%2C%20high%20quality%20portrait&width=100&height=100&seq=1&orientation=squarish',
            ),
            radius: 16,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Welcome back, Rahul',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Wednesday, May 14, 2025',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Stats Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2,
                children: const [
                  StatsCard(
                    icon: Icons.person,
                    color: Colors.blue,
                    label: 'Total Clients',
                    value: '48',
                  ),
                  StatsCard(
                    icon: Icons.attach_money,
                    color: Colors.green,
                    label: 'Received',
                    value: '₹ 1.2M',
                  ),
                  StatsCard(
                    icon: Icons.timelapse,
                    color: Colors.orange,
                    label: 'Pending',
                    value: '₹ 450K',
                  ),
                  StatsCard(
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                    label: 'Due Today',
                    value: '₹ 85K',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: const [
                  QuickAction(
                    icon: Icons.person_add,
                    color: Colors.blue,
                    label: 'Add Client',
                  ),
                  QuickAction(
                    icon: Icons.payment,
                    color: Colors.green,
                    label: 'New Payment',
                  ),
                  QuickAction(
                    icon: Icons.receipt,
                    color: Colors.orange,
                    label: 'Reports',
                  ),
                  QuickAction(
                    icon: Icons.settings,
                    color: Colors.purple,
                    label: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              const SectionTitle(title: 'Recent Transactions'),
              const SizedBox(height: 12),
              const TransactionCard(
                name: 'Mehta Textiles',
                date: 'May 14, 2025',
                amount: '+ ₹ 25,000',
                status: 'Completed',
                color: Colors.green,
              ),
              const TransactionCard(
                name: 'Sharma Fabrics',
                date: 'May 13, 2025',
                amount: '+ ₹ 42,500',
                status: 'Completed',
                color: Colors.green,
              ),
              const TransactionCard(
                name: 'Patel Garments',
                date: 'May 12, 2025',
                amount: '₹ 18,000',
                status: 'Pending',
                color: Colors.orange,
              ),
              const TransactionCard(
                name: 'Singh Exports',
                date: 'May 10, 2025',
                amount: '+ ₹ 35,000',
                status: 'Completed',
                color: Colors.green,
              ),
              const SizedBox(height: 24),

              // Upcoming Payments
              const SectionTitle(title: 'Upcoming Payments'),
              const SizedBox(height: 12),
              const UpcomingPaymentCard(
                name: 'Gupta Textiles',
                due: 'Due Today',
                amount: '₹ 35,000',
                installment: 'Installment 2/3',
                color: Colors.red,
              ),
              const UpcomingPaymentCard(
                name: 'Kumar Fabrics',
                due: 'Due in 2 days',
                amount: '₹ 28,500',
                installment: 'Installment 1/2',
                color: Colors.orange,
              ),
              const UpcomingPaymentCard(
                name: 'Verma Exports',
                due: 'Due in 5 days',
                amount: '₹ 50,000',
                installment: 'Full Payment',
                color: Colors.grey,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.indigo[900],
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.indigo[900],
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ───── COMPONENTS ─────

class StatsCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const StatsCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
          radius: 28,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: () {}, child: const Text('View All')),
      ],
    );
  }
}

class TransactionCard extends StatelessWidget {
  final String name;
  final String date;
  final String amount;
  final String status;
  final Color color;

  const TransactionCard({
    required this.name,
    required this.date,
    required this.amount,
    required this.status,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.arrow_downward, color: color),
        ),
        title: Text(name),
        subtitle: Text(date),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text(
              status,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class UpcomingPaymentCard extends StatelessWidget {
  final String name;
  final String due;
  final String amount;
  final String installment;
  final Color color;

  const UpcomingPaymentCard({
    required this.name,
    required this.due,
    required this.amount,
    required this.installment,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.event, color: color),
        ),
        title: Text(name),
        subtitle: Text(due),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text(
              installment,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
