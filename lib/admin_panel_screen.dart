import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



String _adminTranslate(BuildContext context, String input) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang != 'en' && lang != 'ps') return input;

  final en = <String, String>{
    'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.':'Please make sure you are connected to the internet and try again.',
    'تلاش دوباره':'Try Again','پاسخ نامعتبر از سرور':'Invalid server response','ورود مدیریت ناموفق بود.':'Admin login failed.','نشست مدیریت دریافت نشد.':'Admin session was not received.','خطا در دریافت اطلاعات.':'Failed to load information.','ساختار پاسخ سرور نامعتبر است.':'Invalid server response structure.','عملیات ناموفق بود.':'Operation failed.','حذف ناموفق بود.':'Delete failed.','ایمیل و رمز عبور مدیر را وارد کنید.':'Enter the admin email and password.','ورود مدیریت بازارک':'Bazarek Admin Login','پنل مدیریت':'Admin Panel','ایمیل مدیر':'Admin Email','رمز عبور':'Password','در حال ورود...':'Signing in...','ورود به پنل':'Sign In','عملیات با موفقیت انجام شد.':'Operation completed successfully.','ناشناس':'Unknown','آگهی':'Listing','دسته:':'Category:','ولایت:':'Province:','وضعیت:':'Status:','فعال':'Active','بسته/غیرفعال':'Closed/Inactive','بستن':'Close','حذف آگهی':'Delete Listing','انصراف':'Cancel','حذف':'Delete','آگهی حذف شد.':'Listing deleted.','لطفاً قوانین بازارک را رعایت کنید.':'Please follow Bazarek rules.','هشدار برای':'Warning for','متن هشدار':'Warning message','ارسال':'Send','هشدار برای کاربر ثبت شد.':'Warning sent to the user.','تخلف از قوانین بازارک':'Violation of Bazarek rules','رفع مسدودی':'Unblock User','مسدود کردن کاربر':'Block User','دسترسی این کاربر دوباره فعال شود؟':'Restore access for this user?','دلیل':'Reason','مدت (روز)؛ صفر = دائمی':'Duration (days); zero = permanent','مسدود کردن':'Block','مسدودی رفع شد.':'User unblocked.','کاربر مسدود شد.':'User blocked.','شارژ کیف پول توسط مدیریت':'Wallet top-up by admin','شارژ کیف پول':'Wallet Top-up','مبلغ افغانی':'Amount (AFN)','توضیح':'Description','شارژ':'Top Up','کیف پول شارژ شد.':'Wallet credited.','منقضی شده':'Expired','روز و':'days and','ساعت باقی‌مانده':'hours remaining','ساعت و':'hours and','دقیقه باقی‌مانده':'minutes remaining','دقیقه باقی‌مانده':'minutes remaining','ویژه‌سازی:':'Promotion:','ویژه:':'Featured:','پین:':'Pinned:','⚡ توربو هفتگی':'⚡ Weekly Turbo','👑 توربو ماهانه':'👑 Monthly Turbo','🏆 توربو سالانه':'🏆 Yearly Turbo','اشتراک پایه':'Basic Subscription','اشتراک حرفه‌ای':'Professional Subscription','اشتراک تجاری':'Business Subscription','شروع توربو: بعد از تأیید مدیریت':'Turbo starts after admin approval','شروع توربو:':'Turbo starts:','پایان توربو:':'Turbo ends:','ویژه / پین آگهی':'Featured / Pin Listing','روزهای ویژه':'Featured Days','روزهای پین':'Pin Days','ذخیره':'Save','وضعیت ویژه/پین ذخیره شد.':'Featured/Pin status saved.','آگهی شما به دلیل نقض قوانین بازارک بررسی و غیرفعال شد. لطفاً پیش از انتشار بعدی قوانین را رعایت کنید.':'Your listing was reviewed and disabled for violating Bazarek rules. Please follow the rules before publishing again.','رسیدگی به گزارش':'Review Report','صاحب آگهی:':'Listing owner:','شماره صاحب آگهی:':'Owner phone:','گزارش‌دهنده:':'Reporter:','شماره گزارش‌دهنده:':'Reporter phone:','دلیل گزارش:':'Report reason:','اگر تخلف تأیید شد، آگهی را ببند':'Disable the listing if the violation is confirmed','برای صاحب آگهی اخطار ارسال شود':'Send a warning to the listing owner','اگر گزارش درست بود، از گزارش‌دهنده تشکر کن':'Thank the reporter if the report is valid','یادداشت رسیدگی مدیر':'Admin resolution note','ثبت رسیدگی':'Submit Resolution','گزارش رسیدگی و اقدامات انتخاب‌شده ثبت شد.':'Report review and selected actions were saved.','پرداخت تأیید و ارتقا فعال شد.':'Payment approved and promotion activated.','وضعیت سفارش تغییر کرد.':'Order status updated.','اشتراک تأیید و فعال شد.':'Subscription approved and activated.','وضعیت اشتراک تغییر کرد.':'Subscription status updated.','تراکنش بایگانی شد.':'Transaction archived.','مدیریت بازارک':'Bazarek Admin','به‌روزرسانی':'Refresh','خروج':'Logout','داشبورد':'Dashboard','آگهی‌ها':'Listings','کاربران':'Users','شکایات':'Reports','پشتیبانی':'Support','هشدارها':'Warnings','مالی':'Finance','امنیت':'Security','خلاصه وضعیت':'Overview','شکایات باز':'Open Reports','مسدودها':'Blocked Users','درآمد ثبت‌شده':'Recorded Revenue','سفارش‌های ارتقای آگهی':'Listing Promotion Orders','اشتراک‌ها':'Subscriptions','امنیت مدیریت':'Admin Security','منطق درآمد':'Revenue Logic','فقط پرداخت‌های تأییدشده در درآمد حساب می‌شوند.':'Only approved payments are counted as revenue.','آگهی‌ای وجود ندارد':'No listings found','بدون عنوان':'Untitled','آگهی توسط مدیریت بازارک به دلیل بررسی قوانین غیرفعال شد.':'Listing disabled by Bazarek admin for rules review.','آگهی غیرفعال شد و تحت محدودیت مدیریت قرار گرفت.':'Listing disabled and placed under admin restriction.','آگهی فعال شد و محدودیت مدیریت برداشته شد.':'Listing activated and admin restriction removed.','مشاهده آگهی':'View Listing','🚫 غیرفعال کردن به دلیل قوانین':'🚫 Disable for rule violation','✅ فعال کردن و رفع محدودیت':'✅ Activate and remove restriction','ویژه / پین':'Featured / Pin','کاربری وجود ندارد':'No users found','ارسال هشدار':'Send Warning','گزارشی ثبت نشده است':'No reports found','آگهی حذف شده/نامشخص':'Deleted/Unknown Listing','صاحب:':'Owner:','دلیل:':'Reason:','تاریخ:':'Date:','رسیدگی کامل':'Full Review','گزارش رد شد.':'Report dismissed.','رد گزارش':'Dismiss Report','🐞 گزارش اشکال':'🐞 Bug Report','💡 پیشنهاد':'💡 Suggestion','📢 گزارش آگهی یا کاربر':'📢 Listing or User Report','💬 پشتیبانی':'💬 Support','جدید':'New','در حال بررسی':'Under Review','پاسخ داده شد':'Answered','حل شد':'Resolved','بسته شد':'Closed','درخواست پشتیبانی':'Support Request','نوع:':'Type:','شماره:':'Phone:','متن کاربر:':'User Message:','وضعیت':'Status','پاسخ مدیر':'Admin Reply','پاسخ خود را برای کاربر بنویسید...':'Write your reply to the user...','ذخیره و ارسال پاسخ':'Save & Send Reply','پاسخ پشتیبانی ثبت شد.':'Support reply saved.','درخواست پشتیبانی وجود ندارد':'No support requests','هشداری ثبت نشده است':'No warnings found','درآمد واقعی':'Actual Revenue','در انتظار تأیید':'Pending Approval','سفارش‌های ارتقا':'Promotion Orders','سفارشی وجود ندارد':'No orders found','ارتقا':'Promotion','تأیید پرداخت':'Approve Payment','رد پرداخت':'Reject Payment','لغو سفارش':'Cancel Order','تأیید و فعال‌سازی':'Approve & Activate','رد درخواست':'Reject Request','لغو':'Cancel','تراکنش‌های کیف پول':'Wallet Transactions','تراکنش فعال وجود ندارد':'No active transactions','بایگانی':'Archive','تراکنش بایگانی‌شده از فهرست اصلی حذف می‌شود و برای جلوگیری از به‌هم‌ریختگی گزارش مالی، رکورد اصلی پاک نمی‌شود.':'Archived transactions are removed from the main list; the original record is kept to preserve financial reporting.','هنوز رویداد امنیتی ثبت نشده است':'No security events recorded yet','ورود موفق مدیریت':'Successful admin login','تلاش ناموفق ورود مدیریت':'Failed admin login','ایمیل:':'Email:','IP:':'IP:','باز':'Open','بررسی‌شده':'Reviewed','ردشده':'Rejected','توافقی':'Negotiable','جستجو در این بخش...':'Search this section...','افغانی':'AFN','کاربر:':'User:','آگهی:':'Listing:','رسید/پیگیری:':'Receipt/Reference:','ثبت سفارش:':'Order created:','تأیید و شروع:':'Approved & started:','پایان Boost:':'Boost ends:','شروع توربو:':'Turbo starts:','اشتراک':'Subscription','تراکنش':'Transaction','پاسخ شما:':'Your reply:','پاسخ نامعتبر':'Invalid response','درآمد':'Revenue','مورد در انتظار بررسی':'items pending review','درخواست در انتظار بررسی':'requests pending review','گزارش باز':'open reports','ورود اخیر ثبت شده':'recent logins recorded','محدودیت مدیریت':'Admin restriction','ویژه':'Featured','پین':'Pinned','غیرفعال':'Inactive','گزارش آگهی یا کاربر':'Listing or user report','ک':'U','آگهی‌های':'Listings by','محصولات فروشگاه':'Store products',
  };
  final ps = <String, String>{
    'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.':'مهرباني وکړئ د انټرنېټ له وصلېدو ډاډ ترلاسه کړئ او بیا هڅه وکړئ.','تلاش دوباره':'بیا هڅه','پاسخ نامعتبر از سرور':'د سرور ناسم ځواب','ورود مدیریت ناموفق بود.':'د مدیر ننوتل ناکام شول.','نشست مدیریت دریافت نشد.':'د مدیر ناسته ترلاسه نه شوه.','خطا در دریافت اطلاعات.':'د معلوماتو ترلاسه کولو کې تېروتنه.','ساختار پاسخ سرور نامعتبر است.':'د سرور د ځواب جوړښت ناسم دی.','عملیات ناموفق بود.':'عملیات ناکام شو.','حذف ناموفق بود.':'حذف ناکام شو.','ایمیل و رمز عبور مدیر را وارد کنید.':'د مدیر برېښنالیک او پټنوم دننه کړئ.','ورود مدیریت بازارک':'د بازارک مدیر ننوتل','پنل مدیریت':'د مدیریت پینل','ایمیل مدیر':'د مدیر برېښنالیک','رمز عبور':'پټنوم','در حال ورود...':'ننوتل...','ورود به پنل':'پینل ته ننوتل','عملیات با موفقیت انجام شد.':'عملیات په بریالیتوب بشپړ شو.','ناشناس':'ناپېژندل شوی','آگهی':'اعلان','دسته:':'کټګوري:','ولایت:':'ولایت:','وضعیت:':'حالت:','فعال':'فعال','بسته/غیرفعال':'بند/غیرفعال','بستن':'بندول','حذف آگهی':'اعلان حذفول','انصراف':'لغوه','حذف':'حذفول','آگهی حذف شد.':'اعلان حذف شو.','لطفاً قوانین بازارک را رعایت کنید.':'مهرباني وکړئ د بازارک اصول مراعات کړئ.','هشدار برای':'خبرداری د','متن هشدار':'د خبرداري متن','ارسال':'لېږل','هشدار برای کاربر ثبت شد.':'کارونکي ته خبرداری ولېږل شو.','تخلف از قوانین بازارک':'د بازارک د اصولو سرغړونه','رفع مسدودی':'د کارونکي بندیز لرې کول','مسدود کردن کاربر':'کارونکی بندول','دسترسی این کاربر دوباره فعال شود؟':'د دې کارونکي لاسرسی بېرته فعال شي؟','دلیل':'دلیل','مدت (روز)؛ صفر = دائمی':'موده (ورځې)؛ صفر = دایمي','مسدود کردن':'بندول','مسدودی رفع شد.':'د کارونکي بندیز لرې شو.','کاربر مسدود شد.':'کارونکی بند شو.','شارژ کیف پول توسط مدیریت':'د مدیریت له خوا د والټ چارج','شارژ کیف پول':'والټ چارج','مبلغ افغانی':'مبلغ (AFN)','توضیح':'تشریح','شارژ':'چارج','کیف پول شارژ شد.':'والټ چارج شو.','منقضی شده':'ختم شوی','روز و':'ورځې او','ساعت باقی‌مانده':'ساعتې پاتې','ساعت و':'ساعتې او','دقیقه باقی‌مانده':'دقیقې پاتې','ویژه‌سازی:':'ځانګړی کول:','ویژه:':'ځانګړی:','پین:':'پین:','⚡ توربو هفتگی':'⚡ اوونیز توربو','👑 توربو ماهانه':'👑 میاشتنی توربو','🏆 توربو سالانه':'🏆 کلنی توربو','اشتراک پایه':'اساسي ګډون','اشتراک حرفه‌ای':'مسلکي ګډون','اشتراک تجاری':'سوداګریز ګډون','شروع توربو: بعد از تأیید مدیریت':'توربو د مدیر له تایید وروسته پیلېږي','شروع توربو:':'د توربو پیل:','پایان توربو:':'د توربو پای:','ویژه / پین آگهی':'ځانګړی / د اعلان پین','روزهای ویژه':'ځانګړې ورځې','روزهای پین':'د پین ورځې','ذخیره':'ساتل','وضعیت ویژه/پین ذخیره شد.':'د ځانګړي/پین حالت خوندي شو.','رسیدگی به گزارش':'د راپور کتنه','صاحب آگهی:':'د اعلان مالک:','شماره صاحب آگهی:':'د مالک شمېره:','گزارش‌دهنده:':'راپور ورکوونکی:','شماره گزارش‌دهنده:':'د راپور ورکوونکي شمېره:','دلیل گزارش:':'د راپور دلیل:','اگر تخلف تأیید شد، آگهی را ببند':'که سرغړونه تایید شي، اعلان بند کړئ','برای صاحب آگهی اخطار ارسال شود':'د اعلان مالک ته خبرداری ولېږئ','اگر گزارش درست بود، از گزارش‌دهنده تشکر کن':'که راپور سم وي، له راپور ورکوونکي مننه وکړئ','یادداشت رسیدگی مدیر':'د مدیر د کتنې یادښت','ثبت رسیدگی':'کتنه ثبتول','گزارش رسیدگی و اقدامات انتخاب‌شده ثبت شد.':'د راپور کتنه او ټاکل شوي اقدامات ثبت شول.','پرداخت تأیید و ارتقا فعال شد.':'تادیه تایید او ترفیع فعاله شوه.','وضعیت سفارش تغییر کرد.':'د امر حالت بدل شو.','اشتراک تأیید و فعال شد.':'ګډون تایید او فعال شو.','وضعیت اشتراک تغییر کرد.':'د ګډون حالت بدل شو.','تراکنش بایگانی شد.':'راکړه ورکړه آرشیف شوه.','مدیریت بازارک':'د بازارک مدیریت','به‌روزرسانی':'تازه کول','خروج':'وتل','داشبورد':'ډشبورډ','آگهی‌ها':'اعلانونه','کاربران':'کاروونکي','شکایات':'راپورونه','پشتیبانی':'ملاتړ','هشدارها':'خبرداریونه','مالی':'مالي','امنیت':'امنیت','خلاصه وضعیت':'د حالت لنډیز','شکایات باز':'خلاص راپورونه','مسدودها':'بند شوي کاروونکي','درآمد ثبت‌شده':'ثبت شوی عاید','سفارش‌های ارتقای آگهی':'د اعلان د ترفیع غوښتنې','اشتراک‌ها':'ګډونونه','امنیت مدیریت':'د مدیر امنیت','منطق درآمد':'د عاید منطق','فقط پرداخت‌های تأییدشده در درآمد حساب می‌شوند.':'یوازې تایید شوې تادیې په عاید کې حسابېږي.','آگهی‌ای وجود ندارد':'هیڅ اعلان نشته','بدون عنوان':'بې سرلیک','مشاهده آگهی':'اعلان وګورئ','ویژه / پین':'ځانګړی / پین','کاربری وجود ندارد':'هیڅ کارونکی نشته','ارسال هشدار':'خبرداری لېږل','گزارشی ثبت نشده است':'هیڅ راپور نه دی ثبت شوی','آگهی حذف شده/نامشخص':'حذف شوی/نامعلوم اعلان','صاحب:':'مالک:','دلیل:':'دلیل:','تاریخ:':'نېټه:','رسیدگی کامل':'بشپړه کتنه','گزارش رد شد.':'راپور رد شو.','رد گزارش':'راپور ردول','🐞 گزارش اشکال':'🐞 د ستونزې راپور','💡 پیشنهاد':'💡 وړاندیز','📢 گزارش آگهی یا کاربر':'📢 د اعلان یا کارونکي راپور','💬 پشتیبانی':'💬 ملاتړ','جدید':'نوی','در حال بررسی':'د کتنې په حال کې','پاسخ داده شد':'ځواب ورکړل شو','حل شد':'حل شو','بسته شد':'بند شو','درخواست پشتیبانی':'د ملاتړ غوښتنه','نوع:':'ډول:','شماره:':'شمېره:','متن کاربر:':'د کارونکي متن:','پاسخ مدیر':'د مدیر ځواب','پاسخ خود را برای کاربر بنویسید...':'خپل ځواب کارونکي ته ولیکئ...','ذخیره و ارسال پاسخ':'ځواب خوندي او ولېږئ','پاسخ پشتیبانی ثبت شد.':'د ملاتړ ځواب ثبت شو.','درخواست پشتیبانی وجود ندارد':'هیڅ د ملاتړ غوښتنه نشته','هشداری ثبت نشده است':'هیڅ خبرداری نشته','درآمد واقعی':'اصلي عاید','در انتظار تأیید':'د تایید په تمه','سفارش‌های ارتقا':'د ترفیع غوښتنې','سفارشی وجود ندارد':'هیڅ غوښتنه نشته','ارتقا':'ترفیع','تأیید پرداخت':'تادیه تاییدول','رد پرداخت':'تادیه ردول','لغو سفارش':'غوښتنه لغوه کول','تأیید و فعال‌سازی':'تایید او فعالول','رد درخواست':'غوښتنه ردول','لغو':'لغوه','تراکنش‌های کیف پول':'د والټ راکړې ورکړې','تراکنش فعال وجود ندارد':'هیڅ فعاله راکړه ورکړه نشته','بایگانی':'آرشیف','هنوز رویداد امنیتی ثبت نشده است':'تر اوسه امنیتي پېښه نه ده ثبت شوې','ورود موفق مدیریت':'د مدیر بریالی ننوتل','تلاش ناموفق ورود مدیریت':'د مدیر د ننوتلو ناکامه هڅه','ایمیل:':'برېښنالیک:','باز':'خلاص','بررسی‌شده':'کتل شوی','ردشده':'رد شوی','توافقی':'د هوکړې بیه','جستجو در این بخش...':'په دې برخه کې لټون...','افغانی':'AFN','کاربر:':'کارونکی:','آگهی:':'اعلان:','رسید/پیگیری:':'رسید/تعقیب:','ثبت سفارش:':'غوښتنه ثبت شوه:','تأیید و شروع:':'تایید او پیل:','پایان Boost:':'د Boost پای:','اشتراک':'ګډون','تراکنش':'راکړه ورکړه','محدودیت مدیریت':'د مدیریت محدودیت','ویژه':'ځانګړی','پین':'پین','غیرفعال':'غیرفعال','ک':'ک','مبلغ':'مبلغ',
  };
  final map = lang == 'en' ? en : ps;
  var out = input;
  final keys = map.keys.toList()..sort((a,b) => b.length.compareTo(a.length));
  for (final k in keys) out = out.replaceAll(k, map[k]!);
  if (lang == 'en') {
    out = out.replaceAll(RegExp(r'\b[۰-۹]+\b'), (m) => m.group(0)!.split('').map((c) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(c).toString()).join());
  }
  return out;
}

class AdminText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  const AdminText(this.data, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  @override Widget build(BuildContext context) => Text(_adminTranslate(context, data), style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
}

String _adminFriendlyError(Object error) {
  final raw = error.toString().toLowerCase();
  final networkFailure = raw.contains('failed to fetch') ||
      raw.contains('clientexception') ||
      raw.contains('socketexception') ||
      raw.contains('connection refused') ||
      raw.contains('connection reset') ||
      raw.contains('network is unreachable') ||
      raw.contains('no internet') ||
      raw.contains('network error') ||
      raw.contains('timed out') ||
      raw.contains('timeout') ||
      raw.contains('failed host lookup') ||
      raw.contains('connection closed') ||
      raw.contains('connection terminated');
  return networkFailure
      ? 'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.'
      : error.toString().replaceFirst('Exception: ', '');
}

class _AdminOfflineError extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  _AdminOfflineError({required this.onRetry, this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 52),
        SizedBox(height: 14),
        AdminText(message ?? 'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 14),
        FilledButton.icon(onPressed: onRetry, icon: Icon(Icons.refresh_rounded), label: AdminText('تلاش دوباره')),
      ]),
    ),
  );
}

class _AdminApi {
  static baseUrl = 'https://bazarek.onrender.com/api';
  static Map<String, String> headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic decode(http.Response r) {
    try { return jsonDecode(r.body); } catch (_) { throw Exception('پاسخ نامعتبر از سرور (${r.statusCode})'); }
  }

  static Future<String> login(String email, String password) async {
    final r = await http.post(Uri.parse('$baseUrl/admin/login'), headers: headers(), body: jsonEncode({'email': email, 'password': password}));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'ورود مدیریت ناموفق بود.') : 'ورود مدیریت ناموفق بود.');
    final token = d['token']?.toString();
    if (token == null || token.isEmpty) throw Exception('نشست مدیریت دریافت نشد.');
    return token;
  }

  static Future<List<Map<String, dynamic>>> list(String path, String token) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers(token));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'خطا در دریافت اطلاعات.') : 'خطا در دریافت اطلاعات.');
    if (d is! List) throw Exception('ساختار پاسخ سرور نامعتبر است.');
    return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> map(String path, String token) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers(token));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'خطا در دریافت اطلاعات.') : 'خطا در دریافت اطلاعات.');
    return Map<String, dynamic>.from(d as Map);
  }

  static Future<void> patch(String path, String token, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$baseUrl$path'), headers: headers(token), body: jsonEncode(body));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'عملیات ناموفق بود.') : 'عملیات ناموفق بود.');
  }

  static Future<void> post(String path, String token, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$baseUrl$path'), headers: headers(token), body: jsonEncode(body));
    final d = decode(r);
    if (r.statusCode != 200 && r.statusCode != 201) throw Exception(d is Map ? (d['error'] ?? 'عملیات ناموفق بود.') : 'عملیات ناموفق بود.');
  }

  static Future<void> delete(String path, String token) async {
    final r = await http.delete(Uri.parse('$baseUrl$path'), headers: headers(token));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'حذف ناموفق بود.') : 'حذف ناموفق بود.');
  }
}

class AdminPanelScreen extends StatelessWidget {
  AdminPanelScreen({super.key});
  @override
  Widget build(BuildContext context) => _AdminLoginScreen();
}

class _AdminLoginScreen extends StatefulWidget {
  _AdminLoginScreen();
  @override State<_AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<_AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) { _message('ایمیل و رمز عبور مدیر را وارد کنید.'); return; }
    setState(() => loading = true);
    try {
      final token = await _AdminApi.login(email.text.trim(), password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _AdminDashboard(token: token)));
    } catch (e) { _message(_adminFriendlyError(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: AdminText(text), backgroundColor: Colors.red));
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: AdminText('ورود مدیریت بازارک')),
    body: Center(child: SingleChildScrollView(padding: EdgeInsets.all(24), child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 460), child: Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [
      Icon(Icons.admin_panel_settings, size: 72), SizedBox(height: 16),
      AdminText('پنل مدیریت', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 8),
      SizedBox(height: 8), SizedBox(height: 24),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: _adminTranslate(context, 'ایمیل مدیر'), prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
      SizedBox(height: 16),
      TextField(controller: password, obscureText: obscure, onSubmitted: (_) => _login(), decoration: InputDecoration(labelText: _adminTranslate(context, 'رمز عبور'), prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
      SizedBox(height: 22),
      SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: loading ? null : _login, icon: loading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.login), label: AdminText(loading ? 'در حال ورود...' : 'ورود به پنل'))),
    ]))))),
  ));
}

class _AdminDashboard extends StatefulWidget {
  final String token;
  _AdminDashboard({required this.token});
  @override State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController tabs;
  bool loading = true;
  String? loadError;
  Map<String, dynamic> stats = {}, money = {};
  List<Map<String, dynamic>> users = [], products = [], reports = [], warnings = [], support = [], securityEvents = [];
  Timer? _clockTimer;

  @override void initState() {
    super.initState();
    tabs = TabController(length: 8, vsync: this);
    _loadAll();
    _clockTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }
  @override void dispose() { _clockTimer?.cancel(); tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { loading = true; loadError = null; });
    try {
      final results = await Future.wait([
        _AdminApi.map('/admin/stats', widget.token),
        _AdminApi.list('/admin/users', widget.token),
        _AdminApi.list('/admin/products', widget.token),
        _AdminApi.list('/admin/reports', widget.token),
        _AdminApi.list('/admin/warnings', widget.token),
        _AdminApi.list('/admin/support/requests', widget.token),
        _AdminApi.map('/admin/monetization', widget.token),
        _AdminApi.list('/admin/security/events', widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(results[0] as Map);
        users = List<Map<String, dynamic>>.from(results[1] as List);
        products = List<Map<String, dynamic>>.from(results[2] as List);
        reports = List<Map<String, dynamic>>.from(results[3] as List);
        warnings = List<Map<String, dynamic>>.from(results[4] as List);
        support = List<Map<String, dynamic>>.from(results[5] as List);
        money = Map<String, dynamic>.from(results[6] as Map);
        securityEvents = List<Map<String, dynamic>>.from(results[7] as List);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; loadError = _adminFriendlyError(e); });
    }
  }

  Future<void> _run(Future<void> Function() action, {String success = 'عملیات با موفقیت انجام شد.'}) async {
    try { await action(); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: AdminText(success), backgroundColor: Colors.green)); await _loadAll(); }
    catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: AdminText(_adminFriendlyError(e)), backgroundColor: Colors.red)); }
  }

  String _person(Map<String, dynamic>? p, {String fallback = 'ناشناس'}) {
    if (p == null) return fallback;
    final shop = p['shop_name']?.toString().trim() ?? '';
    final name = p['full_name']?.toString().trim() ?? '';
    return shop.isNotEmpty ? '$shop ($name)' : (name.isNotEmpty ? name : fallback);
  }

  Future<void> _showListing(Map<String, dynamic> p) async {
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: AdminText(p['title']?.toString() ?? 'آگهی'),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _productImage(p, height: 210, width: double.infinity), SizedBox(height: 12),
        AdminText('${NumberFormatLike.listing(p)}', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        AdminText('دسته: ${p['category'] ?? '-'}${p['subcategory']?.toString().isNotEmpty == true ? ' / ${p['subcategory']}' : ''}'),
        AdminText('ولایت: ${p['province'] ?? '-'}'), SizedBox(height: 8),
        AdminText(p['description']?.toString() ?? '-', maxLines: 12, overflow: TextOverflow.ellipsis),
        SizedBox(height: 10), AdminText('وضعیت: ${p['is_active'] == true ? 'فعال' : 'بسته/غیرفعال'}'),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: AdminText('بستن'))],
    ));
  }

  Future<void> _confirmDelete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: AdminText('حذف آگهی'), content: AdminText('آگهی «${p['title'] ?? ''}» حذف شود؟ این عملیات قابل برگشت نیست.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: AdminText('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: AdminText('حذف'))]));
    if (ok == true) await _run(() => _AdminApi.delete('/admin/products/${p['id']}', widget.token), success: 'آگهی حذف شد.');
  }

  Future<void> _warnUser(Map<String, dynamic> u, {String? preset}) async {
    final c = TextEditingController(text: preset ?? 'لطفاً قوانین بازارک را رعایت کنید.');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: AdminText('هشدار برای ${_person(u)}'), content: TextField(controller: c, maxLines: 5, decoration: InputDecoration(labelText: _adminTranslate(context, 'متن هشدار'), border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: AdminText('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: AdminText('ارسال'))]));
    if (ok == true && c.text.trim().isNotEmpty) await _run(() => _AdminApi.post('/admin/users/${u['id']}/warnings', widget.token, {'message': c.text.trim()}), success: 'هشدار برای کاربر ثبت شد.');
    c.dispose();
  }

  Future<void> _blockUser(Map<String, dynamic> u) async {
    final blocked = u['is_blocked'] == true;
    final reason = TextEditingController(text: blocked ? '' : 'تخلف از قوانین بازارک');
    final days = TextEditingController(text: '7');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: AdminText(blocked ? 'رفع مسدودی' : 'مسدود کردن کاربر'), content: blocked ? AdminText('دسترسی این کاربر دوباره فعال شود؟') : Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: reason, decoration: InputDecoration(labelText: _adminTranslate(context, 'دلیل'))), SizedBox(height: 10), TextField(controller: days, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _adminTranslate(context, 'مدت (روز)؛ صفر = دائمی')))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: AdminText('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: AdminText(blocked ? 'رفع مسدودی' : 'مسدود کردن'))]));
    if (ok == true) await _run(() => _AdminApi.patch('/admin/users/${u['id']}/block', widget.token, {'blocked': !blocked, 'duration_days': int.tryParse(days.text) ?? 0, 'reason': reason.text.trim()}), success: blocked ? 'مسدودی رفع شد.' : 'کاربر مسدود شد.');
    reason.dispose(); days.dispose();
  }

  Future<void> _creditWallet(Map<String, dynamic> u) async {
    final amount = TextEditingController(); final desc = TextEditingController(text: 'شارژ کیف پول توسط مدیریت');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: AdminText('شارژ کیف پول ${_person(u)}'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _adminTranslate(context, 'مبلغ افغانی'))), SizedBox(height: 10), TextField(controller: desc, decoration: InputDecoration(labelText: _adminTranslate(context, 'توضیح')))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: AdminText('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: AdminText('شارژ'))]));
    if (ok == true) await _run(() => _AdminApi.post('/admin/wallets/${u['id']}/credit', widget.token, {'amount_afn': int.tryParse(amount.text) ?? 0, 'description': desc.text.trim()}), success: 'کیف پول شارژ شد.');
    amount.dispose(); desc.dispose();
  }

  String _dateTimeAdminText(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final dt = DateTime.tryParse(value.toString())?.toLocal();
    if (dt == null) return value.toString();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _remainingTime(dynamic until) {
    if (until == null || until.toString().trim().isEmpty) return '';
    final end = DateTime.tryParse(until.toString())?.toLocal();
    if (end == null) return '';
    final diff = end.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 'منقضی شده';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    if (days > 0) return '$days روز و $hours ساعت باقی‌مانده';
    if (hours > 0) return '$hours ساعت و $minutes دقیقه باقی‌مانده';
    return '$minutes دقیقه باقی‌مانده';
  }

  String _boostTiming(Map<String, dynamic> p) {
    final until = p['boost_until'];
    final featuredUntil = p['featured_until'];
    final pinnedUntil = p['pinned_until'];
    final parts = <String>[];
    final boost = _remainingTime(until);
    final featured = _remainingTime(featuredUntil);
    final pinned = _remainingTime(pinnedUntil);
    if (boost.isNotEmpty) parts.add('ویژه‌سازی: $boost');
    if (featured.isNotEmpty && featured != boost) parts.add('ویژه: $featured');
    if (pinned.isNotEmpty && pinned != boost) parts.add('پین: $pinned');
    return parts.join(' • ');
  }

  String _subscriptionPlanTitle(dynamic plan) {
    switch (plan?.toString()) {
      case 'boost_weekly': return '⚡ توربو هفتگی';
      case 'boost_monthly': return '👑 توربو ماهانه';
      case 'boost_yearly': return '🏆 توربو سالانه';
      case 'basic': return 'اشتراک پایه';
      case 'pro': return 'اشتراک حرفه‌ای';
      case 'business': return 'اشتراک تجاری';
      default: return plan?.toString() ?? '-';
    }
  }

  String _subscriptionTiming(Map<String, dynamic> s) {
    final status = s['status']?.toString() ?? '';
    if (status == 'pending') return 'شروع توربو: بعد از تأیید مدیریت';
    final start = _dateTimeAdminText(s['starts_at']);
    final endDate = _dateTimeAdminText(s['ends_at']);
    final remaining = _remainingTime(s['ends_at']);
    if (start.isEmpty && endDate.isEmpty) return '';
    final parts = <String>[];
    if (start.isNotEmpty) parts.add('شروع توربو: $start');
    if (endDate.isNotEmpty) parts.add('پایان توربو: $endDate');
    if (remaining.isNotEmpty) parts.add(remaining);
    return parts.join(' • ');
  }

  Future<void> _promotion(Map<String, dynamic> p) async {
    final feature = TextEditingController(text: p['is_featured'] == true ? '7' : '0'); final pin = TextEditingController(text: p['is_pinned'] == true ? '7' : '0');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: AdminText('ویژه / پین آگهی'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: feature, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _adminTranslate(context, 'روزهای ویژه'))), SizedBox(height: 12), TextField(controller: pin, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _adminTranslate(context, 'روزهای پین')))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: AdminText('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: AdminText('ذخیره'))]));
    if (ok == true) await _run(() => _AdminApi.patch('/admin/products/${p['id']}/promotion', widget.token, {'feature_days': int.tryParse(feature.text) ?? 0, 'pin_days': int.tryParse(pin.text) ?? 0}), success: 'وضعیت ویژه/پین ذخیره شد.');
    feature.dispose(); pin.dispose();
  }

  Future<void> _reportAction(Map<String, dynamic> r) async {
    final listing = r['listing'] is Map ? Map<String, dynamic>.from(r['listing']) : null;
    final owner = r['listing_owner'] is Map ? Map<String, dynamic>.from(r['listing_owner']) : null;
    final reporter = r['reporter'] is Map ? Map<String, dynamic>.from(r['reporter']) : null;
    bool disable = false, thank = false, sendWarning = false;
    final warning = TextEditingController(text: 'آگهی شما به دلیل نقض قوانین بازارک بررسی و غیرفعال شد. لطفاً پیش از انتشار بعدی قوانین را رعایت کنید.');
    final note = TextEditingController();
    final valid = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: AdminText('رسیدگی به گزارش'),
      content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (listing != null) _productImage(listing, height: 180, width: double.infinity),
        SizedBox(height: 10), AdminText('آگهی: ${listing?['title'] ?? r['listing_id'] ?? '-'}', style: TextStyle(fontWeight: FontWeight.bold)),
        AdminText('صاحب آگهی: ${_person(owner)}'), AdminText('شماره صاحب آگهی: ${owner?['phone'] ?? '-'}'),
        AdminText('گزارش‌دهنده: ${_person(reporter)}'), AdminText('شماره گزارش‌دهنده: ${reporter?['phone'] ?? '-'}'),
        SizedBox(height: 8), AdminText('دلیل گزارش: ${r['reason'] ?? '-'}'), SizedBox(height: 12),
        CheckboxListTile(value: disable, onChanged: (v) => setLocal(() => disable = v == true), contentPadding: EdgeInsets.zero, title: AdminText('اگر تخلف تأیید شد، آگهی را ببند')),
        CheckboxListTile(value: sendWarning, onChanged: (v) => setLocal(() => sendWarning = v == true), contentPadding: EdgeInsets.zero, title: AdminText('برای صاحب آگهی اخطار ارسال شود')),
        CheckboxListTile(value: thank, onChanged: (v) => setLocal(() => thank = v == true), contentPadding: EdgeInsets.zero, title: AdminText('اگر گزارش درست بود، از گزارش‌دهنده تشکر کن${reporter == null ? ' (اطلاعات کاربر موجود نیست)' : ''}')),
        if (sendWarning) TextField(controller: warning, maxLines: 4, decoration: InputDecoration(labelText: _adminTranslate(context, 'متن هشدار'), border: OutlineInputBorder())),
        SizedBox(height: 10), TextField(controller: note, maxLines: 3, decoration: InputDecoration(labelText: _adminTranslate(context, 'یادداشت رسیدگی مدیر'), border: OutlineInputBorder())),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: AdminText('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: AdminText('ثبت رسیدگی'))],
    )));
    if (valid == true) {
      await _run(() => _AdminApi.post('/admin/reports/${r['id']}/action', widget.token, {
        'status': 'reviewed', 'disable_listing': disable, 'thank_reporter': thank,
        'warning_message': sendWarning ? warning.text.trim() : '', 'resolution_note': note.text.trim()
      }), success: 'گزارش رسیدگی و اقدامات انتخاب‌شده ثبت شد.');
    }
    warning.dispose(); note.dispose();
  }

  Future<void> _orderStatus(Map<String, dynamic> o, String status) => _run(() => _AdminApi.patch('/admin/promotions/orders/${o['id']}', widget.token, {'status': status}), success: status == 'paid' ? 'پرداخت تأیید و ارتقا فعال شد.' : 'وضعیت سفارش تغییر کرد.');
  Future<void> _subscriptionStatus(Map<String, dynamic> s, String status) => _run(() => _AdminApi.patch('/admin/subscriptions/${s['id']}', widget.token, {'status': status}), success: status == 'active' ? 'اشتراک تأیید و فعال شد.' : 'وضعیت اشتراک تغییر کرد.');
  Future<void> _archiveTransaction(Map<String, dynamic> t) => _run(() => _AdminApi.patch('/admin/transactions/${t['id']}/archive', widget.token, {}), success: 'تراکنش بایگانی شد.');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: AdminText('مدیریت بازارک', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [IconButton(onPressed: _loadAll, icon: Icon(Icons.refresh), tooltip: _adminTranslate(context, 'به‌روزرسانی')), IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.logout), tooltip: _adminTranslate(context, 'خروج'))],
      bottom: TabBar(controller: tabs, isScrollable: true, tabs: [
        Tab(text: _adminTranslate(context, 'داشبورد'), icon: Icon(Icons.dashboard_outlined)), Tab(text: _adminTranslate(context, 'آگهی‌ها'), icon: Icon(Icons.campaign_outlined)), Tab(text: _adminTranslate(context, 'کاربران'), icon: Icon(Icons.people_outline)), Tab(text: _adminTranslate(context, 'شکایات'), icon: Icon(Icons.report_problem_outlined)), Tab(text: _adminTranslate(context, 'پشتیبانی'), icon: Icon(Icons.support_agent_outlined)), Tab(text: _adminTranslate(context, 'هشدارها'), icon: Icon(Icons.notifications_outlined)), Tab(text: _adminTranslate(context, 'مالی'), icon: Icon(Icons.account_balance_wallet_outlined)), Tab(text: _adminTranslate(context, 'امنیت'), icon: Icon(Icons.security_outlined)),
      ]),
    ),
    body: loading ? Center(child: CircularProgressIndicator()) : loadError != null ? _ErrorState(error: loadError!, retry: _loadAll) : TabBarView(controller: tabs, children: [_overview(), _products(), _users(), _reports(), _support(), _warnings(), _finance(), _security()]),
  );

  void _go(int index) => tabs.animateTo(index);

  Widget _overview() {
    final openReports = reports.where((x) => x['status'] == 'open').length;
    final blocked = users.where((x) => x['is_blocked'] == true).length;
    final pendingOrders = (money['orders'] as List? ?? []).where((x) => x is Map && x['status'] == 'pending').length;
    final pendingSubs = (money['subscriptions'] as List? ?? []).where((x) => x is Map && x['status'] == 'pending').length;
    final revenue = NumberFormatLike.afn(money['revenue_afn']);
    return RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: EdgeInsets.all(16), children: [
      AdminText('خلاصه وضعیت', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 14),
      GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45, children: [
        _clickStat('کاربران', stats['users'] ?? users.length, Icons.people, 2), _clickStat('آگهی‌ها', stats['products'] ?? products.length, Icons.campaign, 1), _clickStat('شکایات باز', openReports, Icons.report_problem, 3), _clickStat('مسدودها', blocked, Icons.block, 2),
      ]),
      SizedBox(height: 18),
      _dashboardCard(Icons.payments_outlined, 'درآمد ثبت‌شده', '$revenue افغانی', 5),
      _dashboardCard(Icons.pending_actions, 'سفارش‌های ارتقای آگهی', '$pendingOrders مورد در انتظار بررسی', 5),
      _dashboardCard(Icons.subscriptions_outlined, 'اشتراک‌ها', '$pendingSubs درخواست در انتظار بررسی', 5),
      _dashboardCard(Icons.report_gmailerrorred_outlined, 'شکایات', '$openReports گزارش باز', 3),
      _dashboardCard(Icons.security_outlined, 'امنیت مدیریت', '${securityEvents.length} ورود اخیر ثبت شده', 6),
      Card(child: ListTile(leading: Icon(Icons.info_outline), title: AdminText('منطق درآمد'), subtitle: AdminText('فقط پرداخت‌های تأییدشده در درآمد حساب می‌شوند. پرداخت‌های در انتظار بررسی: ${NumberFormatLike.afn(money['pending_afn'])} افغانی.'))),
    ]));
  }

  Widget _clickStat(String title, dynamic value, IconData icon, int index) => InkWell(onTap: () => _go(index), borderRadius: BorderRadius.circular(16), child: _stat(title, value, icon));
  Widget _dashboardCard(IconData icon, String title, String subtitle, int index) => Card(child: InkWell(onTap: () => _go(index), borderRadius: BorderRadius.circular(16), child: ListTile(leading: Icon(icon, size: 36), title: AdminText(title, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: AdminText(subtitle), trailing: Icon(Icons.chevron_left))));
  Widget _stat(String title, dynamic value, IconData icon) => Card(child: Padding(padding: EdgeInsets.all(14), child: Row(children: [Icon(icon, size: 32), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AdminText(title), SizedBox(height: 4), AdminText('$value', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))]))])));

  Widget _products() => _searchableList(products, 'آگهی‌ای وجود ندارد', (p) => Card(child: ListTile(leading: _productImage(p), onTap: () => _showListing(p), title: AdminText(p['title']?.toString() ?? 'بدون عنوان', maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: AdminText('${p['price'] ?? 0} افغانی • ${p['province'] ?? ''}\n${p['is_active'] == true ? 'فعال' : 'غیرفعال'}${p['moderation_disabled'] == true ? ' • 🚫 محدودیت مدیریت' : ''}${p['is_featured'] == true ? ' • ویژه' : ''}${p['is_pinned'] == true ? ' • پین' : ''}${_boostTiming(p).isNotEmpty ? '\n${_boostTiming(p)}' : ''}${p['moderation_reason']?.toString().trim().isNotEmpty == true ? '\nدلیل: ${p['moderation_reason']}' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'view') _showListing(p); if (v == 'status') _run(() => _AdminApi.patch('/admin/products/${p['id']}/status', widget.token, {'is_active': p['is_active'] != true, 'reason': p['is_active'] == true ? 'آگهی توسط مدیریت بازارک به دلیل بررسی قوانین غیرفعال شد.' : ''}), success: p['is_active'] == true ? 'آگهی غیرفعال شد و تحت محدودیت مدیریت قرار گرفت.' : 'آگهی فعال شد و محدودیت مدیریت برداشته شد.'); if (v == 'promotion') _promotion(p); if (v == 'delete') _confirmDelete(p); }, itemBuilder: (_) => [PopupMenuItem(value: 'view', child: AdminText('مشاهده آگهی')), PopupMenuItem(value: 'status', child: AdminText(p['is_active'] == true ? '🚫 غیرفعال کردن به دلیل قوانین' : '✅ فعال کردن و رفع محدودیت')), PopupMenuItem(value: 'promotion', child: AdminText('ویژه / پین')), PopupMenuItem(value: 'delete', child: AdminText('حذف آگهی'))]))));

  Widget _users() => _searchableList(users, 'کاربری وجود ندارد', (u) => Card(child: ListTile(leading: CircleAvatar(child: AdminText((_person(u).isEmpty ? 'ک' : _person(u)).characters.first)), title: AdminText(_person(u)), subtitle: AdminText('${u['phone'] ?? ''}\n${u['city'] ?? ''}${u['is_blocked'] == true ? '\n🚫 مسدود: ${u['block_reason'] ?? ''}' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'block') _blockUser(u); if (v == 'warn') _warnUser(u); if (v == 'wallet') _creditWallet(u); }, itemBuilder: (_) => [PopupMenuItem(value: 'block', child: AdminText(u['is_blocked'] == true ? 'رفع مسدودی' : 'مسدود کردن')), PopupMenuItem(value: 'warn', child: AdminText('ارسال هشدار')), PopupMenuItem(value: 'wallet', child: AdminText('شارژ کیف پول'))]))));

  Widget _reports() => _searchableList(reports, 'گزارشی ثبت نشده است', (r) {
    final listing = r['listing'] is Map ? Map<String, dynamic>.from(r['listing']) : null;
    final owner = r['listing_owner'] is Map ? Map<String, dynamic>.from(r['listing_owner']) : null;
    final reporter = r['reporter'] is Map ? Map<String, dynamic>.from(r['reporter']) : null;
    return Card(child: Padding(padding: EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [if (listing != null) _productImage(listing, height: 70, width: 70) else Icon(Icons.report_problem_outlined, size: 38), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AdminText(listing?['title']?.toString() ?? 'آگهی حذف شده/نامشخص', style: TextStyle(fontWeight: FontWeight.bold)), AdminText('صاحب: ${_person(owner)}'), AdminText('گزارش‌دهنده: ${_person(reporter)}')])), _statusChip(r['status']?.toString() ?? 'open')]),
      SizedBox(height: 8), AdminText('دلیل: ${r['reason'] ?? '-'}'), AdminText('شماره صاحب: ${owner?['phone'] ?? '-'} • شماره گزارش‌دهنده: ${reporter?['phone'] ?? '-'}'), AdminText('تاریخ: ${r['created_at'] ?? '-'}'),
      SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.icon(onPressed: () => _reportAction(r), icon: Icon(Icons.gavel), label: AdminText('رسیدگی کامل')), if (listing != null) OutlinedButton.icon(onPressed: () => _showListing(listing), icon: Icon(Icons.visibility), label: AdminText('مشاهده آگهی')), if (r['status'] != 'dismissed') TextButton(onPressed: () => _run(() => _AdminApi.patch('/admin/reports/${r['id']}', widget.token, {'status': 'dismissed'}), success: 'گزارش رد شد.'), child: AdminText('رد گزارش'))]),
    ])));
  });

  String _supportType(String type) {
    switch (type) {
      case 'bug': return '🐞 گزارش اشکال';
      case 'suggestion': return '💡 پیشنهاد';
      case 'report': return '📢 گزارش آگهی یا کاربر';
      default: return '💬 پشتیبانی';
    }
  }

  String _supportStatus(String status) {
    switch (status) {
      case 'open': return 'جدید';
      case 'in_progress': return 'در حال بررسی';
      case 'answered': return 'پاسخ داده شد';
      case 'resolved': return 'حل شد';
      case 'closed': return 'بسته شد';
      default: return 'جدید';
    }
  }

  Future<void> _replySupport(Map<String, dynamic> item) async {
    final reply = TextEditingController(text: item['admin_reply']?.toString() ?? '');
    String status = item['status']?.toString() ?? 'open';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: AdminText((item['title'] ?? item['subject'])?.toString() ?? 'درخواست پشتیبانی'),
          content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminText('نوع: ${_supportType(item['type']?.toString() ?? 'support')}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            AdminText('کاربر: ${_person(item['user'] is Map ? Map<String, dynamic>.from(item['user']) : null)}'),
            AdminText('شماره: ${item['user'] is Map ? (item['user']['phone'] ?? '-') : '-'}'),
            Divider(height: 24),
            AdminText('متن کاربر:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            AdminText(item['message']?.toString() ?? '-'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              decoration: InputDecoration(labelText: _adminTranslate(context, 'وضعیت'), border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: 'open', child: AdminText('جدید')),
                DropdownMenuItem(value: 'in_progress', child: AdminText('در حال بررسی')),
                DropdownMenuItem(value: 'answered', child: AdminText('پاسخ داده شد')),
                DropdownMenuItem(value: 'resolved', child: AdminText('حل شد')),
                DropdownMenuItem(value: 'closed', child: AdminText('بسته شد')),
              ],
              onChanged: (v) => setDialogState(() => status = v ?? 'open'),
            ),
            SizedBox(height: 12),
            TextField(controller: reply, minLines: 4, maxLines: 8, maxLength: 5000, decoration: InputDecoration(labelText: _adminTranslate(context, 'پاسخ مدیر'), hintText: _adminTranslate(context, 'پاسخ خود را برای کاربر بنویسید...'), border: OutlineInputBorder())),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: AdminText('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: AdminText('ذخیره و ارسال پاسخ')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _run(
        () => _AdminApi.patch('/admin/support/requests/${item['id']}', widget.token, {'status': status, 'admin_reply': reply.text.trim()}),
        success: 'پاسخ پشتیبانی ثبت شد.',
      );
    }
    reply.dispose();
  }

  Widget _support() => _searchableList(support, 'درخواست پشتیبانی وجود ندارد', (s) {
    final user = s['profiles'] is Map ? Map<String, dynamic>.from(s['profiles']) : (s['user'] is Map ? Map<String, dynamic>.from(s['user']) : null);
    final status = s['status']?.toString() ?? 'open';
    return Card(child: ListTile(
      leading: Icon(status == 'new' ? Icons.mark_email_unread_outlined : Icons.support_agent_outlined),
      title: AdminText((s['title'] ?? s['subject'])?.toString() ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: AdminText('${_supportType(s['type']?.toString() ?? 'support')} • ${_supportStatus(status)}\nکاربر: ${_person(user)} • ${user?['phone'] ?? '-'}\n${s['message']?.toString() ?? '-'}', maxLines: 4, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
      trailing: Icon(Icons.reply_outlined),
      onTap: () => _replySupport(s),
    ));
  });

  Widget _warnings() => _searchableList(warnings, 'هشداری ثبت نشده است', (w) => Card(child: ListTile(leading: Icon(Icons.warning_amber_outlined), title: AdminText(w['message']?.toString() ?? '-'), subtitle: AdminText('کاربر: ${w['user_id'] ?? '-'}\n${w['created_at'] ?? '-'}'), isThreeLine: true)));

  Widget _finance() {
    final orders = List<Map<String, dynamic>>.from((money['orders'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final subs = List<Map<String, dynamic>>.from((money['subscriptions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final tx = List<Map<String, dynamic>>.from((money['transactions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    return RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: EdgeInsets.all(12), children: [
      Card(child: ListTile(title: AdminText('درآمد واقعی', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: AdminText('${NumberFormatLike.afn(money['revenue_afn'])} افغانی', style: TextStyle(fontSize: 24)))),
      Card(child: ListTile(title: AdminText('در انتظار تأیید'), subtitle: AdminText('${NumberFormatLike.afn(money['pending_afn'])} افغانی'), leading: Icon(Icons.hourglass_top))),
      Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 6), child: AdminText('سفارش‌های ارتقا', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      if (orders.isEmpty) Card(child: ListTile(title: AdminText('سفارشی وجود ندارد'))),
      ...orders.take(100).map((o) => Card(child: ListTile(onTap: () { final l = o['listing']; if (l is Map) _showListing(Map<String, dynamic>.from(l)); }, leading: o['listing'] is Map ? _productImage(Map<String, dynamic>.from(o['listing']), height: 58, width: 58) : Icon(Icons.campaign), title: AdminText('${o['package']?['title'] ?? o['package_id'] ?? 'ارتقا'} • ${o['amount_afn'] ?? 0} افغانی'), subtitle: AdminText('کاربر: ${_person(o['user'] is Map ? Map<String, dynamic>.from(o['user']) : null)}\nآگهی: ${o['listing']?['title'] ?? o['listing_id'] ?? '-'}\nرسید/پیگیری: ${o['payment_reference'] ?? '-'}\nثبت سفارش: ${o['created_at'] ?? '-'}${o['status'] == 'paid' && o['updated_at'] != null ? '\nتأیید و شروع: ${_dateTimeAdminText(o['updated_at'])}' : ''}${o['listing'] is Map && _boostTiming(Map<String, dynamic>.from(o['listing'])).isNotEmpty ? '\n${_boostTiming(Map<String, dynamic>.from(o['listing']))}' : ''}${o['listing'] is Map && Map<String, dynamic>.from(o['listing'])['boost_until'] != null ? '\nپایان Boost: ${_dateTimeAdminText(Map<String, dynamic>.from(o['listing'])['boost_until'])}' : ''}'), isThreeLine: true, trailing: o['status'] == 'pending' ? PopupMenuButton<String>(onSelected: (v) => _orderStatus(o, v), itemBuilder: (_) => [PopupMenuItem(value: 'paid', child: AdminText('تأیید پرداخت')), PopupMenuItem(value: 'rejected', child: AdminText('رد پرداخت')), PopupMenuItem(value: 'cancelled', child: AdminText('لغو سفارش'))]) : Chip(label: AdminText(o['status']?.toString() ?? '-'))))),
      Padding(padding: EdgeInsets.fromLTRB(4, 18, 4, 6), child: AdminText('اشتراک‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      ...subs.take(100).map((s) => Card(child: ListTile(title: AdminText('${_subscriptionPlanTitle(s['plan'])} • ${s['price_afn'] ?? 0} افغانی • ${s['status'] ?? ''}'), subtitle: AdminText('کاربر: ${_person(s['user'] is Map ? Map<String, dynamic>.from(s['user']) : null)}\nرسید/پیگیری: ${s['payment_reference'] ?? '-'}\n${_subscriptionTiming(s)}'), isThreeLine: true, trailing: s['status'] == 'pending' ? PopupMenuButton<String>(onSelected: (v) => _subscriptionStatus(s, v), itemBuilder: (_) => [PopupMenuItem(value: 'active', child: AdminText('تأیید و فعال‌سازی')), PopupMenuItem(value: 'rejected', child: AdminText('رد درخواست')), PopupMenuItem(value: 'cancelled', child: AdminText('لغو'))]) : Chip(label: AdminText(s['status']?.toString() ?? '-'))))),
      Padding(padding: EdgeInsets.fromLTRB(4, 18, 4, 6), child: AdminText('تراکنش‌های کیف پول', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      if (tx.isEmpty) Card(child: ListTile(title: AdminText('تراکنش فعال وجود ندارد'))),
      ...tx.take(100).map((t) => Card(child: ListTile(title: AdminText('${t['type'] ?? '-'} • ${t['amount_afn'] ?? 0} افغانی'), subtitle: AdminText('کاربر: ${_person(t['user'] is Map ? Map<String, dynamic>.from(t['user']) : null)}\n${t['description'] ?? ''}\n${t['created_at'] ?? ''}'), isThreeLine: true, trailing: IconButton(tooltip: _adminTranslate(context, 'بایگانی'), onPressed: () => _archiveTransaction(t), icon: Icon(Icons.archive_outlined))))),
      SizedBox(height: 8), AdminText('تراکنش بایگانی‌شده از فهرست اصلی حذف می‌شود و برای جلوگیری از به‌هم‌ریختگی گزارش مالی، رکورد اصلی پاک نمی‌شود.'),
    ]));
  }

  Widget _security() => _searchableList(securityEvents, 'هنوز رویداد امنیتی ثبت نشده است', (e) => Card(child: ListTile(leading: Icon(e['success'] == true ? Icons.check_circle_outline : Icons.error_outline), title: AdminText(e['success'] == true ? 'ورود موفق مدیریت' : 'تلاش ناموفق ورود مدیریت'), subtitle: AdminText('ایمیل: ${e['email'] ?? '-'}\nIP: ${e['ip_address'] ?? '-'}\nتاریخ: ${e['created_at'] ?? '-'}'), isThreeLine: true)));

  Widget _searchableList(List<Map<String, dynamic>> source, String empty, Widget Function(Map<String, dynamic>) builder) => _AdminListView(source: source, empty: empty, builder: builder);

  Widget _productImage(Map<String, dynamic> p, {double? height, double? width}) {
    String? url;
    try { final v = jsonDecode(p['image_url']?.toString() ?? ''); if (v is List && v.isNotEmpty) url = v.first.toString(); else if (p['image_url']?.toString().startsWith('http') == true) url = p['image_url'].toString(); } catch (_) {}
    return SizedBox(width: width ?? 64, height: height ?? 64, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: url != null ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined)) : Icon(Icons.image_outlined)));
  }

  Widget _statusChip(String s) => Chip(label: AdminText(s == 'open' ? 'باز' : s == 'reviewed' ? 'بررسی‌شده' : 'ردشده'));
}

class NumberFormatLike {
  static String listing(dynamic item) {
    if (item is Map && (item['is_negotiable'] == true || item['is_negotiable'] == 1)) return 'توافقی';
    final n = num.tryParse(item is Map ? '${item['price'] ?? 0}' : '0') ?? 0;
    final raw = n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
    final formatted = raw.replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'), (_) => '.');
    faDigits = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    final fa = formatted.replaceAllMapped(RegExp(r'[0-9]'), (m) => faDigits[int.parse(m.group(0)!)]);
    return (item is Map && '${item['currency'] ?? 'AFN'}'.toUpperCase() == 'USD') ? '\$$fa' : '$fa افغانی';
  }

  static String afn(dynamic value) {
    final n = num.tryParse(value?.toString() ?? '') ?? 0;
    return n.toStringAsFixed(n % 1 == 0 ? 0 : 2).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',');
  }
}

class _AdminListView extends StatefulWidget {
  final List<Map<String, dynamic>> source; final String empty; final Widget Function(Map<String, dynamic>) builder;
  _AdminListView({required this.source, required this.empty, required this.builder});
  @override State<_AdminListView> createState() => _AdminListViewState();
}
class _AdminListViewState extends State<_AdminListView> {
  final search = TextEditingController(); String q = '';
  @override void dispose() { search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final items = widget.source.where((x) => q.isEmpty || x.values.any((v) => v.toString().toLowerCase().contains(q.toLowerCase()))).toList();
    return Column(children: [Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 4), child: TextField(controller: search, onChanged: (v) => setState(() => q = v.trim()), decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: _adminTranslate(context, 'جستجو در این بخش...'), border: OutlineInputBorder()))), Expanded(child: items.isEmpty ? Center(child: AdminText(widget.empty)) : ListView.builder(padding: EdgeInsets.fromLTRB(12, 8, 12, 24), itemCount: items.length, itemBuilder: (_, i) => widget.builder(items[i]))) ]);
  }
}

class _ErrorState extends StatelessWidget {
  final String error; final VoidCallback retry;
  _ErrorState({required this.error, required this.retry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_off, size: 56), SizedBox(height: 12), AdminText(_adminFriendlyError(error), textAlign: TextAlign.center), SizedBox(height: 16), FilledButton.icon(onPressed: retry, icon: Icon(Icons.refresh), label: AdminText('تلاش دوباره'))])));
}
