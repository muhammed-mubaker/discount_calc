import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DiscountApp());

/// Simple two-language string table (Arabic / English), picked from device locale.
class S {
  final bool ar;
  const S(this.ar);
  static S of(BuildContext c) =>
      S(Localizations.localeOf(c).languageCode == 'ar');

  String get title => ar ? 'حاسبة الخصم والضريبة' : 'Discount & Tax Calculator';
  String get price => ar ? 'السعر الأصلي' : 'Original price';
  String get discount => ar ? 'نسبة الخصم %' : 'Discount %';
  String get tax => ar ? 'نسبة الضريبة %' : 'Tax %';
  String get discountAmount => ar ? 'قيمة الخصم' : 'Discount amount';
  String get afterDiscount => ar ? 'السعر بعد الخصم' : 'Price after discount';
  String get taxAmount => ar ? 'قيمة الضريبة' : 'Tax amount';
  String get finalPrice => ar ? 'السعر النهائي' : 'Final price';
  String get youSave => ar ? 'وفّرت' : 'You save';
  String get clear => ar ? 'مسح' : 'Clear';
  String get hint => ar
      ? 'أدخل السعر ونسبة الخصم لمعرفة السعر النهائي'
      : 'Enter a price and discount to see the final price';
  String get taxSaved =>
      ar ? 'يتم حفظ نسبة الضريبة تلقائياً' : 'Tax rate is saved automatically';
}

class DiscountApp extends StatelessWidget {
  const DiscountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => S.of(c).title,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F9D58),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F9D58),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const _taxKey = 'tax_rate';
  final _price = TextEditingController();
  final _discount = TextEditingController();
  final _tax = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_price, _discount, _tax]) {
      c.addListener(() => setState(() {}));
    }
    _tax.addListener(_saveTax);
    _loadTax();
  }

  Future<void> _loadTax() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_taxKey);
    if (v != null && mounted) _tax.text = v;
  }

  Future<void> _saveTax() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_taxKey, _tax.text);
  }

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    _tax.dispose();
    super.dispose();
  }

  /// Parses user input, accepting Arabic-Indic digits and Arabic decimal comma.
  double _num(String s) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in s.trim().split('')) {
      final i = arabic.indexOf(ch);
      b.write(i >= 0 ? '$i' : (ch == '٫' || ch == ',' ? '.' : ch));
    }
    return double.tryParse(b.toString()) ?? 0;
  }

  String _fmt(double v) {
    var s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
    return s;
  }

  void _clear() {
    _price.clear();
    _discount.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    final price = _num(_price.text);
    final disc = _num(_discount.text).clamp(0, 100).toDouble();
    final taxRate = _num(_tax.text).clamp(0, 100).toDouble();
    final discAmt = price * disc / 100;
    final after = price - discAmt;
    final taxAmt = after * taxRate / 100;
    final total = after + taxAmt;
    final hasInput = price > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.title),
        actions: [
          IconButton(
            tooltip: s.clear,
            icon: const Icon(Icons.refresh),
            onPressed: _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_price, s.price, Icons.sell_outlined),
            const SizedBox(height: 12),
            _field(_discount, s.discount, Icons.percent),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [5, 10, 15, 20, 25, 30, 40, 50, 70].map((p) {
                final selected = _discount.text == '$p';
                return ChoiceChip(
                  label: Text('$p%'),
                  selected: selected,
                  onSelected: (_) => _discount.text = '$p',
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _field(_tax, s.tax, Icons.receipt_long_outlined,
                helper: s.taxSaved),
            const SizedBox(height: 20),
            if (!hasInput)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant)),
              )
            else
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row(s.discountAmount, '- ${_fmt(discAmt)}'),
                      _row(s.afterDiscount, _fmt(after)),
                      if (taxRate > 0) _row(s.taxAmount, '+ ${_fmt(taxAmt)}'),
                      const Divider(height: 24),
                      Text(s.finalPrice,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(_fmt(total),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold)),
                      if (discAmt > 0) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.savings_outlined, size: 18),
                          label: Text('${s.youSave} ${_fmt(discAmt)}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? helper}) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: c.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: c.clear,
              ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
