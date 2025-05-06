// lib/components/help_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para Clipboard

class HelpButton extends StatelessWidget {
  final Color? iconColor;

  const HelpButton({
    super.key,
    this.iconColor,
  });

  void _showHelpDialog(BuildContext context) {
    const String email = 'sistemas@sanjuandelrio.gob.mx';

    // Definimos los estilos de texto que queremos usar en el diálogo
    // Inspirados en los estilos de onboarding_screen.dart
    const TextStyle titleStyle = TextStyle(
      fontSize: 20, // Similar a los títulos de página del onboarding
      fontWeight: FontWeight.bold,
      color: Color(0xFF0B3B60), // Color principal de la app
    );

    const TextStyle contentStyle = TextStyle(
      fontSize: 15, // Similar a los subtítulos/texto de cuerpo
      color: Color(0xFF0B3B60), // Buena legibilidad para el contenido
    );

    final TextStyle emailStyle = contentStyle.copyWith(
      // Basado en contentStyle pero en negrita
      fontWeight: FontWeight.bold,
      // Podrías añadir un color específico si quieres que el email resalte más
      // color: Color(0xFF0377C6), // Ejemplo de color azul para el email
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Información de Ayuda',
            style: titleStyle, // Aplicamos el estilo al título del diálogo
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Si necesitas ayuda, contáctanos:',
                style:
                    contentStyle, // Aplicamos el estilo al texto introductorio
              ),
              const SizedBox(
                  height: 12), // Un poco más de espacio antes del email
              SelectableText(
                email,
                style: emailStyle, // Aplicamos el estilo al email
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: email));
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    // Usar dialogContext para el SnackBar aquí
                    const SnackBar(
                        content: Text('Email copiado al portapapeles')),
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Copiar Email',
                // Opcional: Aplicar un estilo a los botones del diálogo si es necesario
                // style: TextStyle(color: Color(0xFF0B3B60), fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: email));
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Email copiado al portapapeles')),
                );
              },
            ),
            TextButton(
              child: const Text(
                'Cerrar',
                // Opcional: Aplicar un estilo
                // style: TextStyle(color: Color(0xFF0B3B60), fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor =
        iconColor ?? Theme.of(context).iconTheme.color ?? Colors.black;

    return IconButton(
      icon: Icon(
        Icons.help_outline,
        color: effectiveIconColor,
      ),
      tooltip: 'Ayuda y Soporte',
      onPressed: () {
        _showHelpDialog(context);
      },
    );
  }
}