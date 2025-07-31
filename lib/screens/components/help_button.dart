// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpButton extends StatefulWidget {
  //? Color del ícono
  final Color? iconColor;

  //? Color de fondo del botón
  final Color? backgroundColor;

  //? Email de soporte
  final String supportEmail;

  //? URL de FAQs o documentación
  final String? faqUrl;

  //? Asunto predeterminado para el correo
  final String emailSubject;

  const HelpButton({
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.faqUrl,
    this.emailSubject = 'Soporte y ayuda',
    this.supportEmail = 'sistemas@sanjuandelrio.gob.mx',
  });

  @override
  State<HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: widget.supportEmail,
      queryParameters: {
        'subject': widget.emailSubject,
      },
    );
    if (await canLaunchUrl(uri)) {
      //* Usamos externalApplication para forzar app nativa de correo
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AlertHelper.showAlert(
        'No se pudo abrir la aplicación de correo',
        type: AlertType.error,
      );
    }
  }

  void _copyEmail() {
    Clipboard.setData(ClipboardData(text: widget.supportEmail));
    Navigator.of(context).pop();
    AlertHelper.showAlert(
      'Email copiado al portapapeles',
      type: AlertType.success,
    );
  }

  void _showHelpOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copiar email'),
                onTap: () {
                  _copyEmail();
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Enviar email'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _launchEmail();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconC = widget.iconColor ?? Colors.white;
    final bgC = widget.backgroundColor ??
        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9);

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        _showHelpOptions();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgC, bgC.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.help_outline,
            color: iconC,
            size: 22,
          ),
        ),
      ),
    );
  }
}
