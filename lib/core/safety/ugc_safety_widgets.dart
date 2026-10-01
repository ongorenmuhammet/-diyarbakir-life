import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import 'ugc_safety_provider.dart';

void showEulaDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.gavel, color: Colors.blueAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kullanıcı Sözleşmesi ve Topluluk Kuralları (EULA)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Diyarbakır Life 21 Kullanıcı Sözleşmesi ve Güvenlik İlkeleri',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '1. SIFIR TOLERANS POLİTİKASI (ZERO TOLERANCE):\nPlatformumuzda nefret söylemi, hakaret, taciz, müstehcenlik, şiddet tehdidi, dolandırıcılık veya her türlü yasa dışı ve sakıncalı içeriğe KESİNLİKLE SIFIR TOLERANS gösterilmektedir.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '2. İÇERİK DENETİMİ VE 24 SAAT İÇİNDE KALDIRMA:\nKullanıcılar tarafından paylaşılan tüm içerikler (ilanlar, işletmeler, iş ilanları ve halı saha paylaşımları) moderasyon denetimine tabidir. Bildirilen veya tespit edilen sakıncalı içerikler en geç 24 saat içinde incelenir ve derhal sistemden kaldırılır.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '3. KULLANICI İHRAÇ VE ENGELLEME:\nTopluluk kurallarını ihlal eden, sakıncalı içerik paylaşan veya diğer kullanıcıları taciz eden kişilerin hesapları derhal ve kalıcı olarak engellenir ve platformdan ihraç edilir.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '4. KULLANICI HAKLARI:\nHer kullanıcı, uygunsuz bulduğu içerikleri şikayet etme (Şikayet Et) ve rahatsız edici kullanıcıları tek tıkla engelleme (Kullanıcıyı Engelle) hakkına sahiptir. Engellenen kullanıcıların içerikleri akışınızdan anında kaldırılır.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Anladım'),
        ),
      ],
    ),
  );
}

void showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String contentType,
  required String contentId,
  required String contentTitle,
  required String reportedUser,
}) {
  final reasons = [
    'Müstehcen veya Uygunsuz İçerik',
    'Nefret Söylemi veya Şiddet',
    'Taciz veya Hakaret',
    'Yanıltıcı / Dolandırıcılık',
    'Yasa Dışı veya Sakıncalı İçerik',
    'Diğer',
  ];
  String selectedReason = reasons.first;
  final descController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.orange),
            SizedBox(width: 8),
            Text('İçeriği Şikayet Et', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lütfen şikayet nedeninizi seçin. Şikayetiniz 24 saat içinde incelenecektir:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (val) {
                      if (val != null) setState(() => selectedReason = val);
                    },
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Açıklama ekleyin (İsteğe bağlı)',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final auth = ref.read(authProvider);
              await ref.read(ugcSafetyProvider.notifier).reportContent(
                    contentType: contentType,
                    contentId: contentId,
                    contentTitle: contentTitle,
                    reportedUser: reportedUser,
                    reason: selectedReason,
                    description: descController.text.trim(),
                    reporterEmail: auth.email,
                  );
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (infoCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Şikayetiniz Alındı'),
                      ],
                    ),
                    content: const Text(
                      'Bildiriminiz için teşekkür ederiz. Topluluk güvenliği ilkemiz doğrultusunda bu içerik en geç 24 saat içinde moderatörlerimiz tarafından incelenecek ve uygunsuz bulunması durumunda derhal kaldırılacaktır.',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(infoCtx).pop(),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Şikayeti Gönder'),
          ),
        ],
      ),
    ),
  );
}

void showBlockDialog(
  BuildContext context,
  WidgetRef ref, {
  required String userIdentifier,
  required String userName,
  VoidCallback? onBlocked,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 8),
          Text('Kullanıcıyı Engelle'),
        ],
      ),
      content: Text(
        '"' + userName + '" adlı kullanıcıyı engellemek istediğinize emin misiniz?\n\nBu kullanıcı engellendiğinde, paylaştığı tüm ilanlar ve içerikler akışınızda bir daha gösterilmeyecektir.',
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            await ref.read(ugcSafetyProvider.notifier).blockUser(userIdentifier);
            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            onBlocked?.call();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("'" + userName + "' engellendi. Bu kullanıcının içerikleri gizlendi."),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
          child: const Text('Engelle'),
        ),
      ],
    ),
  );
}

class UgcSafetyActionMenu extends ConsumerWidget {
  final String contentType;
  final String contentId;
  final String contentTitle;
  final String reportedUserEmail;
  final String reportedUserName;
  final VoidCallback? onUserBlocked;

  const UgcSafetyActionMenu({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.contentTitle,
    required this.reportedUserEmail,
    required this.reportedUserName,
    this.onUserBlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Güvenlik ve Şikayet',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'report') {
          showReportDialog(
            context,
            ref,
            contentType: contentType,
            contentId: contentId,
            contentTitle: contentTitle,
            reportedUser: reportedUserEmail.isNotEmpty ? reportedUserEmail : reportedUserName,
          );
        } else if (val == 'block') {
          showBlockDialog(
            context,
            ref,
            userIdentifier: reportedUserEmail.isNotEmpty ? reportedUserEmail : reportedUserName,
            userName: reportedUserName.isNotEmpty ? reportedUserName : 'Bu kullanıcı',
            onBlocked: onUserBlocked,
          );
        } else if (val == 'eula') {
          showEulaDialog(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Text('İçeriği Şikayet Et'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block_outlined, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Kullanıcıyı Engelle', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'eula',
          child: Row(
            children: [
              Icon(Icons.gavel_outlined, color: Colors.blueGrey, size: 20),
              SizedBox(width: 10),
              Text('Topluluk Kuralları (EULA)', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
