import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

part 'main.g.dart';

@HiveType(typeId: 0)
class Transaction {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final bool isExpense;

  Transaction({required this.name, required this.amount, required this.date, required this.isExpense});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions_box');

  final prefs = await SharedPreferences.getInstance();
  final String? savedUsername = prefs.getString('username_key');

  runApp(AccessibleFinanceApp(username: savedUsername));
}

class AccessibleFinanceApp extends StatelessWidget {
  final String? username;
  const AccessibleFinanceApp({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finanças Acessíveis',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: username == null ? const OnboardingScreen() : const MainScreen(),
    );
  }
}

// --- ONBOARDING SCREEN ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController nameController = TextEditingController();

  void saveProfile() async {
    String username = nameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Por favor, digite seu nome.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username_key', username);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Boas-vindas ao seu gerenciador financeiro!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 15),
            const Text(
              'Como podemos chamar você?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite seu nome aqui...',
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text('Começar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MAIN SCREEN: NAVIGATION HUB ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentTab = 0;
  double balance = 0.00;
  String username = '';
  final Box<Transaction> transactionBox = Hive.box<Transaction>('transactions_box');
  List<Transaction> transactionHistory = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadFinancialData();
  }

  void loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username_key') ?? 'Usuário';
    });
  }

  void loadFinancialData() {
    transactionHistory = transactionBox.values.toList();
    double computedBalance = 0.00;
    for (var item in transactionHistory) {
      if (item.isExpense) {
        computedBalance -= item.amount;
      } else {
        computedBalance += item.amount;
      }
    }
    setState(() {
      balance = computedBalance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      HomeTab(username: username, balance: balance),
      HistoryTab(history: transactionHistory, onUpdate: () => loadFinancialData()),
      ReportsTab(history: transactionHistory),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Meu Dinheiro', 
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: tabs[currentTab],
      
      floatingActionButton: currentTab == 2 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormScreen()),
                );
                if (result != null && result is Transaction) {
                  await transactionBox.add(result);
                  loadFinancialData();
                }
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Novo Registro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentTab,
          onDestinationSelected: (index) {
            setState(() {
              currentTab = index;
              loadFinancialData();
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 30),
              selectedIcon: Icon(Icons.home, size: 30, color: Colors.blue),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined, size: 30),
              selectedIcon: Icon(Icons.list_alt, size: 30, color: Colors.blue),
              label: 'Histórico',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline, size: 30),
              selectedIcon: Icon(Icons.pie_chart, size: 30, color: Colors.blue),
              label: 'Gráficos',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TAB 1: HOME =================
class HomeTab extends StatelessWidget {
  final String username;
  final double balance;

  const HomeTab({super.key, required this.username, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olá, $username!', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          
          Card(
            elevation: 4,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seu Saldo Disponível:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Text(
                    'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}', 
                    style: TextStyle(
                      fontSize: 36, 
                      fontWeight: FontWeight.bold, 
                      color: balance >= 0 ? Colors.green.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 2: HISTORY =================
class HistoryTab extends StatelessWidget {
  final List<Transaction> history;
  final VoidCallback onUpdate;

  const HistoryTab({super.key, required this.history, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final Box<Transaction> transactionBox = Hive.box<Transaction>('transactions_box');

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suas Movimentações', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum registro encontrado.',
                      style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      String day = item.date.day.toString().padLeft(2, '0');
                      String month = item.date.month.toString().padLeft(2, '0');
                      String formattedDate = "$day/$month";

                      return Dismissible(
                        key: Key(item.date.millisecondsSinceEpoch.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white, size: 32),
                        ),
                        onDismissed: (direction) {
                          transactionBox.deleteAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${item.name}" removido!')),
                          );
                          onUpdate();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isExpense ? Colors.redAccent : Colors.greenAccent.shade700,
                              child: Icon(item.isExpense ? Icons.trending_down : Icons.trending_up, color: Colors.white),
                            ),
                            title: Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            subtitle: Text("Data: $formattedDate", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            trailing: Text(
                              '${item.isExpense ? "-" : "+"} R\$ ${item.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(
                                fontSize: 18, 
                                color: item.isExpense ? Colors.red : Colors.green.shade700, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 3: REPORTS WITH LIVE PIE CHART =================
class ReportsTab extends StatelessWidget {
  final List<Transaction> history;

  const ReportsTab({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final onlyExpenses = history.where((t) => t.isExpense).toList();

    if (onlyExpenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Sem dados para o gráfico',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                'Adicione um ou mais gastos para ver a distribuição visual do seu dinheiro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    Map<String, double> aggregatedExpenses = {};
    for (var expense in onlyExpenses) {
      String keyName = expense.name.trim();
      aggregatedExpenses[keyName] = (aggregatedExpenses[keyName] ?? 0.0) + expense.amount;
    }

    final List<Color> colorPalette = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.amber,
      Colors.cyan,
      Colors.pinkAccent,
      Colors.teal,
    ];

    int colorIndex = 0;
    List<PieChartSectionData> chartSections = aggregatedExpenses.entries.map((entry) {
      final color = colorPalette[colorIndex % colorPalette.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: 'R\$ ${entry.value.toStringAsFixed(0)}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: Colors.white,
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Para onde vai o seu dinheiro:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: chartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          const Text('Legenda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView(
              children: aggregatedExpenses.keys.toList().asMap().entries.map((entry) {
                int idx = entry.key;
                String name = entry.value;
                Color legendColor = colorPalette[idx % colorPalette.length];
                double totalValue = aggregatedExpenses[name]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: legendColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        'R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- FORM SCREEN ---
class FormScreen extends StatefulWidget {
  const FormScreen({super.key});
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool operationIsExpense = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Novo Registro', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Que tipo de registro é este?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => operationIsExpense = true),
                      icon: const Icon(Icons.trending_down),
                      label: const Text('Gasto (Saída)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: operationIsExpense ? Colors.redAccent : Colors.grey.shade200,
                        foregroundColor: operationIsExpense ? Colors.white : Colors.black,
                        elevation: operationIsExpense ? 4 : 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => operationIsExpense = false),
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Ganho (Entrada)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !operationIsExpense ? Colors.green.shade600 : Colors.grey.shade200,
                        foregroundColor: !operationIsExpense ? Colors.white : Colors.black,
                        elevation: !operationIsExpense ? 4 : 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            const Text('Descrição / Identificação:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: nameController, 
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: operationIsExpense ? 'Ex: Farmácia, Mercado...' : 'Ex: Aposentadoria, Pix...',
              ),
            ),
            const SizedBox(height: 30),
            const Text('Qual o valor?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: amountController, 
              style: const TextStyle(fontSize: 20),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  double? parsedAmount = double.tryParse(amountController.text.replaceAll(',', '.'));
                  String parsedName = nameController.text.trim().isEmpty 
                      ? (operationIsExpense ? "Gasto Geral" : "Ganho Geral") 
                      : nameController.text;
                  
                  if (parsedAmount == null || parsedAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Por favor, digite um valor válido.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    Navigator.pop(
                      context, 
                      Transaction(name: parsedName, amount: parsedAmount, date: DateTime.now(), isExpense: operationIsExpense),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                child: const Text('Confirmar e Salvar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}