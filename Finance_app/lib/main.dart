import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  Transaction({
    required this.name, 
    required this.amount, 
    required this.date, 
    this.isExpense = true,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter()); // <-- Alinhado com o main.g.dart
  await Hive.openBox<Transaction>('expenses_box'); // <-- Alinhado com o main.g.dart

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
      home: username == null ? const OnboardingScreen() : MainScreen(username: username!),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController usernameController = TextEditingController();

  void saveProfile() async {
    String username = usernameController.text.trim();
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
        MaterialPageRoute(builder: (context) => MainScreen(username: username)),
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
              controller: usernameController,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Começar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String username;

  const MainScreen({super.key, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double balance = 1500.00;
  final Box<Transaction> expenseBox = Hive.box<Transaction>('expenses_box');
  List<Transaction> expenseHistory = [];

  @override
  void initState() {
    super.initState();
    loadFinancialData();
  }

  // Isolates local storage fetch operations and computes wallet balances dynamically
  void loadFinancialData() {
    expenseHistory = expenseBox.values.toList();
    double computedBalance = 1500.00;
    for (var expense in expenseHistory) {
      computedBalance = computedBalance - expense.amount;
    }
    setState(() {
      balance = computedBalance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Meu Dinheiro', 
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${widget.username}!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20), 
            
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Seu Saldo:',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}', 
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Meus Gastos:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: expenseHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum gasto cadastrado ainda.',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: expenseHistory.length,
                      itemBuilder: (context, index) {
                        final item = expenseHistory[index];
                        String day = item.date.day.toString().padLeft(2, '0');
                        String month = item.date.month.toString().padLeft(2, '0');
                        String formattedDate = "$day/$month";

                        // Implements swift swipe-to-delete contextual action mechanics
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
                            expenseBox.deleteAt(index);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gasto "${item.name}" apagado com sucesso!'),
                              ),
                            );

                            loadFinancialData();
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.trending_down, color: Colors.white),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Adicionado em $formattedDate",
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              trailing: Text(
                                '- R\$ ${item.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, 
              height: 60, 
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FormScreen()),
                  );

                  if (result != null && result is Transaction) {
                    await expenseBox.add(result);
                    loadFinancialData(); 
                  }
                },
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  'Adicionar Gasto', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormScreen extends StatelessWidget {
  const FormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Novo Gasto', 
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onde você gastou?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController, 
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Supermercado, Farmácia...',
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Qual o valor?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
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
                  String parsedName = nameController.text.trim().isEmpty ? "Gasto Geral" : nameController.text;
                  
                  if (parsedAmount == null || parsedAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          'Por favor, digite um valor válido para o gasto.',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    Navigator.pop(
                      context, 
                      Transaction(name: parsedName, amount: parsedAmount, date: DateTime.now()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Salvar Gasto',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}