import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'invoice_page.dart';
import '../../../domain/models/invoice.dart';

class InvoiceDatesPage extends StatefulWidget {
  const InvoiceDatesPage({super.key, this.selectedDate});
  final DateTime? selectedDate;

  @override
  State<InvoiceDatesPage> createState() => _DatesPageState();
}

class _DatesPageState extends State<InvoiceDatesPage> {
  String searchQuery = "";

  // No init required
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        try {
          final invoices = ref.watch(invoicesProvider);

          // استخراج التواريخ الفريدة من الفواتير
          final uniqueDates = invoices
              .map((i) => i.date.toIso8601String().split('T')[0])
              .toSet()
              .toList();

          uniqueDates.sort((a, b) => b.compareTo(a)); // ترتيب تنازلي

          // فلترة حسب البحث
          final filteredDates =
          uniqueDates.where((date) => date.contains(searchQuery)).toList();

          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text(
                'الفــواتيــر',
                style: TextStyle(color: Colors.black),
              ),
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // مربع البحث
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "البحث",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // قائمة التواريخ
                  Expanded(
                    child: filteredDates.isEmpty
                        ? const Center(
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style:
                        TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredDates.length,
                      itemBuilder: (context, index) {
                        final dateString = filteredDates[index];
                        final selectedDate = DateTime.parse(dateString);
                        final List<Invoice> invoicesForDate = invoices
                            .where((i) => i.date.toIso8601String().startsWith(dateString))
                            .toList();
                        return Card(
                          child: ListTile(
                            title: Text(dateString),
                            trailing:
                            const Icon(Icons.arrow_forward_ios_outlined),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoicePage(
                                    date: selectedDate,
                                    invoices: invoicesForDate,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          return Scaffold(
            body: Center(
              child: Text(
                'خطأ في التحميل: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      },
    );
  }
}