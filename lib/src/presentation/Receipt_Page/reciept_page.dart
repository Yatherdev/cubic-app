import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/utils/pdf_generator.dart';
import '../../domain/models/client.dart';
import '../../domain/models/invoice.dart';
import '../providers/providers.dart';


class ReceiptPage extends ConsumerWidget {
  final String invoiceId;

  const ReceiptPage({super.key, required this.invoiceId});

  Future<Invoice> _loadInvoice(WidgetRef ref) async {
    final invoices = ref.read(invoicesProvider.notifier);
    final invoice = invoices.state.firstWhere((i) => i.id == invoiceId,
        orElse: () => throw Exception('Invoice not found'));
    return invoice;
  }

  Future<Client?> _loadClient(WidgetRef ref, String? clientId) async {
    if (clientId == null) return null;
    final clients = ref.read(clientsProvider);
    return clients.firstWhere(
          (c) => c.key == clientId,
     // orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Invoice>(
      future: _loadInvoice(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('خطأ: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('لا توجد فاتورة')),
          );
        }

        final invoice = snapshot.data!;
        final totalVolume = invoice.items.fold(0.0, (sum, item) => sum + item.volume);
        final totalPrice = invoice.totalAfterDiscount;

        return FutureBuilder<Client?>(
          future: _loadClient(ref, invoice.clientId),
          builder: (context, clientSnapshot) {
            final clientName = clientSnapshot.data?.name ?? 'غير محدد';

            return Scaffold(
              appBar: AppBar(
                title: const Text('تفاصيل الإيصال'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      try {
                        final bytes = await generateInvoicePdf(
                          invoice: invoice,
                          shopName: 'متجري', // يمكنك تغييره حسب الحاجة
                          //clientName: clientName,
                        );
                        final dir = await getApplicationDocumentsDirectory();
                        final file = File('${dir.path}/receipt_${invoice.id}.pdf');
                        await file.writeAsBytes(await bytes);
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'إيصال فاتورة #${invoice.number} للعميل $clientName',
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ أثناء مشاركة الـ PDF: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رقم الفاتورة: ${invoice.number}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}',
                          style: const TextStyle(fontSize: 16)),
                      Text('العميل: $clientName',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      const Text('تفاصيل المنتجات:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoice.items.length,
                        itemBuilder: (context, index) {
                          final item = invoice.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(item.product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('العرض: ${item.product.width} مم'),
                                  Text('الارتفاع: ${item.product.height} مم'),
                                  Text('الطول: ${item.length ?? 0} م'),
                                  Text('الكمية: ${item.quantity ?? 1}'),
                                  Text('الحجم (م³): ${item.volume.toStringAsFixed(2)}'),
                                  Text('السعر للمتر المكعب: ${(item.pricePerM3 ?? item.product.unitPricePerM3 ?? 0).toStringAsFixed(2)} ج.م'),
                                  Text('القيمة الإجمالية: ${(item.totalValue ?? item.subtotal).toStringAsFixed(2)} ج.م'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('التكعيب الإجمالي: ${totalVolume.toStringAsFixed(2)} م³',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('السعر الإجمالي: ${totalPrice.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('طريقة الدفع: ${invoice.paymentType == PaymentType.cash ? 'نقدي' : 'آجل'}',
                          style: const TextStyle(fontSize: 16)),
                      if (invoice.discount > 0)
                        Text('الخصم: ${invoice.discount.toStringAsFixed(2)} ج.م',
                            style: const TextStyle(fontSize: 16, color: Colors.red)),
                      const SizedBox(height: 20),
                      if (!invoice.isPaid)
                        Text('ملاحظة: الفاتورة لم تُدفع بعد',
                            style: TextStyle(fontSize: 14, color: Colors.red[700])),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}