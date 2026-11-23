import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

String _t(BuildContext context, String fa, String ps, String en) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ps':
      return ps;
    case 'en':
      return en;
    default:
      return fa;
  }
}

/// تکمیل خودکار آگهی با هوش مصنوعی: کنار تکمیل دستی فرم قرار می‌گیرد.
/// کاربر عکس‌ها را انتخاب می‌کند و (اختیاری) چند کلمه می‌نویسد؛ فرم خودش پر می‌شود و کاربر فقط مرور می‌کند.
class AiAssistCard extends StatefulWidget {
  final List<Uint8List> Function() getImages;
  final Future<Map<String, dynamic>> Function(String text, List<Uint8List> images) fetchDraft;
  final void Function(Map<String, dynamic> draft) onApply;
  final Future<Uint8List?> Function(Uint8List image)? cleanImage;
  final void Function(int index, Uint8List bytes)? onReplaceImage;
  /// متنی که کاربر خودش در فرم نوشته (عنوان + توضیحات)؛ هوش مصنوعی از همین دسته، ولایت، قیمت و ... را درمی‌آورد.
  final String Function()? getFormText;

  const AiAssistCard({
    super.key,
    required this.getImages,
    required this.fetchDraft,
    required this.onApply,
    this.cleanImage,
    this.onReplaceImage,
    this.getFormText,
  });

  @override
  State<AiAssistCard> createState() => _AiAssistCardState();
}

class _AiAssistCardState extends State<AiAssistCard> {
  final TextEditingController _text = TextEditingController();
  bool _busy = false;
  bool _clean = false;
  String _status = '';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _errorText(Object e) {
    if (e is TimeoutException) {
      return _t(context, 'سرور دیر جواب داد (شاید تازه از خواب بیدار می‌شود). چند ثانیه بعد یک بار دیگر امتحان کنید.', 'سرور ناوخته ځواب ورکړ. څو ثانیې وروسته بیا هڅه وکړئ.', 'The server was slow to respond. Please try again in a few seconds.');
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _run() async {
    if (_busy) return;
    final images = widget.getImages();
    final text = [widget.getFormText?.call() ?? '', _text.text].where((t) => t.trim().isNotEmpty).join('\n').trim();
    if (images.isEmpty && text.length < 5) {
      _snack(_t(context, 'اول عکس‌های کالا را اضافه کنید یا چند کلمه درباره‌ی آن بنویسید.', 'لومړی د توکي انځورونه اضافه کړئ یا څو کلمې ولیکئ.', 'Add photos or write a few words about the item first.'));
      return;
    }
    setState(() {
      _busy = true;
      _status = _t(context, 'هوش مصنوعی در حال خواندن عکس‌ها و ساخت آگهی است...', 'مصنوعي هوښ انځورونه لولي او اعلان جوړوي...', 'AI is reading your photos and building the ad...');
    });
    try {
      final draft = await widget.fetchDraft(text, images);
      if (!mounted) return;
      widget.onApply(draft);
      final originals = List<Uint8List>.from(images);
      var cleaned = 0;
      final clean = widget.cleanImage;
      final replace = widget.onReplaceImage;
      if (_clean && clean != null && replace != null) {
        for (var i = 0; i < originals.length && i < 2; i++) {
          if (!mounted) return;
          setState(() => _status = _t(context, 'در حال تمیز کردن پس‌زمینه‌ی عکس ${i + 1}...', 'د ${i + 1} انځور شالید پاکول...', 'Cleaning the background of photo ${i + 1}...'));
          try {
            final out = await clean(originals[i]);
            if (out != null && mounted) {
              replace(i, out);
              cleaned++;
            }
          } catch (e) {
            _snack(_errorText(e));
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() => _status = '');
      final done = _t(context, 'فرم پر شد. لطفاً یک بار مرور و در صورت نیاز اصلاح کنید ✅', 'فورم ډک شو. مهرباني وکړئ یو ځل یې وګورئ ✅', 'Form filled. Please review it once ✅');
      if (cleaned > 0) {
        _snack(
          done,
          action: SnackBarAction(
            label: _t(context, 'برگرداندن عکس‌ها', 'انځورونه بېرته کړئ', 'Undo photos'),
            onPressed: () {
              final r = widget.onReplaceImage;
              if (r == null) return;
              for (var i = 0; i < cleaned && i < originals.length; i++) {
                r(i, originals[i]);
              }
            },
          ),
        );
      } else {
        _snack(done);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '');
      _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF3D1A9E), Color(0xFF7B3FE4)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.18), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(context, 'تکمیل خودکار با هوش مصنوعی', 'د مصنوعي هوښ سره اتوماتیک بشپړول', 'Auto-fill with AI'),
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          _t(context, 'عکس‌ها را اضافه کنید و همه‌ی معلومات (قیمت، ولایت، آدرس، واتساپ و...) را در بخش «توضیحات» همین فرم بنویسید؛ بعد دکمه‌ی زیر را بزنید. دسته، زیردسته، ولایت، قیمت و آدرس خودکار پر می‌شود. اگر قیمت نبود، «پیام بدهید یا تماس بگیرید» می‌آید.',
              'انځورونه پورته اضافه کړئ او (که غواړئ) څو کلمې ولیکئ. سرلیک، کټګورۍ، ولایت، تشریحات، بیه، واټساپ او پته په اتوماتیک ډول ډکېږي. یا فورم په لاس ډک کړئ.',
              'Add photos above and (optionally) a few words. Title, category, province, description, price, WhatsApp and address are filled automatically. Or fill the form manually.'),
          style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _text,
          minLines: 2,
          maxLines: 4,
          enabled: !_busy,
          decoration: InputDecoration(
            hintText: _t(context, 'مثلاً: بخاری ترکی ۴ شعله، ۱۲۰۰۰ افغانی، هرات، واتساپ ۰۷۸۸۳۵۶۶۷۵', 'لکه: ترکي بخاري، ۱۲۰۰۰ افغانۍ، هرات، واټساپ ۰۷۸۸۳۵۶۶۷۵', 'e.g. Turkish stove, 12000 AFN, Herat, WhatsApp 0788356675'),
            hintStyle: const TextStyle(fontSize: 12.5),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        if (widget.cleanImage != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(_t(context, 'پس‌زمینه‌ی عکس‌ها را تمیز کن (آزمایشی)', 'د انځورونو شالید پاک کړه (آزموینه)', 'Clean photo backgrounds (experimental)'),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            value: _clean,
            onChanged: _busy ? null : (v) => setState(() => _clean = v),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _busy ? null : _run,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD814), foregroundColor: const Color(0xFF111111), disabledBackgroundColor: Colors.white24),
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF111111)))
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_t(context, 'پر کردن خودکار فرم', 'فورم په اتوماتیک ډول ډک کړئ', 'Fill the form automatically'), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }
}
